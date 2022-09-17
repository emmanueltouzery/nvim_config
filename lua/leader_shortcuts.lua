--Remap space as leader key
vim.keymap.set({ 'n', 'v' }, '<Space>', '<Nop>', { silent = true })
vim.g.mapleader = ' '
vim.g.maplocalleader = ' '

vim.keymap.set( "n", "<leader>.", "<cmd>Telescope file_browser hidden=true<CR>", {desc="Telescope files"})
vim.keymap.set( "n", "<leader>,", "<cmd>Telescope buffers show_all_buffers=true<CR>", {desc="Telescope buffers"})
vim.keymap.set("n", "<leader>?", ":Cheat40<cr>", {desc="help"})

-- BUFFER
require 'key-menu'.set('n', '<Space>b', {desc='Buffer'})
-- https://stackoverflow.com/a/19619038/516188
--":b#<bar>bd#<CR>",
-- that didn't cut it => https://github.com/qpkorr/vim-bufkill
-- further options: https://www.reddit.com/r/vim/comments/m6jl0b/i_made_a_plugin_a_replacement_for_bdelete_that/
-- and also https://github.com/mhinz/vim-sayonara
vim.keymap.set("n", "<leader>bd",  ":BD<cr>", {desc="Delete buffer"})
vim.keymap.set("n", "<leader>bD",  ":BD!<cr>", {desc="Force delete buffer"})

function open_buf_in_window(jump_to_target)
  local line = vim.fn.line('.')
  local target_win_idx = vim.api.nvim_eval("choosewin#start(range(1, winnr('$')), { 'noop': 1 })[1]")
  local target_winnr = vim.api.nvim_list_wins()[target_win_idx]
  vim.api.nvim_win_set_buf(target_winnr, vim.api.nvim_win_get_buf(0))
  if jump_to_target then
    vim.cmd(target_win_idx .. ' wincmd w')
    vim.cmd(':' .. line)
    vim.fn.feedkeys('zz')
  end
end
vim.keymap.set("n", "<leader>bw",  "<cmd>lua open_buf_in_window(true)<cr>", {desc="Open cur. buffer in window+go there"})
vim.keymap.set("n", "<leader>bW",  "<cmd>lua open_buf_in_window(false)<cr>", {desc="Open cur. buffer in window"})
vim.keymap.set("n", "<leader>bo", "<cmd>%bd|e#<cr>", {desc="Close all buffers but the current one"}) -- https://stackoverflow.com/a/42071865/516188

require 'key-menu'.set('n', '<Space>')

-- FILES
require 'key-menu'.set('n', '<Space>f', {desc='File'})
vim.keymap.set('n', '<leader>fn', ":enew<cr>", {desc = "New file"})
vim.keymap.set("n", "<leader>fs", ":w<cr>", {desc="Save file"})
vim.keymap.set("n", "<leader>fS", ":wa<cr>", {desc="Save all files"})
vim.keymap.set("n", "<leader>ff", "<cmd>Telescope find_files hidden=true<cr>", {desc = "Find files"})
vim.keymap.set("n", "<leader>fr", "<cmd>Telescope oldfiles<cr>", { desc = "Recent files"})
vim.keymap.set("n", "<leader>fR", "<cmd>SudaRead<cr>", { desc = "Re-open file with sudo permissions"})
vim.keymap.set("n", "<leader>fw", "<cmd>SudaWrite<cr>", { desc = "Write file with sudo permissions"})
vim.keymap.set("n", "<leader>fp", ':lua copy_to_clipboard(cur_file_path_in_project())<cr>', {desc="Copy file path"}) -- ':let @+ = expand("%")<cr>',
vim.keymap.set("n", "<leader>fP", ':let @+ = expand("%:p")<cr>', {desc="Copy file full path"})
vim.keymap.set("n", "<leader>fW", ":noautocmd w<cr>", {desc="save_noindent"})

