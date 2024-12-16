-- https://github.com/nvim-treesitter/nvim-treesitter/issues/6723#issuecomment-2151597595
-- better than the builtin XML indent, although still not perfect
vim.bo.indentexpr = "nvim_treesitter#indent()"
