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