-- SEARCH
require 'key-menu'.set('n', '<Space>s', {desc='Search'})
vim.keymap.set("n", "<leader>*", "<cmd>lua my_open_tele()<cr>", {desc="Search word under cursor, raw"})
vim.keymap.set("v", "<leader>*", "<cmd>lua my_open_tele_sel()<cr>", {desc="Search selected text, raw"})
vim.keymap.set("n", "<leader>sr", "<cmd>lua require('telescope').extensions.live_grep_raw.live_grep_raw()<cr>", {desc="Search text raw"})
require 'key-menu'.set('n', '<Space>ss', {desc='Search LSP symbols'})
vim.keymap.set("n", "<leader>ssf", "<cmd>Telescope lsp_document_symbols<cr>", { desc = "Goto file LSP symbol"})
vim.keymap.set( "n", "<leader>ssw", "<cmd>Telescope lsp_workspace_symbols<CR>", {desc="Goto workspace LSP symbol"})
function filter_lsp_workspace_symbols()
  vim.ui.input({prompt="Enter LSP symbol filter please: ", kind="center_win"}, function(word)
    if word ~= nil then
      filter_lsp_symbols(word)
    end
  end)
end
vim.keymap.set( "n", "<leader>ssW", "<cmd>lua filter_lsp_workspace_symbols()<CR>", {desc="Filter workspace LSP symbols"})
function ws_symbol_under_cursor()
  local word = vim.fn.expand('<cword>')
  filter_lsp_symbols(word)
end
vim.keymap.set( "n", "<leader>s*", "<cmd>lua ws_symbol_under_cursor()<CR>", {desc="Goto workspace symbol under cursor"})

-- WINDOW
require 'key-menu'.set('n', '<Space>w', {desc='Window'})
vim.keymap.set("n", "<leader>wd", "<C-W>c", {desc="Close current window"})
vim.keymap.set("n", "<leader>w=", "<C-W>=", {desc = "Balance window"})
vim.keymap.set("n", "<leader>ws", "<C-W>s", {desc = "Split window below"})
vim.keymap.set("n", "<leader>wv", "<C-W>v", {desc = "Split window right"})
vim.keymap.set("n", "<leader>wr", "<C-w>r", {desc="Window rotate"})
vim.keymap.set("n", "<leader>wm", "<C-w>o", {desc="Window maximize"})
vim.keymap.set("n", "<leader>wM", "<cmd>lua max_win_in_new_tab()<cr>", {desc="Window maximize in a new tab"})
vim.keymap.set("n", "<leader>wc", "<cmd>lua clamp_windows()<cr>", {desc="Clamp popups so they fit in the screen"})

-- PACKAGES
require 'key-menu'.set('n', '<Space>p', {desc='Packages'})
vim.keymap.set("n", "<leader>pp", "<cmd>PackerSync<cr>", { desc = "Packer sync"})
vim.keymap.set("n", "<leader>pl", "<cmd>LspInstallInfo<cr>", { desc = "LSP install info"})
vim.keymap.set("n", "<leader>pt", "<cmd>TSInstallInfo<cr>", { desc = "Tree-sitter install info"})
vim.keymap.set("n", "<leader>pT", "<cmd>TSUpdate<cr>", { desc = "Tree-sitter update packages"})

-- a bit messy to remap telescope-project key mappings: https://github.com/nvim-telescope/telescope-project.nvim/issues/84
-- I want telescope-live-grep-raw instead of the normal telescope-rg
function tel_proj_attach_mappings(prompt_bufnr, map)
  map('i', '<C-s>', function(nr)
    require('telescope').extensions.live_grep_raw.live_grep_raw{
      cwd=require("telescope.actions.state").get_selected_entry(prompt_bufnr).value
    } 
  end)
  map('i', '<C-g>', function(nr)
    require('telescope.builtin').git_status{
      cwd=require("telescope.actions.state").get_selected_entry(prompt_bufnr).value
    } 
  end)
  return true 
end
_G.telescope_project_command = [[<cmd>lua require'telescope'.extensions.project.project{ display_type = 'full', attach_mappings = tel_proj_attach_mappings}<CR>]]

