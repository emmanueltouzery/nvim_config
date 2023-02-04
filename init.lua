-- Install packer
local install_path = vim.fn.stdpath 'data' .. '/site/pack/packer/start/packer.nvim'

if vim.fn.empty(vim.fn.glob(install_path)) > 0 then
  vim.fn.execute('!git clone https://github.com/wbthomason/packer.nvim ' .. install_path)
end

local packer_group = vim.api.nvim_create_augroup('Packer', { clear = true })
vim.api.nvim_create_autocmd('BufWritePost', { command = 'source <afile> | PackerCompile', group = packer_group, pattern = 'init.lua' })

vim.g.doom_one_terminal_colors = true
vim.g.BufKillCreateMappings = 0 -- vim-bufkill plugin
vim.g.lightspeed_no_default_keymaps = true

require('packer').startup(function(use)
  use 'wbthomason/packer.nvim' -- Package manager
  -- UI to select things (files, grep results, open buffers...)
  use { 'nvim-telescope/telescope.nvim', requires = {
    'nvim-lua/plenary.nvim',
    { 'debugloop/telescope-undo.nvim', commit = 'b5e31b358095074b60d87690bd1dc0a020a2afab' },
  }, commit="f7bceabcc9dc049141ab0ea9e6301c0d21dbda57", config = function()
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
            ["<C-n>"] = actions.cycle_history_next,
            ["<C-p>"] = actions.cycle_history_prev,
          },
        },
      },
      pickers = {
        buffers = {
          sort_lastused = true,
          mappings = {
            i = {
              ["<c-Del>"] = actions.delete_buffer + actions.move_to_top,
            }
          }
        }
      },
      extensions = {
        undo = {
          side_by_side = true,
          diff_context_lines = 3,
          layout_strategy = "vertical",
          layout_config = {
            preview_height = 0.8,
            preview_cutoff = 0,
          },
          mappings = {
            i = {
              ["<C-r>a"] = function(prompt_bufnr)
                local base = require("telescope-undo.actions").yank_additions(prompt_bufnr)
                local function with_notif()
                    res = base()
                    notif({"Copied " .. #res .. " lines to the clipboard"})
                end
                return with_notif
              end,
              ["<C-r>d"] = function(prompt_bufnr)
                local base = require("telescope-undo.actions").yank_deletions(prompt_bufnr)
                local function with_notif()
                    res = base()
                    notif({"Copied " .. #res .. " lines to the clipboard"})
                end
                return with_notif
              end,
              ["<cr>"] = require("telescope-undo.actions").restore,
            },
          },
        },
      },
    }
    require("telescope").load_extension("undo")

    -- Enable telescope fzf native
    require('telescope').load_extension 'fzf'
  end}
  use { 'nvim-telescope/telescope-fzf-native.nvim', run = 'make', commit="2330a7eac13f9147d6fe9ce955cb99b6c1a0face" }
  use { 'nvim-telescope/telescope-file-browser.nvim', commit='ea7905ed9b13bcf50e0ba4f3bff13330028d298c', config=function()
    require("telescope").load_extension "file_browser"
  end}
  use { 'nvim-lualine/lualine.nvim', commit='a52f078026b27694d2290e34efa61a6e4a690621'}
  use { 'lewis6991/gitsigns.nvim', requires = { 'nvim-lua/plenary.nvim' }, commit='f98c85e7c3d65a51f45863a34feb4849c82f240f', config = function()
    require("gitsigns").setup {}
  end}
  -- Highlight, edit, and navigate code using a fast incremental parsing library
  use {'nvim-treesitter/nvim-treesitter', commit='e2efbb6569dbe50e6604cfc2d5d0819eb07d5623', config=function()
    require("nvim-treesitter.configs").setup({
      -- https://github.com/nvim-treesitter/nvim-treesitter#supported-languages
      ensure_installed = { "c", "lua", "rust", "json", "yaml", "toml", "html", "javascript", "markdown",
        "elixir","jsdoc","json","scss","typescript", "bash", "dockerfile", "eex", "graphql", "tsx" },
      highlight = { enable = true },
      autopairs = {
        enable = true,
      },
      indent = { enable = false },
      playground = { enable = true },
      tree_docs = { enable = true },
      context_commentstring = { enable = true },
      matchup = {
        enable = true,
        disable_virtual_text = true,
      },
      autotag = {
        enable = true,
        filetypes = {
          "html",
          "javascript",
          "javascriptreact",
          "svelte",
          "vue",
          "markdown",
        },
      },
    })
  end}
  use {'JoosepAlviste/nvim-ts-context-commentstring', commit='a0f89563ba36b3bacd62cf967b46beb4c2c29e52'}
  use {'neovim/nvim-lspconfig', commit='2dd9e060f21eecd403736bef07ec83b73341d955'} -- Collection of configurations for built-in LSP client
  use {'hrsh7th/nvim-cmp', commit='2427d06b6508489547cd30b6e86b1c75df363411'} -- Autocompletion plugin
  use {'hrsh7th/cmp-nvim-lsp', commit='affe808a5c56b71630f17aa7c38e15c59fd648a8'}
  use { "hrsh7th/cmp-buffer", commit = "3022dbc9166796b644a841a02de8dd1cc1d311fa" }
  use { "hrsh7th/cmp-path", commit = "447c87cdd6e6d6a1d2488b1d43108bfa217f56e1" }
  -- i NEED a snippet engine, whether I want it or not, see https://github.com/hrsh7th/nvim-cmp/issues/304#issuecomment-939279715
  use {'saadparwaiz1/cmp_luasnip', commit = 'a9de941bcbda508d0a45d28ae366bb3f08db2e36'}
  -- alternative: https://github.com/ray-x/lsp_signature.nvim but the cmp one is more lightweight
  use {'hrsh7th/cmp-nvim-lsp-signature-help', commit = '3dd40097196bdffe5f868d5dddcc0aa146ae41eb'}
  use {'emmanueltouzery/doom-one.nvim', commit='d89ea4a9ea08759d58caefba6d7c2dc6b9ccd8c0', config = function()
    require('doom-one').setup({
      cursor_coloring = true,
      diagnostics_color_text = false,
      plugins_integrations = {
        telescope = true,
      }
    })

    -- the theme MUST be loaded before we attempt to load bufferline
    require("plugins.bufferline")
  end}
  use {'airblade/vim-rooter', commit='0415be8b5989e56f6c9e382a04906b7f719cfb38', config = function() 
    vim.g.rooter_silent_chdir = 1 
    vim.g.rooter_cd_cmd = 'lcd'
    vim.g.rooter_change_directory_for_non_project_files = 'current'
  end, commit='0415be8b5989e56f6c9e382a04906b7f719cfb38'}
  use {'CodingdAwn/vim-choosewin', commit='554edfec23c9b7fe523f957a90821b4e0da7aa36'} -- fork which adds the "close window" feature
  use {'sindrets/diffview.nvim', commit='168c8fc1e5729a00b7dd0317d393e6acf21faad7',
    config = function()
      local actions = require("diffview.config").actions
      require('diffview').setup {
        -- view = {
        --   merge_tool = {
        --     layout = "diff4_mixed",
        --   },
        -- },
        keymaps = {
          view = {
            ["šx"] = function()
              require'diffview.config'.actions.prev_conflict()
              vim.cmd("norm! zz") -- center on screen
            end,
            ["đx"] = function()
              require'diffview.config'.actions.next_conflict()
              vim.cmd("norm! zz") -- center on screen
            end,
            ["gf"] = diffview_gf,
          },
          file_panel = {
            ["-"] = false, -- i want this shortcut for choosewin
            ["s"] = actions.toggle_stage_entry, -- Stage / unstage the selected entry.
            ["c"] = function() 
              -- cc should commit from diffview same as from neogit
              vim.cmd('DiffviewClose')
              vim.cmd('Neogit')
              vim.fn.feedkeys('c')
            end,
            ["šx"] = actions.prev_conflict,
            ["đx"] = actions.next_conflict,
            ["gf"] = diffview_gf,
          },
          file_history_panel = {
            ["gf"] = diffview_gf,
          },
        },
        file_history_panel = {
          log_options = {
            git = {
              single_file = {
                follow = true,       -- Follow renames (only for single file)
              }
            }
          }
        }
      }
      require('diffview').init()
    end
  }
  use {'nvim-telescope/telescope-live-grep-raw.nvim', commit='8124094e11b54a1853c3306d78e6ca9a8d40d0cb'}
  use {'emmanueltouzery/agitator.nvim', commit='838dd14fb89687b4f054724d4fa55d2317eb3c4b'}
  use {'nvim-telescope/telescope-project.nvim', commit='8cd22b696e14b353fe8ea9648a03364cb56c39d4'}
  -- vim.cmd("let g:yankstack_yank_keys = ['c', 'C', 'd', 'D', 's', 'S', 'x', 'X', 'y', 'Y']")
  -- drop s and S due to lightspeed
  vim.g.yoinkIncludeDeleteOperations = 1
  use {'svermeulen/vim-yoink', commit='89ed6934679fdbc3c20f552b50b1f869f624cd22', config= function()
    vim.cmd[[nmap <M-p> <plug>(YoinkPostPasteSwapBack)]]
    vim.cmd[[nmap <M-P> <plug>(YoinkPostPasteSwapForward)]]
    
    vim.cmd[[nmap p <plug>(YoinkPaste_p)]]
    vim.cmd[[nmap P <plug>(YoinkPaste_P)]]
  end} -- considered https://github.com/gbprod/yanky.nvim & https://github.com/AckslD/nvim-neoclip.lua too, previously used maxbrunsfeld/vim-yankstack
  use {'emmanueltouzery/vim-elixir', commit='735528cecc19ecffa002ffa20176e9984cced970'}
  use {'ellisonleao/glow.nvim', commit='c6685381d31df262b776775b9f4252f6c7fa98d0'}
  use {'smjonas/live-command.nvim', commit='ce4b104ce702c7bb9fdff863059af6d47107ca61', config=function()
    require("live-command").setup {
      commands = {
        Norm = { cmd = "norm" },
        S = { cmd = "Subvert"}, -- must be defined before we import vim-abolish
      },
    }
  end}
  use {'tpope/vim-abolish', commit='3f0c8faadf0c5b68bcf40785c1c42e3731bfa522'}
  use {'qpkorr/vim-bufkill', commit='2bd6d7e791668ea52bb26be2639406fcf617271f'}
  use {'lifepillar/vim-cheat40', commit='ae237b02f9031bc82a8ad9202bffee2bcef71ed1'}
  use {
    "ggandor/leap.nvim",
    commit="ff4c3663e5a0a0ecbb3fffbc8318825def35d2aa",
    config = function()

    -- require("leap").add_default_mappings()
      vim.api.nvim_set_keymap('n', 's', '<Plug>(leap-forward-to)', {silent = true})
      vim.api.nvim_set_keymap('n', 'S', '<Plug>(leap-backward-to)', {silent = true})
      vim.api.nvim_set_keymap('v', 's', '<Plug>(leap-forward-to)', {silent = true})
      vim.api.nvim_set_keymap('v', 'S', '<Plug>(leap-backward-to)', {silent = true})
      vim.api.nvim_set_keymap('n', 'gs', '<Plug>(leap-cross-window)', {silent = true})

      -- The below settings make Leap's highlighting a bit closer to what you've been
      -- used to in Lightspeed.
      vim.api.nvim_set_hl(0, "LeapBackdrop", {link = "Comment"})
      vim.api.nvim_set_hl(
      0,
      "LeapMatch",
      {
        fg = "white", -- for light themes, set to 'black' or similar
        bold = true,
        nocombine = true
      }
      )
      require("leap").opts.highlight_unlabeled_phase_one_targets = true
    end
  }
  use {'tpope/vim-dispatch', commit='00e77d90452e3c710014b26dc61ea919bc895e92'} -- used by vim-test
  use {'vim-test/vim-test', commit='56bbfa295fe62123d2ebe8ed57dd002afab46097'}
  -- vim-markify, considered alternative: https://github.com/tomtom/quickfixsigns_vim
  use {'dhruvasagar/vim-markify', commit='14158865c0f37a02a5d6d738437eb00a821b31ef', config = function()
    vim.g.markify_error_text = ""
    vim.g.markify_warning_text = ""
    vim.g.markify_info_text = ""
    vim.g.markify_info_texthl = "Todo"
  end}
  use {'jose-elias-alvarez/null-ls.nvim', commit='c0c19f32b614b3921e17886c541c13a72748d450', config = function()

    require("null-ls").setup({
      sources = {
        -- require("null-ls").builtins.formatting.stylua,
        require("null-ls").builtins.diagnostics.eslint.with({
          -- eslint: display rule name
          -- https://github.com/jose-elias-alvarez/null-ls.nvim/blob/main/doc/BUILTIN_CONFIG.md#diagnostics-format
          diagnostics_format = "#{m} [#{c}]",
        }),
        require("null-ls").builtins.code_actions.eslint, -- eslint code actions
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

          vim.fn.setreg('+', human_readable_url .. ' ' .. url)
        end,
      },
callbacks = {
        ["gitlab.*"] = require"gitlinker.hosts".get_gitlab_type_url
      },
      -- default mapping to call url generation with action_callback
      mappings = "<leader>gy"
    })
  end}
  use {'emmanueltouzery/lualine-lsp-progress', commit='323c172eb74dd2007682bc8f7aaf52dc0517d6cf'}
  use {'stevearc/dressing.nvim', commit='12b808a6867e8c38015488ad6cee4e3d58174182', config=function()
    require('dressing').setup({
      input = {
        -- ESC won't close the modal, ability to use vim keys
        insert_only = false,
        get_config = function(opts)
          if opts.kind == 'center_win' then
            return {
              relative = 'editor',
            }
          end
        end
      },
      select = {
        get_config = function(opts)
          -- https://github.com/stevearc/dressing.nvim/issues/22#issuecomment-1067211863
          -- for codeaction, we want null-ls to be last
          -- https://github.com/jose-elias-alvarez/null-ls.nvim/issues/630
          -- for eslint, it's offering me options like "disable eslint rule" which
          -- are almost never what I want, and they appear before the more useful options
          -- from the LSP
          if opts.kind == 'codeaction' then
            return {
              telescope = {
                sorter = require'telescope.sorters'.Sorter:new {
                  scoring_function = function(_, _, line)
                    local order = tonumber(string.match(line, "^[%d]+"))
                    if string.find(line, escape_pattern('null-ls')) then
                      return order+100
                    else
                      return order
                    end
                  end,
                },
                -- copied from the telescope dropdown theme
                sorting_strategy = "ascending",
                layout_strategy = "center",
                layout_config = {
                  preview_cutoff = 1, -- Preview should always show (unless previewer = false)
                  width = 80,
                  height = 15,
                },
                borderchars = {
                  prompt = { "─", "│", " ", "│", "╭", "╮", "│", "│" },
                  results = { "─", "│", "─", "│", "├", "┤", "╯", "╰" },
                  preview = { "─", "│", "─", "│", "╭", "╮", "╯", "╰" },
                },
              }
            }
          end
        end,
      },
    })
  end}
  use {
    "williamboman/mason.nvim",
    commit = "bf170f8379a3eaeed662f2c8e42dced96e78f429",
  }
  use {
    "williamboman/mason-lspconfig.nvim",
    commit = "a910b4d50f7a32d2f9057d636418a16843094b7c",
    config = function()
      require("mason").setup()
      require("mason-lspconfig").setup {
        automatic_installation = true,
      }
      local lspconfig = require("lspconfig")
      local log = require 'vim.lsp.log';
      local util = require 'vim.lsp.util'

      lspconfig.tsserver.setup {
        on_attach = function(client)
          if vim.version().minor > 7 then
            client.server_capabilities.documentFormattingProvider = false
            client.server_capabilities.documentRangeFormattingProvider = false
          else
            client.resolved_capabilities.document_formatting = false
            client.resolved_capabilities.document_range_formatting = false
          end
        end,

        -- fix annoying quickfix opening because tsserver returns multiple matches
        -- usually the first one is the right one
        -- https://www.reddit.com/r/neovim/comments/nrfr5h/neovim_auto_opens_quickfix_list/
        -- https://github.com/neovim/neovim/blob/1186f7dd96b054d6a653685089fc845a8f5d2f27/runtime/lua/vim/lsp/handlers.lua#L275-L295
        -- https://github.com/neovim/neovim/blob/v0.7.2/runtime/lua/vim/lsp/handlers.lua#L322
        handlers = {
          ["textDocument/definition"] = function(_, result, ctx, _)
            if result == nil or vim.tbl_isempty(result) then
              local _ = log.info() and log.info(ctx.method, 'No location found')
              return nil
            end
            local client = vim.lsp.get_client_by_id(ctx.client_id)

            -- textDocument/definition can return Location or Location[]
            -- https://microsoft.github.io/language-server-protocol/specifications/specification-current/#textDocument_definition

            if vim.tbl_islist(result) then
              util.jump_to_location(result[1], client.offset_encoding)

              -- if #result > 1 then
              --   vim.fn.setqflist({}, ' ', {
              --     title = 'LSP locations',
              --     items = util.locations_to_items(result, client.offset_encoding)
              --   })
              --   vim.api.nvim_command("botright copen")
              -- end
            else
              util.jump_to_location(result, client.offset_encoding)
            end
          end
        }
      }
      local navic = require("nvim-navic")

      -- lspconfig.rust_analyzer.setup {}
      lspconfig.elixirls.setup {
        on_attach = function(client, bufnr)
          navic.attach(client, bufnr)
        end,
      }
      lspconfig.bashls.setup {}
      lspconfig.jsonls.setup {
        -- use null-ls & prettier for json indentation
        on_attach = function(client, bufnr)
          navic.attach(client, bufnr)
          if vim.version().minor > 7 then
            client.server_capabilities.documentFormattingProvider = false
            client.server_capabilities.documentRangeFormattingProvider = false
          else
            client.resolved_capabilities.document_formatting = false
            client.resolved_capabilities.document_range_formatting = false
          end
        end,
      }
      local capabilities = vim.lsp.protocol.make_client_capabilities()
      capabilities = require("cmp_nvim_lsp").update_capabilities(capabilities)
      lspconfig.cssls.setup {
        capabilities = capabilities
      }
      lspconfig.graphql.setup {}
    end,
    after = "nvim-lspconfig",
  }
  use {'linty-org/key-menu.nvim', commit='34c226a4bdadd59ca10f046e3d44f959504b12a4'}
  use {'lambdalisue/suda.vim', commit='6bffe36862faa601d2de7e54f6e85c1435e832d0'}
  use {'akinsho/toggleterm.nvim', commit='2a787c426ef00cb3488c11b14f5dcf892bbd0bda', config = function()
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
  use {'simrat39/symbols-outline.nvim', commit='15ae99c27360ab42e931be127d130611375307d5'}
  use {'TimUntersberger/neogit', commit='74c9e29b61780345d3ad9d7a4a4437607caead4a', config = function()
    require('neogit') .setup {
      -- disable_context_highlighting = true,
      signs = {
        -- { CLOSED, OPENED }
        section = { "▶", "▼" },
        item = { "▶", "▼" },
        hunk = { "", "" },
      },
      integrations = {
        diffview = true,
      },
    }
    vim.cmd[[autocmd User NeogitCommitComplete NvimTreeRefresh]]
  end}
  use {
    'nvim-tree/nvim-tree.lua', commit='c446527056e92a57b51e2f79be47c28ba8ed43e4',
    requires = { 'kyazdani42/nvim-web-devicons', },
    -- for some reason must call init outside of the config block, elsewhere
    -- config = function() require'nvim-tree'.setup {} end
  }
  use {"b3nj5m1n/kommentary", commit='533d768a140b248443da8346b88e88db704212ab', config = function()
    require('kommentary.config')
    .configure_language("default", {
      prefer_single_line_comments = true,
    })
  end}
  use {"folke/todo-comments.nvim", commit='98b1ebf198836bdc226c0562b9f906584e6c400e'
    -- https://github.com/folke/todo-comments.nvim/issues/93 https://github.com/folke/todo-comments.nvim/issues/99
    -- can't put the config inline, causes weird issues
  }
  use {"windwp/nvim-autopairs", commit='b9cc0a26f3b5610ce772004e1efd452b10b36bc9', config=function()
    require("nvim-autopairs").setup({
      check_ts = true,
      enable_afterquote = true,
      enable_moveright = true,
      enable_check_bracket_line = true,
    })
  end}
  use {"goolord/alpha-nvim", commit="0bb6fc0646bcd1cdb4639737a1cee8d6e08bcc31", config=function()
    local alpha = require'alpha'
    local dashboard = require'alpha.themes.dashboard'
    dashboard.section.header.val = {
      "⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣠⠞⠁⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀",
      "⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣠⠞⠁⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀",
      "⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣰⠟⠁⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀",
      "⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣠⠞⠁⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀",
      "⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⣾⣿⠃⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀",
      "⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⣴⡟⢻⡇⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀",
      "⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣀⣀⣀⡀⠀⠀⠀⣠⣴⠟⠋⠀⠘⣧⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀",
      "⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠐⢶⣄⠀⠀⢠⣄⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⣴⠟⠛⠉⠙⠻⣦⣶⠟⠋⠁⠀⠀⠀⠀⢹⡄⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀",
      "⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠙⠷⣦⣈⣿⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣾⠇⠀⠀⠀⠀⠀⠈⢻⣆⠀⠀⠀⠀⠀⠀⠀⡇⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠁⢰⣿⣧⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀",
      "⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠈⠻⣿⣆⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣿⠀⠀⠀⠀⠀⠀⠀⠀⣿⠀⠀⠀⠀⠀⠀⠀⠃⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠆⢼⣿⣿⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀",
      "⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢻⡟⠛⠿⢶⣤⣄⣀⣀⡀⠀⠀⠀⣀⣀⣀⣀⣀⣀⣀⣀⣤⣤⣿⣷⡀⠀⠀⠀⠀⠀⠀⣿⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠰⠀⣿⣿⡟⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀",
      "⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠸⣷⣤⣴⡶⠾⠿⠟⠛⠛⠛⠛⠛⠛⠛⠋⠉⠉⠉⠉⠉⠉⠉⢻⣿⣿⣤⡀⠀⠀⢀⣼⠏⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠠⠀⣿⣿⣿⡆⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀",
      "⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠙⢿⣿⠻⠶⠾⠛⠁⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠄⢠⣿⣿⣿⠃⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀",
      "⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠈⠻⣷⣤⣀⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠄⢸⣿⣿⣿⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀",
      "⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠈⠉⠛⠻⢶⣦⣄⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠠⠄⢸⣿⣿⡏⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀",
      "⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠈⠛⠿⣶⣤⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⠀⣸⣿⣿⡇⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀",
      "⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠁⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣀⣀⣿⣿⣿⡇⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀",
      "⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣀⣀⣀⣀⣤⣄⡀⠀⠀⠀⠀⠀⠀⠀⣈⣉⣡⣿⣇⣀⣀⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀",
      "⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢠⣿⣿⣿⣿⣯⣭⣭⣼⣧⣀⣤⣤⣤⣠⣼⣿⣿⣿⣿⣿⣿⣿⣿⣿⣦⣤⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀",
      "⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢸⣏⣉⣉⣉⣩⣭⣭⣥⣤⣤⣤⠶⠶⠶⠶⠶⠶⠶⠶⠶⠤⠤⠶⠶⠶⠶⣶⡿⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀",
      "⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠈⠉⢻⠁⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣿⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀",
      "⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢸⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣿⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀",
      "⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢸⡇⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢰⡟⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀",
      "⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢨⣷⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢸⡇⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀",
      "⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢸⡇⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢸⡇⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀",
      "⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢸⡇⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠸⠇⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀",
    }
    dashboard.section.buttons.val = {
      dashboard.button( "e", "  New file" , ":ene <BAR> startinsert <CR>"),
      dashboard.button( "p", "  Open project" , _G.telescope_project_command),
      dashboard.button( "b", "  Open file browser" , "<cmd>lua require 'telescope'.extensions.file_browser.file_browser({grouped = true})<CR>"), -- alt icon: פּ
      dashboard.button( "q", "  Quit NVIM" , ":qa<CR>"),
    }
    dashboard.config.opts.noautocmd = true
    alpha.setup(dashboard.config)
  end}
  use {'L3MON4D3/LuaSnip', commit = '52f4aed58db32a3a03211d31d2b12c0495c45580'} -- Snippets plugin
  use {'akinsho/bufferline.nvim', commit = 'a703bb919aeb436eaa83bcbefdac51fbb92b4c74'}
  use {'emmanueltouzery/vim-dispatch-neovim', commit='8e9fe1a6dd7709d0948d2bcc76c620aabcb63017'}
  -- private, optional stuff
  use {'git@github.com:emmanueltouzery/nvim_config_private', config=function()
    if pcall(require, 'nvim_config_private') then
      require'nvim_config_private'.setup{}
    end
  end}
  -- combining changes from max397574 and Gelio
  -- https://github.com/mfussenegger/nvim-treehopper/pull/14
  -- https://github.com/mfussenegger/nvim-treehopper/issues/10#issuecomment-1126289736
  -- and other improvements
  -- alternative => https://github.com/ggandor/leap-ast.nvim
  use {'emmanueltouzery/nvim-treehopper', commit='ddf243f8c2f7c7efdf3a038c50ff5eaba31022e2'}
  use {'kylechui/nvim-surround', commit='d91787d5a716623be7cec3be23c06c0856dc21b8', config=function()
    require("nvim-surround").setup({
      keymaps = {
        -- https://github.com/ggandor/lightspeed.nvim/issues/31
        -- fix conflict with lightspeed
        visual = "gs",
      }
    })
  end}
  use {'tpope/vim-sleuth', commit='1d25e8e5dc4062e38cab1a461934ee5e9d59e5a8'}
  -- language syntax-aware matchit. for instance, json {"test": "value}rest"}
  -- or JSX <TextField<string> ... />, or things in comments which are correctly ignored
  use {'andymass/vim-matchup', commit='ab8575d05f760da64321fefa88ed5d6cc8bb9369', config=function()
    -- https://github.com/andymass/vim-matchup#customizing-the-highlighting-colors
    vim.cmd [[
      augroup matchup_matchparen_highlight
        autocmd!
        autocmd ColorScheme * hi MatchParen ctermfg=yellow guifg=yellow,\
            hi MatchWord cterm=bold,underline gui=bold,underline ctermfg=NONE guifg=NONE
      augroup END
    ]]
  end}
  use {'stevearc/overseer.nvim', commit='4d8614e829d8702bff6e9a5279820dd60591d9c0', config=function()
    require('overseer').setup{
      task_list = {
        direction = 'right',
        default_detail = 2,
      },
      task_editor = {
        bindings = {
          n = {
            ["<Esc>"] = "Cancel",
          }
        },
      },
      component_aliases = {
        default = {
          { "display_duration", detail_level = 2 },
          "on_output_summarize",
          "on_exit_set_status",
          {"on_complete_dispose", timeout = 900}
        }
      }
    }
  end}
  use {'mfussenegger/nvim-dap', commit='3d0d7312bb2a8491eb2927504e5cfa6e81b66de4', config=function()
-- require'dap'.adapters.codelldb = {
--   type = 'server',
--   port = "20392",
--   executable = {
--     -- CHANGE THIS to your path!
--     command = 'codelldb',
--     args = {"--port", "20392"},

--     -- On windows you may have to uncomment this:
--     -- detached = false,
--   }
-- }
  end}
  use {'/simrat39/rust-tools.nvim', commit='86a2b4e31f504c00715d0dd082a6b8b5d4afbf03', config=function()
    local rt = require("rust-tools")

    --https://github.com/LunarVim/LunarVim/issues/2894#issuecomment-1236420149
-- https://github.com/simrat39/rust-tools.nvim#a-better-debugging-experience
opts = {}
local path = vim.fn.glob(vim.fn.stdpath("data") .. "/mason/packages/codelldb/extension/") or ""
local codelldb_path = path .. "adapter/codelldb"
local liblldb_path = path .. "lldb/lib/liblldb.so"

if vim.fn.filereadable(codelldb_path) and vim.fn.filereadable(liblldb_path) then
  opts.dap = {
    adapter = require("rust-tools.dap").get_codelldb_adapter(codelldb_path, liblldb_path),
  }
else
  local msg = "Either codelldb or liblldb is not readable."
    .. "\n codelldb: "
    .. codelldb_path
    .. "\n liblldb: "
    .. liblldb_path
  vim.notify(msg, vim.log.levels.ERROR)
end
    -- print(vim.inspect(opts))

rt.setup(opts)
    -- rt.setup({
    --   server = {
    --     on_attach = function(_, bufnr)
    --       -- Hover actions
    --       vim.keymap.set("n", "<C-space>", rt.hover_actions.hover_actions, { buffer = bufnr })
    --       -- Code action groups
    --       vim.keymap.set("n", "<Leader>a", rt.code_action_group.code_action_group, { buffer = bufnr })
    --     end,
    --   },
    --   -- dap = {
    --   --   adapter = require('rust-tools.dap').get_codelldb_adapter(
    --   --   "codelldb", "liblldb.so")
    --   -- },
    -- })
  end}
  use {'rcarriga/nvim-dap-ui', commit='f889edb4f2b7fafa2a8f8101aea2dc499849b2ec', config=function()
    require("dapui").setup{}
  end}
  use {'SmiteshP/nvim-navic', commit='40c0ab2640a0e17c4fad7e17f260414d18852ce6'}
end)

--Set highlight on search
vim.o.hlsearch = false

-- disable word wrapping (selectively reenabled eg for markdown through an autocommand)
vim.opt.wrap = false

--Make line numbers default
vim.wo.number = true

--Enable mouse mode
vim.o.mouse = 'a'

--Enable break indent
vim.o.breakindent = true

--Save undo history
vim.opt.undofile = false
--Swap file -- annoying if you open twice the same file in two editors
vim.opt.swapfile = false

--Case insensitive searching UNLESS /C or capital in search
vim.o.ignorecase = true
vim.o.smartcase = true

--Decrease update time
vim.o.updatetime = 250

-- Buffer options
vim.opt.smartindent = true
vim.opt.copyindent = true
vim.opt.preserveindent = true

-- display eg the git status in more cases, for instance git status+TODO marker
-- it's 2-3 in doom-nvim
vim.wo.signcolumn = 'auto:1-2' 

-- no folds by defaults
vim.opt.foldenable = false

--Set colorscheme
vim.o.termguicolors = true
-- vim.cmd [[colorscheme onedark]]

-- Set completeopt to have a better completion experience
vim.o.completeopt = 'menuone,noselect'

-- Highlight on yank
vim.cmd[[au TextYankPost * silent! lua vim.highlight.on_yank()]]
-- local highlight_group = vim.api.nvim_create_augroup('YankHighlight', { clear = true })
-- vim.api.nvim_create_autocmd('TextYankPost', {
--   callback = function()
--     vim.highlight.on_yank()
--   end,
--   group = highlight_group,
--   pattern = '*',
-- })

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
}

-- guifont = "JetBrains Mono Nerd Font"
-- or 10.9 or 11
vim.opt.guifont = "JetBrainsM3n3 Nerd Font:h10.6"
-- the stl is related to https://vi.stackexchange.com/a/34849/38754
-- workaround for carets in the statusline
vim.opt.fillchars = vim.opt.fillchars + 'diff:╱,stl: '
vim.o.relativenumber = true
vim.opt.cursorline = true -- highlight the current line number
vim.opt.clipboard = "unnamedplus"
vim.opt.timeoutlen = 500 -- related to linty-org/key-menu.nvim, how fast do we show the menu

require("plugins.lualine")
require("plugins.cmp")
require("plugins.misc")
require("leader_shortcuts")
require("shortcuts")
require("helpers")
require("telescope_global_marks")
require("telescope_qf_locations")
require("telescope_modified_git_projects")
require("qftf")
require("notifs")
require("ts_unused_imports")
require("elixir")

if vim.version().minor > 7 then
  vim.cmd [[autocmd BufWritePre *.ex lua vim.lsp.buf.format()]]
  vim.cmd [[autocmd BufWritePre *.exs lua vim.lsp.buf.format()]]
  vim.cmd [[autocmd BufWritePre *.rs lua vim.lsp.buf.format()]]
  vim.cmd [[autocmd BufWritePre *.tsx lua vim.lsp.buf.format()]]
  vim.cmd [[autocmd BufWritePre *.jsx lua vim.lsp.buf.format()]]
  vim.cmd [[autocmd BufWritePre *.ts lua vim.lsp.buf.format()]]
  vim.cmd [[autocmd BufWritePre *.js lua vim.lsp.buf.format()]]
  vim.cmd [[autocmd BufWritePre *.md lua vim.lsp.buf.format()]]
  vim.cmd [[autocmd BufWritePre *.css lua vim.lsp.buf.format()]]
  vim.cmd [[autocmd BufWritePre *.scss lua vim.lsp.buf.format()]]
  vim.cmd [[autocmd BufWritePre *.less lua vim.lsp.buf.format()]]
  vim.cmd [[autocmd BufWritePre *.json lua vim.lsp.buf.format()]]
  vim.cmd [[autocmd BufWritePre *.graphql lua vim.lsp.buf.format()]]
else
  vim.cmd [[autocmd BufWritePre *.ex lua vim.lsp.buf.formatting_sync()]]
  vim.cmd [[autocmd BufWritePre *.exs lua vim.lsp.buf.formatting_sync()]]
  vim.cmd [[autocmd BufWritePre *.rs lua vim.lsp.buf.formatting_sync()]]
  vim.cmd [[autocmd BufWritePre *.tsx lua vim.lsp.buf.formatting_sync()]]
  vim.cmd [[autocmd BufWritePre *.jsx lua vim.lsp.buf.formatting_sync()]]
  vim.cmd [[autocmd BufWritePre *.ts lua vim.lsp.buf.formatting_sync()]]
  vim.cmd [[autocmd BufWritePre *.js lua vim.lsp.buf.formatting_sync()]]
  vim.cmd [[autocmd BufWritePre *.md lua vim.lsp.buf.formatting_sync()]]
  vim.cmd [[autocmd BufWritePre *.css lua vim.lsp.buf.formatting_sync()]]
  vim.cmd [[autocmd BufWritePre *.scss lua vim.lsp.buf.formatting_sync()]]
  vim.cmd [[autocmd BufWritePre *.less lua vim.lsp.buf.formatting_sync()]]
  vim.cmd [[autocmd BufWritePre *.json lua vim.lsp.buf.formatting_sync()]]
  vim.cmd [[autocmd BufWritePre *.graphql lua vim.lsp.buf.formatting_sync()]]
end

vim.diagnostic.config({
  virtual_text = false,
  float = {
    severity_sort = true,
    source = true,
    border = 'single',
  },
})
-- Change border of documentation hover window, See https://github.com/neovim/neovim/pull/13998.
vim.lsp.handlers["textDocument/hover"] = vim.lsp.with(vim.lsp.handlers.hover, {
  border = "rounded",
})

vim.fn.sign_define("DiagnosticSignError", { text = "", texthl = "DiagnosticSignError", numhl = "DiagnosticSignError", })
vim.fn.sign_define("DiagnosticSignWarn", { text = "", texthl = "DiagnosticSignWarn", numhl = "DiagnosticSignWarn", })
vim.fn.sign_define("DiagnosticSignInfo", { text = "", texthl = "DiagnosticSignInfo", numhl = "DiagnosticSignInfo", })
vim.fn.sign_define("DiagnosticSignHint", { text = "", texthl = "DiagnosticSignHint", numhl = "DiagnosticSignHint", })

-- for some reason the Red default color looks horrible in neovide for me...
-- bad subpixel rendering, i think => pick a diff tone of red, looks OK
vim.cmd("hi DiagnosticError guifg=#ff6262")

-- vim.api.nvim_set_hl(0, "TelescopeBorder", {fg="#88c0d0"})
-- vim.api.nvim_set_hl(0, "TelescopePromptPrefix", {fg="#88c0d0"})

-- https://stackoverflow.com/a/14407121/516188
vim.cmd("au BufRead,BufNewFile,BufEnter /home/emmanuel/projects/* setlocal sw=2")

-- elixir: warnings as errors
vim.cmd("let g:test#elixir#exunit#options = { 'all': '--warnings-as-errors'}")

-- SPELL CHECKING
vim.cmd("set spell")
vim.cmd("set spelloptions=camel")
vim.cmd("hi clear SpellCap")
vim.cmd("au BufNewFile,BufRead,BufWritePost *.lua setlocal nospell")
if vim.version().minor <= 7 then
  -- neovim 0.8.0 is smarter about spellcheck, with tree-sitter
  vim.cmd("au BufNewFile,BufRead,BufWritePost *.sh setlocal nospell")
end
-- neogit has stuff like [c]ommit that don't spell check well
-- and generally nothing mine to spell check there
vim.cmd('autocmd FileType NeogitStatus setlocal nospell')
vim.cmd("set spelllang=en,sl")
-- https://vi.stackexchange.com/a/4003/38754
-- don't spellcheck URLs in markdown files and similar
vim.cmd([[autocmd FileType NeogitCommitMessage syn match UrlNoSpell "\w\+:\/\/[^]] .. '[:space:]]' .. [[\+" contains=@NoSpell]])
vim.cmd([[autocmd BufNewFile,BufRead,BufEnter * syn match UrlNoSpell "\w\+:\/\/[^]] .. '[:space:]]' .. [[\+" contains=@NoSpell]])
-- ignore words shorter than 4 (helps with short variables in code)
-- http://www.panozzaj.com/blog/2016/03/21/ignore-urls-and-acroynms-while-spell-checking-vim/
-- word 1 to 4 characters longs (typically variable name)
vim.cmd([[autocmd BufNewFile,BufRead,BufEnter * syn match ShortNoSpell "\<\(\w\|\d\)\{1,4}\>" contains=@NoSpell]])
-- word 1 to 4 characters longs (typically variable name), leading underscore
vim.cmd([[autocmd BufNewFile,BufRead,BufEnter * syn match ShortNoSpell "\<_\(\w\|\d\)\{1,4}\>" contains=@NoSpell]])
-- word up to 5 chars with underscore in the middle (typically variable name)
vim.cmd([[autocmd BufNewFile,BufRead,BufEnter * syn match ShortNoSpell "\<\(\w\|\d\)\{1,2}_\(\w\|\d\)\{1,3}\>" contains=@NoSpell]])
-- word up to 5 chars with underscore in the middle (typically variable name), leading underscore
vim.cmd([[autocmd BufNewFile,BufRead,BufEnter * syn match ShortNoSpell "\<_\(\w\|\d\)\{1,2}_\(\w\|\d\)\{1,3}\>" contains=@NoSpell]])
-- word up to 5 chars with underscore in the middle (typically variable name)
vim.cmd([[autocmd BufNewFile,BufRead,BufEnter * syn match ShortNoSpell "\<\(\w\|\d\)\{1,3}_\(\w\|\d\)\{1,2}\>" contains=@NoSpell]])
-- word up to 5 chars with underscore in the middle (typically variable name), leading underscore
vim.cmd([[autocmd BufNewFile,BufRead,BufEnter * syn match ShortNoSpell "\<_\(\w\|\d\)\{1,3}_\(\w\|\d\)\{1,2}\>" contains=@NoSpell]])
-- colors eg #ffffff or #ffffffff -- rgb(a)
vim.cmd([[autocmd BufNewFile,BufRead,BufEnter * syn match ShortNoSpell "#\([abcdefABCDEF]\|\d\)\{6,8}\>" contains=@NoSpell]])
-- generic type parameters eg TInput
vim.cmd([[autocmd BufNewFile,BufRead,BufEnter *.ts syn match ShortNoSpell "\<T[A-Z]\w\{1,20}\>" contains=@NoSpell]])
vim.cmd([[autocmd BufNewFile,BufRead,BufEnter *.tsx syn match ShortNoSpell "\<T[A-Z]\w\{1,20}\>" contains=@NoSpell]])

-- word-wrapping in markdown files
vim.cmd('autocmd FileType markdown setlocal wrap linebreak')

-- matchpairs, switch between pairs of characters with %
vim.cmd("autocmd FileType typescript setlocal matchpairs+=<:>") -- not needed for tsx
vim.cmd("autocmd FileType rust setlocal matchpairs+=<:>")

-- workaround for https://github.com/nvim-telescope/telescope.nvim/issues/559
vim.cmd('autocmd BufRead * autocmd BufWinEnter * ++once normal! zx')

-- visible tab
-- https://www.reddit.com/r/vim/comments/4hoa6e/what_do_you_use_for_your_listchars/
vim.cmd("set list")
vim.cmd("set listchars=tab:→\\ ,trail:·,nbsp:␣")

-- for instance nginx configuration files
vim.cmd('autocmd BufNewFile,BufRead *.conf set syntax=conf')
vim.cmd('autocmd BufNewFile,BufRead *.conf.template set syntax=conf')
vim.cmd('autocmd BufNewFile,BufRead *.yml.template set syntax=yaml')

-- syntax highlight for fennel files
vim.cmd('autocmd BufNewFile,BufRead *.fnl set ft=lisp')

vim.cmd("set title")
vim.api.nvim_create_autocmd("DirChanged", {
    pattern = "*",
    callback = function(args)
        vim.opt.titlestring = "nvim - " .. lualine_project()
    end,
    desc = "Update neovim window title",
})


require'nvim-web-devicons'.set_icon {
  javascriptreact = {
    -- change color compared to .tsx
    -- and the builtin jsx
    icon = "",
    color = "#cbcb41",
    cterm_color = "67",
    name = "Jsx",
  };
}

-- check if file changed outside of vim on focus
-- https://www.reddit.com/r/neovim/comments/f0qx2y/automatically_reload_file_if_contents_changed/
vim.cmd([[autocmd FocusGained * if mode() != 'c' | checktime | endif]])
vim.cmd([[autocmd BufWritePost * let b:conflict_status = '']])
vim.cmd([[autocmd BufReadPost * let b:conflict_status = '']])

-- slightly more bright line number color than the OOB color for the doom-one theme
-- otherwise i don't find it readable enough for fast jumps
vim.cmd[[au Colorscheme * highlight LineNr guifg=#494949]]

-- I REALLY dislike the builtin vim blocking workflow when a file is edited
-- on disk and there is a conflict. Implement a non-blocking popup
vim.cmd([[
function! ProcessFileChangedShell()
  if v:fcs_reason == 'mode' || v:fcs_reason == 'time'
    let v:fcs_choice = ''
  elseif v:fcs_reason == 'changed'
    let v:fcs_choice = 'reload'
  else
    " deleted or conflict
    " don't warn the user again if we already warned
    if !exists('b:conflict_status') || b:conflict_status != v:fcs_reason
      let b:conflict_status = v:fcs_reason
      lua handleFileChanged()
    end
    let v:fcs_choice = ''
  endif
endfunction
autocmd FileChangedShell * call ProcessFileChangedShell()
]])

-- the mouse right-click menu is annoying
vim.opt.mousemodel = 'extend'

-- return to the line we were the last time we opened this file
vim.cmd([[au BufReadPost * if line("'\"") > 1 && line("'\"") <= line("$") | exe "normal! g'\"" | endif ]])

-- https://github.com/groves/invim
vim.cmd[[let $EDITOR='nvr --remote-tab-wait']]
vim.cmd[[autocmd FileType gitcommit,gitrebase,gitconfig set bufhidden=delete]]

-- emphasize dressing.nvim window border some more
vim.cmd[[hi FloatBorder guifg=#dfdad9]]

-- stay in visual mode after indenting with < and >
-- https://superuser.com/a/310424/214371
vim.cmd[[
vnoremap < <gv
vnoremap > >gv
]]

-- open quickfix window below vertical splits
-- https://stackoverflow.com/a/47077341/516188
vim.cmd[[au FileType qf wincmd J | 15wincmd_]]

-- https://www.reddit.com/r/neovim/comments/ctrdtq/always_open_help_in_a_vertical_split/
vim.cmd[[autocmd! FileType help :wincmd L]]
vim.cmd[[autocmd! FileType man :wincmd L]]
-- vim.cmd[[autocmd! BufEnter * if &ft ==# 'man' | wincmd L | endif]]

-- move the cursor to the beginning of non-whitespace characters in a line
-- EDIT: undo. want to be able to move back to the 0th column in case of right scroll
-- vim.cmd[[
-- nmap 0 ^
-- nmap <Home> ^
-- ]]

-- vim: ts=2 sts=2 sw=2 et
