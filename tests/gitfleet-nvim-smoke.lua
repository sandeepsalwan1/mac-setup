local lua_dir = assert(vim.env.GIT_FLEET_LUA_DIR, 'GIT_FLEET_LUA_DIR is required')
local smoke_home = vim.env.GIT_FLEET_SMOKE_HOME
local home = assert(vim.uv.fs_realpath(smoke_home or vim.env.HOME), 'HOME is required')
package.path = lua_dir .. '/?.lua;' .. package.path

local picker_calls = {}
_G.Snacks = {
  picker = {
    pick = function(opts) picker_calls[#picker_calls + 1] = opts end,
  },
}

local neogit_calls = {}
local neogit_cwds = {}
local reused_neogit_buf = nil
package.loaded.neogit = nil
package.preload.neogit = function()
  return {
    open = function(opts)
      if reused_neogit_buf and vim.api.nvim_buf_is_valid(reused_neogit_buf) then
        vim.api.nvim_set_current_buf(reused_neogit_buf)
      end
      neogit_calls[#neogit_calls + 1] = opts or false
      neogit_cwds[#neogit_cwds + 1] = vim.fn.getcwd()
    end,
  }
end

local function wait_for(predicate, message)
  assert(vim.wait(10000, predicate, 20), message)
end

local function assert_neogit_opened(index, selected, expected_cwd, expected_scope)
  assert(neogit_calls[index] and neogit_calls[index].cwd == selected.path, 'Neogit did not open at the selected worktree')
  assert(neogit_cwds[index] == selected.path, 'Neogit did not resolve from the selected worktree')
  assert(vim.fn.getcwd() == expected_cwd, 'opening Neogit changed the picker window directory')
  assert(vim.fn.haslocaldir() == expected_scope, 'opening Neogit changed the picker directory scope')
end

local function close_neogit_and_wait(expected_picker_count, message, status_buf)
  status_buf = status_buf or vim.api.nvim_create_buf(false, true)
  if vim.bo[status_buf].filetype ~= 'NeogitStatus' then
    vim.api.nvim_set_current_buf(status_buf)
    vim.bo[status_buf].filetype = 'NeogitStatus'
  end
  vim.api.nvim_buf_delete(status_buf, { force = true })
  wait_for(function() return #picker_calls == expected_picker_count end, message)
end

vim.fn.chdir(home)
local fleet = dofile(lua_dir .. '/gitfleet.lua')
assert(fleet.context() == home, 'workspace context was not detected')

vim.cmd('enew')
vim.cmd('lcd ' .. vim.fn.fnameescape(home))
assert(fleet.context() == home, 'window-local workspace directory was not detected')

local uri_buf = vim.api.nvim_create_buf(false, true)
vim.api.nvim_set_current_buf(uri_buf)
vim.api.nvim_buf_set_name(uri_buf, 'oil://' .. home .. '/projects')
assert(fleet.context() == home, 'URI-backed buffer did not use its window-local workspace')

local directory_buf = vim.api.nvim_create_buf(false, true)
vim.api.nvim_set_current_buf(directory_buf)
vim.api.nvim_buf_set_name(directory_buf, home)
assert(fleet.context() == home, 'workspace directory buffer was not detected')

local new_file_buf = vim.api.nvim_create_buf(false, true)
vim.api.nvim_set_current_buf(new_file_buf)
vim.api.nvim_buf_set_name(new_file_buf, home .. '/projects/not-created-yet.txt')
vim.fn.chdir(vim.fn.fnamemodify(home, ':h'))
assert(fleet.context() == home, 'new file buffer did not resolve its workspace')
vim.fn.chdir(home)

fleet.open()
wait_for(function() return #picker_calls == 1 end, 'first fleet picker did not open')
if smoke_home then
  assert(#picker_calls[1].items > 0, 'real fleet picker has no changed repositories')
else
  assert(#picker_calls[1].items == 1, 'first picker must contain one changed repository')
end
local first_item = picker_calls[1].items[1]
assert(first_item.rec, 'picker item has no summary record: ' .. vim.inspect(first_item))

if smoke_home then
  local selected = first_item
  local cwd_scope = vim.fn.haslocaldir()
  picker_calls[1].confirm({ close = function() end }, selected)
  assert_neogit_opened(1, selected, home, cwd_scope)
  close_neogit_and_wait(2, 'closing Neogit did not return to the real fleet picker')
  print(('gitfleet picker smoke: rows=%d selected=%s return=ok'):format(#picker_calls[1].items, selected.path))
  return
end

local fresh_scope = vim.fn.haslocaldir()
picker_calls[1].confirm({ close = function() end }, first_item)
assert_neogit_opened(1, first_item, home, fresh_scope)
close_neogit_and_wait(2, 'closing a fresh Neogit buffer did not return to the picker')
assert(#picker_calls[2].items == 1, 'fresh Neogit return did not reuse the selected fleet view')

local second = home .. '/projects/second'
vim.fn.mkdir(second, 'p')
assert(vim.system({ 'git', 'init', '-q', second }):wait().code == 0, 'could not create second repository')
vim.fn.writefile({ 'new work' }, second .. '/new.txt')

fleet.open()
wait_for(function() return #picker_calls == 3 end, 'second fleet picker did not open')
assert(#picker_calls[3].items == 2, 'explicit fleet open reused stale rows')

local selected = picker_calls[3].items[1]
local picker_closed = false
local cwd_scope = vim.fn.haslocaldir()
local picker_buf = vim.api.nvim_get_current_buf()
reused_neogit_buf = vim.api.nvim_create_buf(false, true)
vim.api.nvim_set_current_buf(reused_neogit_buf)
vim.bo[reused_neogit_buf].filetype = 'NeogitStatus'
vim.api.nvim_set_current_buf(picker_buf)
picker_calls[3].confirm({
  close = function() picker_closed = true end,
}, selected)
assert(picker_closed, 'confirm did not close the picker')
assert_neogit_opened(2, selected, home, cwd_scope)

local third = home .. '/projects/third'
vim.fn.mkdir(third, 'p')
assert(vim.system({ 'git', 'init', '-q', third }):wait().code == 0, 'could not create third repository')
vim.fn.writefile({ 'new work' }, third .. '/new.txt')

close_neogit_and_wait(4, 'closing a reused Neogit buffer did not return to the picker', reused_neogit_buf)
reused_neogit_buf = nil
assert(#picker_calls[4].items == 2, 'return-to-picker re-scanned instead of using the selected fleet view')

local external_home = vim.fn.fnamemodify(home, ':h') .. '/external-home'
local external_repo = external_home .. '/projects/external'
vim.fn.mkdir(external_home .. '/state', 'p')
vim.fn.writefile({ 'workspace' }, external_home .. '/VISION.md')
assert(vim.system({ 'git', 'init', '-q', external_repo }):wait().code == 0, 'could not create external repository')
vim.fn.writefile({ 'new work' }, external_repo .. '/new.txt')
external_repo = assert(vim.uv.fs_realpath(external_repo), 'external repository did not resolve')
vim.cmd('enew')
vim.fn.chdir(external_home)
assert(fleet.context() == external_home, 'workspace outside HOME was not detected')
fleet.open()
wait_for(function() return #picker_calls == 5 end, 'external-home fleet picker did not open')
local external_found = false
for _, item in ipairs(picker_calls[5].items) do
  if item.path == external_repo then external_found = true end
end
assert(external_found, 'fleet picker omitted a detected workspace outside HOME')

local false_home = vim.fn.fnamemodify(home, ':h') .. '/not-a-home'
vim.fn.mkdir(false_home .. '/state', 'p')
vim.fn.writefile({ 'workspace' }, false_home .. '/VISION.md')
vim.fn.writefile({ 'not a directory' }, false_home .. '/projects')
vim.cmd('enew')
vim.fn.chdir(false_home)
assert(fleet.context() == nil, 'wrong marker types were treated as a workspace context')

vim.fn.chdir(vim.fn.fnamemodify(home, ':h'))
assert(fleet.context() == nil, 'outside directory was treated as a workspace context')
fleet.open()
assert(#picker_calls == 5, 'outside context unexpectedly opened the fleet picker')
assert(#neogit_calls == 3 and neogit_calls[3] == false, 'outside context was not plain Neogit')