-- OPEN
require 'key-menu'.set('n', '<Space>o', {desc='Open'})
vim.keymap.set("n", "<leader>op", telescope_project_command, {desc="Open project"})
vim.keymap.set("n", "<leader>oc", ":lua goto_fileline()<cr>", {desc="Open code (file+line)"})
vim.keymap.set("n", "<leader>ob", "<cmd>lua require 'telescope'.extensions.file_browser.file_browser({grouped = true})<CR>", {desc="Open file browser"})
vim.keymap.set("n", "<leader>og", "<cmd>lua telescope_global_marks{}<CR>", {desc="Open global marks"})
vim.keymap.set("n", "<leader>om", ":lua open_manpage()<cr>", {desc="Open man page"})
vim.keymap.set("n", "<leader>ok", "<cmd>lua require'telescope.builtin'.keymaps{}<CR>", {desc="Open keyboard shortcuts"})
vim.keymap.set("n", "<leader>oq", "<cmd>lua telescope_quickfix_locations{}<CR>", {desc="Open quickfix locations"})

-- TOGGLE
require 'key-menu'.set('n', '<Space>t', {desc='Toggle'})
vim.keymap.set("n", "<leader>te", "<cmd>NvimTreeToggle<CR>", {desc = "Toggle file explorer"})
vim.keymap.set("n", "<leader>ts", "<cmd>SymbolsOutline<CR>", {desc = "Toggle SymbolsOutline (LSP symbols)"})
vim.keymap.set("n", "<leader>tt", "<cmd>ToggleTerm<CR>", {desc = "Toggle terminal"})
vim.keymap.set("n", "<leader>tm", "<cmd>lua toggle_highlight_global_marks()<CR>", {desc = "Toggle highlight of global marks"})
vim.keymap.set("n", "<leader>tw", ":set wrap! linebreak<cr>", {desc = "Toggle word-wrapping"})

function toggle_diff()
  if vim.opt.diff:get() then
    vim.cmd("windo diffoff")
  else
    vim.cmd("windo diffthis")
  end
end
vim.keymap.set("n", "<leader>tf", ":lua toggle_diff()<cr>", {desc = "Toggle diff"})

vim.api.nvim_exec([[
function! ToggleQuickFix()
    if empty(filter(getwininfo(), 'v:val.quickfix'))
        copen
    else
        cclose
    endif
endfunction
 ]], false)
vim.keymap.set("n", "<leader>tq", ":call ToggleQuickFix()<cr>", {desc="Toggle quickfix"})
vim.keymap.set("n", "<leader>th", ":set invhlsearch<cr>", {desc="Toggle highlight"})
vim.keymap.set("n", "<leader>td", ":tabc<cr>", {desc="Delete tab"}) -- that one doesn't fit under toggle.. it's TAB delete. but keeping it here for now.
vim.keymap.set("n", "<leader>tg", "<cmd>lua telescope_enable_disable_diagnostics()<cr>", {desc = "Toggle Diagnostics sources for buffer"})

-- GIT
require 'key-menu'.set('n', '<Space>g', {desc='Git'})
vim.keymap.set("n", "<leader>gs", "<cmd>Telescope git_status<CR>", {desc = "Browse git status"})
vim.keymap.set("n", "<leader>gB", "<cmd>Telescope git_branches<CR>", {desc=  "Browse git branches"})

function telescope_commits_mappings(prompt_bufnr, map)
  map('i', '<C-r>i', function(nr)
    commit = require("telescope.actions.state").get_selected_entry(prompt_bufnr).value
    vim.cmd(":term! git rebase -i " .. commit .. "~")
  end)
  return true
end
function telescope_branches_mappings(prompt_bufnr, map)
  local actions = require('telescope.actions')
  local action_state = require "telescope.actions.state"
  map('i', '<C-f>', function(nr)
    branch = require("telescope.actions.state").get_selected_entry(prompt_bufnr).value
    actions.close(prompt_bufnr)
    vim.cmd(":DiffviewOpen ..." .. branch)
  end)
  map('i', '<C-c>', function(nr) -- mnemonic Compare
    branch = require("telescope.actions.state").get_selected_entry(prompt_bufnr).value
    actions.close(prompt_bufnr)
    vim.cmd(":DiffviewOpen " .. branch)
  end)
  map('i', '<C-d>', function(nr)
    local current_picker = action_state.get_current_picker(prompt_bufnr)
    current_picker:delete_selection(function(selection)
      branch = require("telescope.actions.state").get_selected_entry(selection.bufnr).value
      local Job = require'plenary.job'
      Job:new({
        command = 'git',
        args = { 'branch', '-D', branch },
        on_exit = function(j, return_val)
          -- prints the sha of the tip of the deleted branch, useful for a manual undo
          print(vim.inspect(j:result()))
        end,
      }):sync()
    end)
  end)
  return true
