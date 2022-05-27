-- Install packer
local install_path = vim.fn.stdpath 'data' .. '/site/pack/packer/start/packer.nvim'

if vim.fn.empty(vim.fn.glob(install_path)) > 0 then
  vim.fn.execute('!git clone https://github.com/wbthomason/packer.nvim ' .. install_path)
end

local packer_group = vim.api.nvim_create_augroup('Packer', { clear = true })
vim.api.nvim_create_autocmd('BufWritePost', { command = 'source <afile> | PackerCompile', group = packer_group, pattern = 'init.lua' })

vim.g.doom_one_terminal_colors = true

require('packer').startup(function(use)
  use 'wbthomason/packer.nvim' -- Package manager
  -- UI to select things (files, grep results, open buffers...)
  use { 'nvim-telescope/telescope.nvim', requires = { 'nvim-lua/plenary.nvim' }, config = function()
      local actions = require("telescope.actions")
      require('telescope').setup {
          defaults = {
              path_display = {'truncate'},
              prompt_prefix = "   ",
              selection_caret = " ",
              layout_config = {
                  width = 0.75,
                  preview_cutoff = 120,
                  horizontal = {
                      preview_width = 0.6,
                  },
              },
              file_ignore_patterns = { "^%.git/", "^node_modules/", "^__pycache__/" },
              mappings = {
                  i = {
                      ['<C-u>'] = false,
                      ['<C-d>'] = false,
                      ["<C-n>"] = actions.cycle_history_next,
                      ["<C-p>"] = actions.cycle_history_prev,
                  },
              },
          },
          pickers = {
              buffers = {
                  mappings = {
                      i = {
                          ["<c-d>"] = actions.delete_buffer + actions.move_to_top,
                      }
                  }
              }
          },
      }

      -- Enable telescope fzf native
      require('telescope').load_extension 'fzf'
  end}
  use { 'nvim-telescope/telescope-fzf-native.nvim', run = 'make' }
  use 'nvim-lualine/lualine.nvim' -- Fancier statusline
  -- Add git related info in the signs columns and popups
  use { 'lewis6991/gitsigns.nvim', requires = { 'nvim-lua/plenary.nvim' }, config = function()
    require("gitsigns").setup {}
  end}
  -- Highlight, edit, and navigate code using a fast incremental parsing library
  use 'nvim-treesitter/nvim-treesitter'
  -- Additional textobjects for treesitter
  use 'nvim-treesitter/nvim-treesitter-textobjects'
  use 'neovim/nvim-lspconfig' -- Collection of configurations for built-in LSP client
  use 'hrsh7th/nvim-cmp' -- Autocompletion plugin
  use 'hrsh7th/cmp-nvim-lsp'
  use 'romgrk/doom-one.vim'
  use {'airblade/vim-rooter', config = function() 
    vim.g['rooter_silent_chdir'] = 1 
    vim.g['rooter_cd_cmd'] = 'lcd'
  end, commit='0415be8b5989e56f6c9e382a04906b7f719cfb38'}
  use {'CodingdAwn/vim-choosewin', commit='554edfec23c9b7fe523f957a90821b4e0da7aa36'} -- fork which adds the "close window" feature
  use {'sindrets/diffview.nvim', commit='39f401c778a3694fecd94872130373586d1038b8',
  config = function()
      local actions = require("diffview.config").actions
      require('diffview').setup {
	  keymaps = {
	      file_panel = {
		  ["-"] = false, -- i want this shortcut for choosewin
		  ["s"] = actions.toggle_stage_entry, -- Stage / unstage the selected entry.
	      }
	  }
      }
      require('diffview').init()
  end
  }
  use {'nvim-telescope/telescope-live-grep-raw.nvim', commit='8124094e11b54a1853c3306d78e6ca9a8d40d0cb'}
  use 'emmanueltouzery/agitator.nvim'
  use {'nvim-telescope/telescope-project.nvim', commit='d317c3cef6917d650d9a638c627b54d3e1173031'}
  -- vim.cmd("let g:yankstack_yank_keys = ['c', 'C', 'd', 'D', 's', 'S', 'x', 'X', 'y', 'Y']")
  -- drop s and S due to lightspeed
  use {'maxbrunsfeld/vim-yankstack', commit='157a659c1b101c899935d961774fb5c8f0775370', config= function()
    vim.cmd("let g:yankstack_yank_keys = ['c', 'C', 'd', 'D', 'x', 'X', 'y', 'Y']") 
  end} -- considered https://github.com/AckslD/nvim-neoclip.lua too
  use {'emmanueltouzery/vim-elixir', commit='735528cecc19ecffa002ffa20176e9984cced970'}
  use {'ellisonleao/glow.nvim', commit='c6685381d31df262b776775b9f4252f6c7fa98d0'}
  use {'tpope/vim-abolish', commit='3f0c8faadf0c5b68bcf40785c1c42e3731bfa522'}
  use {'qpkorr/vim-bufkill', commit='2bd6d7e791668ea52bb26be2639406fcf617271f'}
  use {'lifepillar/vim-cheat40', commit='ae237b02f9031bc82a8ad9202bffee2bcef71ed1'}
  use {'ggandor/lightspeed.nvim', commit='23565bcdd45afea0c899c71a367b14fc121dbe13', config = function()
      require'lightspeed'.setup {
	  ignore_case = true,
      }
  end}
  use {'samoshkin/vim-mergetool', commit='0275a85256ad173e3cde586d54f66566c01b607f'}
  use {'tpope/vim-dispatch', commit='00e77d90452e3c710014b26dc61ea919bc895e92'} -- used by vim-test
  use {'vim-test/vim-test', commit='56bbfa295fe62123d2ebe8ed57dd002afab46097'}
  -- vim-markify, considered alternative: https://github.com/tomtom/quickfixsigns_vim
  use {'dhruvasagar/vim-markify', commit='14158865c0f37a02a5d6d738437eb00a821b31ef', config = function()
    vim.g.markify_error_text = ""
    vim.g.markify_warning_text = ""
    vim.g.markify_info_text = ""
    vim.g.markify_info_texthl = "Todo"
  end}
  use {'jose-elias-alvarez/null-ls.nvim', commit='af192263b33764fa91d3fa578abd9e674a1984c7', config = function()

    require("null-ls").setup({
      sources = {
        -- require("null-ls").builtins.formatting.stylua,
        require("null-ls").builtins.diagnostics.eslint,
        require("null-ls").builtins.diagnostics.credo,
        -- require("null-ls").builtins.completion.spell,
        require("null-ls").builtins.formatting.prettier,
        -- null_ls.builtins.formatting.mix,
      },
    })
  end,
  requires = {"nvim-lua/plenary.nvim", "neovim/nvim-lspconfig"} }
  use {'ruifm/gitlinker.nvim', commit='ff33d07', config = function()
    require"gitlinker".setup({
      opts = {
        action_callback = function(url)
          local human_readable_url = ''
          if vim.fn.mode() == 'n' then
            human_readable_url = _G.get_file_line()
          else
            human_readable_url = _G.get_file_line_sel()
          end

          vim.api.nvim_command('let @+ = \'' .. human_readable_url .. ' ' .. url .. '\'')
        end,
      },
      callbacks = {
        ["gitlab.*"] = require"gitlinker.hosts".get_gitlab_type_url
      },
      -- default mapping to call url generation with action_callback
      mappings = "<leader>gy"
    })
  end}
  use {'j-hui/fidget.nvim', commit='37d536bbbee47222ddfeca0e8186e8ee6884f9a2', config= function()
    require"fidget".setup{}
  end}
  use {'stevearc/dressing.nvim', commit='55e4ceae81d9169f46ea4452ce6e8c58cca00651', config=function()
    require('dressing').setup({
      input = {
        -- ESC won't close the modal, ability to use vim keys
        insert_only = false,
      }
    })
  end}
  use {
    "williamboman/nvim-lsp-installer",
    commit = "b70099151c401014b875e3a375c751714fdd4144",
    config = function()
      require("nvim-lsp-installer").setup {
        automatic_installation = true,
      }
      local lspconfig = require("lspconfig")
      lspconfig.tsserver.setup {
        on_attach = function(client)
          client.resolved_capabilities.document_formatting = false
          client.resolved_capabilities.document_range_formatting = false
        end,
      }
      lspconfig.rust_analyzer.setup {}
      lspconfig.elixirls.setup {}
      lspconfig.bashls.setup {}
    end,
    after = "nvim-lspconfig",
  }
  use 'linty-org/key-menu.nvim'
  use 'lambdalisue/suda.vim'
  use {'akinsho/toggleterm.nvim', config = function()
    require("toggleterm").setup{
      direction = 'float',
      float_opts = {
        width = 140,
        height = 45,
      }
    }
    function _G.set_terminal_keymaps()
      local opts = {noremap = true}
      vim.api.nvim_buf_set_keymap(0, 't', '<esc>', [[<C-\><C-n>]], opts)
    end
    -- if you only want these mappings for toggle term use term://*toggleterm#* instead
    vim.cmd('autocmd! TermOpen term://* lua set_terminal_keymaps()')
  end}
  use 'simrat39/symbols-outline.nvim'
  use {'TimUntersberger/neogit', config = function()
      require('neogit') .setup {
	  -- disable_context_highlighting = true,
	  signs = {
	      -- { CLOSED, OPENED }
	      section = { "▶", "▼" },
	      item = { "▶", "▼" },
	      hunk = { "", "" },
	  }
      }
  end}
  use 'folke/trouble.nvim'
  use {
    'kyazdani42/nvim-tree.lua',
    requires = { 'kyazdani42/nvim-web-devicons', },
    -- for some reason must call init outside of the config block, elsewhere
    -- config = function() require'nvim-tree'.setup {} end
  }
  use {"b3nj5m1n/kommentary", config = function()
      require('kommentary.config')
      .configure_language("default", {
	  prefer_single_line_comments = true,
      })
  end}
  use {"folke/todo-comments.nvim"
  -- https://github.com/folke/todo-comments.nvim/issues/93 https://github.com/folke/todo-comments.nvim/issues/99
  -- can't put the config inline, causes weird issues
  }
end)

