return {
  {
    'NeogitOrg/neogit',
    dependencies = { 'nvim-lua/plenary.nvim', 'sindrets/diffview.nvim' },
    -- Neogit is single-repository by design. Inside an agent workspace root this
    -- key first offers a picker of every changed repository in the fleet, then
    -- opens ordinary Neogit on the one chosen. Everywhere else it is plain
    -- Neogit, unchanged. See lua/gitfleet.lua and docs/git-fleet.md.
    init = function() require('gitfleet').setup() end,
    keys = {
      {
        '<leader>g',
        function() require('gitfleet').open() end,
        desc = 'Neogit (fleet picker in an agent workspace root)',
      },
    },
  },
  {
    'lewis6991/gitsigns.nvim',
    event = 'BufWinEnter',
    opts = { current_line_blame = true },  -- who last touched this line
  },
}
