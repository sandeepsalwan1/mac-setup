# Personal pstack bundle

42 skills adapted for Sandeep. The files in `skills/` are the editable source. The mac-setup `skills/<name>` entries and agent discovery folders point here with symlinks. Edits take effect for every linked local agent on its next skill read. Start a fresh session to refresh a cached skill list.

Technical tasks automatically load `poteto-mode` through mac-setup's shared `home/AGENTS.md`. It chooses only relevant skills. You can also say `use potato mode`, `/skill:poteto-mode` in Pi, `/poteto-mode` in Claude, or `$poteto-mode` in Codex.

## What changed

- FirstMate retains agent orchestration. No agent spawning, model panels, model choices, or budget setup.
- `correct`, `recall`, `reflect`, and `automate-me` use scoped Codex, Claude, and Pi history. Transcript lookup instructions live in `skills/poteto-mode/references/transcripts.md`.
- Reuse existing solutions first. One-off work uses a direct path; automation needs an observed blocker or repeated need.
- Existing `teach`, `technical-writing`, `writing-br`, and `/kun` remain authoritative. `automate-me` uses `/kun` when clustering findings needs workflow judgment.
- Useful engineering principles and TypeScript examples are retained. The duration example now states that a plain number needs boundary validation.
- `4x4` is retired. This Mac's recovery copy is `~/.local/state/pstack-backups/20261028/4x4`. The portable linker also retires old installations with its usual backup behavior.

## Source and updates

Adapted from [backnotprop/pstack](https://github.com/backnotprop/pstack) at `25abb38559ddbabec563646224d09eff9a250eca`, the portable mirror of [Cursor's pstack](https://github.com/cursor/plugins/tree/main/pstack/skills). MIT attribution is preserved in `LICENSE`. `manifest.json` records the exact selection.

This is a local customization, with no automatic upstream updates. Compare a new upstream revision against the recorded revision, review the diff, then port useful changes. Do not overwrite this folder with an upstream install. Never restore orchestration or model defaults during an update.

## Disable or remove

Run `bash skill-bundles/pstack/disable.sh` from the mac-setup checkout. This removes only symlinks that resolve into this bundle, including the mac-setup registration links. It leaves the editable bundle and every unrelated skill intact. The automatic instruction becomes inactive because `~/.skills/poteto-mode/SKILL.md` is absent.

To remove it permanently, disable it first, then remove this bundle folder. Remove the optional poteto-mode line from `home/AGENTS.md` too if desired. No agent histories or configs need deletion.

To enable it again, recreate the registration links and run the existing linker:

```bash
for source in "$PWD"/skill-bundles/pstack/skills/*; do
  name="$(basename "$source")"
  [ -e "skills/$name" ] || [ -L "skills/$name" ] || ln -s "../skill-bundles/pstack/skills/$name" "skills/$name"
done
scripts/link-portable-skills
```

To restore the original upstream contents instead, disable this customization and install the selected original skills separately. Review their model and orchestration behavior before enabling them.

## Included skills

- `architect`
- `automate-me`
- `benchmark-checklist`
- `blast-radius`
- `correct`
- `create-verification-skill`
- `how`
- `maintain-verification-skill`
- `poteto-help`
- `poteto-mode`
- `principle-attack-the-premise`
- `principle-boundary-discipline`
- `principle-build-the-lever`
- `principle-encode-lessons-in-structure`
- `principle-exhaust-the-design-space`
- `principle-experience-first`
- `principle-explain-the-number`
- `principle-fix-root-causes`
- `principle-foundational-thinking`
- `principle-guard-the-context-window`
- `principle-laziness-protocol`
- `principle-make-operations-idempotent`
- `principle-migrate-callers-then-delete-legacy-apis`
- `principle-minimize-reader-load`
- `principle-model-the-domain`
- `principle-never-block-on-the-human`
- `principle-outcome-oriented-execution`
- `principle-prove-it-works`
- `principle-redesign-from-first-principles`
- `principle-separate-before-serializing-shared-state`
- `principle-sequence-verifiable-units`
- `principle-subtract-before-you-add`
- `principle-test-behavior-not-implementation`
- `principle-type-system-discipline`
- `recall`
- `reflect`
- `sharpen`
- `show-me-your-work`
- `tdd`
- `typescript-best-practices`
- `unslop`
- `why`

## Excluded skills

- `arena`
- `bro`
- `create-formal-verification-skill`
- `figure-it-out`
- `in-your-own-words`
- `interrogate`
- `ketchup`
- `ketchup-video`
- `maintain-formal-verification-skill`
- `make-bot-ui`
- `no-comments`
- `setup-pstack`
- `statechart`
- `swarm`
- `teach`
- `technical-writing`

`teach` and `technical-writing` were excluded because existing versions already serve those roles. The other exclusions remove orchestration, interview or presentation workflows, bot UI, aggressive comment cleanup, and specialized formal-verification tooling not needed for this setup.

The distribution covers local Pi, Claude Code, Codex, Kiro, Hermes, and Cursor discovery folders. It does not install anything on a separately hosted Hermes server.
