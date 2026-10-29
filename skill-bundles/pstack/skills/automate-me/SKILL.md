---
name: automate-me
description: "Adapt the user's working style into their existing mode skill using explicit preferences and relevant Codex, Claude, and Pi history. Use for automate me or update my mode."
---

# Automate me

1. Find the existing personal mode. This installation uses `poteto-mode`. Preserve established choices unless the user changes them.
2. Read `../poteto-mode/references/transcripts.md`. Mine relevant history directly. Default to the active workspace; use broader history only when requested. Explicit instructions are sufficient evidence. Inferred habits need two distinct examples, with transcript pointers.
3. Group findings into autonomy, communication, engineering, verification, and memory. Use the existing `/kun` skill for guidance when clustering involves a real workflow judgment. Apply the user's preferences over generic advice. FirstMate retains orchestration.
4. Make the smallest useful edit with the existing skill-creator and writing guidance. Reference existing skills instead of duplicating their contents. Keep model choices out.
5. Show the changed behavior briefly and verify skill discovery. Do not require an interview when the conversation and local evidence already answer it. Ask only what the user alone can resolve.

Keep personal history local. Do not run Backpass automatically. Do not publish, push, or open a PR merely to save a personal preference.
