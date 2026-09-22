---
name: cross-host-workflow
description: Validate workflows that span local and remote hosts before declaring them working or giving the user a final path.
user-invocable: false
metadata:
  internal: true
---

# Cross-host workflow validation

Test the complete workflow from both endpoints. Confirm that each endpoint can perform its role before declaring the workflow working or presenting it as the final path.

- Herdr's prefix is the right Command key, remapped to F12 in the HID stack because a terminal cannot transmit a bare modifier; that indirection is what makes the same key work over ssh. Herdr accepts `f13` and then ignores its escape sequence, and its onboarding overlay swallows every key when `onboarding = false` is absent, so any future rebinding must be proved against a running Herdr, not just `config check`. Keep the config, terminal course, and regression synchronized.
