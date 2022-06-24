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
-- if that doesn't cut it, consider https://github.com/qpkorr/vim-bufkill
-- and check https://www.reddit.com/r/vim/comments/m6jl0b/i_made_a_plugin_a_replacement_for_bdelete_that/
--":b#<bar>bd#<CR>",
vim.keymap.set("n", "<leader>bd",  ":BD<cr>", {desc="Delete buffer"})
vim.keymap.set("n", "<leader>bD",  ":bd!<cr>", {desc="Force delete buffer"})

function open_buf_in_window(jump_to_target)
  local target_win_idx = vim.api.nvim_eval("choosewin#start(range(1, winnr('$')), { 'noop': 1 })[1]")
  local target_winnr = vim.api.nvim_list_wins()[target_win_idx]
  vim.api.nvim_win_set_buf(target_winnr, vim.api.nvim_win_get_buf(0))
  if jump_to_target then
    vim.cmd(target_win_idx .. ' wincmd w')
  end
end
vim.keymap.set("n", "<leader>bw",  "<cmd>lua open_buf_in_window(true)<cr>", {desc="Open cur. buffer in window+go there"})
vim.keymap.set("n", "<leader>bW",  "<cmd>lua open_buf_in_window(false)<cr>", {desc="Open cur. buffer in window"})

require 'key-menu'.set('n', '<Space>')

-- FILES
require 'key-menu'.set('n', '<Space>f', {desc='File'})
vim.keymap.set('n', '<leader>fn', "<cmd>vert new<cr>", {desc = "New file"})
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
vim.keymap.set("n", "<leader>ss", "<cmd>Telescope lsp_document_symbols<cr>", { desc = "Goto LSP symbol"})
vim.keymap.set("n", "<leader>*", "<cmd>lua my_open_tele()<cr>", {desc="Search word under cursor, raw"})
vim.keymap.set("n", "<leader>sr", "<cmd>lua require('telescope').extensions.live_grep_raw.live_grep_raw()<cr>", {desc="Search text raw"})
vim.keymap.set( "n", "<leader>sS", "<cmd>Telescope lsp_workspace_symbols<CR>", {desc="Goto workspace symbol"})
function ws_symbol_under_cursor()
  local word = vim.fn.expand('<cword>')
  require'telescope.builtin'.lsp_workspace_symbols {query=word}
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
vim.keymap.set("n", "<leader>om", "<cmd>lua telescope_global_marks{}<CR>", {desc="Open global marks"})
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
vim.keymap.set("n", "<leader>tQ", ":TroubleToggle quickfix<cr>", {desc = "Toggle Trouble quickfix"})
vim.keymap.set("n", "<leader>th", ":set invhlsearch<cr>", {desc="Toggle highlight"})
vim.keymap.set("n", "<leader>td", ":tabc<cr>", {desc="Delete tab"}) -- that one doesn't fit under toggle.. it's TAB delete. but keeping it here for now.

-- GIT
require 'key-menu'.set('n', '<Space>g', {desc='Git'})
vim.keymap.set("n", "<leader>gs", "<cmd>Telescope git_status<CR>", {desc = "Browse git status"})
vim.keymap.set("n", "<leader>gB", "<cmd>Telescope git_branches<CR>", {desc=  "Browse git branches"})

function telescope_commits_mappings(prompt_bufnr, map)
  map('i', '<C-r>i', function(nr)
    commit=require("telescope.actions.state").get_selected_entry(prompt_bufnr).value
    vim.cmd(":term! git rebase -i " .. commit)
  end)
  return true