end
-- vim.keymap.set("n", "<leader>gc", "<cmd>lua require'telescope.builtin'.git_commits{attach_mappings=telescope_commits_mappings}<CR>", {desc ="Browse git commits"})
vim.keymap.set("n", "<leader>gc", "<cmd>lua require'telescope.builtin'.git_commits{attach_mappings=telescope_commits_mappings, git_command={\"git\", \"log\", \"--pretty=tformat:%<(10)%h%<(16,trunc)%an %ad%d %s\", \"--date=short\", \"--\", \".\"}, layout_config={width=0.9, horizontal={preview_width=0.5}}}<CR>", {desc ="Browse git commits"})
vim.keymap.set("n", "<leader>gt", "<cmd>lua require'agitator'.git_time_machine()<cr>", {desc = "Time machine"})
vim.keymap.set("n", "<leader>gB", "<cmd>lua require'agitator'.git_blame_toggle()<cr>", {desc="Git blame"})
vim.keymap.set("n", "<leader>gf", "<cmd>lua require'agitator'.open_file_git_branch()<cr>", {desc="Open file from branch"})
vim.keymap.set("n", "<leader>gp", "<cmd>lua require'agitator'.search_git_branch()<cr>", {desc="Search in another branch"})
vim.keymap.set("n", "<leader>gL", "<cmd>lua vim.cmd('DiffviewFileHistory ' .. cur_file_project_root())<cr>", {desc="project_history"})
vim.keymap.set("n", "<leader>gT", "<cmd>:DiffviewFileHistory %<cr>", {desc="file_history"})
vim.keymap.set("n", "<leader>gg", "<cmd>Neogit<cr>", {desc="neogit"})
vim.keymap.set("n", "<leader>gG", "<cmd>DiffviewOpen<cr>", {desc="Git two-way diff"})
vim.keymap.set("n", "<leader>gm", ":MergetoolToggle<cr>", {desc="toggle_gitmerge"})
vim.keymap.set("n", "<leader>gv", ":lua ShowCommitAtLine()<cr>", {desc="View commit for line"})
vim.keymap.set("n", "<leader>gY", ":lua copy_file_line()<cr>", {desc="Copy line and line number"})
vim.keymap.set("v", "<leader>gY", ":lua copy_file_line_sel()<cr>", {desc="Copy line and line number (sel)"})
vim.keymap.set("n", "<leader>gR", '<cmd>lua require"gitsigns".reset_buffer()<CR>', {desc="reset buffer"})
vim.keymap.set("n", "<leader>gb", '<cmd>lua require"gitsigns".blame_line()<CR>', {desc="blame line"})
vim.keymap.set("n", "<leader>gr", '<cmd>lua require"telescope.builtin".git_branches{attach_mappings=telescope_branches_mappings}<CR>', {desc="git bRanches"})

require 'key-menu'.set('n', '<Space>h', {desc='Hunks'})
vim.keymap.set("n", "<leader>hS", '<cmd>lua require"gitsigns".stage_hunk()<CR>', {desc= "stage hunk"})
vim.keymap.set("n", "<leader>hu", '<cmd>lua require"gitsigns".undo_stage_hunk()<CR>', {desc="undo stage hunk"})
vim.keymap.set("n", "<leader>hr", '<cmd>lua require"gitsigns".reset_hunk()<CR>', {desc="reset hunk"})
vim.keymap.set("n", "<leader>hh", '<cmd>lua require"gitsigns".preview_hunk()<CR>', {desc="preview hunk"})

-- CODE
require 'key-menu'.set('n', '<Space>c', {desc='Code'})

