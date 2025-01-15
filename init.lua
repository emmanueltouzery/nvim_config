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

-- https://superuser.com/a/1842153
vim.g.gitcommit_summary_length = 72

function _G.aerial_elixir_get_entry_text(item)
  if item.parent and #item.parent.name < 20 then
    return string.format("%s.%s", string.gsub(item.parent.name, "^.*%.", ""), item.name)
  end
  return item.name
end

  -- show hide .po files
function prompt_toggle_rg_po_files(prompt_bufnr)
  local action_state = require("telescope.actions.state")
  local current_picker = action_state.get_current_picker(prompt_bufnr)
  local prompt = current_picker:_get_prompt()
  if prompt:match("Tpo") then
    current_picker:set_prompt(prompt:gsub(" .Tpo", ""), true)
  else
    if #prompt:gsub('[^"]', '') == 1 then
      -- opened but not closed ", which i do often, close it
      current_picker:set_prompt('"', false)
    end
    current_picker:set_prompt(" -Tpo", false)
  end
end

function _G.nvim_lint_create_autocmds()
    local lint = require'lint'
    local aug = vim.api.nvim_create_augroup("Lint", { clear = true })
    -- lifted from https://github.com/stevearc/dotfiles/blob/master/.config/nvim/lua/plugins/lint.lua
    -- also see https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/plugins/linting.lua
    local uv = vim.uv or vim.loop
    local timer = assert(uv.new_timer())
    triggered = false
    local DEBOUNCE_MS = 500
    -- local aug = vim.api.nvim_create_augroup("Lint", { clear = true })
    -- vim.api.nvim_create_autocmd({ "BufEnter", "BufWritePost", "TextChanged", "InsertLeave" }, {
    --   group = aug,
    --   callback = function()
    --             lint.try_lint(nil, { ignore_errors = true })
    --             lint.try_lint(nil, { ignore_errors = true })
    --   end,
    -- })
    vim.api.nvim_create_autocmd({ "BufEnter", "BufWritePost", "TextChanged", "InsertLeave" }, {
      group = aug,
      callback = function()
        local bufnr = vim.api.nvim_get_current_buf()
        timer:stop()
        timer:start(
          DEBOUNCE_MS,
          0,
          vim.schedule_wrap(function()
            if vim.api.nvim_buf_is_valid(bufnr) then
              vim.api.nvim_buf_call(bufnr, function()
                lint.try_lint(nil, { ignore_errors = true })
              end)
            end
          end)
        )
      end,
    })
end

