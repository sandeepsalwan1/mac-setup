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
-- Every current and since-last-run row shown here comes verbatim from
-- `scripts/git-fleet-status --json`, which is also the plain shell command. The
-- summary logic lives in that one script, so the two surfaces cannot drift.

local M = {}

-- An agent workspace root is a checkout carrying all three of these. Any one of
-- them alone is far too common to be a reliable signal.
local HOME_MARKERS = { 'VISION.md', 'projects', 'state' }

local function is_home(dir)
  for _, marker in ipairs(HOME_MARKERS) do
    if not vim.uv.fs_stat(dir .. '/' .. marker) then return false end
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
  if name ~= '' and vim.uv.fs_stat(name) then
    return vim.fn.fnamemodify(name, ':p:h')
  end
  return vim.uv.cwd()
end

-- The script ships next to this file in the dotfiles repo, but the activated
-- Neovim config can be a read-only store path, so look in the usual checkout
-- locations too. GIT_FLEET_STATUS overrides everything, which is what the
-- isolated smoke runs use.
--
-- The candidates are appended one at a time rather than written as a table
-- literal on purpose. GIT_FLEET_STATUS is normally unset, and a literal starting
-- with a nil element is a table with a hole: ipairs stops at the first nil, so it
-- would visit none of the fallbacks and report the script as missing on every
-- machine where the override is not exported.
local function find_script()
  local candidates = {}
  local function consider(path)
    if path and path ~= '' then candidates[#candidates + 1] = path end
  end
  consider(vim.env.GIT_FLEET_STATUS)
  consider(vim.fn.exepath('git-fleet-status'))
  consider(vim.fn.expand('~/.dotfiles/scripts/git-fleet-status'))
  consider(vim.fn.expand('~/mac-setup/scripts/git-fleet-status'))
  for _, candidate in ipairs(candidates) do
    if vim.fn.executable(candidate) == 1 then
      return candidate
    end
  end
  return nil
end

-- Last scan, so returning to the picker after visiting a repository is instant
-- rather than another full fleet walk.
local cached = nil

local function item(rec, text)
  return {
    text = text,
    path = rec.path,
    file = vim.uv.fs_stat(rec.path) and rec.path or nil,
    rec = rec,
  }
end

local function decode(stdout)
  local view = { meta = nil, since = {}, current = {} }
  for line in (stdout or ''):gmatch('[^\n]+') do
    local ok, rec = pcall(vim.json.decode, line)
    if ok and type(rec) == 'table' then
      if rec.type == 'meta' then
        view.meta = rec
      elseif rec.type == 'repo' and rec.path then
        view.current[#view.current + 1] = item(rec, rec.row)
        if rec.activity == 'new' or rec.activity == 'updated' then
          view.since[#view.since + 1] = item(rec, rec.activityRow)
        end
      elseif rec.type == 'cleared' and rec.path then
        view.since[#view.since + 1] = item(rec, rec.activityRow)
      end
    end
  end
  return view
end

local show

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

local function clear_return_hook()
  vim.api.nvim_create_augroup(AUGROUP, { clear = true })
end

local function arm_return_hook()
  local group = vim.api.nvim_create_augroup(AUGROUP, { clear = true })
  vim.api.nvim_create_autocmd('FileType', {
    group = group,
    pattern = 'NeogitStatus',
    once = true,
    callback = function(args)
      vim.api.nvim_create_autocmd('BufWipeout', {
        group = group,
        buffer = args.buf,
        once = true,
        callback = function()
          -- Not while Neovim is quitting: :qa also wipes the buffer, and
          -- reopening a picker on the way out would be nothing but obstruction.
          if vim.v.exiting ~= vim.NIL then return end
          vim.schedule(function() M.picker({ cached = true }) end)
        end,
      })
    end,
  })
end

local function open_neogit(item)
  if not item.path or not vim.uv.fs_stat(item.path) then
    vim.notify('gitfleet: checkout no longer exists: ' .. (item.path or ''), vim.log.levels.WARN)
    return
  end
  local ok, neogit = pcall(require, 'neogit')
  if not ok then
    vim.notify('gitfleet: neogit is not available', vim.log.levels.ERROR)
    return
  end
  arm_return_hook()
  -- Newer Neogit takes an explicit cwd; older versions resolve from the window's
  -- directory, so fall back to setting that.
  if not pcall(neogit.open, { cwd = item.path }) then
    vim.cmd('lcd ' .. vim.fn.fnameescape(item.path))
    neogit.open()
  end
end

local preview_generation = 0
local MAX_PREVIEW_LINES = 1200

local function preview(ctx)
  preview_generation = preview_generation + 1
  local generation = preview_generation
  local item = ctx.item
  if not item then return true end
  if item.section then
    ctx.preview:set_lines({ item.text })
    return true
  end
  if not item.path or not vim.uv.fs_stat(item.path) then
    ctx.preview:set_lines({ item.text, '', 'Checkout no longer exists.' })
    return true
  end

  ctx.preview:set_lines({ 'Loading current diff for ' .. (item.rec.label or item.path) .. '...' })

  local status_args = {
    'git', '-C', item.path, '--no-optional-locks',
    'status', '--short', '--branch',
  }
  local diff_args = {
    'git', '-C', item.path, '--no-optional-locks',
    'diff', '--no-ext-diff', '--find-renames', '--stat', '--patch',
  }
  local base = item.rec.base
  if base and base ~= '' then
    diff_args[#diff_args + 1] = base
  elseif item.rec.head and item.rec.head ~= '' then
    diff_args[#diff_args + 1] = item.rec.head
  end
  diff_args[#diff_args + 1] = '--'

  local pending = 2
  local results = {}
  local function done(kind, result)
    results[kind] = result
    pending = pending - 1
    if pending ~= 0 then return end
    vim.schedule(function()
      if generation ~= preview_generation or not ctx.preview.win:buf_valid() then return end
      local status = vim.split(results.status.stdout or '', '\n', { plain = true, trimempty = true })
      local patch = vim.split(results.diff.stdout or '', '\n', { plain = true, trimempty = true })
      local lines = { 'STATUS' }
      vim.list_extend(lines, #status > 0 and status or { '(clean working tree)' })
      lines[#lines + 1] = ''
      lines[#lines + 1] = 'CURRENT DIFF'
      if results.diff.code ~= 0 then
        local err = vim.trim(results.diff.stderr or '')
        lines[#lines + 1] = err ~= '' and err or '(diff unavailable)'
      else
        vim.list_extend(lines, #patch > 0 and patch or { '(no tracked-file diff)' })
      end
      if #lines > MAX_PREVIEW_LINES then
        lines = vim.list_slice(lines, 1, MAX_PREVIEW_LINES)
        lines[#lines + 1] = ('(diff truncated at %d lines)'):format(MAX_PREVIEW_LINES)
      end
      ctx.preview:set_lines(lines)
      ctx.preview:highlight({ ft = 'diff' })
    end)
  end

  vim.system(status_args, { text = true }, function(result) done('status', result) end)
  vim.system(diff_args, { text = true }, function(result) done('diff', result) end)
  return true
end

show = function(view)
  local meta = view.meta or {}
  local items = {}
  vim.list_extend(items, view.since)
  items[#items + 1] = {
    text = ('ALL CURRENT CHANGES (%d)'):format(#view.current),
    section = true,
  }
  vim.list_extend(items, view.current)

  local ok, snacks = pcall(function() return Snacks end)
  if not ok or not snacks or not snacks.picker then
    vim.notify('gitfleet: snacks.picker is not available', vim.log.levels.ERROR)
    return
  end
  local since_label
  if meta.hasPrevious then
    since_label = ('since %s: %d changed'):format(meta.previousAt or 'last run', #view.since)
  else
    since_label = 'baseline saved'
  end
  snacks.picker.pick({
    source = 'gitfleet',
    title = ('Fleet %s | %d current'):format(since_label, #view.current),
    items = items,
    format = 'text',
    layout = { preset = 'default' },
    matcher = { sort_empty = false },
    sort = { fields = { 'idx' } },
    confirm = function(picker, item)
      if not item or item.section then return end
      picker:close()
      open_neogit(item)
    end,
    preview = preview,
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
  vim.system({ exe, '--json' }, { text = true }, function(res)
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