--Set highlight on search
vim.o.hlsearch = false

--Make line numbers default
vim.wo.number = true

--Enable mouse mode
vim.o.mouse = 'a'

--Enable break indent
vim.o.breakindent = true

--Save undo history
vim.opt.undofile = true

--Case insensitive searching UNLESS /C or capital in search
vim.o.ignorecase = true
vim.o.smartcase = true

--Decrease update time
vim.o.updatetime = 250
vim.wo.signcolumn = 'yes'

--Set colorscheme
vim.o.termguicolors = true
-- vim.cmd [[colorscheme onedark]]

-- Set completeopt to have a better completion experience
vim.o.completeopt = 'menuone,noselect'

--Remap space as leader key
vim.keymap.set({ 'n', 'v' }, '<Space>', '<Nop>', { silent = true })
vim.g.mapleader = ' '
vim.g.maplocalleader = ' '

--Remap for dealing with word wrap
vim.keymap.set('n', 'k', "v:count == 0 ? 'gk' : 'k'", { expr = true, silent = true })
vim.keymap.set('n', 'j', "v:count == 0 ? 'gj' : 'j'", { expr = true, silent = true })

-- Highlight on yank
local highlight_group = vim.api.nvim_create_augroup('YankHighlight', { clear = true })
vim.api.nvim_create_autocmd('TextYankPost', {
  callback = function()
    vim.highlight.on_yank()
  end,
  group = highlight_group,
  pattern = '*',
})

