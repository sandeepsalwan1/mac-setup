---
name: create-readonly-db-role
description: Provision a hardened SELECT-only Postgres role for safe agent data access. Use when the user asks for a read-only database role, safe production query access, or Postgres agent access. This skill creates the role plan; day-to-day querying belongs in a project-local skill.
---

# Create a Read-Only Postgres Role

A SELECT-only role prevents writes at the database permission layer. Query timeouts and a sensitive-table denylist reduce the remaining data-exposure and load risks.

## Design

1. Grant `SELECT` and schema usage only.
2. Set `default_transaction_read_only = on` and a bounded `statement_timeout`.
3. Revoke access to tables containing secrets or restricted personal data.
4. Never grant the `auth` schema by default.
5. Decide explicitly how Row Level Security applies. `BYPASSRLS` reveals every row and should be used only when that is the intended access model.

## Workflow

1. Check whether the role already exists.
2. Ask the user which schemas and tables must remain inaccessible.
3. Write reviewed SQL to a repository file. Include application, verification, rotation, and rollback instructions.
4. Have the user or an authorized database operator apply production DDL. Do not run it merely because this skill was invoked.
5. Store the connection string in an approved secret manager or local environment. Never commit it.
6. Verify both successful reads and rejected writes before declaring the role ready.

## Template

```sql
create role agent_reader with login password 'REPLACE_ME';
alter role agent_reader set default_transaction_read_only = on;
alter role agent_reader set statement_timeout = '10s';

grant usage on schema public to agent_reader;
grant select on all tables in schema public to agent_reader;
alter default privileges for role postgres in schema public
  grant select on tables to agent_reader;

revoke select on table public.secrets from agent_reader;
revoke select on table public.private_events from agent_reader;
```

Use `alter role agent_reader bypassrls` only after the user confirms that unrestricted row visibility is correct. Roll back with `drop owned by agent_reader; drop role agent_reader;` after checking ownership implications.

## Verification

Using the read-only connection:

```bash
psql "$READONLY_DATABASE_URL" -X -c "select current_user;"
psql "$READONLY_DATABASE_URL" -X -c "show statement_timeout;"
psql "$READONLY_DATABASE_URL" -X -c "select count(*) from public.<expected_table>;"
psql "$READONLY_DATABASE_URL" -X -c "delete from public.<expected_table> where false;"
psql "$READONLY_DATABASE_URL" -X -c "begin; set transaction read write; delete from public.<expected_table> where false; rollback;"
psql "$READONLY_DATABASE_URL" -X -c "select * from public.<denylisted_table> limit 1;"
```

The first three commands must succeed. Both write probes and the denylisted read must fail. If a write succeeds, revoke the role's privileges and stop until the grants are corrected.
