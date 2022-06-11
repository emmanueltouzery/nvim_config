vim.keymap.set('n', 'gd', vim.lsp.buf.definition, {desc = "Jump to definition"})

require 'key-menu'.set('n', 'đ')
require 'key-menu'.set('n', 'š')
vim.keymap.set('n', 'šq', '<Cmd>:cp<CR>', {desc="Next quickfix"})
vim.keymap.set('n', 'đq', '<Cmd>:cn<CR>', {desc="Previous quickfix"})
vim.keymap.set('n', 'šh', '<Cmd>lua require("gitsigns").prev_hunk()<CR>', {desc="Next git hunk"})
vim.keymap.set('n', 'đh', '<Cmd>lua require("gitsigns").next_hunk()<CR>', {desc="Previous git hunk"})
vim.keymap.set('n', 'šd', '[c', {desc="Previous diff hunk"}) -- :h jumpto-diffs diffs+diffview.nvim
vim.keymap.set('n', 'đd', ']c', {desc="Next diff hunk"})
vim.keymap.set('n', 'šg', '<Cmd>lua vim.diagnostic.goto_prev()<CR>', {desc="Previous diagnostic"})
vim.keymap.set('n', 'đg', '<Cmd>lua vim.diagnostic.goto_next()<CR>', {desc="Next diagnostic"})
vim.keymap.set('n', 'đs', ']S', {desc="Next misspelled word"})
vim.keymap.set('n', 'šs', '[S', {desc="Previous misspelled word"})
vim.keymap.set('n', 'đq', '<cmd>lua next_quickfix()<cr>', {desc="Next quickfix location"})
vim.keymap.set('n', 'šq', '<cmd>lua previous_quickfix()<cr>', {desc="Previous quickfix location"})

vim.keymap.set('n', '-', '<Cmd>ChooseWin<CR>', {desc="Choose win"})
vim.keymap.set( "n", "K", ":lua vim.lsp.buf.hover()<CR>", {desc="Display type under cursor"})
vim.keymap.set( "n", "<C-p>", ":lua vim.diagnostic.goto_prev()<CR>", {desc="Jump to previous diagnostic"})
vim.keymap.set( "n", "<C-n>", ":lua vim.diagnostic.goto_next()<CR>", {desc="Jump to next diagnostic"})

-- https://github.com/b3nj5m1n/kommentary/issues/11
vim.api.nvim_set_keymap('n', 'gCC', '<cmd>lua toggle_comment_custom_commentstring_curline()<cr>', { noremap = true, silent = true })
vim.api.nvim_set_keymap('v', 'gC', ':<C-u>lua toggle_comment_custom_commentstring_sel()<cr>', { noremap = true, silent = true })

-- resizing splits
vim.keymap.set("n", "<C-Up>", ":resize +2<CR>", {desc="Resize window (increase width)"})
vim.keymap.set("n", "<C-Down>", ":resize -2<CR>", {desc="Resize window (decrease width)"})
vim.keymap.set("n", "<C-Left>", ":vertical resize -2<CR>", {desc="Resize window (decrease height)"})
vim.keymap.set("n", "<C-Right>", ":vertical resize +2<CR>", {desc="Resize window (increase height)"})

-- https://vi.stackexchange.com/a/27803/38754
-- the default 'gx' to open links doesn't work.
-- there are plugins..  https://github.com/felipec/vim-sanegx
-- https://github.com/tyru/open-browser.vim
-- https://gist.github.com/habamax/0a6c1d2013ea68adcf2a52024468752e
-- but this seems KISS and functional
vim.cmd('nmap gx :silent execute "!xdg-open " . shellescape("<cWORD>")<CR>')
-- https://stackoverflow.com/questions/1533565/how-to-get-visually-selected-text-in-vimscript#comment10417791_1533565
vim.cmd('vmap gx <Esc>:silent execute "!xdg-open " . shellescape(getline("\'<")[getpos("\'<")[2]-1:getpos(".")[2]]) . " &"<CR>')

-- customization for https://github.com/samoshkin/vim-mergetool
vim.cmd("nmap <expr> db &diff? ':lua diffget_and_keep_before()<cr>' : 'db'")
vim.cmd("nmap <expr> da &diff? ':lua diffget_and_keep_after()<cr>' : 'da'")

--Remap for dealing with word wrap
vim.keymap.set('n', 'k', "v:count == 0 ? 'gk' : 'k'", { expr = true, silent = true })
vim.keymap.set('n', 'j', "v:count == 0 ? 'gj' : 'j'", { expr = true, silent = true })

-- https://vim.fandom.com/wiki/Map_Ctrl-Backspace_to_delete_previous_word
vim.cmd('inoremap <C-h> <C-\\><C-o>db')
vim.cmd('inoremap <C-BS> <C-\\><C-o>db')

-- way better spell checker than the builtin z=
vim.keymap.set("n", "z=", ":lua require'telescope.builtin'.spell_suggest{}<cr>")