-- Treesitter configuration
-- Parsers must be installed manually via :TSInstall
require('nvim-treesitter.configs').setup {
  highlight = {
    enable = true, -- false will disable the whole extension
  },
  incremental_selection = {
    enable = true,
    keymaps = {
      init_selection = 'gnn',
      node_incremental = 'grn',
      scope_incremental = 'grc',
      node_decremental = 'grm',
    },
  },
  indent = {
    enable = true,
  },
  textobjects = {
    select = {
      enable = true,
      lookahead = true, -- Automatically jump forward to textobj, similar to targets.vim
      keymaps = {
        -- You can use the capture groups defined in textobjects.scm
        ['af'] = '@function.outer',
        ['if'] = '@function.inner',
        ['ac'] = '@class.outer',
        ['ic'] = '@class.inner',
      },
    },
    move = {
      enable = true,
      set_jumps = true, -- whether to set jumps in the jumplist
      goto_next_start = {
        [']m'] = '@function.outer',
        [']]'] = '@class.outer',
      },
      goto_next_end = {
        [']M'] = '@function.outer',
        [']['] = '@class.outer',
      },
      goto_previous_start = {
        ['[m'] = '@function.outer',
        ['[['] = '@class.outer',
      },
      goto_previous_end = {
        ['[M'] = '@function.outer',
        ['[]'] = '@class.outer',
      },
    },
  },
}

-- nvim-cmp setup
local cmp = require 'cmp'
cmp.setup {
  snippet = {
    expand = function(args)
      luasnip.lsp_expand(args.body)
    end,
  },
  mapping = cmp.mapping.preset.insert({
    ['<C-d>'] = cmp.mapping.scroll_docs(-4),
    ['<C-f>'] = cmp.mapping.scroll_docs(4),
    ['<C-Space>'] = cmp.mapping.complete(),
    ['<CR>'] = cmp.mapping.confirm {
      behavior = cmp.ConfirmBehavior.Replace,
      select = true,
    },
    ['<Tab>'] = cmp.mapping(function(fallback)
      if cmp.visible() then
        cmp.select_next_item()
      elseif luasnip.expand_or_jumpable() then
        luasnip.expand_or_jump()
      else
        fallback()
      end
    end, { 'i', 's' }),
    ['<S-Tab>'] = cmp.mapping(function(fallback)
      if cmp.visible() then
        cmp.select_prev_item()
      elseif luasnip.jumpable(-1) then
        luasnip.jump(-1)
      else
        fallback()
      end
    end, { 'i', 's' }),
  }),
  sources = {
    { name = 'nvim_lsp' },
    { name = 'luasnip' },
  },
}

