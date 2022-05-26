vim.keymap.set('n', 'gd', vim.lsp.buf.definition, {desc = "Jump to definition"})
vim.keymap.set('n', 'čp', '<Cmd>:cp<CR>', {desc="Next quickfix"})
vim.keymap.set('n', 'čn', '<Cmd>:cn<CR>', {desc="Previous quickfix"})
vim.keymap.set('n', 'ćp', '<Cmd>lua require("gitsigns").prev_hunk()<CR>', {desc="Next git hunk"})
vim.keymap.set('n', 'ćn', '<Cmd>lua require("gitsigns").next_hunk()<CR>', {desc="Previous git hunk"})
vim.keymap.set('n', 'žp', '[c', {desc="Previous diff hunk"}) -- :h jumpto-diffs diffs+diffview.nvim
vim.keymap.set('n', 'žn', ']c', {desc="Next diff hunk"})
vim.keymap.set('n', 'šp', '<Cmd>lua vim.diagnostic.goto_prev()<CR>', {desc="Previous diagnostic"})
vim.keymap.set('n', 'šn', '<Cmd>lua vim.diagnostic.goto_next()<CR>', {desc="Next diagnostic"})
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
vim.keymap.set("n", "<C-Right>", ":vertical resize -2<CR>", {desc="Resize window (decrease height)"})
vim.keymap.set("n", "<C-Left>", ":vertical resize +2<CR>", {desc="Resize window (increase height)"})

-- https://vi.stackexchange.com/a/27803/38754
-- the default 'gx' to open links doesn't work.
-- there are plugins..  https://github.com/felipec/vim-sanegx
-- https://github.com/tyru/open-browser.vim
-- https://gist.github.com/habamax/0a6c1d2013ea68adcf2a52024468752e
-- but this seems KISS and functional
vim.cmd('nmap gx :silent execute "!xdg-open " . shellescape("<cWORD>")<CR>')
-- https://stackoverflow.com/questions/1533565/how-to-get-visually-selected-text-in-vimscript#comment10417791_1533565
vim.cmd('vmap gx <Esc>:silent execute "!xdg-open " . shellescape(getline("\'<")[getpos("\'<")[2]-1:getpos(".")[2]]) . " &"<CR>')