end
vim.keymap.set("n", "<leader>gc", "<cmd>lua require'telescope.builtin'.git_commits{attach_mappings=telescope_commits_mappings}<CR>", {desc ="Browse git commits"})
vim.keymap.set("n", "<leader>gt", "<cmd>lua require'agitator'.git_time_machine()<cr>", {desc = "Time machine"})
vim.keymap.set("n", "<leader>gB", "<cmd>lua require'agitator'.git_blame_toggle()<cr>", {desc="Git blame"})
vim.keymap.set("n", "<leader>gf", "<cmd>lua require'agitator'.open_file_git_branch()<cr>", {desc="Open file from branch"})
vim.keymap.set("n", "<leader>gd", "<cmd>lua require'diffview'.open()<cr>", {desc="diffview"})
vim.keymap.set("n", "<leader>gL", "<cmd>lua require'diffview'.file_history(cur_file_project_root())<cr>", {desc="project_history"})
vim.keymap.set("n", "<leader>gT", "<cmd>:DiffviewFileHistory %<cr>", {desc="file_history"})
vim.keymap.set("n", "<leader>gg", "<cmd>Neogit<cr>", {desc="neogit"})
vim.keymap.set("n", "<leader>gG", ":lua require('diffview').open()<cr>", {desc="Git two-way diff"})
vim.keymap.set("n", "<leader>gm", ":MergetoolToggle<cr>", {desc="toggle_gitmerge"})
vim.keymap.set("n", "<leader>gv", ":lua ShowCommitAtLine()<cr>", {desc="View commit"})
vim.keymap.set("n", "<leader>gY", ":lua copy_file_line()<cr>", {desc="Copy line and line number"})
vim.keymap.set("v", "<leader>gY", ":lua copy_file_line_sel()<cr>", {desc="Copy line and line number (sel)"})
vim.keymap.set("n", "<leader>gR", '<cmd>lua require"gitsigns".reset_buffer()<CR>', {desc="reset buffer"})
vim.keymap.set("n", "<leader>gb", '<cmd>lua require"gitsigns".blame_line()<CR>', {desc="blame line"})
vim.keymap.set("n", "<leader>gr", '<cmd>lua require"telescope.builtin".git_branches{}<CR>', {desc="git bRanches"})

require 'key-menu'.set('n', '<Space>h', {desc='Hunks'})
vim.keymap.set("n", "<leader>hS", '<cmd>lua require"gitsigns".stage_hunk()<CR>', {desc= "stage hunk"})
vim.keymap.set("n", "<leader>hu", '<cmd>lua require"gitsigns".undo_stage_hunk()<CR>', {desc="undo stage hunk"})
vim.keymap.set("n", "<leader>hr", '<cmd>lua require"gitsigns".reset_hunk()<CR>', {desc="reset hunk"})
vim.keymap.set("n", "<leader>hh", '<cmd>lua require"gitsigns".preview_hunk()<CR>', {desc="preview hunk"})

-- CODE
require 'key-menu'.set('n', '<Space>c', {desc='Code'})
vim.keymap.set("n", "<leader>cf", ":lua vim.lsp.buf.formatting_sync()<cr>", {desc="Code format"})
vim.keymap.set("n", "<leader>cm", ":Glow<cr>", {desc="Markdown preview"})
vim.keymap.set("n", "<leader>cw", ":set wrap! linebreak<cr>", {desc="toggle_linebreak"})

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

-- LSP
require 'key-menu'.set('n', '<Space>cl', {desc='LSP'})
vim.keymap.set("n", "<leader>cla", "<cmd>lua vim.lsp.buf.code_action()<CR>", {desc="Code actions"})
vim.keymap.set("n", "<leader>cll", '<cmd>lua vim.diagnostic.open_float(0, {scope="line"})<CR>', {desc="Show line diagnostics"})
vim.keymap.set("n", "<leader>clr", "<cmd>lua vim.lsp.buf.rename()<CR>", {desc="Rename the reference under cursor"})
vim.keymap.set("n", "<leader>clf", ":Trouble lsp_references<cr>", {desc="Display lsp references"})
vim.keymap.set("n", "<leader>clF", ":TroubleClose<cr>", {desc="Close lsp references"})
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