-- guifont = "JetBrains Mono Nerd Font"
-- or 10.9 or 11
vim.opt.guifont = "JetBrainsM3n3 Nerd Font:h10.6"
vim.opt.fillchars = vim.opt.fillchars + 'diff:╱'
vim.o.relativenumber = true
vim.opt.cursorline = true -- highlight the current line number
vim.opt.clipboard = "unnamedplus"

require("plugins.lualine")
require("plugins.misc")
require("leader_shortcuts")
require("shortcuts")
require("helpers")

vim.o.timeoutlen = 200
require 'key-menu'.set('n', '<Space>')
require 'key-menu'.set('n', '<Space>f', {desc='File'})
require 'key-menu'.set('n', '<Space>g', {desc='Git'})
require 'key-menu'.set('n', '<Space>s', {desc='Search'})
require 'key-menu'.set('n', '<Space>o', {desc='Open'})
require 'key-menu'.set('n', '<Space>g', {desc='Git'})
require 'key-menu'.set('n', '<Space>w', {desc='Window'})
require 'key-menu'.set('n', '<Space>c', {desc='Code'})
require 'key-menu'.set('n', '<Space>cl', {desc='LSP'})
require 'key-menu'.set('n', '<Space>ct', {desc='Tests'})
require 'key-menu'.set('n', '<Space>cq', {desc='Quickfix'})
require 'key-menu'.set('n', '<Space>t', {desc='Tab'})
require 'key-menu'.set('n', '<Space>b', {desc='Buffer'})

vim.cmd [[autocmd BufWritePre *.ex lua vim.lsp.buf.formatting_sync()]]
vim.cmd [[autocmd BufWritePre *.exs lua vim.lsp.buf.formatting_sync()]]
vim.cmd [[autocmd BufWritePre *.rs lua vim.lsp.buf.formatting_sync()]]
vim.cmd [[autocmd BufWritePre *.tsx lua vim.lsp.buf.formatting_sync()]]
vim.cmd [[autocmd BufWritePre *.jsx lua vim.lsp.buf.formatting_sync()]]

vim.diagnostic.config({
  virtual_text = false,
  float = {
    severity_sort = true,
    source = true,
    border = 'single',
  },
})

vim.fn.sign_define("DiagnosticSignError", { text = "", texthl = "DiagnosticSignError", numhl = "DiagnosticSignError", })
vim.fn.sign_define("DiagnosticSignWarn", { text = "", texthl = "DiagnosticSignWarn", numhl = "DiagnosticSignWarn", })
vim.fn.sign_define("DiagnosticSignInfo", { text = "", texthl = "DiagnosticSignInfo", numhl = "DiagnosticSignInfo", })
vim.fn.sign_define("DiagnosticSignHint", { text = "", texthl = "DiagnosticSignHint", numhl = "DiagnosticSignHint", })

-- for some reason the Red default color looks horrible in neovide for me...
-- bad subpixel rendering, i think => pick a diff tone of red, looks OK
vim.cmd("hi DiagnosticError guifg=#ff6262")

vim.api.nvim_set_hl(0, "TelescopeBorder", {fg="#88c0d0"})
vim.api.nvim_set_hl(0, "TelescopePromptPrefix", {fg="#88c0d0"})

vim.cmd("colorscheme doom-one")

-- https://stackoverflow.com/a/14407121/516188
vim.cmd("au BufRead,BufNewFile,BufEnter /home/emmanuel/projects/* setlocal sw=2")

vim.cmd("let g:test#elixir#exunit#options = { 'all': '--warnings-as-errors'}")

-- https://github.com/do-no-van/nvim/blob/main/lua/ascii_bg.lua
-- don't want piping either... https://github.com/NTBBloodbath/doom-nvim/commit/16c4987ed125f434efb182158c0e294bcac5fd12
-- Check if there were args (i.e. opened file), non-empty buffer, or started in insert mode
--[[ if vim.fn.argc() == 0 or vim.fn.line2byte("$") ~= -1 and not opt.insertmode then
    require("ascii_bg").set_ascii_bg()
end ]]

-- vim: ts=4 sts=4 sw=4 et
