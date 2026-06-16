local function clear_qf()
  vim.fn.setqflist({}, 'f')
  vim.cmd[[MarkifyClear]]
  vim.cmd[[Markify]]
end

vim.keymap.set('n', '<localleader>x', clear_qf, { buffer = true, desc = "Clear the quickfix list" })

local function remove_qf_under_cursor()
  local qf = vim.fn.getqflist()
  table.remove(qf, vim.fn.line('.'))
  vim.fn.setqflist(qf, 'u')
  require('quicker').refresh()
  vim.cmd[[MarkifyClear]]
  vim.cmd[[Markify]]
end

vim.keymap.set('n', '<localleader>d', remove_qf_under_cursor, { buffer = true, desc = "Remove QF entry under cursor" })
