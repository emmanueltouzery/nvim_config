local function add_buf(bufnr)
  if vim.b.diff_buf_a ~= nil then
    local buf_a = vim.b.diff_buf_a
    vim.b.diff_buf_a = nil
    vim.cmd("tabnew")
    vim.api.nvim_win_set_buf(0, buf_a)
    vim.cmd('vsplit')
    vim.cmd('wincmd r')
    vim.api.nvim_win_set_buf(0, bufnr)
    vim.cmd("windo diffthis")
  else
    vim.b.diff_buf_a = bufnr
  end
end

local function add_file_to_diff()
  local buf_a = require'diffview.lib'.get_current_view().cur_layout.a.file.bufnr
  local buf_b = require'diffview.lib'.get_current_view().cur_layout.b.file.bufnr
  if vim.api.nvim_buf_line_count(buf_a) > 1 then
    add_buf(buf_a)
  else
    add_buf(buf_b)
  end
end

-- sometimes in git, a file is marked as Deleted then Added instead of Renamed.
-- this allows to mark the deleted file, then the added file and we get a clean
-- diff of the changes for that renamed file.
vim.keymap.set('n', '<localleader>a', add_file_to_diff, { buffer = true, desc = "Add file to diff" })

local function diff_with_difftastic()
  local absolute_file_path = require'diffview.lib'.get_current_view().panel.cur_file.absolute_path
  local git_path = vim.fs.root(absolute_file_path, '.git')
  local file_path = absolute_file_path:gsub(escape_pattern(git_path) .. "/", "")
  local conflicts = require'diffview.lib'.get_current_view().panel.cur_file.stats.conflicts
  if conflicts ~= nil and conflicts > 0 then
    open_command_in_popup("difft " .. file_path)
  else
    local left_commit = require'diffview.lib'.get_current_view().left.commit
    local right_commit = require'diffview.lib'.get_current_view().right.commit
    if left_commit ~= nil and right_commit ~= nil then
      open_difftastic(file_path, left_commit, right_commit)
    else
      open_command_in_popup("PAGER=cat GIT_EXTERNAL_DIFF='difft --display side-by-side-show-both' git diff " .. file_path)
    end
  end
end

vim.keymap.set('n', '<localleader>f', diff_with_difftastic, { buffer = true, desc = "Diff with difftastic" })

local function toggle_expand_panel()
  if vim.w.orig_width == nil then
    local bufnr = vim.api.nvim_win_get_buf(0)
    local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
    local maxcols = 0
    for _, line in ipairs(lines) do
      local cols = #line
      if cols > maxcols then
        maxcols = cols
      end
    end
    vim.w.orig_width = vim.api.nvim_win_get_width(0)
    vim.api.nvim_win_set_width(0, maxcols)
  else
    vim.api.nvim_win_set_width(0, vim.w.orig_width)
    vim.w.orig_width = nil
  end
end
vim.keymap.set('n', '<localleader>s', toggle_expand_panel, { buffer = true, desc = "Toggle expansion of file panel to fit" })

require 'key-menu'.set('n', '<localleader>x', {buffer = true, desc='Conflicts'})

vim.keymap.set("n", "<localleader>xb", function()
  local merge_ctx = require'diffview.lib'.get_current_view().cur_entry.merge_ctx
  local commit = merge_ctx.base.hash
  vim.cmd(":DiffviewOpen " .. commit .. "^.." .. commit)
end, {buffer = true, desc="view conflicting commit - base"})

vim.keymap.set("n", "<localleader>xo", function()
  local merge_ctx = require'diffview.lib'.get_current_view().cur_entry.merge_ctx
  local commit = merge_ctx.ours.hash
  vim.cmd(":DiffviewOpen " .. commit .. "^.." .. commit)
end, {buffer = true, desc="view conflicting commit - ours"})

vim.keymap.set("n", "<localleader>xt", function()
  local merge_ctx = require'diffview.lib'.get_current_view().cur_entry.merge_ctx
  local commit = merge_ctx.theirs.hash
  vim.cmd(":DiffviewOpen " .. commit .. "^.." .. commit)
end, {buffer = true, desc="view conflicting commit - theirs"})

