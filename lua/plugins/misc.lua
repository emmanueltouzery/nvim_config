vim.cmd("let g:choosewin_label = '1234567890'")
vim.cmd("let g:choosewin_tablabel = 'abcdefghijklmnop'")

-- local tree_cb = require("nvim-tree.config").nvim_tree_callback
local function nvim_tree_on_attach(bufnr)
  local api = require "nvim-tree.api"

  local function opts(desc)
    return { desc = "nvim-tree: " .. desc, buffer = bufnr, noremap = true, silent = true, nowait = true }
  end

  -- default mappings
  api.config.mappings.default_on_attach(bufnr)

  -- custom mappings

  -- drop the - shortcut, i want it for vim-choosewin
  vim.keymap.del('n', '-', { buffer = bufnr })
  vim.keymap.set('n', 'U', api.tree.change_root_to_parent, opts('Up'))

  -- drop C-e and C-x, i want the scrolling
  vim.keymap.del('n', '<C-e>', { buffer = bufnr })
  vim.keymap.del('n', '<C-x>', { buffer = bufnr })

  -- drop s and S, i want lightning jumps
  vim.keymap.del('n', 'S', { buffer = bufnr })
  vim.keymap.del('n', 's', { buffer = bufnr })

  -- remap search to C-s
  vim.keymap.set('n', '<C-s>', api.tree.search_node, opts('Search'))

  -- override to open with no picker (same as `o`)
  vim.keymap.set('n', '<CR>',       api.node.open.edit,                  opts('Open'))
  -- open with picker (same as `O`)
  vim.keymap.set('n', '<M-CR>',       api.node.open.no_window_picker,      opts('Open: No Window Picker'))
end

require'nvim-tree'.setup {
  on_attach = nvim_tree_on_attach,
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
  },
  renderer = {
    group_empty = true,
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
  elseif string.match(data.fname, "%.java$") then
    local folders = vim.split(data.fname, '/')
    local package_elements = {}
    for i = #folders-1, 1, -1 do
      if folders[i] == 'java' then
        break
      else
        table.insert(package_elements, folders[i])
      end
    end
    local package_name = ""
    for i = #package_elements, 1, -1 do
      if #package_name > 0 then
        package_name = package_name .. "."
      end
      package_name = package_name .. package_elements[i]
    end
    local class_name = string.gsub(folders[#folders], ".java$", "")
    local path = require("plenary.path")
    path.new(data.fname):write(
      "package " .. package_name .. ";\n\npublic class " .. class_name .. " {\n\n}", 'w'
    )
  end
  -- require'nvim-tree.api'.tree.find_file(data.fname)
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
