-- Fleet-wide git view.
--
-- Why this exists: `<leader>g` opens Neogit, and Neogit is inherently a
-- single-repository tool. It resolves exactly one repository from the current
-- buffer or cwd, so it structurally cannot show sibling worktrees or other
-- checkouts. Inside an agent workspace root, where work is spread over many
-- clones and pooled worktrees at once, that answers the wrong question.
--
-- So `<leader>g` becomes context-sensitive, and only there:
--   * inside an agent workspace root -> a picker of every CHANGED repository,
--     and <CR> opens ordinary Neogit rooted at the one you picked
--   * anywhere else                  -> plain Neogit, exactly as before
--
-- Every row shown here comes verbatim from `scripts/git-fleet-status --json`,
-- which is also the plain shell command. The summary logic lives in that one
-- script, so the two surfaces cannot drift apart.

local M = {}

-- An agent workspace root is a checkout carrying all three of these. Any one of
-- them alone is far too common to be a reliable signal.
local HOME_MARKERS = {
  ['VISION.md'] = 'file',
  ['projects'] = 'directory',
  ['state'] = 'directory',
}

local function is_home(dir)
  for marker, expected_type in pairs(HOME_MARKERS) do
    local stat = vim.uv.fs_stat(dir .. '/' .. marker)
    if not stat or stat.type ~= expected_type then return false end
  end
  return true
end

-- Walk up from `start` looking for an agent workspace root. Returns nil when there is
-- none, which is the signal to leave `<leader>g` completely alone.
local function find_home(start)
  local dir = start
  while dir and dir ~= '' do
    if is_home(dir) then return dir end
    local parent = vim.fn.fnamemodify(dir, ':h')
    if parent == dir then return nil end
    dir = parent
  end
  return nil
end

local function context_dir()
  local name = vim.api.nvim_buf_get_name(0)
  local stat = name ~= '' and vim.uv.fs_stat(name) or nil
  if stat and stat.type == 'directory' then
    local absolute = vim.fn.fnamemodify(name, ':p')
    if absolute ~= '/' then absolute = absolute:gsub('/+$', '') end
    return absolute
  end
  if name ~= '' and not name:match('^[%w+.-]+://') then
    return vim.fn.fnamemodify(name, ':p:h')
  end
  return vim.fn.getcwd()
end

-- The script ships next to this file in the dotfiles repo, but the activated
-- Neovim config can be a read-only store path, so look in the usual checkout
-- locations too. GIT_FLEET_STATUS overrides everything, which is what the
-- isolated smoke runs use.
local function find_script()
  local candidates = {
    vim.env.GIT_FLEET_STATUS,
    vim.fn.exepath('git-fleet-status'),
    vim.fn.expand('~/.dotfiles/scripts/git-fleet-status'),
    vim.fn.expand('~/mac-setup/scripts/git-fleet-status'),
  }
  for _, candidate in ipairs(candidates) do
    if candidate and candidate ~= '' and vim.fn.executable(candidate) == 1 then
      return candidate
    end
  end
  return nil
end

-- Last scan, so returning to the picker after visiting a repository is instant
-- rather than another full fleet walk.
local cached = nil

local function decode(stdout)
  local items = {}
  for line in (stdout or ''):gmatch('[^\n]+') do
    local ok, rec = pcall(vim.json.decode, line)
    if ok and type(rec) == 'table' and rec.path then
      items[#items + 1] = {
        text = rec.row,
        path = rec.path,
        file = rec.path,
        rec = rec,
      }
    end
  end
  return items
end

local show

