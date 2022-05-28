vim.cmd("let g:choosewin_label = '1234567890'")
vim.cmd("let g:choosewin_tablabel = 'abcdefghijklmnop'")

local tree_cb = require("nvim-tree.config").nvim_tree_callback
require'nvim-tree'.setup {
  diagnostics = {
    enable = true,
  },
  remove_file_close_window = false,
  update_focused_file = {
    enable = true,
  },
  view = {
    mappings = {
      list = {
        -- drop the - shortcut, i want it for vim-choosewin
        { key = "U", cb = tree_cb("dir_up") }, -- my change
        { key = "-", action = "" },
      }
    }
  },
  renderer = {
    icons = {
      glyphs = {
        git = {
          unstaged = "",
        }
      }
    }
  },
  actions = {
    open_file = {
      window_picker = {
        chars = '234567890ABCDEFGHIJKLMNOPQRSTUVWXYZ',
      }
    }
  },
  filters = {
    custom = { ".git" }, -- ignore .git
  },
}

vim.g.glow_width = 120
vim.g.glow_border = "rounded"

require("todo-comments").setup {
  highlight = {
    pattern = {[[\s*\/\/.*<(KEYWORDS)\s*]], [[\s*--.*<(KEYWORDS)\s*]], [[\s*#.*<(KEYWORDS)\s*]]},
  }
}

-- vim: ts=2 sts=2 sw=2 et
