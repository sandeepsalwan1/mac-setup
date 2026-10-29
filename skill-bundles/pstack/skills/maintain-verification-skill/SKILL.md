---
name: maintain-verification-skill
description: "Audit a project verification skill and feature map against current source and live user journeys. Use for maintain-verification-skill or audit the verify skill."
---

# Maintain a verification skill

Locate the requested project verification skill. Read its feature map and check each feature against source. Reconcile missing or stale entries. Search directly; do not start source-reader agents.

Follow the skill's launch, health-check, drive, and cleanup instructions. Exercise every mapped feature through the real user interface. Use one owned instance where appropriate. Recheck health after a surprising failure. Preserve captured evidence and clean up only resources this run created.

Edit only the verification skill and its owned scripts or feature map. Distinguish doc drift from a product regression; report a product regression rather than rewriting the map to hide it. Rerun every corrected journey. Report clean, changed, or incomplete, including exact coverage and any unreachable prerequisite. Open a PR only when the task calls for one.