require('packer').startup(function(use)
  use 'wbthomason/packer.nvim' -- Package manager
  -- UI to select things (files, grep results, open buffers...)
  use { 'emmanueltouzery/telescope.nvim', requires = {
    'nvim-lua/plenary.nvim',
    { 'debugloop/telescope-undo.nvim', commit = 'b5e31b358095074b60d87690bd1dc0a020a2afab' },
  }, commit="2e9b88fcdeee847d6957e563591acec31cad002b", config = function()
    local actions = require("telescope.actions")
    -- https://github.com/nvim-telescope/telescope.nvim/issues/2778#issuecomment-2202572413
    local focus_preview = function(prompt_bufnr)
      local action_state = require("telescope.actions.state")
      local picker = action_state.get_current_picker(prompt_bufnr)
      local prompt_win = picker.prompt_win
      local previewer = picker.previewer
      local bufnr = previewer.state.bufnr or previewer.state.termopen_bufnr
      local winid = previewer.state.winid or vim.fn.win_findbuf(bufnr)[1]
      vim.keymap.set("n", "<S-Tab>", function()
        vim.cmd(string.format("noautocmd lua vim.api.nvim_set_current_win(%s)", prompt_win))
      end, { buffer = bufnr })
      vim.cmd(string.format("noautocmd lua vim.api.nvim_set_current_win(%s)", winid))
      -- api.nvim_set_current_win(winid)
    end
    require('telescope').setup {
      defaults = {
        path_display = {'truncate'},
        prompt_prefix = "   ",
        selection_caret = " ",
        sorting_strategy = "ascending",
        layout_config = {
          prompt_position = "top",
          width = 0.75,
          preview_cutoff = 120,
          horizontal = {
            preview_width = 0.6,
          },
        },
        cache_picker = {
          -- keep 3 recent pickers in cache. see `:help telescope.defaults.cache_picker`
          -- https://github.com/nvim-telescope/telescope.nvim/issues/1483
          -- useful for the shortcut to open recent pickers, `:help builtin.pickers`
          num_pickers = 3,
        },
        file_ignore_patterns = { "/%.git/", "^%.git/", "/node_modules/", "^node_modules/", "^__pycache__/" },
        mappings = {
          i = {
            ["<C-n>"] = actions.cycle_history_next,
            ["<C-p>"] = actions.cycle_history_prev,

              -- https://github.com/nvim-telescope/telescope.nvim/issues/2115#issuecomment-1366575821
            ["<CR>"] = require("telescope.actions").select_default + require("telescope.actions").center,
            ["<kEnter>"] = require("telescope.actions").select_default + require("telescope.actions").center,
            ["<C-x>"] = require("telescope.actions").select_horizontal + require("telescope.actions").center,
            ["<C-v>"] = require("telescope.actions").select_vertical + require("telescope.actions").center,
            ["<C-t>"] = require("telescope.actions").select_tab + require("telescope.actions").center,
            ["<C-r><C-w>"] = function(picker)
                require("telescope.actions").close(picker)
                local word = vim.fn.expand('<cword>')
                vim.cmd[[Telescope resume]]
                vim.defer_fn(function()
                  vim.fn.feedkeys(word)
                end, 10)
              end,
            ["<S-Tab>"] = focus_preview,
          },
          n = {
            ["<CR>"] = require("telescope.actions").select_default + require("telescope.actions").center,
            ["<kEnter>"] = require("telescope.actions").select_default + require("telescope.actions").center,
            ["<C-x>"] = require("telescope.actions").select_horizontal + require("telescope.actions").center,
            ["<C-v>"] = require("telescope.actions").select_vertical + require("telescope.actions").center,
            ["<C-t>"] = require("telescope.actions").select_tab + require("telescope.actions").center,
            ["<S-Tab>"] = focus_preview,
          }
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
            n = {
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
        project = {
          hidden_files = true,
        },
        live_grep_args = {
          auto_quoting = false,
          vimgrep_arguments = {
            -- add --ignore-file to the defaults
            "rg",
            "--color=never",
            "--no-heading",
            "--with-filename",
            "--line-number",
            "--column",
            "--smart-case",
            "--ignore-file=" .. vim.fn.stdpath("config") .. "/rg-ignore",
          },
          mappings = {
              i = {
                ["<C-t>"] = prompt_toggle_rg_po_files,
              },
          },
        },
        file_browser = {
          mappings = {
            i = {
              ["<CR>"] = require("telescope.actions").select_default,
              ["<C-S-N>"] = require'telescope'.extensions.file_browser.actions.sort_by_date,
            },
            n = {
              ["<CR>"] = require("telescope.actions").select_default,
              ["<C-S-N>"] = require'telescope'.extensions.file_browser.actions.sort_by_date,
            },
          },
        },
        aerial = {
          col1_width = 2,
          col2_width = 32,
        }
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
  use { 'nvim-lualine/lualine.nvim', commit='2a5bae925481f999263d6f5ed8361baef8df4f83', config=function()
    setup_lualine()
  end}
  use {'echasnovski/mini.diff', commit = '65c59f9967fec965d8759a88c1baa43147699035', config=function()
    require('mini.diff').setup({
      view = {
        style = 'sign',
        signs = { add = '┃', change = '┃', delete = '_' },
        -- put a priority lower than the default 10 for diagnostic errors, so that
        -- the signs for a hunk are together on the left, instead of individual
        -- diagnostics moving the sign for a line to not line up
        priority = 9,
      }
    })
  end}
  -- Highlight, edit, and navigate code using a fast incremental parsing library
  use {'nvim-treesitter/nvim-treesitter', commit='b4897f5a8453e7efeafb21ff5b2bbdc2e3faf1bd', config=function()
    require("nvim-treesitter.configs").setup({
      -- https://github.com/nvim-treesitter/nvim-treesitter#supported-languages
      -- groovy is for gradle build files
      ensure_installed = { "c", "cpp", "lua", "rust", "json", "yaml", "toml", "html", "javascript", "markdown", "markdown_inline", "vimdoc",
        "elixir","jsdoc","json","scss","typescript", "bash", "dockerfile", "eex", "graphql", "tsx", "python", "java", "ruby", "awk", "groovy", "sql", "go", "xml" },
      highlight = {
        enable = true ,
        -- syntax highlight for XML looks significantly worse with tree-sitter than regex,
        -- and we use HTML support for XML
        -- disable = {"html"},
      },
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
      incremental_selection = {
        enable = false, -- not using, always afraid of treesitter in terms of perf
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
    -- currently not tree-sitter support for XML, use the HTML support instead
    -- https://github.com/nvim-treesitter/nvim-treesitter/issues/3295
    -- vim.treesitter.language.register("html", "xml")
  end}
  use {'neovim/nvim-lspconfig', commit='3ad562700d0615818bf358268ac8914f6ce2b079'} -- Collection of configurations for built-in LSP client
  use {'hrsh7th/nvim-cmp', commit='04e0ca376d6abdbfc8b52180f8ea236cbfddf782'} -- Autocompletion plugin
  use {'emmanueltouzery/cmp-nvim-lsp', commit='85a1f3ab3324c3bd8be40baf12669dbb53972878'} -- my hack so the rust LSP doesn't overwrite my text
  use { "hrsh7th/cmp-buffer", commit = "3022dbc9166796b644a841a02de8dd1cc1d311fa" }
  use { "hrsh7th/cmp-path", commit = "91ff86cd9c29299a64f968ebb45846c485725f23" }
  use { "hrsh7th/cmp-emoji", commit = "0acd702358230abeb6576769f7116e766bca28a0" }
  -- i NEED a snippet engine, whether I want it or not, see https://github.com/hrsh7th/nvim-cmp/issues/304#issuecomment-939279715
  use {'saadparwaiz1/cmp_luasnip', commit = '18095520391186d634a0045dacaa346291096566'}
  -- alternative: https://github.com/ray-x/lsp_signature.nvim but the cmp one is more lightweight
  use {'hrsh7th/cmp-nvim-lsp-signature-help', commit = '3d8912ebeb56e5ae08ef0906e3a54de1c66b92f1'}
  use {'emmanueltouzery/doom-one.nvim', commit='2dedefe10f3294b6fd8b7b459673548e209da06d', config = function()
    require('doom-one').setup({
      cursor_coloring = true,
      italic_comments = true,
      diagnostics_color_text = false,
      plugins_integrations = {
        telescope = true,
      }
    })
  end}
  use {'airblade/vim-rooter', commit='0415be8b5989e56f6c9e382a04906b7f719cfb38', config = function()
    vim.g.rooter_silent_chdir = 1
    vim.g.rooter_cd_cmd = 'lcd'
    vim.g.rooter_change_directory_for_non_project_files = 'current'
  end, commit='0415be8b5989e56f6c9e382a04906b7f719cfb38'}
  use {'emmanueltouzery/vim-choosewin', commit='251440acb6f8291e1c48d248d41c4a25c046d8f2',
    -- fork which adds the "close window" feature
  config = function()
    vim.cmd[[nmap ¸ <Plug>(choosewin)]] -- "quake key" on the left of the numbers
    vim.keymap.set("n", "¸¸", function() vim.fn.feedkeys('--') end)
  end} 
  use {'emmanueltouzery/diffview.nvim', commit='adc48a3ad330fa77f4c8484eafdf12b15a8eb259',
    config = function()
      local function open_difftastic(file_path, left_commit, right_commit)
        local cmd = "PAGER=cat GIT_EXTERNAL_DIFF='difft --display side-by-side-show-both' git diff " .. left_commit .. ":" .. file_path .. " " .. right_commit .. ":" ..  file_path

        open_command_in_popup(cmd)
      end

      require('diffview').setup {
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
            {"n", "gf", diffview_gf,
              {desc = "Goto File"},
            },
          },
          file_panel = {
            ["-"] = false, -- i want this shortcut for choosewin
            {"n", "s", require("diffview.config").actions.toggle_stage_entry,
              {desc = "Stage / unstage the selected entry"},
            },
            {"n", "c",
              function()
              -- cc should commit from diffview same as from neogit
              vim.cmd('DiffviewClose')
              vim.api.nvim_set_current_tabpage(1) -- in case i had a dadbod in the second tab, where i could have jumped after closing the diffview tab
              -- check whether we already have a neogit tab
              local tps = vim.api.nvim_list_tabpages()
              for _, tp in ipairs(tps) do
                  local wins = vim.api.nvim_tabpage_list_wins(tp)
                  if #wins == 1 then
                    local buf = vim.api.nvim_win_get_buf(wins[1])
                    local ft = vim.api.nvim_buf_get_option(buf, 'ft')
                    if ft == 'NeogitStatus' then
                      -- switch to that tabpage
                      vim.api.nvim_set_current_tabpage(tp)
                      require'neogit'.open({ "commit" })
                      return
                    end
                  end
              end
              -- neogit is not open, open it
              vim.cmd('Neogit')
              require'neogit'.open({ "commit" })
            end,
              {desc = "Invoke diffview"}
            },
            {"n", "šx", require("diffview.config").actions.prev_conflict, {desc = "Go to previous conflict"}},
            {"n", "đx", require("diffview.config").actions.next_conflict, {desc = "Go to next conflict"}},
            {"n", "gf", diffview_gf,
              {desc = "Goto File"},
            },
            {"n", "F",
              function() -- jump to first file in the diff
                local view = require'diffview.lib'.get_current_view()
                view:set_file(view.panel:ordered_file_list()[1], false, true)
              end,
              {desc = "Jump to first file"},
            },
            {"n", "<leader>cm", function()
              local bufnr = require'diffview.lib'.get_current_view().cur_entry.layout.b.file.bufnr
              glow_for_buffer(bufnr)
            end,
              {desc = "Display markdown"},
            },
            {"n", "<leader>x", function()
              if vim.w.orig_width == nil then
                local bufnr = vim.api.nvim_win_get_buf(0)
                local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
                local maxcols = 0
                for _, line in ipairs(lines) do
                  local cols = #line
                  if cols > maxcols then
                    maxcols = cols
                  end
                end
                vim.w.orig_width = vim.api.nvim_win_get_width(0)
                vim.api.nvim_win_set_width(0, maxcols)
              else
                vim.api.nvim_win_set_width(0, vim.w.orig_width)
                vim.w.orig_width = nil
              end
            end, {desc = "Toggle expansion of file panel to fit"}
            },
            {"n", "<leader>cF", function()
              local absolute_file_path = require'diffview.lib'.get_current_view().panel.cur_file.absolute_path
              local git_path = vim.fs.root(absolute_file_path, '.git')
              local file_path = absolute_file_path:gsub(escape_pattern(git_path) .. "/", "")
              local conflicts = require'diffview.lib'.get_current_view().panel.cur_file.stats.conflicts
              if conflicts ~= nil and conflicts > 0 then
                open_command_in_popup("difft " .. file_path)
              else
                local left_commit = require'diffview.lib'.get_current_view().left.commit
                local right_commit = require'diffview.lib'.get_current_view().right.commit
                if left_commit ~= nil and right_commit ~= nil then
                  open_difftastic(file_path, left_commit, right_commit)
                else
                  open_command_in_popup("PAGER=cat GIT_EXTERNAL_DIFF='difft --display side-by-side-show-both' git diff " .. file_path)
                end
              end
            end, {desc= "Diff with difftastic"}}
          },
          file_history_panel = {
            {"n", "gf", diffview_gf,
              {desc = "Goto File"},
            },
            {"n", "<leader>cF", function()
              local file_path = require'diffview.lib'.get_current_view().cur_layout.b.file.path
              local left_commit = require'diffview.lib'.get_current_view().cur_layout.a.file.rev.commit
              local right_commit = require'diffview.lib'.get_current_view().cur_layout.b.file.rev.commit
              open_difftastic(file_path, left_commit, right_commit)
            end, {desc= "Diff with difftastic"}}
          },
        },
        file_history_panel = {
          log_options = {
            git = {
              single_file = {
                follow = true,       -- Follow renames (only for single file)
              }
            },
            relative_date_cutoff_seconds = 3 * 24 * 60 * 60,
          }
        }
      }
      -- require('diffview').init()

      vim.api.nvim_create_autocmd("FileType", {
        pattern = "DiffviewFiles",
        callback=function(ev)
          local branch = "unknown branch"
          vim.fn.jobstart("git branch --show", {
            on_stdout = vim.schedule_wrap(function(j, output)
              if #output[1] > 0 then
                branch = output[1]
              end
            end),
            on_exit = vim.schedule_wrap(function(j, output)
              for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
                if vim.api.nvim_win_get_buf(win) == ev.buf then
                  vim.wo[win].winbar = "%#Title#%= " .. branch
                  if vim.fn.exists('&winfixbuf') == 1 then
                    vim.wo[win].winfixbuf = true
                  end
                end
              end
            end)
          })
        end,
      })
    end

  }
  use {'nvim-telescope/telescope-live-grep-raw.nvim', commit='731a046da7dd3adff9de871a42f9b7fb85f60f47'}
  use {'emmanueltouzery/agitator.nvim', commit='dc2843869b8bb9e5096edf53583b1dee1e62aa6b'}
  -- use {'/home/emmanuel/home/elixir-extras.nvim'
  use {'emmanueltouzery/elixir-extras.nvim'
  , config=function()
    require'elixir-extras'.setup_multiple_clause_gutter()
  end
  }
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
  use {'smjonas/live-command.nvim', commit='ce4b104ce702c7bb9fdff863059af6d47107ca61', config=function()
    require("live-command").setup {
      defaults = {
        inline_highlighting = false, -- https://github.com/smjonas/live-command.nvim/issues/23
      },
      commands = {
        Norm = { cmd = "norm" },
        S = { cmd = "Subvert"}, -- must be defined before we import vim-abolish
      },
    }
  end}
  use {'tpope/vim-abolish', commit='3f0c8faadf0c5b68bcf40785c1c42e3731bfa522'}
  use {'qpkorr/vim-bufkill', commit='2bd6d7e791668ea52bb26be2639406fcf617271f'}
  use {'lifepillar/vim-cheat40', commit='22c505b9334abc603fc23a3776360ab3a86e0ab5', config=function()
    vim.cmd[[autocmd! FileType cheat40 :set signcolumn=no]]
  end}
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
      -- disable because this sometimes leaves some lines as highlighted as commented when they're not
      -- vim.api.nvim_set_hl(0, "LeapBackdrop", {link = "Comment"})
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
  use {'vim-test/vim-test', commit='c63b94c1e5089807f4532e05f087351ddb5a207c', config = function()
    -- https://github.com/vim-test/vim-test/issues/711
    -- trigger tests also for non-test elixir files, useful to run all tests
    -- also from a non-test file
    -- tolerate .ex, .exs, and .eex
    vim.g["test#elixir#exunit#file_pattern"] = "^.*\\.ee\\?xs\\?$"

    -- elixir: warnings as errors
    vim.cmd("let g:test#elixir#exunit#options = { 'all': '--warnings-as-errors'}")

    -- need this to parse more errors from tests into quickfix when i have debugging statements
    -- otherwise the test output may get truncated
    vim.cmd[[set scrollback=40000]]
  end}
  -- vim-markify, considered alternative: https://github.com/tomtom/quickfixsigns_vim
  use {'dhruvasagar/vim-markify', commit='14158865c0f37a02a5d6d738437eb00a821b31ef', config = function()
    vim.g.markify_error_text = ""
    vim.g.markify_warning_text = ""
    vim.g.markify_info_text = ""
    vim.g.markify_info_texthl = "Todo"
    vim.g.markify_echo_current_message = 0
  end}
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
  use {'emmanueltouzery/dressing.nvim', commit='ed59504b70f2ced477eb39f1fe6e1acc668dcfbf', config=function()
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
                -- sorter = require'telescope.sorters'.Sorter:new {
                --   scoring_function = function(_, _, line)
                --     local order = tonumber(string.match(line, "^[%d]+"))
                --     if string.find(line, escape_pattern('null-ls')) then
                --       return order+100
                --     else
                --       return order
                --     end
                --   end,
                -- },
                cache_picker = false,
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
    vim.cmd[[set winhighlight=NormalFloat:DressingInputText]]
  end}
  use {
    "williamboman/mason.nvim",
    commit = "d66c60e17dd6fd8165194b1d14d21f7eb2c1697a",
  }
  use {
    "williamboman/mason-lspconfig.nvim",
    commit = "2451adb9bdb0fd32140bf3aa8dbc17ff60050db3",
    config = function()
      require("mason").setup()
      require("mason-lspconfig").setup {
        automatic_installation = true,
      }
      local lspconfig = require("lspconfig")
      local log = require 'vim.lsp.log';
      local util = require 'vim.lsp.util'
      local capabilities = require('cmp_nvim_lsp').default_capabilities()

      lspconfig.tsserver.setup {
        on_attach = function(client)
        -- use prettier for JS indentation (through conform.nvim)
          client.server_capabilities.documentFormattingProvider = false
          client.server_capabilities.documentRangeFormattingProvider = false
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

      lspconfig.rust_analyzer.setup {}
      lspconfig.elixirls.setup {
        cmd = { "elixir-ls" }; -- for some reason I must specify the command. I think I shouldn't have to, due to mason
        -- use conform.nvim for elixir indentation, because it can give me the mix fmt output
        -- which sometimes pinpoints the syntax error
        on_attach = function(client, bufnr)
          client.server_capabilities.documentFormattingProvider = false
          client.server_capabilities.documentRangeFormattingProvider = false
        end,
      }
      lspconfig.bashls.setup {}
      lspconfig.jsonls.setup {
        -- use prettier for json indentation (through conform.nvim)
        on_attach = function(client, bufnr)
          client.server_capabilities.documentFormattingProvider = false
          client.server_capabilities.documentRangeFormattingProvider = false
        end,
      }
      lspconfig.cssls.setup {
        capabilities = capabilities
      }
      lspconfig.graphql.setup {
        -- disabling for typescript & typescriptreact as i don't know what it gives me
        -- and i suspect it slows things down
        filetypes = {'graphql'}
      }
    end,
    after = "nvim-lspconfig",
  }
  use {'emmanueltouzery/key-menu.nvim', commit='171ad5c40fe978ebba86026beac1ac3ed8eda42d'} -- originally linty-org/key-menu.nvim but the git repo was deleted...
  use {'lambdalisue/suda.vim', commit='6bffe36862faa601d2de7e54f6e85c1435e832d0'}
  use {'akinsho/toggleterm.nvim', commit='2a787c426ef00cb3488c11b14f5dcf892bbd0bda', config = function()
    require("toggleterm").setup{
      direction = 'float',
      float_opts = {
        width = 140,
        height = 45,
      },
      size = function(term)
        if term.direction == "horizontal" then
          return 15
        elseif term.direction == "vertical" then
          return vim.o.columns * 0.5
        end
      end,
      on_open=function(term)
        -- q to close a terminal
        vim.api.nvim_buf_set_keymap(term.bufnr, "n", "<esc>", "<cmd>close<CR>", {noremap = true, silent = true})
      end,
    }
    function _G.set_terminal_keymaps()
      local opts = {noremap = true}
      vim.api.nvim_buf_set_keymap(0, 't', '<esc>', [[<C-\><C-n>]], opts)
    end
    -- if you only want these mappings for toggle term use term://*toggleterm#* instead
    vim.cmd('autocmd! TermOpen term://* lua set_terminal_keymaps()')
  end}
  use {'nvim-treesitter/playground', commit="4044b53c4d4fcd7a78eae20b8627f78ce7dc6f56"}
  use {'stevearc/aerial.nvim', commit="60a784614acb1d7695bd9ae0fee8ada1bf7b0c28", config = function()
    local protocol = require("vim.lsp.protocol")
    local function get_symbol_kind_name(kind_number)
      return protocol.SymbolKind[kind_number] or "Unknown"
    end
    vim.api.nvim_set_hl(0, 'AerialPrivate', { default = true, italic = true})
    require("aerial").setup({
      -- i find the lazy load is not all worth it for me
      -- i don't notice the startup delay, but the first use
      -- delay is reeeeally noticeable
      lazy_load = false,
      disable_max_lines = 20000, -- useful for json output in dadbod-jq
      backends = {
        ['_'] = { "treesitter", "lsp", "markdown", "man" },
        elixir = { "treesitter" },
        typescript = { "treesitter" },
        typescriptreact = { "treesitter" },
        groovy = { "treesitter" },
      },
      filter_kind = false,
      icons = {
        Field       = "󰙅 ",
        Type        = "󰊄 ",
      },
      treesitter = {
        experimental_selection_range = true,
      },
      k = 2,
      post_parse_symbol = function(bufnr, item, ctx)
        if ctx.backend_name == "treesitter" and (ctx.lang == "typescript" or ctx.lang == "tsx") then
          local utils = require"nvim-treesitter.utils"

          -- don't want to display in-function items
          local value_node = (utils.get_at_path(ctx.match, "var_type") or {}).node
          local cur_parent = value_node and value_node:parent()
          while cur_parent do
            if cur_parent:type() == "arrow_function"
              or cur_parent:type() == "function_declaration"
              or cur_parent:type() == "method_definition" then
              return false
            end
            cur_parent = cur_parent:parent()
          end

          -- find out whether the function is public or private
          -- this combines with get_highlight for which we highlight
          -- private symbols differently
          item.scope = "private"
          local value_node = (utils.get_at_path(ctx.match, "symbol") or {}).node
          local cur_parent = value_node and value_node:parent()
          while cur_parent do
            if cur_parent:type() == "export_statement" then
              item.scope = nil
            end
            cur_parent = cur_parent:parent()
          end
        elseif ctx.backend_name == "treesitter" and ctx.lang == "groovy" then
          if ctx.match.kind ~= "Constant" then
            return true
          end
          local utils = require"nvim-treesitter.utils"

          -- don't want to display in-function items
          local value_node = (utils.get_at_path(ctx.match, "symbol") or {}).node
          local cur_parent = value_node and value_node:parent()
          while cur_parent do
            if cur_parent:type() == "closure" then
              return false
            end
            cur_parent = cur_parent:parent()
          end
        elseif ctx.backend_name == "lsp" and ctx.symbol and ctx.symbol.location and string.match(ctx.symbol.location.uri, "%.graphql$") then
          -- for graphql it was easier to go with LSP. Use the symbol kind to keep only the toplevel queries/mutations
          return ctx.symbol.kind == 5
        elseif ctx.backend_name == "treesitter" and ctx.lang == "html" and vim.fn.expand("%:e") == "ui" then
          -- in GTK UI files only display 'object' items (widgets), and display their
          -- class instead of the tag name (which is always 'object')
          if item.name == "object" then
            local line = vim.api.nvim_buf_get_lines(bufnr, item.lnum-1, item.lnum, false)[1]
            local _, _, class = string.find(line, [[class=.([^'"]+)]])
            item.name = class
            return true
          else
            return false
          end
        elseif ctx.backend_name == "treesitter" and ctx.lang == "rust" then
          local utils = require"nvim-treesitter.utils"
          local value_node = (utils.get_at_path(ctx.match, "symbol") or {}).node
          local child_text = vim.treesitter.get_node_text(value_node:child(0), bufnr) or "<parse error>"
          if child_text ~= "pub" then
            item.scope = "private"
          end
        elseif ctx.backend_name == "treesitter" and ctx.lang == "java" then
          local utils = require"nvim-treesitter.utils"
          local value_node = (utils.get_at_path(ctx.match, "symbol") or {}).node
          local child_text = vim.treesitter.get_node_text(value_node:child(0), bufnr) or "<parse error>"
          local is_private = child_text:match("private")
          if is_private then
            item.scope = "private"
          end
        elseif ctx.backend_name == "treesitter" and ctx.lang == "python" then
          -- don't want to display in-function items
          local utils = require"nvim-treesitter.utils"
          local value_node = (utils.get_at_path(ctx.match, "symbol") or {}).node
          local cur_parent = value_node and value_node:parent()
          while cur_parent do
            if cur_parent:type() == "function_definition" then
              return false
            end
            cur_parent = cur_parent:parent()
          end
        end
        return true
      end,
      get_highlight = function(symbol, is_icon)
        if symbol.scope == "private" then
          return "AerialPrivate"
        else
          return "variable"
        end
      end,
    })
    require('telescope').load_extension('aerial')
  end}
  use {'NeogitOrg/neogit', commit='bc0c609e3568a171e0549b449aa1b2b4b5b20e8c', config = function()
    require('neogit').setup {
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

    vim.api.nvim_create_autocmd({ "User" }, {
      pattern = 'NeogitCommitComplete',
      callback = function()
        lualine_refresh_all()
        vim.cmd[[NvimTreeRefresh]]
      end,
    })
  end}
  use {
    'nvim-tree/nvim-tree.lua', commit='50e919426a4a2053f78b2f8ab001c8ad8eb47ef6',
    requires = { 'nvim-tree/nvim-web-devicons', commit='19d257cf889f79f4022163c3fbb5e08639077bd8' },
    -- for some reason must call init outside of the config block, elsewhere
    -- config = function() require'nvim-tree'.setup {} end
  }
  use {"b3nj5m1n/kommentary", commit='533d768a140b248443da8346b88e88db704212ab', config = function()
    require('kommentary.config')
    .configure_language("default", {
      prefer_single_line_comments = true,
    })
  end}
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
      dashboard.button( "b", "  Open file browser" , "<cmd>lua require 'telescope'.extensions.file_browser.file_browser({grouped = true})<CR>"), -- alt icon: 󰙅
      dashboard.button( "q", "  Quit NVIM" , ":qa<CR>"),
    }
    dashboard.config.opts.noautocmd = true
    alpha.setup(dashboard.config)
  end}
  use {'L3MON4D3/LuaSnip', commit = '52f4aed58db32a3a03211d31d2b12c0495c45580'} -- Snippets plugin
  use {'emmanueltouzery/vim-dispatch-neovim', commit='412fa79d6cf59dcc21b6e9f562202537fa8f456d'}
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
  use {'emmanueltouzery/nvim-treehopper', commit='e1824c4'}
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
  use {'andymass/vim-matchup', commit='2d660e4aa7c566014c667af2cda0458043527902', config=function()
    -- https://github.com/andymass/vim-matchup#customizing-the-highlighting-colors
    vim.cmd [[
      augroup matchup_matchparen_highlight
        autocmd!
        autocmd ColorScheme * hi MatchParen ctermfg=yellow guifg=yellow,\
            hi MatchWord cterm=bold,underline gui=bold,underline ctermfg=NONE guifg=NONE
      augroup END
    ]]
  end}
  use {'stevearc/overseer.nvim', commit='965f8159408cee5970421ad36c4523333b798502', config=function()
    require('overseer').setup{
      dap = false,
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
  -- use {'mfussenegger/nvim-dap', commit='6f79b822997f2e8a789c6034e147d42bc6706770', config=function()
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
  -- end}
--   use {'/simrat39/rust-tools.nvim', commit='86a2b4e31f504c00715d0dd082a6b8b5d4afbf03', config=function()
--     local rt = require("rust-tools")

--     --https://github.com/LunarVim/LunarVim/issues/2894#issuecomment-1236420149
-- -- https://github.com/simrat39/rust-tools.nvim#a-better-debugging-experience
-- opts = {
--     server = {
--       on_attach = function(client, bufnr)
--         -- disable LSP based syntax highlighting https://github.com/simrat39/rust-tools.nvim/issues/365#issuecomment-1506286437
--         -- it takes time to appear so is jarring, plus i find it worse than tree-sitter
--         client.server_capabilities.semanticTokensProvider = nil
--       end
--     }
-- }
-- local path = vim.fn.glob(vim.fn.stdpath("data") .. "/mason/packages/codelldb/extension/") or ""
-- local codelldb_path = path .. "adapter/codelldb"
-- local liblldb_path = path .. "lldb/lib/liblldb.so"

-- if vim.fn.filereadable(codelldb_path) and vim.fn.filereadable(liblldb_path) then
--   opts.dap = {
--     adapter = require("rust-tools.dap").get_codelldb_adapter(codelldb_path, liblldb_path),
--   }
-- else
--   local msg = "Either codelldb or liblldb is not readable."
--     .. "\n codelldb: "
--     .. codelldb_path
--     .. "\n liblldb: "
--     .. liblldb_path
--   vim.notify(msg, vim.log.levels.ERROR)
-- end
--     -- print(vim.inspect(opts))

-- rt.setup(opts)
--     -- rt.setup({
--     --   server = {
--     --     on_attach = function(_, bufnr)
--     --       -- Hover actions
--     --       vim.keymap.set("n", "<C-space>", rt.hover_actions.hover_actions, { buffer = bufnr })
--     --       -- Code action groups
--     --       vim.keymap.set("n", "<Leader>a", rt.code_action_group.code_action_group, { buffer = bufnr })
--     --     end,
--     --   },
--     --   -- dap = {
--     --   --   adapter = require('rust-tools.dap').get_codelldb_adapter(
--     --   --   "codelldb", "liblldb.so")
--     --   -- },
--     -- })
--   end}
  -- use {'rcarriga/nvim-dap-ui', commit='f889edb4f2b7fafa2a8f8101aea2dc499849b2ec', config=function()
  --   require("dapui").setup{}
  -- end}
  -- tracking my 'search' branch.
  -- upstream has archived the plugin: https://github.com/luckasRanarison/nvim-devdocs
  use {"emmanueltouzery/nvim-devdocs",
    commit = '0abc94890747ae5458da6ae17fd1cced63da83d6',
    requires = {
      "nvim-lua/plenary.nvim",
      "nvim-telescope/telescope.nvim",
      "nvim-treesitter/nvim-treesitter",
    },
    config=function()
      require("nvim-devdocs").setup({
        float_win = { -- passed to nvim_open_win(), see :h api-floatwin
          relative = "editor",
          height = 45,
          width = 90,
          border = "rounded",
        },
        -- previewer_cmd = 'glow',
        -- cmd_args = { "-s", "tokyo-night", "-w", "80" },
        -- picker_cmd = 'glow',
        -- picker_cmd_args = { "-s", "tokyo-night", "-w", "80", "-p" },
        ensure_installed = { "lodash-4", "javascript", "date_fns", "react", "openjdk-8", "rust", "dom"},
      })
    end}
  use {"mfussenegger/nvim-lint", commit="f707b3ae50417067fa63fdfe179b0bff6b380da1", config=function()
    local lint = require("lint")
    lint.linters_by_ft = {
      javascript = { "eslint" },
      javascriptreact = { "eslint" },
      typescript = { "eslint" },
      typescriptreact = { "eslint" },
      elixir = { "credo" },
      java = { "checkstyle" },
    }

    -- customize credo, remove the --strict flag
    local credo = lint.linters.credo
    credo.args = vim.tbl_filter(function(p) return p ~= "--strict" end, credo.args)

    -- install checkstyle using mason (spc-pl)
    local checkstyle = lint.linters.checkstyle
    checkstyle.config_file = vim.fn.stdpath("config") .. "/java-checkstyle.xml"

    nvim_lint_create_autocmds()
  end}
  use {"stevearc/conform.nvim", commit="62d5accad8b29d6ba9b58d3dff90c43a55621c60", config=function()
    require("conform").setup({
      formatters_by_ft = {
        javascript = { "prettier" },
        javascriptreact = { "prettier" },
        typescript = { "prettier" },
        typescriptreact = { "prettier" },
        markdown = { "prettier" },
        json = { "prettier" },
        css = { "prettier" },
        scss = { "prettier" },
        less = { "prettier" },
        graphql = { "prettier" },
        elixir = { "mix" },
      },
      format_after_save = function(bufnr)
        if vim.g.disable_autoformat or vim.b[bufnr].disable_autoformat then
          return
        end
        return {}
      end,
    })
    -- vim.api.nvim_create_autocmd("BufWritePre", {
    --   pattern = { "*.ts", "*.tsx", "*.js", "*.jsx", "*.md", "*.json", "*.css", "*.scss", "*.less", "*.graphql", "*.ex", "*.exs", "*.rs" },
    --   callback = function(args)
    --     if vim.g.disable_autoformat or vim.b[args.buf].disable_autoformat then
    --       return
    --     end
    --     require("conform").format({ bufnr = args.buf })
    --   end,
    -- })
  end}
  use {"emmanueltouzery/vim-dadbod", commit="42319fd7dbe45aa4aba44c6d00e55019f89ad6f6"} -- no OOM on large queries, adbsqlite adapter
  use {"kristijanhusak/vim-dadbod-ui", commit="9ddb0623e69d696b7a8355b93e3950a8dc6e00a0", config=function()
    vim.g.db_ui_use_nerd_fonts = 1
    vim.g.db_ui_auto_execute_table_helpers = 1
    -- executing on save is annoying when i run :wa in another tab: the query in
    -- the background tab is run and the output displayed in the foreground tab.
    -- also my ,g mapping is good enough
    vim.g.db_ui_execute_on_save = 0
    -- vim.g.db_ui_use_nvim_notify = 1

    -- can use my own notifications, but i actually prefer theirs
    -- vim.notify = function(msg, level, opts)
    --   if opts and (opts.title == "Neogit" or opts.title == "[DBUI]") then
    --     if level == "info" then -- needed for DBUI/dadbod-ui
    --       level = vim.log.levels.INFO
    --     end

    vim.api.nvim_create_autocmd({ "User" }, {
      pattern = {'DBQueryPost', "*DBExecutePost"},
      callback = function()
        local out_filetype = get_dbout_filetype()
        if out_filetype == 'dbout' then
          local _w, bufnr = get_dbout_win_buf()
          if bufnr ~= nil then
            -- it will be null for jq queries
            vim.api.nvim_buf_call(bufnr, function()
              require("zebrazone").start()
            end)
          end
        end
      end,
    })
  end}
  use {"kristijanhusak/vim-dadbod-completion", commit="880f7e9f2959e567c718d52550f9fae1aa07aa81", config=function()
    vim.cmd[[autocmd FileType sql,mysql,plsql lua require('cmp').setup.buffer({ sources = {{ name = 'vim-dadbod-completion' }} })]]
    vim.api.nvim_create_autocmd("FileType", {
      pattern = "dbout",
      callback=function(ev)
        vim.api.nvim_win_set_height(0, 40)
      end})
  end}
  use {"emmanueltouzery/code-compass.nvim"}
  use {"emmanueltouzery/decisive.nvim", config=function()
    require('decisive').setup{}
    vim.cmd[[hi CsvFillHlOdd  guibg=#2f3542]]
  end}
  -- https://github.com/neovim/neovim/issues/20092
  use {"notomo/zebrazone.nvim", commit="c4704c0bdbb7ad5de3779e32b76d6852cfb458e3", config=function()
    -- tone down the zebra effect with my theme
    vim.cmd[[hi ZebrazoneDefault guibg=#2f3542]]
  end}
  use {"stevearc/quicker.nvim", commit="cde090601b24cd6f4982e702dd31a810c19ee975", config=function()
    require("quicker").setup({
      keys = {
        {
          ">",
          function()
            require("quicker").expand({ before = 2, after = 2, add_to_existing = true })
          end,
          desc = "Expand quickfix context",
        },
        {
          "<",
          function()
            require("quicker").collapse()
          end,
          desc = "Collapse quickfix context",
        },
      },
    })
  end}
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
-- vim.opt.guifont = "JetBrainsM3n3 Nerd Font:h10.6"
-- vim.opt.guifont = "JetBrainsM3n3 Nerd Font:h9.8"
vim.opt.guifont = "JetBrainsMono Nerd Font,Noto Color Emoji:h9.8"
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
require("global_marks")
require("previous_next")
require("telescope_global_marks")
require("telescope_branches")
require("telescope_recent_or_all")
require("telescope_git_stash")
require("telescope_lsp_hierarchy")
require("telescope_qf_locations")
require("telescope_modified_git_projects")
require("notifs")
require("ts_unused_imports")
require("elixir")
require("database")
require("mini_diff_extras")

vim.cmd [[autocmd BufWritePre *.rs lua vim.lsp.buf.format()]]

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

-- reasonable default, will get overwritten most of the time by autoindent or vim-sleuth
vim.cmd("set sw=2")

-- SPELL CHECKING
vim.cmd("set spell")
vim.cmd("set spelloptions=camel")
vim.cmd[[au FileType qf setlocal spelloptions=camel]] -- unsure why i need special treatment for QF, but it helps
vim.cmd[[au FileType dbout setlocal spelloptions=camel]] -- unsure why i need special treatment for dbout, but it helps

-- tune spellcheck in terminals
-- vim.cmd[[au TermOpen * setlocal spelloptions=camel,noplainbuffer]]
vim.cmd[[au TermOpen * setlocal nospell]]

vim.cmd("hi clear SpellCap")
vim.cmd("au BufNewFile,BufRead,BufWritePost *.lua setlocal nospell")
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
vim.cmd[[au Colorscheme * highlight Whitespace guifg=#999999 ctermfg=lightgray]]

-- for instance nginx configuration files
vim.cmd('autocmd BufNewFile,BufRead *.conf set syntax=conf')
vim.cmd('autocmd BufNewFile,BufRead *.conf.template set syntax=conf')
vim.cmd('autocmd BufNewFile,BufRead *.yml.template set syntax=yaml')
vim.cmd('autocmd BufNewFile,BufRead *.service set syntax=systemd')

-- fix undercurls in neovim 0.10 (on 'private' keywords in java for instance)
vim.cmd[[set spellcapcheck=]]

-- https://stackoverflow.com/a/76388188/516188
-- when splitting windows, i don't like the horizontal scroll to be
-- moved. rather keep the scroll position and move the cursor if needed.
-- example, double split, put the cursor at the end of a long line, vert split
-- again, then delete the new split: the rightmost split has had a
-- scroll to the right. not anymore with splitkeep=screen.
vim.cmd[[set splitkeep=screen]]

function set_extra_spellfiles()
  if vim.bo.filetype == "man" then
    vim.cmd("setlocal nospell")
  else
    vim.cmd("setlocal spellfile=" .. vim.fn.stdpath("config")  .. "/spell/en.utf-8.add")
    vim.cmd("setlocal spellfile+=" .. vim.fn.stdpath("config")  .. "/spell/" .. vim.bo.filetype .. ".utf-8.add")
    local project_name = vim.fn.getcwd(vim.fn.winnr()):match("[^/]+$")
    -- only if the "project name" doesn't contain spaces and other special characters
    if not project_name:match('[%s()]') then
      vim.cmd("setlocal spellfile+=" .. vim.fn.stdpath("config")  .. "/spell/" .. project_name .. ".utf-8.add")
    end
  end
end

-- https://vi.stackexchange.com/a/15053/38754
vim.api.nvim_create_autocmd("FileType", {
  callback=function(ev)
    set_extra_spellfiles()
  end})

vim.api.nvim_create_autocmd("User", {
  pattern = "RooterChDir",
  callback=function()
    set_extra_spellfiles()
  end})

-- syntax highlight for fennel files
vim.cmd('autocmd BufNewFile,BufRead *.fnl set ft=lisp')
-- bpftrace
vim.cmd('autocmd BufNewFile,BufRead *.bt set ft=c')

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

-- https://github.com/nvim-tree/nvim-web-devicons/issues/36#issuecomment-1267259762
-- different icon color for elixir tests START
local devicons = require "nvim-web-devicons"

local get_icon = devicons.get_icon
devicons.get_icon = function(name, ext, opts)
  if name:find "^.+_test.exs$" then
    return "", "DevIconDockerfile"
  else
    return get_icon(name, ext, opts)
  end
end

local get_icon_colors = devicons.get_icon_colors
devicons.get_icon_colors = function(name, ext, opts)
  if name:find "^.+_test.exs$" then
    return "", "#458ee6", 68
  else
    return get_icon_colors(name, ext, opts)
  end
end
-- different icon color for elixir tests END

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
vim.cmd[[let $EDITOR='invim --tabedit --remote-wait']]
vim.cmd[[autocmd FileType gitcommit,gitrebase,gitconfig set bufhidden=delete]]

-- emphasize dressing.nvim window border some more
vim.cmd[[hi FloatBorder guifg=#dfdad9]]

-- stay in visual mode after indenting with < and >
-- https://superuser.com/a/310424/214371
vim.cmd[[
vnoremap < <gv
vnoremap > >gv
]]

-- no extra spaces when joining lines
-- https://vi.stackexchange.com/a/440/38754
-- revert for now, it doesn't remove any leading spaces:
-- https://www.reddit.com/r/vim/comments/st9not/when_is_gj_join_without_space_useful_on_indented/
-- https://vi.stackexchange.com/a/440/38754
-- vim.cmd[[nnoremap J gJ]]

-- https://vim.fandom.com/wiki/Search_only_in_unfolded_text
-- by default don't open folds when searching.
-- "a search shows one hit per fold that contains the search target. The fold is not opened, 
-- and is only found once, even if it contains several instances of the search target."
vim.cmd[[set foldopen-=search]]

-- open quickfix window below vertical splits
-- https://stackoverflow.com/a/47077341/516188
vim.cmd[[au FileType qf wincmd J | 15wincmd_]]

-- https://www.reddit.com/r/neovim/comments/ctrdtq/always_open_help_in_a_vertical_split/
vim.cmd[[autocmd! FileType help :wincmd L]]
vim.cmd[[autocmd! FileType man :wincmd L]]
-- vim.cmd[[autocmd! BufEnter * if &ft ==# 'man' | wincmd L | endif]]

-- compared to the default, activate the 'linematch' extra option
-- for nicer diff lines matching
vim.o.diffopt = "internal,filler,closeoff,linematch:60"

-- move the cursor to the beginning of non-whitespace characters in a line
-- EDIT: undo. want to be able to move back to the 0th column in case of right scroll
-- vim.cmd[[
-- nmap 0 ^
-- nmap <Home> ^
-- ]]

-- https://vi.stackexchange.com/questions/17816/solved-ish-neovim-dont-close-terminal-buffer-after-process-exit
-- don't autoclose terminal buffers when the app exits. Useful when opening elixir apidocs in buffers using
-- elixir-extras.nvim
vim.cmd[[au TermClose * call feedkeys("\<C-\>\<C-n>")]]

-- winfixbuf
if vim.fn.has("nvim-0.10") == 1 then
  vim.api.nvim_create_autocmd("BufEnter", {
    callback = function()
      if vim.list_contains({"NvimTree", "OverseerList", "aerial", "dbui", "dbout"}, vim.bo.filetype) then
        vim.wo.winfixbuf = true
      end
    end,
  })
end

-- https://stackoverflow.com/a/11710333/516188
vim.api.nvim_create_autocmd({ "FileType" }, {
  -- i don't want this to match on the telescope prompt for instance
  pattern = {"java", "elixir", "javascript", "typescript", "typescriptreact",
    "sh", "python", "c", "cpp", "lua", "rust", "ruby", "css", "scss", "json", "jsonc"},
  command = "call matchadd('TodoGroup', 'TODO', -1)",
})
vim.cmd [[hi TodoGroup guibg=#ECBE7B guifg=black]]

-- useful for android development
vim.api.nvim_create_autocmd("FileType", {
  pattern = "java",
  callback=function(ev)
    local matches = vim.fs.find("AndroidManifest.xml", {
      upward = true,
      type = "file",
      path = vim.fs.dirname(vim.api.nvim_buf_get_name(0)),
    })
    if #matches > 0 then
      -- this is an android project, and this is a java file, for which i'm assuming
      -- no LSP. Let's override K to something more useful than nothing.
      vim.keymap.set('n', 'K', function()
        -- assume we're on top of an import <package>; line
        local url = "https://developer.android.com/reference/" .. vim.fn.expand('<cWORD>'):gsub(';', ''):gsub('%.', '/')
        vim.fn.jobstart({"xdg-open", url})
      end, { buffer = true })
    end
  end
})

-- vim: ts=2 sts=2 sw=2 et
