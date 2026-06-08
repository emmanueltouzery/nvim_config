-- improve % matching for ruby files. the builtin way is confused when eg `break if var` is introduced
local function smart_percent()
  local node = vim.treesitter.get_node()

  if node:type() == 'if' or node:type() == 'do_block' then
    local cur_row = vim.fn.line('.') - 1
    local start_row, start_col, end_row, end_col = node:range()
    if cur_row == start_row then
      vim.api.nvim_win_set_cursor(0, { end_row + 1, end_col })
    else
      vim.api.nvim_win_set_cursor(0, { start_row + 1, start_col })
    end
    return
  end

  vim.cmd('normal! %')
  return
end

vim.keymap.set('n', '%', smart_percent, { silent = true, desc = "better ruby jump", buffer = 0 })