local function scan_command(exe)
  local command = { exe, '--json' }
  local workspace = M.context()
  if not workspace then return command end

  local home = vim.uv.fs_realpath(vim.fn.expand('~')) or vim.fn.expand('~')
  local root = vim.uv.fs_realpath(workspace) or workspace
  local inside_home = root == home or root:sub(1, #home + 1) == home .. '/'
  if not inside_home then
    vim.list_extend(command, { '-r', home, '-r', root })
  end
  return command
end

-- Closing Neogit with `q` should land back on the fleet picker, but only when the
-- picker is what opened it.
--
-- This stays deliberately small. Neogit's `q` wipes its status buffer, so one
-- BufWipeout autocmd bound to that single buffer number is the whole mechanism:
-- because it is scoped to one buffer and fires once, it cannot trigger on a diff,
-- a commit message or any other Neogit buffer, and nothing patches or wraps
-- Neogit itself. The augroup is recreated with clear = true on every use, so a
-- hook can never outlive the visit that armed it or leak into plain `<leader>g`.
local AUGROUP = 'GitFleetReturn'
local return_buffers = {}

local function clear_return_hook()
  vim.api.nvim_create_augroup(AUGROUP, { clear = true })
  return_buffers = {}
end

local function attach_return_hook(group, buf)
  if not vim.api.nvim_buf_is_valid(buf) or vim.bo[buf].filetype ~= 'NeogitStatus' then return end
  if return_buffers[buf] then return end
  return_buffers[buf] = true
  vim.api.nvim_create_autocmd('BufWipeout', {
    group = group,
    buffer = buf,
    once = true,
    callback = function(args)
      return_buffers[args.buf] = nil
      -- Not while Neovim is quitting: :qa also wipes the buffer, and
      -- reopening a picker on the way out would be nothing but obstruction.
      if vim.v.exiting ~= vim.NIL and vim.v.exiting ~= 0 then return end
      vim.schedule(function() M.picker({ cached = true }) end)
    end,
  })
end

local function arm_return_hook()
  local group = vim.api.nvim_create_augroup(AUGROUP, { clear = true })
  return_buffers = {}
  local filetype_hook = vim.api.nvim_create_autocmd('FileType', {
    group = group,
    pattern = 'NeogitStatus',
    once = true,
    callback = function(args) attach_return_hook(group, args.buf) end,
  })
  return function()
    local buf = vim.api.nvim_get_current_buf()
    attach_return_hook(group, buf)
    if return_buffers[buf] then pcall(vim.api.nvim_del_autocmd, filetype_hook) end
  end
end

local function open_neogit(item)
  local ok, neogit = pcall(require, 'neogit')
  if not ok then
    vim.notify('gitfleet: neogit is not available', vim.log.levels.ERROR)
    return
  end
  local attach_existing = arm_return_hook()
  -- Newer Neogit takes an explicit cwd; older versions resolve from the current
  -- window. Set both inputs, then restore the picker window even when Neogit opens
  -- in another tab.
  local window = vim.api.nvim_get_current_win()
  local previous_cwd
  vim.api.nvim_win_call(window, function()
    previous_cwd = vim.fn.chdir(item.path)
  end)
  local opened, err = pcall(neogit.open, { cwd = item.path })
  if not opened then opened, err = pcall(neogit.open) end
  if opened then attach_existing() end
  if previous_cwd and previous_cwd ~= '' and vim.api.nvim_win_is_valid(window) then
    vim.api.nvim_win_call(window, function()
      vim.fn.chdir(previous_cwd)
    end)
  end
  if not opened then
    clear_return_hook()
    error(err)
  end
end

show = function(items)
  if #items == 0 then
    vim.notify('gitfleet: no changed repositories in the fleet', vim.log.levels.INFO)
    return
  end
  local ok, snacks = pcall(function() return Snacks end)
  if not ok or not snacks or not snacks.picker then
    vim.notify('gitfleet: snacks.picker is not available', vim.log.levels.ERROR)
    return
  end
  snacks.picker.pick({
    source = 'gitfleet',
    title = 'Fleet git changes (' .. #items .. ' changed)',
    items = items,
    format = 'text',
    layout = { preset = 'default' },
    confirm = function(picker, item)
      picker:close()
      if item then open_neogit(item) end
    end,
    preview = function(ctx)
      local item = ctx.item
      if not item then return end
      local out = vim.fn.systemlist({
        'git', '-C', item.path, '--no-optional-locks',
        'status', '--short', '--branch',
      })
      ctx.preview:set_lines(out)
      ctx.preview:highlight({ ft = 'gitcommit' })
      return true
    end,
  })
end

-- Scan the fleet, then show the picker. Asynchronous on purpose: a fleet walk
-- takes a couple of seconds over dozens of worktrees and must not freeze the
-- editor while it runs.
function M.picker(opts)
  opts = opts or {}
  if opts.cached and cached then
    show(cached)
    return
  end
  local exe = find_script()
  if not exe then
    vim.notify(
      'gitfleet: git-fleet-status not found; set $GIT_FLEET_STATUS or install the dotfiles',
      vim.log.levels.ERROR
    )
    return
  end
  vim.notify('gitfleet: scanning fleet...', vim.log.levels.INFO)
  vim.system(scan_command(exe), { text = true }, function(res)
    vim.schedule(function()
      if res.code ~= 0 then
        vim.notify('gitfleet: scan failed: ' .. (res.stderr or ''), vim.log.levels.ERROR)
        return
      end
      cached = decode(res.stdout)
      show(cached)
    end)
  end)
end

-- The agent workspace root containing the current buffer or cwd, or nil when there is
-- none. Exposed so the branch `<leader>g` will take can be inspected directly.
function M.context()
  return find_home(context_dir())
end

-- What `<leader>g` calls. Outside an agent workspace root this is plain Neogit and
-- nothing about the old behaviour changes - including no return hook, so `q`
-- there simply closes Neogit as it always has.
function M.open()
  if M.context() then
    M.picker()
  else
    clear_return_hook()
    require('neogit').open()
  end
end

-- Force the fleet picker regardless of context, for scripted use and for when
-- the captain wants it from an unrelated buffer.
function M.setup()
  vim.api.nvim_create_user_command('GitFleet', function()
    M.picker()
  end, { desc = 'Fleet-wide git changes picker' })
end

return M
