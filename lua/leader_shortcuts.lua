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

require 'key-menu'.set('n', '<Space>')

-- FILES
require 'key-menu'.set('n', '<Space>f', {desc='File'})
vim.keymap.set('n', '<leader>fn', "<cmd>vert new<cr>", {desc = "New file"})
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

-- WINDOW
require 'key-menu'.set('n', '<Space>w', {desc='Window'})
vim.keymap.set("n", "<leader>wd", "<C-W>c", {desc="Close current window"})
vim.keymap.set("n", "<leader>w=", "<C-W>=", {desc = "Balance window"})
vim.keymap.set("n", "<leader>ws", "<C-W>s", {desc = "Split window below"})
vim.keymap.set("n", "<leader>wv", "<C-W>v", {desc = "Split window right"})
vim.keymap.set("n", "<leader>wr", "<C-w>r", {desc="Window rotate"})
vim.keymap.set("n", "<leader>wm", "<C-w>o", {desc="Window maximize"})

-- OPEN
require 'key-menu'.set('n', '<Space>o', {desc='Open'})
vim.keymap.set("n", "<leader>op", "<cmd>lua require'telescope'.extensions.project.project{ display_type = 'full' }<CR>", {desc="Open project"})
vim.keymap.set("n", "<leader>oc", ":lua goto_fileline()<cr>", {desc="Open code (file+line)"})

-- TOGGLE
require 'key-menu'.set('n', '<Space>t', {desc='Toggle'})
vim.keymap.set("n", "<leader>te", "<cmd>NvimTreeToggle<CR>", {desc = "Toggle file explorer"})
vim.keymap.set("n", "<leader>ts", "<cmd>SymbolsOutline<CR>", {desc = "Toggle SymbolsOutline (LSP symbols)"})
vim.keymap.set("n", "<leader>tt", "<cmd>ToggleTerm<CR>", {desc = "Toggle terminal"})

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

-- GIT
require 'key-menu'.set('n', '<Space>g', {desc='Git'})
vim.keymap.set("n", "<leader>gs", "<cmd>Telescope git_status<CR>", {desc = "Browse git status"})
vim.keymap.set("n", "<leader>gB", "<cmd>Telescope git_branches<CR>", {desc=  "Browse git branches"})
vim.keymap.set("n", "<leader>gc", "<cmd>Telescope git_commits<CR>", {desc ="Browse git commits"})
vim.keymap.set("n", "<leader>gt", "<cmd>lua require'agitator'.git_time_machine()<cr>", {desc = "Open project"})
vim.keymap.set("n", "<leader>gB", "<cmd>lua require'agitator'.git_blame_toggle()<cr>", {desc="Open project"})
vim.keymap.set("n", "<leader>gf", "<cmd>lua require'agitator'.open_file_git_branch()<cr>", {desc="open_file_git_branch"})
vim.keymap.set("n", "<leader>gd", "<cmd>lua require'diffview'.open()<cr>", {desc="diffview"})
vim.keymap.set("n", "<leader>gL", "<cmd>lua require'diffview'.file_history(cur_file_project_root())<cr>", {desc="project_history"})
vim.keymap.set("n", "<leader>gT", "<cmd>lua require'diffview'.file_history()<cr>", {desc="file_history"})
vim.keymap.set("n", "<leader>gg", "<cmd>Neogit<cr>", {desc="neogit"})
vim.keymap.set("n", "<leader>gG", ":lua require('diffview').open()<cr>", {desc="Git two-way diff"})
vim.keymap.set("n", "<leader>gm", ":MergetoolToggle<cr>", {desc="toggle_gitmerge"})
vim.keymap.set("n", "<leader>gv", ":lua ShowCommitAtLine()<cr>", {desc="view_commit"})
vim.keymap.set("n", "<leader>gY", ":lua copy_file_line()<cr>", {desc="Copy line and line number"})
vim.keymap.set("v", "<leader>gY", ":lua copy_file_line_sel()<cr>", {desc="Copy line and line number (sel)"})
vim.keymap.set("n", "<leader>gS", '<cmd>lua require"gitsigns".stage_hunk()<CR>', {desc= "stage hunk"})
vim.keymap.set("n", "<leader>gu", '<cmd>lua require"gitsigns".undo_stage_hunk()<CR>', {desc="undo stage hunk"})
vim.keymap.set("n", "<leader>gr", '<cmd>lua require"gitsigns".reset_hunk()<CR>', {desc="reset hunk"})
vim.keymap.set("n", "<leader>gR", '<cmd>lua require"gitsigns".reset_buffer()<CR>', {desc="reset buffer"})
vim.keymap.set("n", "<leader>gh", '<cmd>lua require"gitsigns".preview_hunk()<CR>', {desc="preview hunk"})
vim.keymap.set("n", "<leader>gb", '<cmd>lua require"gitsigns".blame_line()<CR>', {desc="blame link"})

-- CODE
require 'key-menu'.set('n', '<Space>c', {desc='Code'})
vim.keymap.set("n", "<leader>cf", ":lua vim.lsp.buf.formatting_sync()<cr>", {desc="Code format"})
vim.keymap.set("n", "<leader>cm", ":Glow<cr>", {desc="Markdown preview"})
vim.keymap.set("n", "<leader>cw", ":set wrap! linebreak<cr>", {desc="toggle_linebreak"})

require 'key-menu'.set('n', '<Space>ct', {desc='Tests'})
vim.keymap.set("n", "<leader>ctf", ":TestFile -strategy=dispatch<cr>", {desc="test file"})
vim.keymap.set("n", "<leader>ctn", ":TestNearest -strategy=dispatch<cr>", {desc="test nearest"})
vim.keymap.set("n", "<leader>ctl", ":TestLast -strategy=dispatch<cr>", {desc="test last"})
vim.keymap.set("n", "<leader>cta", ":TestSuite -strategy=dispatch<cr>", {desc="test all"})

require 'key-menu'.set('n', '<Space>cq', {desc='Quickfix'})
vim.keymap.set("n", "<leader>cqs", ":lua select_current_qf(false)<cr>", {desc="quickfix select current"})
vim.keymap.set("n", "<leader>cqv", ":lua select_current_qf(true)<cr>", {desc="quickfix view & select current"})

require 'key-menu'.set('n', '<Space>cl', {desc='LSP'})
vim.keymap.set("n", "<leader>cla", "<cmd>lua vim.lsp.buf.code_action()<CR>", {desc="Code actions"})
vim.keymap.set("n", "<leader>cll", '<cmd>lua vim.diagnostic.open_float(0, {scope="line"})<CR>', {desc="Show line diagnostics"})
vim.keymap.set("n", "<leader>clr", "<cmd>lua vim.lsp.buf.rename()<CR>", {desc="Rename the reference under cursor"})
vim.keymap.set("n", "<leader>clf", ":TroubleToggle lsp_references<cr>", {desc="Toggle lsp references"})
