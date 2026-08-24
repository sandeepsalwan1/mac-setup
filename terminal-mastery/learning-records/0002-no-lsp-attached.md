# The `gd` mapping cannot work: no LSP is configured

`plugins/navigation.lua` maps `gd` to `Snacks.picker.lsp_definitions()`, but the config
installs no language server - no `nvim-lspconfig`, no `mason`, no `vim.lsp.enable()` call
anywhere under `home/.config/nvim/`. So `gd` returns nothing.

This matters for teaching: it is a genuine gap in the inherited config, not a mistake the
learner made, and it must be named as such or he will assume he broke something. Until it
is fixed, teach `*` (search word under cursor) and `<leader>s` (project grep) as the
navigation primitives. Adding an LSP is a natural later lesson and roughly fifteen lines.

**Implications:** also means no autocomplete and no Treesitter, so expect regex syntax
highlighting and no popup completion menu. Do not promise IDE behaviour.
