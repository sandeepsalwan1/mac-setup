# Personal pstack bundle

Portable skills adapted for Sandeep. The files in `skills/` are the editable source. The mac-setup `skills/<name>` entries and agent discovery folders point here with symlinks. Edits take effect for every linked local agent on its next skill read. Start a fresh session to refresh a cached skill list.

Technical tasks automatically load `poteto-mode` through mac-setup's shared `home/AGENTS.md`. It chooses only relevant skills. You can also say `use potato mode`, `/skill:poteto-mode` in Pi, `/poteto-mode` in Claude, or `$poteto-mode` in Codex.

## What changed

- FirstMate retains agent orchestration. No agent spawning, model panels, model choices, or budget setup.
- `correct`, `recall`, `reflect`, and `automate-me` use scoped Codex, Claude, and Pi history. Transcript lookup instructions live in `skills/poteto-mode/references/transcripts.md`.
- Reuse existing solutions first. One-off work uses a direct path; automation needs an observed blocker or repeated need.
- Existing `teach`, `technical-writing`, `writing-br`, and `/kun` remain authoritative. `automate-me` uses `/kun` when clustering findings needs workflow judgment.
- Useful engineering principles and TypeScript examples are retained. The duration example now states that a plain number needs boundary validation.
- `4x4` is retired. This Mac's recovery copy is `~/.local/state/pstack-backups/20261028/4x4`. The portable linker also retires old installations with its usual backup behavior.

## Source and updates

Adapted from [backnotprop/pstack](https://github.com/backnotprop/pstack), the portable mirror of [Cursor's pstack](https://github.com/cursor/plugins/tree/main/pstack/skills). [manifest.json](manifest.json) pins the source revision. MIT attribution is preserved in `LICENSE`.

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

## Skill selection

[manifest.json](manifest.json) owns the included and excluded skill lists.

`teach` and `technical-writing` were excluded because existing versions already serve those roles. The other exclusions remove orchestration, interview or presentation workflows, bot UI, aggressive comment cleanup, and specialized formal-verification tooling not needed for this setup.

See [Agent setup](../../README.md#agent-setup) for discovery folders and the external profile ownership rule. That rule also applies when enabling this bundle again.
