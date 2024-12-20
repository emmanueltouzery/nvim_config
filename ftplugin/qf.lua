local function clear_qf()
  vim.fn.setqflist({}, 'f')
  vim.cmd[[MarkifyClear]]
  vim.cmd[[Markify]]
end

vim.keymap.set('n', '<localleader>x', clear_qf, { buffer = true, desc = "Clear the quickfix list" })
