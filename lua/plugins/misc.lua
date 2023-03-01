vim.cmd("let g:choosewin_label = '1234567890'")
vim.cmd("let g:choosewin_tablabel = 'abcdefghijklmnop'")
local tree_cb = require("nvim-tree.config").nvim_tree_callback
require'nvim-tree'.setup {
  diagnostics = {
    enable = true,
  },
  update_focused_file = {
    enable = true,
    update_root = true,
  },
  select_prompts = true,
  view = {
    centralize_selection = true,
    signcolumn = "no",
    float = {
      enable = true,
      quit_on_focus_loss = false,
      open_win_config = function()
        local width = vim.api.nvim_get_option("columns")
        local height = vim.api.nvim_get_option("lines")
        local float_width = 37
        return {
          relative = "editor",
          border = "rounded",
          width = float_width,
          height = height - 5,
          row = 1,
          col = width - float_width - 2,
        }
      end,
    },
    mappings = {
      list = {
        -- drop the - shortcut, i want it for vim-choosewin
        { key = "U", cb = tree_cb("dir_up") }, -- my change
        { key = "-", action = "" },
        -- drop C-e and C-x, i want the scrolling
        { key = "<C-e>", action = "" },
        { key = "<C-x>", action = "" },
        -- drop s and S, i want lightning jumps
        { key = "S", action = "" },
        { key = "s", action = "" },
        -- remap search to C-s
        { key = "<c-s>", action = "search_node" },
        -- override to open with no picker (same as `o`)
        { key = "<CR>", action = "edit_no_picker" },
        -- open with picker (same as `O`)
        { key = "<M-CR>", action = "open_file" },
      }
    }
  },
  renderer = {
    highlight_opened_files = "name",
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
     quit_on_open = false,
      window_picker = {
        enable = true,
        chars = '1234567890ABCDEFGHIJKLMNOPQRSTUVWXYZ',
      }
    },
    remove_file = {
      close_window = false,
    },
  },
  filters = {
    custom = { "^.git$" }, -- ignore .git folder
  },
}
vim.cmd[[au Colorscheme * hi NvimTreeOpenedFile guifg=#ecbe7b]]

local api = require("nvim-tree.api")
local Event = api.events.Event
api.events.subscribe(Event.FileCreated, function(data)
  if string.match(data.fname, "%.tsx$") then
    vim.api.nvim_exec([[!echo "import React from 'react';" > ]] .. data.fname, {output=false})
  end
end)

vim.cmd[[autocmd BufNewFile *.tsx exe "norm iimport React from 'react';"]]

-- more visible comments compared to the doom-nvim default
-- nice in general, almost required in diff mode.
vim.cmd[[au Colorscheme * hi Comment guifg=#808080]]

vim.g.glow_width = 120
vim.g.glow_border = "rounded"

require("todo-comments").setup {
  highlight = {
    pattern = {[[\s*\/\/.*<(KEYWORDS)\s*]], [[\s*--.*<(KEYWORDS)\s*]], [[\s*#.*<(KEYWORDS)\s*]]},
  }
}

-- vim: ts=2 sts=2 sw=2 et
