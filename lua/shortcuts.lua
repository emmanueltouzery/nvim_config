-- vim.keymap.set('n', 'gd', vim.lsp.buf.definition, {desc = "Jump to definition"})
vim.keymap.set('n', 'gd', "<cmd>lua lsp_goto_def_center()<cr>", {desc = "Jump to definition"})
vim.keymap.set("n", "gr", function()
  local params = {
    attach_mappings = lsp_refs_extra_mappings,
    entry_maker = my_gen_from_quickfix({
        path_display=function(opts, transformed_path)
          -- compared to the basic strategy, also display icons
          p = require'telescope.utils'.path_tail(transformed_path)
          return require'telescope.utils'.transform_devicons(transformed_path ,p)
        end
      }),
  }
  if vim.bo.filetype == "typescript" or vim.bo.filetype == "typescriptreact" then
    -- for typescript, filter out import statements
    local Path = require("plenary.path")
    params.post_process_results = function(list)
      return vim.tbl_filter(function(match)
        local file = match.uri:gsub("file://", "")
        local lnum = match.range.start.line
        if lnum+1 == vim.fn.line('.') and file == vim.fn.expand('%:p') then
          -- drop the declaration i'm asking the references from...
          -- not sure why typescript is listing the declaration in the references...
          return false
        end
        local path = Path.new(file)
        local contents = path:read()
        local it = contents:gmatch("([^\n]*)\n?")
        local line = ""
        for _i = 0,lnum,1 do
          line = it()
        end
        return not line:match("^%s*import ")
      end, list)
    end
  elseif vim.bo.filetype == "rust" then
    params.post_process_results = function(list)
      return vim.tbl_filter(function(match)
        local file = match.uri:gsub("file://", "")
        local lnum = match.range.start.line
        if lnum+1 == vim.fn.line('.') and file == vim.fn.expand('%:p') then
          -- drop the declaration i'm asking the references from...
          -- not sure why the LSP is listing the declaration in the references...
          return false
        end
        return true
      end, list)
    end
  end
  require'telescope.builtin'.lsp_references(params)
end, {desc="Display lsp references"})