function format_buf()
  if #vim.lsp.buf_get_clients() > 0 then
    vim.lsp.buf.formatting_sync()
  elseif vim.bo.filetype == 'json' then
    -- i think this happens if the file is unsaved
    vim.cmd(':%!prettier --parser json')
  else
    print("No LSP and unhandled filetype " .. vim.bo.filetype)
  end
end
vim.keymap.set("n", "<leader>cf", ":lua format_buf()<cr>", {desc="Code format"})
vim.keymap.set("n", "<leader>cm", ":Glow<cr>", {desc="Markdown preview"})
require 'key-menu'.set('n', '<Space>cn', {desc='Code Nodes'})
vim.keymap.set('n', '<leader>cns', ":lua require('tsht').nodes()<cr>", {desc="select custom block"})
vim.keymap.set('n', '<leader>cnj', ":lua require('tsht').jump_nodes()<cr>", {desc="jump to code node"})

-- TESTS
require 'key-menu'.set('n', '<Space>ct', {desc='Tests'})
vim.keymap.set("n", "<leader>ctf", ":TestFile -strategy=dispatch<cr>", {desc="test file"})
vim.keymap.set("n", "<leader>ctn", ":TestNearest -strategy=dispatch<cr>", {desc="test nearest"})
vim.keymap.set("n", "<leader>ctl", ":TestLast -strategy=dispatch<cr>", {desc="test last"})
vim.keymap.set("n", "<leader>cta", ":TestSuite -strategy=dispatch<cr>", {desc="test all"})
vim.keymap.set("n", "<leader>ctp", "<cmd>lua test_output_in_popup()<cr>", {desc="test output in popup"})
vim.keymap.set("n", "<leader>cto", "<cmd>lua test_output_open()<cr>", {desc="open test output"})

-- QUICKFIX
require 'key-menu'.set('n', '<Space>cq', {desc='Quickfix'})
vim.keymap.set("n", "<leader>cqs", ":lua select_current_qf(false)<cr>", {desc="quickfix select current"})
vim.keymap.set("n", "<leader>cqv", ":lua select_current_qf(true)<cr>", {desc="quickfix view & select current"})
vim.keymap.set("n", "<leader>cqb", ":cbottom<cr>", {desc="quickfix go to bottom"})

vim.cmd[[set errorformat^=ERROR\ in\ %f:%l:%c]] -- needed for tsc, typescript
vim.keymap.set("n", "<leader>cqc", ":cexpr @+<cr>", {desc="Quickfix from clipboard"})

-- LSP
require 'key-menu'.set('n', '<Space>cl', {desc='LSP'})
vim.keymap.set("n", "<leader>cla", "<cmd>lua vim.lsp.buf.code_action()<CR>", {desc="Code actions"})
vim.keymap.set("n", "<leader>cll", '<cmd>lua vim.diagnostic.open_float(0, {scope="line"})<CR>', {desc="Show line diagnostics"})
vim.keymap.set("n", "<leader>clr", "<cmd>lua vim.lsp.buf.rename()<CR>", {desc="Rename the reference under cursor"})
vim.keymap.set("n", "<leader>clf", "<cmd>lua require'telescope.builtin'.lsp_references{path_display={'tail'}}<cr>", {desc="Display lsp references"})
-- possible alternative from ":h lsp-faq":
-- :lua vim.lsp.stop_client(vim.lsp.get_active_clients())
-- :edit
vim.keymap.set("n", "<leader>clR", "<cmd>:LspRestart<CR>", {desc="Restart LSP clients for this buffer"})

-- MARKS
require 'key-menu'.set('n', '<Space>m', {desc='Marks'})
vim.keymap.set("n", "<leader>ma", ":lua add_global_mark()<cr>", {desc="Add mark"})

-- VIM
require 'key-menu'.set('n', '<Space>v', {desc='Vim'})
vim.keymap.set("n", "<leader>vc", ":let @+=@:<cr>", {desc="Yank last ex command text"})
vim.keymap.set("n", "<leader>vm", [[:let @+=substitute(execute('messages'), '\n\+', '\n', 'g')<cr>]], {desc="Yank vim messages output"})

-- vim: ts=2 sts=2 sw=2 et