require 'key-menu'.set('n', 'đ')
require 'key-menu'.set('n', 'š')
vim.keymap.set('n', 'šQ', '<Cmd>:cn<CR>', {desc="Previous quickfix"})
vim.keymap.set('n', 'đQ', '<Cmd>:cp<CR>', {desc="Next quickfix"})
-- pcall for MiniDiff.goto_hunk because sometimes i hit the shortcuts in a non-minidiff managed window,
-- like a popup, and in that case it blows up.
vim.keymap.set('n', 'šh', function() pcall(MiniDiff.goto_hunk, "prev") end, {desc="Previous git hunk"})
vim.keymap.set('n', 'đh', function() pcall(MiniDiff.goto_hunk, "next") end, {desc="Next git hunk"})
vim.keymap.set('n', 'šd', '[c', {desc="Previous diff hunk"}) -- :h jumpto-diffs diffs+diffview.nvim
vim.keymap.set('n', 'đd', ']c', {desc="Next diff hunk"})
vim.keymap.set('n', 'šg', '<Cmd>lua vim.diagnostic.goto_prev()<CR>', {desc="Previous diagnostic"})
vim.keymap.set('n', 'đg', '<Cmd>lua vim.diagnostic.goto_next()<CR>', {desc="Next diagnostic"})
vim.keymap.set('n', 'šs', '[S', {desc="Previous misspelled word"})
vim.keymap.set('n', 'đs', ']S', {desc="Next misspelled word"})
vim.keymap.set('n', 'šq', '<cmd>lua previous_quickfix()<cr>', {desc="Previous quickfix location"})
vim.keymap.set('n', 'đq', '<cmd>lua next_quickfix()<cr>', {desc="Next quickfix location"})
vim.keymap.set('n', 'š%', '<plug>(matchup-[%)', {desc="Previous % marker"})
vim.keymap.set('n', 'đ%', '<plug>(matchup-]%)', {desc="Next % marker"})
vim.keymap.set('n', 'šf', '<cmd>lua previous_closed_fold()<cr>', {desc="Previous closed fold"})
vim.keymap.set('n', 'đf', '<cmd>lua next_closed_fold()<cr>', {desc="Next closed fold"})
vim.keymap.set('n', 'ša', function()
  vim.cmd('AerialPrev')
  -- in the case of typescriptreact, we want to skip "Struct" items, they're JSX nodes
  if vim.bo.filetype == 'typescriptreact' then
    while true do
      local loc = require'aerial'.get_location()
      if loc and #loc > 0 then
        if loc[#loc].kind ~= 'Struct' then
          break
        end
      else
        break
      end
      vim.cmd('AerialPrev')
    end
  end
end, {desc="Previous aerial symbol"})
vim.keymap.set('n', 'đa', function()
  vim.cmd('AerialNext')
  -- in the case of typescriptreact, we want to skip "Struct" items, they're JSX nodes
  if vim.bo.filetype == 'typescriptreact' then
    while true do
      local loc = require'aerial'.get_location()
      if loc and #loc > 0 then
        if loc[#loc].kind ~= 'Struct' then
          break
        end
      else
        break
      end
      vim.cmd('AerialNext')
    end
  end
end, {desc="Next aerial symbol"})

vim.keymap.set('n', '-', '<Cmd>ChooseWin<CR>', {desc="Choose win"})
vim.keymap.set("n", "K", ":lua vim.lsp.buf.hover()<CR>", {desc="Display type under cursor"})
vim.keymap.set("n", "<C-p>", ":lua vim.diagnostic.goto_prev({severity=vim.diagnostic.severity.ERROR})<CR>", {desc="Jump to previous diagnostic"})
vim.keymap.set("n", "<C-n>", ":lua vim.diagnostic.goto_next({severity=vim.diagnostic.severity.ERROR})<CR>", {desc="Jump to next diagnostic"})

-- https://github.com/b3nj5m1n/kommentary/issues/11
vim.api.nvim_set_keymap('n', 'gCC', '<cmd>lua toggle_comment_custom_commentstring_curline()<cr>', { noremap = true, silent = true })
vim.api.nvim_set_keymap('n', 'gR', '<cmd>lua recomment_last_selection_custom_commentstring()<cr>', { noremap = true, silent = true })
vim.api.nvim_set_keymap('v', 'gC', ':<C-u>lua toggle_comment_custom_commentstring_sel()<cr>', { noremap = true, silent = true })

-- resizing splits
vim.keymap.set("n", "<C-Up>", ":resize +2<CR>", {desc="Resize window (increase width)"})
vim.keymap.set("n", "<C-Down>", ":resize -2<CR>", {desc="Resize window (decrease width)"})
vim.keymap.set("n", "<C-Left>", ":vertical resize -2<CR>", {desc="Resize window (decrease height)"})
vim.keymap.set("n", "<C-Right>", ":vertical resize +2<CR>", {desc="Resize window (increase height)"})

-- zoom in and out
if vim.g.neovide == true then
  vim.api.nvim_set_keymap("n", "<C-+>", ":lua vim.g.neovide_scale_factor = vim.g.neovide_scale_factor * 1.1<CR>", { silent = true })
  vim.api.nvim_set_keymap("n", "<C-->", ":lua vim.g.neovide_scale_factor = vim.g.neovide_scale_factor * 0.9<CR>", { silent = true })
  vim.api.nvim_set_keymap("n", "<C-0>", ":lua vim.g.neovide_scale_factor = 1<CR>", { silent = true })
end

-- https://vi.stackexchange.com/a/27803/38754
-- the default 'gx' to open links doesn't work.
-- there are plugins..  https://github.com/felipec/vim-sanegx
-- https://github.com/tyru/open-browser.vim
-- https://gist.github.com/habamax/0a6c1d2013ea68adcf2a52024468752e
-- but this seems KISS and functional
vim.cmd('nmap gx :silent execute "!xdg-open " . shellescape("<cWORD>") . " &"<CR>')
-- https://stackoverflow.com/questions/1533565/how-to-get-visually-selected-text-in-vimscript#comment10417791_1533565
vim.cmd('vmap gx <Esc>:silent execute "!xdg-open " . shellescape(getline("\'<")[getpos("\'<")[2]-1:getpos(".")[2]]) . " &"<CR>')

-- customization for https://github.com/samoshkin/vim-mergetool
vim.cmd("nmap <expr> db &diff? ':lua diffget_and_keep_before()<cr>' : 'db'")
vim.cmd("nmap <expr> da &diff? ':lua diffget_and_keep_after()<cr>' : 'da'")

--Remap for dealing with word wrap
-- vim.keymap.set('n', 'k', "v:count == 0 ? 'gk' : 'k'", { expr = true, silent = true })
-- vim.keymap.set('n', 'j', "v:count == 0 ? 'gj' : 'j'", { expr = true, silent = true })

-- combine dealing with word wrap AND adding the current pos to the jump stack
-- in case of jk with count
-- https://vi.stackexchange.com/a/9103/38754
vim.cmd([[
nnoremap <silent> k :<C-U>execute 'normal!' (v:count > 1 ? "m'" . v:count : '') . (v:count == 0 ? 'gk' : 'k')<CR>
nnoremap <silent> j :<C-U>execute 'normal!' (v:count > 1 ? "m'" . v:count : '') . (v:count == 0 ? 'gj' : 'j')<CR>
]])

-- move by line, useful when we have word-wrapping
vim.cmd([[
nnoremap <Down> gj
nnoremap <Up> gk
vnoremap <Down> gj
vnoremap <Up> gk
]])

-- https://vim.fandom.com/wiki/Map_Ctrl-Backspace_to_delete_previous_word
vim.cmd('inoremap <C-h> <C-\\><C-o>db')
vim.cmd('inoremap <C-BS> <C-\\><C-o>db')

-- way better spell checker than the builtin z=
vim.keymap.set("n", "z=", ":lua require'telescope.builtin'.spell_suggest{}<cr>")
