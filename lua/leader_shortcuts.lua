--Remap space as leader key
vim.keymap.set({ 'n', 'v' }, '<Space>', '<Nop>', { silent = true })
vim.g.mapleader = ' '
vim.g.maplocalleader = ','

vim.keymap.set( "n", "<leader>.", "<cmd>Telescope file_browser hidden=true<CR>", {desc="Telescope files"})
vim.keymap.set( "n", "<leader>,", "<cmd>Telescope buffers show_all_buffers=true<CR>", {desc="Telescope buffers"})
vim.keymap.set("n", "<leader>?", ":Cheat40<cr>", {desc="help"})
vim.keymap.set("n", "<leader>q", "<cmd>lua jump_to_qf()<cr>", {desc="Jump to the quickfix window"})
vim.keymap.set( "n", "<leader>;", "<cmd>Telescope resume<CR>", {desc="Resume telescope search"})

-- BUFFER
require 'key-menu'.set('n', '<Space>b', {desc='Buffer'})
-- https://stackoverflow.com/a/19619038/516188
--":b#<bar>bd#<CR>",
-- that didn't cut it => https://github.com/qpkorr/vim-bufkill
-- further options: https://www.reddit.com/r/vim/comments/m6jl0b/i_made_a_plugin_a_replacement_for_bdelete_that/
-- and also https://github.com/mhinz/vim-sayonara
vim.keymap.set("n", "<leader>bd",  ":BD<cr>", {desc="Delete buffer"})
vim.keymap.set("n", "<leader>bD",  ":BD!<cr>", {desc="Force delete buffer"})
vim.keymap.set("n", "<leader>bF",  function()
    if vim.b.disable_autoformat == true then
      vim.b.disable_autoformat = false
      notif({"Autoformat enabled for buffer"})
    else
      vim.b.disable_autoformat = true
      notif({"Autoformat disabled for buffer"})
    end
  end, {desc="Toggle autoformat for buffer"})

function open_buf_in_window(jump_to_target)
  local line = vim.fn.line('.')
  local cur_buf = vim.api.nvim_win_get_buf(0)
  local target_win_idx = vim.api.nvim_eval("choosewin#start(range(1, winnr('$')), { 'noop': 1 })[1]")
  local target_winnr = vim.api.nvim_list_wins()[target_win_idx]
  vim.api.nvim_win_set_buf(target_winnr, cur_buf)
  if jump_to_target then
    vim.cmd(target_win_idx .. ' wincmd w')
    vim.cmd(':' .. line)
    vim.cmd("norm! zz") -- center on screen
  end
end
vim.keymap.set("n", "<leader>bw",  "<cmd>lua open_buf_in_window(true)<cr>", {desc="Open cur. buffer in window+go there"})
vim.keymap.set("n", "<leader>bW",  "<cmd>lua open_buf_in_window(false)<cr>", {desc="Open cur. buffer in window"})
vim.keymap.set("n", "<leader>bo", "<cmd>lua close_nonvisible_buffers()<cr>", {desc="Close all buffers but the visible ones"})
vim.keymap.set("n", "<leader>bR", "<cmd>lua reopen_buffer()<cr>", {desc="Reopen the current buffer. Can be useful to reset LSP and similar"})

require 'key-menu'.set('n', '<Space>')
require 'key-menu'.set('n', ',')

-- FILES
require 'key-menu'.set('n', '<Space>f', {desc='File'})
vim.keymap.set('n', '<leader>fn', ":enew<cr>", {desc = "New file"})
vim.keymap.set("n", "<leader>fs", ":w<cr>", {desc="Save file"})
vim.keymap.set("n", "<leader>fS", ":wa<cr>", {desc="Save all files"})
vim.keymap.set("n", "<leader>ff", "<cmd>Telescope find_files hidden=true<cr>", {desc = "Find files"})
vim.keymap.set("n", "<leader>fr", "<cmd>lua telescope_recent_or_all()<cr>", { desc = "Recent files"})
vim.keymap.set("n", "<leader>fR", "<cmd>SudaRead<cr>", { desc = "Re-open file with sudo permissions"})
vim.keymap.set("n", "<leader>fw", "<cmd>SudaWrite<cr>", { desc = "Write file with sudo permissions"})
vim.keymap.set("n", "<leader>fp", ':lua copy_to_clipboard(cur_file_path_in_project())<cr>', {desc="Copy file path"}) -- ':let @+ = expand("%")<cr>',
vim.keymap.set("n", "<leader>fP", ':let @+ = expand("%:p")<cr>', {desc="Copy file full path"})
vim.keymap.set("n", "<leader>fW", ":noautocmd w<cr>", {desc="save without indenting/formatting the file"})
vim.keymap.set("n", "<leader>fD", ":lua convert_dos()<cr>", {desc="reload file as DOS"}) -- https://vim.fandom.com/wiki/File_format many typescript library files have windows line endings except for the copyright header
require 'key-menu'.set('n', '<Space>fd', {desc='file Directory'})
vim.keymap.set("n", "<leader>fdd", ":lua open_file_cur_dir(false)<cr>", {desc="open a file from the current Directory"})
vim.keymap.set("n", "<leader>fdc", ":lua open_file_cur_dir(true)<cr>", {desc="open a file from the current directory and Children dirs"})
vim.keymap.set('n', '<leader>f!', ":lua reload_all()<cr>", {desc = "Reload all files from disk"})

function _G.quick_set_ft()
  local filetypes = {"typescript", "json", "elixir", "rust", "lua", "diff", "sh", "markdown", "html", "config", "sql", "strace", "xml", "other"}
  vim.ui.select(filetypes, {prompt="Pick filetype to switch to"}, function(choice)
    if choice == "other" then
      vim.ui.input({prompt="Enter filetype", kind="center_win"}, function(word)
        if word ~= nil then
          vim.cmd("set ft=" .. word) 
        end
      end)
    elseif choice ~= nil then
      vim.cmd("set ft=" .. choice) 
    end 
  end)
end
vim.keymap.set("n", "<leader>ft", ":lua quick_set_ft()<cr>", {desc="Quickly change to common file types"})

function _G.quick_set_fm()
  local filetypes = {"syntax", "indent", "manual", "disable"}
  vim.ui.select(filetypes, {prompt="Pick fold method to switch to"}, function(choice)
    if choice ~= nil then
      set_fm(choice)
    end 
  end)
end

function _G.set_fm(choice)
  if choice == "disable" then
    vim.cmd("set nofoldenable")
  else
    if choice == "syntax" then
      vim.cmd("syntax on")
    end
    vim.cmd("setlocal foldmethod=" .. choice .. " | setlocal foldenable | set foldlevel=2")
  end
end

vim.keymap.set("n", "<leader>fM", ":lua quick_set_fm()<cr>", {desc="Quickly change folding method"})
vim.keymap.set("n", "<leader>fmi", ":lua set_fm('indent')<cr>", {desc="Set indent folding method"})
vim.keymap.set("n", "<leader>fms", ":lua set_fm('syntax')<cr>", {desc="Set syntax folding method"})
vim.keymap.set("n", "<leader>fmd", ":lua set_fm('disable')<cr>", {desc="Disable folding"})

-- SEARCH
require 'key-menu'.set('n', '<Space>s', {desc='Search'})
vim.keymap.set("n", "<leader>*", "<cmd>lua my_open_tele()<cr>", {desc="Search word under cursor, raw"})
vim.keymap.set("v", "<leader>*", "<cmd>lua my_open_tele_sel()<cr>", {desc="Search selected text, raw"})
vim.keymap.set("n", "<leader>sr", function() require('telescope').extensions.live_grep_args.live_grep_args(
  {entry_maker=my_gen_from_vimgrep({
    path_display=function(opts, transformed_path)
      -- compared to the basic strategy, also display icons
      p = require'telescope.utils'.path_tail(transformed_path)
      return require'telescope.utils'.transform_devicons(transformed_path ,p)
    end
  })})
end, {desc="Search text raw"})
function _G.buffer_fuzzy_find(word_under_cursor)
  local w = vim.fn.expand('<cword>')
  local opts = {}
  -- https://github.com/nvim-telescope/telescope.nvim/issues/1080
  -- keep lines ordered for in-buffer search as much as possible,
  -- ignore the match quality algorithm
  opts.tiebreak = function(current_entry, existing_entry, prompt)
    return false
  end
  require'telescope.builtin'.current_buffer_fuzzy_find(opts)
  if word_under_cursor then
    vim.fn.feedkeys(w)
  end
end
vim.keymap.set("n", "<leader>sbb", "<cmd>lua buffer_fuzzy_find(false)<cr>", {desc="search in Buffer"})
vim.keymap.set("n", "<leader>sb*", "<cmd>lua buffer_fuzzy_find(true)<cr>", {desc="search in Buffer"})
require 'key-menu'.set('n', '<Space>sd', {desc='Search in file Directory'})
vim.keymap.set("n", "<leader>sdd", function()
  require('telescope').extensions.live_grep_args.live_grep_args({cwd=vim.fn.expand('%:h'), prompt_title="Search text in directory " .. vim.fn.expand('%:h')})
end, {desc="Search text raw in Directory"})
vim.keymap.set("n", "<leader>sd*", "<cmd>lua my_open_tele(true)<cr>", {desc="Search word under cursor, raw"})
vim.keymap.set("v", "<leader>sd*", "<cmd>lua my_open_tele_sel(true)<cr>", {desc="Search selected text, raw"})
require 'key-menu'.set('n', '<Space>ss', {desc='Search LSP symbols'})
-- vim.keymap.set("n", "<leader>ssf", "<cmd>lua require'telescope.builtin'.lsp_document_symbols{symbol_width=80}<cr>", { desc = "Goto file LSP symbol"}) -- show_line=true would be another possible option
vim.keymap.set("n", "<leader>sD", "<cmd>:DevdocsGrep<cr>", {desc="Search in apidocs"})

-- telescope display+center vertically
function _G.telescope_center_mappings(prompt_bufnr, map)
  local actions = require('telescope.actions')
  map('i', '<Cr>',  actions.select_default + actions.center)
  return true
end

local function aerial_up()
  local aerial = require('aerial')
  -- in the case of typescriptreact, we want to skip "Struct" items, they're JSX nodes
  if vim.bo.filetype == 'typescriptreact' then
    while true do
      aerial.prev_up()
      local loc = aerial.get_location()
      if loc and #loc > 0 then
        if loc[#loc].kind ~= 'Struct' then
          break
        end
      else
        break
      end
    end
  else
    aerial.prev_up()
  end
end
vim.keymap.set("n", "<leader>ssp", aerial_up, { desc = "Goto parent symbol"})
vim.keymap.set("n", "<leader>ssf", function()
  local conf = require("telescope.config").values

  -- i want to filter out TSX tags/GQL fields for telescope, but still keep them
  -- for the symbols sidebar and for my leader-cp
  local sorter = conf.generic_sorter({discard = true})
  sorter._delimiter = ':'
  sorter.filter_function = function(_, prompt, entry)
    local filter_out_tsx = entry.filename:match("%.tsx$") and entry.value.kind == 'Struct'
    local filter_out_gql = entry.filename:match("%.graphql$") and entry.value.kind == 'Field'
    if filter_out_tsx or filter_out_gql then
      return -1, prompt
    else
      return 0, prompt
    end
  end

  require('telescope').extensions.aerial.aerial({
    get_entry_text = aerial_elixir_get_entry_text,
    attach_mappings = telescope_center_mappings,
    sorter = sorter,
  })
end, { desc = "Goto file LSP symbol"})
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
require 'key-menu'.set('n', '<Space>sc', {desc='Search code'})
vim.keymap.set( "n", "<leader>scd", "<cmd>lua search_code_deps()<CR>", {desc="Search code deps"})
vim.keymap.set( "n", "<leader>sct", "<cmd>Telescope ast_grep<CR>", {desc="ast-grep code search"})

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
vim.keymap.set("n", "<leader>wq", "<cmd>lua win_bring_qf_here()<cr>", {desc="Bring quickfix to this window"})
-- workaround for.. sometimes this gets enabled. might be me hitting the wrong shortcut, or a neovim/plugin bug
vim.keymap.set("n", "<leader>wS", "<cmd>windo set nocursorbind | windo set noscrollbind<cr>", {desc="Disable cursor bind & scroll lock"})

require 'key-menu'.set('n', '<Space>wf', {desc='Window diFF'})
vim.keymap.set("n", "<leader>wfj", "<cmd>lua window_diff_json()<cr>", {desc="window diff JSON"})

require 'key-menu'.set('n', '<Space>wh', {desc='Window highlight'})
vim.keymap.set("n", "<leader>whs", "<cmd>lua window_highlight_set()<cr>", {desc="window highlight set"})
vim.keymap.set("n", "<leader>whc", "<cmd>lua window_highlight_clear()<cr>", {desc="window highlight clear"})

-- PACKAGES
require 'key-menu'.set('n', '<Space>p', {desc='Packages'})
vim.keymap.set("n", "<leader>pp", "<cmd>PackerSync<cr>", { desc = "Packer sync"})
vim.keymap.set("n", "<leader>pl", "<cmd>Mason<cr>", { desc = "LSP install info"})
vim.keymap.set("n", "<leader>pt", "<cmd>TSInstallInfo<cr>", { desc = "Tree-sitter install info"})
vim.keymap.set("n", "<leader>pT", "<cmd>TSUpdate<cr>", { desc = "Tree-sitter update packages"})

-- a bit messy to remap telescope-project key mappings: https://github.com/nvim-telescope/telescope-project.nvim/issues/84
-- I want telescope-live-grep-raw instead of the normal telescope-rg
-- also used by telescope_modified_git_projects
function _G.tel_proj_attach_mappings(prompt_bufnr, map)
  map('i', '<C-s>', function(nr)
    require('telescope').extensions.live_grep_args.live_grep_args{
      cwd=require("telescope.actions.state").get_selected_entry(prompt_bufnr).value
    }
  end)
  map('i', '<C-g>', function(nr)
    require('telescope.builtin').git_status{
      cwd=require("telescope.actions.state").get_selected_entry(prompt_bufnr).value
    }
  end)
  map('i', '<C-r>', function(nr)
    telescope_recent_or_all{
      cwd_only=true,
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
vim.keymap.set("n", "<leader>of", "<cmd>lua require 'telescope'.extensions.file_browser.file_browser({grouped = true, path=vim.fn.expand(\"%:p:h\"), select_buffer=true})<CR>", {desc="Open browser in current folder"})
vim.keymap.set("n", "<leader>og", "<cmd>lua telescope_global_marks{}<CR>", {desc="Open global marks"})
vim.keymap.set("n", "<leader>om", function() require("telescope.builtin").man_pages{sections={'ALL'}} end, {desc="Open man page"})
vim.keymap.set("n", "<leader>oh", require("telescope.builtin").help_tags, {desc="Open vim help"})
vim.keymap.set("n", "<leader>ok", "<cmd>lua require'telescope.builtin'.keymaps{}<CR>", {desc="Open keyboard shortcuts"})
vim.keymap.set("n", "<leader>oH", "<cmd>lua require'telescope.builtin'.highlights{}<CR>", {desc="Open highlights"})
vim.keymap.set("n", "<leader>oq", "<cmd>lua telescope_quickfix_locations{}<CR>", {desc="Open quickfix locations"})
vim.keymap.set("n", "<leader>oy", "<cmd>lua clip_history()<CR>", {desc="Open yank stack"})
vim.keymap.set("n", "<leader>oj", "<cmd>lua telescope_jumplist()<CR>", {desc="Open location Jump list"})
vim.keymap.set("n", "<leader>oe", "<cmd>NvimTreeFocus<CR>", {desc="Open file explorer"})
vim.keymap.set("n", "<leader>ot", "<cmd>lua telescope_modified_git_projects()<CR>", {desc="Open touched projects"})
vim.keymap.set("n", "<leader>ou", "<cmd>lua require('telescope').extensions.undo.undo()<CR>", {desc="Open undo history"})
vim.keymap.set("n", "<leader>os", "<cmd>AerialOpen<CR>", {desc = "Open symbols"})
vim.keymap.set("n", "<leader>od", "<cmd>DevdocsOpen<CR>", {desc = "Open devdocs"})
vim.keymap.set("n", "<leader>oi", "<cmd>ConformInfo<CR>", {desc = "Open indent infos"}) -- useful if formatting fails, can see info
vim.keymap.set("n", "<leader>oP", "<cmd>lua require'telescope.builtin'.pickers{}<CR>", {desc = "(re)open recent telescope picker"})
vim.keymap.set("n", "<leader>ow", "<cmd>lua open_in_centered_popup()<CR>", {desc = "open the current buffer in a centered window"})

-- TOGGLE
require 'key-menu'.set('n', '<Space>t', {desc='Toggle'})
vim.keymap.set("n", "<leader>te", "<cmd>NvimTreeToggle<CR>", {desc = "Toggle file explorer"})
vim.keymap.set("n", "<leader>ts", "<cmd>AerialToggle!<CR>", {desc = "Toggle symbols"})
vim.keymap.set("n", "<leader>tm", "<cmd>lua toggle_highlight_global_marks()<CR>", {desc = "Toggle highlight of global marks"})
vim.keymap.set("n", "<leader>tw", ":set wrap! linebreak<cr>", {desc = "Toggle word-wrapping"})
vim.keymap.set("n", "<leader>tS", ":set spell!<CR>", {desc = "Toggle Spellcheck"})
vim.keymap.set("n", "<leader>tf", ":lua toggle_diff()<cr>", {desc = "Toggle diff"})
vim.keymap.set("n", "<leader>tc", function()
  if vim.o.conceallevel == 2 then
    vim.o.conceallevel = 0
  else
    vim.o.conceallevel = 2
  end
end, {desc = "Toggle conceal"})
vim.keymap.set("n", "<leader>ta", function()
  if vim.g.stop_adb_monitor == nil or vim.g.stop_adb_monitor == false then
    start_adb_monitor()
  else
    stop_adb_monitor()
  end
end, {desc = "Toggle adb device monitoring"})

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
vim.keymap.set("n", "<leader>tW", function()
  if vim.o.diffopt:match("iwhiteall") then
    vim.cmd[[set diffopt-=iwhiteall]]
    notif({"Disabling diff whitespaces"})
  else
    vim.cmd[[set diffopt+=iwhiteall]]
    notif({"Enabling diff whitespaces"})
  end
end, {desc="Toggle white spaces in diff"})

require 'key-menu'.set('n', '<Space>tp', {desc='Toggle picker'})
vim.keymap.set("n", "<leader>tpp", function()
  vim.g.telescope_entry_fullpath_display = not vim.g.telescope_entry_fullpath_display
  notif({"Picker full path display is now " .. vim.inspect(vim.g.telescope_entry_fullpath_display)})
end, {desc="Toggle picker full path display"})
vim.keymap.set("n", "<leader>tpv", function()
  vim.g.telescope_vertical = not vim.g.telescope_vertical
  notif({"Picker vertical display is now " .. vim.inspect(vim.g.telescope_vertical)})
end, {desc="Toggle picker vertical display"})

local function tab_delete_custom()
  vim.cmd[[:tabc]]
  local tab = vim.api.nvim_get_current_tabpage()
  if tabpage_is_sql(tab) or tabpage_is_terminal(tab) then
    vim.api.nvim_set_current_tabpage(1)
  end
end
vim.keymap.set("n", "<leader>td", tab_delete_custom, {desc="Delete tab"}) -- that one doesn't fit under toggle.. it's TAB delete. but keeping it here for now.
vim.keymap.set("n", "<leader>to", ":tabo<cr>", {desc="Delete other tabs"}) -- that one doesn't fit under toggle.. it's TAB delete. but keeping it here for now.
vim.keymap.set("n", "<leader>tl", "<cmd>lua toggle_linting()<cr>", {desc = "Toggle linting for the whole neovim"})

function _G.neogit_open_or_switch_to()
  local tabs = vim.api.nvim_list_tabpages()
  for _, tab in ipairs(tabs) do
    local wins = vim.api.nvim_tabpage_list_wins(tab)
    if #wins == 1 then
      win = wins[1]
      local buf = vim.api.nvim_win_get_buf(win)
      if vim.api.nvim_buf_get_option(buf, "ft") == 'NeogitStatus' then
        -- found the terminal tab, switch to it
        vim.api.nvim_set_current_tabpage(tab)
        return
      end
    end
  end
  -- didn't find the terminal tab, create it
  vim.cmd("Neogit")
end

function _G.tabpage_is_terminal(tab)
  local wins = vim.api.nvim_tabpage_list_wins(tab)
  if #wins == 1 then
    win = wins[1]
    local buf = vim.api.nvim_win_get_buf(win)
    if vim.api.nvim_buf_get_option(buf, "buftype") == 'terminal' then
      return true
    end
  end
  return false
end

function _G.create_or_switch_tab_terminal()
  local tabs = vim.api.nvim_list_tabpages()
  for _, tab in ipairs(tabs) do
    if tabpage_is_terminal(tab) then
      -- found the terminal tab, switch to it
      vim.api.nvim_set_current_tabpage(tab)
      return
    end
  end
  -- didn't find the terminal tab, create it
  vim.cmd("ToggleTerm direction=tab")
end

function _G.tabpage_is_sql(tab)
  local wins = vim.api.nvim_tabpage_list_wins(tab)
  if #wins ~= 1 then
    for _, win in ipairs(wins) do
      local buf = vim.api.nvim_win_get_buf(win)
      if vim.api.nvim_buf_get_option(buf, "ft") == 'dbui' then
        return true
      end
    end
  end
  return false
end

function _G.switch_to_sql_tab()
  local tabs = vim.api.nvim_list_tabpages()
  for _, tab in ipairs(tabs) do
    if tabpage_is_sql(tab) then
      -- found the sql tab, switch to it
      vim.api.nvim_set_current_tabpage(tab)
      return
    end
  end
  vim.cmd[[echohl ErrorMsg | echo "No SQL tab open" | echohl None]]
end


-- TAB
require 'key-menu'.set('n', '<Space>tt', {desc='Tab'})
vim.keymap.set("n", "<leader>ttm", function() vim.api.nvim_set_current_tabpage(1) end, {desc = "Switch to main tab"})
vim.keymap.set("n", "<leader>ttt", "<cmd>lua create_or_switch_tab_terminal()<cr>", {desc = "Open or switch to terminal tab"})
vim.keymap.set("n", "<leader>ttq", "<cmd>lua switch_to_sql_tab()<cr>", {desc = "Switch to SQL tab"})
vim.keymap.set("n", "<leader>ttp", "<cmd>ToggleTerm direction=float<CR>", {desc = "Toggle popup terminal"})
vim.keymap.set("n", "<leader>ttv", "<cmd>ToggleTerm direction=vertical<CR>", {desc = "Open terminal in vertical split"})
vim.keymap.set("n", "<leader>tth", "<cmd>ToggleTerm direction=horizontal<CR>", {desc = "Open terminal in horizontal window"})

-- GIT
require 'key-menu'.set('n', '<Space>g', {desc='Git'})

-- when we detect the rebase finished, switch the first tab
function check_interactive_rebase_done()
  if vim.fn.filereadable(".git/rebase-merge/interactive") == 1 then
    -- the rebase is still ongoing. maybe we closed the first window and a new one (for instance to edit a commit message) will open now
    -- => re-create the autocommand
    vim.api.nvim_create_autocmd("BufDelete", {
      callback=function(ev)
        -- defer_fn to give git the time to process the change
        vim.defer_fn(check_interactive_rebase_done, 100)
      end,
      once = true
    })
  else
    -- the rebase finished
    vim.api.nvim_set_current_tabpage(1)
  end
end

function telescope_commits_mappings(prompt_bufnr, map)
  local actions = require('telescope.actions')
  map('i', '<C-r>i', function(nr)
    commit = require("telescope.actions.state").get_selected_entry(prompt_bufnr).value
    -- in case i have multiple tabs open (for instance dadbod in the second tab),
    -- and i do a rebase, due to invim integration, i do the rebase stuff in a new
    -- tab, and then i'm returned in the last tab. But the rebase outcome is displayed
    -- in the first tab. This switches back to the first tab after the rebase is done.
    vim.api.nvim_create_autocmd("BufDelete", {
      callback=function(ev)
        -- defer_fn to give git the time to process the change
        vim.defer_fn(check_interactive_rebase_done, 100)
      end,
      once = true
    })
    vim.cmd(":term! git rebase -i " .. commit .. "~")
  end, {desc = "Interactive rebase"})
  map('i', '<C-f>', function(nr)
    local action_state = require "telescope.actions.state"
    local picker = action_state.get_current_picker(nr)

    local commits = {}
    for _, entry in ipairs(picker:get_multi_selection()) do
      table.insert(commits, entry.value)
    end
    if #commits == 0 then
      commit = require("telescope.actions.state").get_selected_entry(prompt_bufnr).value
      actions.close(prompt_bufnr)
      vim.cmd(":DiffviewOpen " .. commit .. "^.." .. commit)
    elseif #commits ~= 2 then
      print("Must select two commits for diff")
    else
      actions.close(prompt_bufnr)
      vim.cmd(":DiffviewOpen " .. commits[1] .. "^.." .. commits[2])
    end
  end, {desc = "Diff in diffview"})
  map('i', '<C-k>', function(nr)
    commit = require("telescope.actions.state").get_selected_entry(prompt_bufnr).value
    vim.cmd(":term! git cherry-pick " .. commit)
  end, {desc = "Cherry-pick commit"})
  map('i', '<C-y>', function(nr)
    commit = require("telescope.actions.state").get_selected_entry(prompt_bufnr).value
    copy_to_clipboard(commit)
    notif({"Copied the commit GUID '" .. commit .. "' to the clipboard"})
  end, {desc = "Copy commit GUID"})
  return true
end

function telescope_branches_mappings(prompt_bufnr, map)
  local actions = require('telescope.actions')
  local action_state = require "telescope.actions.state"
  map('i', '<C-f>', function(nr)
    local branches = {}
    local picker = action_state.get_current_picker(nr)
    for _, entry in ipairs(picker:get_multi_selection()) do
      table.insert(branches, entry.value)
    end
    if #branches == 0 then
      branch = require("telescope.actions.state").get_selected_entry(prompt_bufnr).value
      actions.close(prompt_bufnr)
      -- heuristics.. will see if it works out
      if string.match(branch, "develop") or string.match(branch, "master") or string.match(branch, "main") then
        -- i want to compare to develop. presumably i'm ahead, comparing behind
        diffspec = branch .. "..."
      else
        -- i want to compare with another branch which isn't develop. i'm probably
        -- on develop => presumably i'm behind, comparing ahead
        diffspec = "..." .. branch
      end
      vim.cmd(":DiffviewOpen " .. diffspec)
    else
      actions.close(prompt_bufnr)
      vim.cmd(":DiffviewOpen " .. branches[1] .. "..." .. branches[2])
    end
  end, {desc = "Git diff"})
  map('i', '<C-enter>', function(nr) -- create a local branch to track an origin branch
    branch = require("telescope.actions.state").get_selected_entry(prompt_bufnr).value
    local cmd_output = {}
    if string.match(branch, "^origin/") then
      actions.close(prompt_bufnr)
      vim.fn.jobstart('git checkout ' .. branch:gsub("^origin/", ""), {
        stdout_buffered = true,
        on_stdout = vim.schedule_wrap(function(j, output)
          for _, line in ipairs(output) do
            if #line > 0 then
              table.insert(cmd_output, line)
            end
          end
        end),
        on_stderr = vim.schedule_wrap(function(j, output)
          for _, line in ipairs(output) do
            if #line > 0 then
              table.insert(cmd_output, line)
            end
          end
        end),
        on_exit = vim.schedule_wrap(function(j, output)
          notif(cmd_output)
        end),
      })
    end
  end, {desc = "Create local branch"})
  map('i', '<C-g>', function(nr) -- merge another branch
    branch = require("telescope.actions.state").get_selected_entry(prompt_bufnr).value
    local cmd_output = {}
    actions.close(prompt_bufnr)
    local require_ff_msg = "Fail if a merge commit would be created"
    vim.ui.select({require_ff_msg, "Allow merge commits"}, {prompt="Merge: select merge commit mode", kind="center_win"}, function(choice)
      if choice ~= nil then
        local extra_flags = ""
        if choice == require_ff_msg then
          extra_flags = " --ff-only"
        end
        vim.fn.jobstart('git merge ' .. branch .. extra_flags, {
          stdout_buffered = true,
          on_stdout = vim.schedule_wrap(function(j, output)
            for _, line in ipairs(output) do
              if #line > 0 then
                table.insert(cmd_output, line)
              end
            end
          end),
          on_stderr = vim.schedule_wrap(function(j, output)
            for _, line in ipairs(output) do
              if #line > 0 then
                table.insert(cmd_output, line)
              end
            end
          end),
          on_exit = vim.schedule_wrap(function(j, output)
            notif(cmd_output)
          end),
        })
      end
    end)
  end, {desc= "merGe"})
  map('i', '<C-Del>', function(nr) -- delete
    local current_picker = action_state.get_current_picker(prompt_bufnr)
    current_picker:delete_selection(function(selection)
      branch = require("telescope.actions.state").get_selected_entry(selection.bufnr).value
      actions.close(prompt_bufnr)
      local Job = require'plenary.job'
      if string.match(branch, "^origin/") then
        -- remote branch
        local answer = vim.ui.select({"Yes", "No"}, {
            prompt="Are you sure you want to delete the remote branch '" .. string.gsub(branch, "^origin/", "") .. "'?"
          }, function(choice)
            if choice == "Yes" then
              local branch_without_origin = string.gsub(branch, "^origin/", "")
              local cmd_output = {}
              vim.fn.jobstart('git push origin --delete ' .. branch_without_origin, {
                stdout_buffered = true,
                on_stdout = vim.schedule_wrap(function(j, output)
                  for _, line in ipairs(output) do
                    if #line > 0 then
                      table.insert(cmd_output, line)
                    end
                  end
                end),
                on_stderr = vim.schedule_wrap(function(j, output)
                  for _, line in ipairs(output) do
                    if #line > 0 then
                      table.insert(cmd_output, line)
                    end
                  end
                end),
                on_exit = function(j, return_val)
                  notif(cmd_output)
                end,
              })
            end
          end)
      else
        -- local branch
        Job:new({
          command = 'git',
          args = { 'branch', '-D', branch },
          on_exit = function(j, return_val)
            -- prints the sha of the tip of the deleted branch, useful for a manual undo
            print(vim.inspect(j:result()))
          end,
        }):sync()
      end
    end)
  end, {desc="Delete"})
  map('i', '<C-c>', function(nr) -- commits
    branch = require("telescope.actions.state").get_selected_entry(prompt_bufnr).value
    actions.close(prompt_bufnr)
    -- require'telescope.builtin'.git_commits{
    telescope_commits({
        attach_mappings=telescope_commits_mappings,
        entry_maker=custom_make_entry_gen_from_git_commits(),
        git_command={"git", "log", branch, "--pretty=tformat:%<(10)%h %<(16,trunc)%an %ad%d %s", "--date=short", "--",  vim.fs.root(vim.fn.getcwd(), ".git")}, layout_config={width=0.9, horizontal={preview_width=0.5}},
        branch=branch
      })
  end, {desc="Commits"})
  map('i', '<C-h>', function(nr) -- history
    branch = require("telescope.actions.state").get_selected_entry(prompt_bufnr).value
    actions.close(prompt_bufnr)
    vim.cmd('DiffviewFileHistory ' ..  vim.fs.root(0, '.git') .. " --range=" .. branch)
  end)
  map('i', '<C-y>', function(nr) -- copy branch name
    branch = require("telescope.actions.state").get_selected_entry(prompt_bufnr).value
    copy_to_clipboard(branch)
  end, {desc="Copy branch name"})
  map('i', '<C-w>', function(nr) -- fast-forWard to origin
    branch = require("telescope.actions.state").get_selected_entry(prompt_bufnr).value
    -- https://samuelgruetter.net/blog/2018/08/31/git-ffwd-without-checkout/
    local cmd_output = {"FF branch:"}
    vim.fn.jobstart('git fetch origin ' .. branch .. ":" .. branch, {
      stdout_buffered = true,
      on_stdout = vim.schedule_wrap(function(j, output)
        for _, line in ipairs(output) do
          if #line > 0 then
            table.insert(cmd_output, line)
          end
        end
      end),
      on_stderr = vim.schedule_wrap(function(j, output)
        for _, line in ipairs(output) do
          if #line > 0 then
            table.insert(cmd_output, line)
          end
        end
      end),
      on_exit = function(j, return_val)
        notif(cmd_output)
      end,
    })
  end, {desc="fast-forward to origin"})
  return true
end
vim.keymap.set("n", "<leader>gc", function()
  telescope_commits{
    attach_mappings=telescope_commits_mappings,
    entry_maker=custom_make_entry_gen_from_git_commits(),
    git_command={"git", "log", "--pretty=tformat:%<(10)%h %<(16,trunc)%an %ad%d %s", "--date=short", "--",  vim.fs.root(0, ".git")},
    layout_config={width=0.9, horizontal={preview_width=0.5}},
    -- sorting_strategy = 'descending',
  }
end, {desc ="Browse git commits"})
vim.keymap.set("n", "<leader>gt", "<cmd>lua require'agitator'.git_time_machine({use_current_win=true})<cr>", {desc = "Time machine"})
vim.keymap.set("n", "<leader>gB", "<cmd>lua require'agitator'.git_blame_toggle()<cr>", {desc="Git blame"})
vim.keymap.set("n", "<leader>gf", "<cmd>lua require'agitator'.open_file_git_branch()<cr>", {desc="Open file from branch"})
vim.keymap.set("n", "<leader>gs", "<cmd>lua require'agitator'.search_git_branch()<cr>", {desc="Search in another branch"})
vim.keymap.set("n", "<leader>gL", function() vim.cmd('DiffviewFileHistory ' .. vim.fs.root(vim.fn.getcwd(), '.git')) end, {desc="project_history"})
vim.keymap.set("n", "<leader>gT", "<cmd>:DiffviewFileHistory %<cr>", {desc="file_history"})
vim.keymap.set("n", "<leader>gg", "<cmd>lua neogit_open_or_switch_to()<cr>", {desc="neogit"})
vim.keymap.set("n", "<leader>gG", "<cmd>DiffviewOpen<cr>", {desc="Git two-way diff"})
vim.keymap.set("n", "<leader>gC", ":lua display_git_commit()<cr>", {desc="Git display commit"})
vim.keymap.set("n", "<leader>gv", ":lua ShowCommitAtLine()<cr>", {desc="View commit for line"})
vim.keymap.set("n", "<leader>gY", ":lua copy_file_line()<cr>", {desc="Copy line and line number"})
vim.keymap.set("v", "<leader>gY", ":lua copy_file_line_sel()<cr>", {desc="Copy line and line number (sel)"})
-- vim.keymap.set("n", "<leader>gR", '<cmd>lua require"gitsigns".reset_buffer()<CR>', {desc="reset buffer"})
-- vim.keymap.set("n", "<leader>gb", '<cmd>lua require"gitsigns".blame_line()<CR>', {desc="blame line"})
vim.keymap.set("n", "<leader>gr", '<cmd>lua git_branches{attach_mappings=telescope_branches_mappings, pattern="--sort=-committerdate"}<CR>', {desc="git bRanches"})
vim.keymap.set("n", "<leader>ga", "<cmd>lua require'agitator'.search_in_added()<CR>", {desc="git search in added files & lines"})
-- using neogit to push
vim.keymap.set("n", "<leader>gp", '<cmd>lua run_command("git", {"pull", "--rebase", "--autostash"}, reload_all)<CR>', {desc="git pull"})
vim.keymap.set("n", "<leader>gF", '<cmd>lua run_command("git", {"fetch", "origin"})<CR>', {desc="git fetch origin"})

require 'key-menu'.set('n', '<Space>gh', {desc='git stasH'})
vim.keymap.set("n", "<leader>gho", '<cmd>lua telescope_git_list_stashes{}<CR>', {desc="list git stashes"})

function _G.git_do_stash()
  vim.ui.input({prompt="Enter a name for the stash: ", kind="center_win"}, function(input)
    if input ~= nil then
      run_command("git", {"stash", "push", "-m", input, "-u"}, reload_all)
    end
  end)
end
vim.keymap.set("n", "<leader>ghh", '<cmd>lua git_do_stash()<CR>', {desc="git stash"})

require 'key-menu'.set('n', '<Space>h', {desc='Hunks'})
vim.keymap.set({"n", "v"}, "<leader>hS", function() vim.cmd[[norm ghgh]] end, {desc= "stage hunk"})
-- vim.keymap.set("n", "<leader>hu", '<cmd>lua require"gitsigns".undo_stage_hunk()<CR>', {desc="undo stage hunk"})
vim.keymap.set({"n", "v"}, "<leader>hr", function() vim.cmd[[norm gHgh]] end, {desc="reset hunk"})
vim.keymap.set("n", "<leader>hh", function() hunk_popup() end, {desc="preview hunk"})

-- CODE
require 'key-menu'.set('n', '<Space>c', {desc='Code'})

function format_buf()
  if vim.bo.filetype == 'html' then
    vim.cmd(':%!prettier --parser html')
  elseif vim.bo.filetype == 'xml' then
    vim.cmd(':%!xmllint --format -')
  elseif vim.bo.filetype == 'sql' then
    -- npx will install the app on first use... in theory i could use mason to set it up, but it's lacking
    -- an "ensure_installed" option: https://github.com/williamboman/mason.nvim/issues/103
    -- https://github.com/williamboman/mason.nvim/issues/130 https://github.com/williamboman/mason.nvim/issues/1338
    vim.cmd(':%!npx sql-formatter --language postgresql')
  else
    -- default
    require('conform').format()
  end
end
vim.keymap.set("n", "<leader>cf", ":lua format_buf()<cr>", {desc="Code format/indent"})
vim.keymap.set("n", "<leader>cm", function() glow_for_buffer(0) end, {desc="Markdown preview"})
require 'key-menu'.set('n', '<Space>cn', {desc='Code Nodes'})
vim.keymap.set('n', '<leader>cns', ":lua require('tsht').nodes()<cr>", {desc="select custom block"})
vim.keymap.set('n', '<leader>cnj', ":lua require('tsht').jump_nodes()<cr>", {desc="jump to code node"})
vim.keymap.set('n', '<leader>cnf', function()
  require('tsht').nodes()
  vim.cmd[[norm! zf]]
end, {desc="fold custom block"})
vim.keymap.set('n', '<leader>cp', ":lua print_lsp_path()<cr>", {desc="print & yank code LSP Path", silent=true})

require 'key-menu'.set('n', '<Space>cC', {desc='Code Conflicts'})
vim.keymap.set('n', '<leader>cCb', ":lua diffview_conflict_view_commit('base')<cr>", {desc="conflict show BASE commit", silent=true})
vim.keymap.set('n', '<leader>cCo', ":lua diffview_conflict_view_commit('ours')<cr>", {desc="conflict show OURS commit", silent=true})
vim.keymap.set('n', '<leader>cCt', ":lua diffview_conflict_view_commit('theirs')<cr>", {desc="conflict show THEIRS commit", silent=true})

require 'key-menu'.set('n', '<Space>cc', {desc='Code Csv'})
vim.keymap.set('n', '<leader>cca', function()
  require('decisive').align_csv({print_speed=true})
  require("zebrazone").start()
end, {desc="align CSV", silent=true})
vim.keymap.set('n', '<leader>ccA', function()
  require('decisive').align_csv_clear({})
  require("zebrazone").stop()
end, {desc="align CSV clear", silent=true})
vim.keymap.set('n', 'šc', ":lua require('decisive').align_csv_prev_col()<cr>", {desc="align CSV prev col", silent=true})
vim.keymap.set('n', 'đc', ":lua require('decisive').align_csv_next_col()<cr>", {desc="align CSV next col", silent=true})


-- TESTS
require 'key-menu'.set('n', '<Space>ct', {desc='Tests'})
vim.keymap.set("n", "<leader>ctf", ":TestFile -strategy=dispatch<cr>", {desc="test file"})
vim.keymap.set("n", "<leader>ctn", ":TestNearest -strategy=dispatch<cr>", {desc="test nearest"})
vim.keymap.set("n", "<leader>ctl", ":TestLast -strategy=dispatch<cr>", {desc="test last"})
vim.keymap.set("n", "<leader>cta", ":TestSuite -strategy=dispatch<cr>", {desc="test all"})
vim.keymap.set("n", "<leader>ctA", ":lua test_all_bg_run()<cr>", {desc="test all, background run"})
vim.keymap.set("n", "<leader>ctk", ":AbortDispatch<cr>", {desc="kill tests"})
vim.keymap.set("n", "<leader>ctK", ":lua vim.fn.jobstop(vim.g.test_bg_jobid)<cr>", {desc="kill background tests"})
vim.keymap.set("n", "<leader>ctp", "<cmd>lua test_output_in_popup()<cr>", {desc="test output in popup"})
vim.keymap.set("n", "<leader>cto", "<cmd>lua test_output_open()<cr>", {desc="open test output"})
vim.keymap.set("n", "<leader>ctO", ":Copen<cr>", {desc="open test output for background run"})
function  tests_current_buffer_to_qf()
  if vim.g['test#last_command']:match("^mix test") then
    vim.cmd("compiler exunit")
  end
  vim.cmd("cb!")
end
vim.keymap.set("n", "<leader>ctq", tests_current_buffer_to_qf, {desc="load the test results from the current buffer to quickfix"})

-- QUICKFIX
require 'key-menu'.set('n', '<Space>cq', {desc='Quickfix'})
vim.keymap.set("n", "<leader>cqs", ":lua select_current_qf(false)<cr>", {desc="quickfix select current"})
vim.keymap.set("n", "<leader>cqv", ":lua select_current_qf(true)<cr>", {desc="quickfix view & select current"})
vim.keymap.set("n", "<leader>cqb", ":lua quickfix_goto_bottom()<cr>", {desc="quickfix go to bottom"})

vim.cmd[[set errorformat^=ERROR\ in\ %f:%l:%c]] -- needed for tsc, typescript
vim.keymap.set("n", "<leader>cqc", ":cexpr @+<cr>", {desc="Quickfix from clipboard"})

function _G.lsp_refs_extra_mappings(p, map)
  map("i", "<c-g>", function(prompt_nr)
    local action_state = require "telescope.actions.state"
    local current_picker = action_state.get_current_picker(prompt_nr) -- picker state
    local entry = action_state.get_selected_entry()
    local full_path = entry.filename
    local path_in_cwd = string.gsub(full_path, vim.loop.cwd() .. '/', "")
    notif({path_in_cwd})
  end)
  return true
end

local function indent_ts_type(str)
  local nested_levels = 0
  local is_after_cr = false
  local in_backticks = false
  local result = ""
  for i = 1, #str do
    local c = str:sub(i,i)
    if c == "`" then
      result = result .. c
      in_backticks = not in_backticks
      goto skip_to_next
    end
    if not in_backticks then
      if c == "{" then
        nested_levels = nested_levels + 1
      elseif c == "}" then
        nested_levels = nested_levels - 1
      end
    end
    if c == " " and is_after_cr then
      -- do nothing, wait for the next character
      goto skip_to_next
    elseif is_after_cr then
      result = result .. string.rep("  ", nested_levels)
      is_after_cr = false
    end

    if c == ";" then
      result = result .. ";\n"
      is_after_cr = true
    elseif c == "{" and not in_backticks then
      result = result .. "{\n"
      is_after_cr = true
    else
      result = result .. c
    end
    ::skip_to_next::
  end
  return result
end

local function indent_ts_types(str)
  local result = ""
  local next_is_type = false
  for line in vim.gsplit(str, "\n") do
    if line == "```typescript" then
      next_is_type = true
      result = result .. line .. "\n"
    elseif next_is_type then
      result = result .. indent_ts_type(line) .. "\n"
    else
      result = result .. line .. "\n"
    end
  end
  return result
end

-- https://stackoverflow.com/a/24691027/516188
function count_lines(string)
  return select(2, string:gsub('\n', '\n'))
end

-- LSP
require 'key-menu'.set('n', '<Space>cl', {desc='LSP'})
vim.keymap.set("n", "<leader>cla", "<cmd>lua vim.lsp.buf.code_action()<CR>", {desc="Code actions"})
vim.keymap.set("n", "<leader>cll", function()
  if vim.bo.filetype == "typescriptreact" or vim.bo.filetype == 'typescript' then
    local diag = vim.diagnostic.get(0, {lnum = vim.fn.line('.')-1})
    -- don't activate on simple messages like 'expected property shorthand'
    if #diag == 1 and diag[1].message:match("'") then
      local msg = diag[1].message
      local msg_md = msg
        :gsub(" '(%w+)'([%s%.%?,:])", " `%1`%2")
        :gsub("\n%s+", string.rep("─", 80) .. "\n")
        :gsub("^'(%w+)'([%s%.%?,:])", " `%1`%2")
        :gsub(" '", "\n```typescript\n")
        :gsub("'[%s%.,:]", "\n```\n")
        :gsub("\nOverload ", "\n\n## Overload ")
      local indented_msg = indent_ts_types(msg_md)
      if count_lines(indented_msg) == 1 then
        -- the special display is overkill if it's only one line after formatting
        vim.diagnostic.open_float(0, {scope="line"})
      else
        local buf = string_to_buffer(indented_msg)
        vim.api.nvim_buf_set_option(buf, 'modifiable', false)
        vim.api.nvim_buf_set_option(buf, "readonly", true)
        vim.api.nvim_set_option_value("filetype", "markdown", {buf = buf})
        vim.api.nvim_set_option_value("modified", false, {buf = buf})
        vim.api.nvim_set_option_value("bufhidden", 'wipe', {buf = buf})
        local win = open_in_centered_popup(buf, count_lines(indented_msg)+2)
        vim.api.nvim_set_option_value("conceallevel", 2, {win = win})
        vim.api.nvim_set_option_value("wrap", true, {win = win})
        vim.api.nvim_set_option_value("linebreak", true, {win = win})
        -- q closes the window
        vim.cmd("nmap <buffer> q <C-W>c")
      end
    else
      vim.diagnostic.open_float(0, {scope="line"})
    end
  else
    vim.diagnostic.open_float(0, {scope="line"})
  end
end, {desc="Show line diagnostics"})
vim.keymap.set("n", "<leader>clr", "<cmd>lua vim.lsp.buf.rename()<CR>", {desc="Rename the reference under cursor"})
-- TODO drop <leader>clf for gr
vim.keymap.set("n", "<leader>clf", "<cmd>lua require'telescope.builtin'.lsp_references{path_display={'tail'}, attach_mappings=lsp_refs_extra_mappings}<cr>", {desc="Display lsp references"})
vim.keymap.set("n", "<leader>clc", "<cmd>lua require'telescope.builtin'.lsp_incoming_calls{path_display={'tail'}}<cr>", {desc="Display lsp incoming calls"})
vim.keymap.set("n", "<leader>clh", "<cmd>lua telescope_display_call_hierarchy()<cr>", {desc="Display lsp call hierarchy"})

-- i had issues after the mason migration where lsp restart would not restart all LSPs.. or i would lose some LSPs or something
-- => bulletproof it with my own restart that really restarts everything
-- vim.keymap.set("n", "<leader>clR", "<cmd>:LspRestart<CR>", {desc="Restart LSP clients for this buffer"})
vim.keymap.set("n", "<leader>clR", "<cmd>:lua lsp_restart_all()<CR>", {desc="Restart LSP clients for this buffer"})
vim.keymap.set("n", "<leader>cli", "<cmd>lua remove_unused_imports()<CR>", {desc="Remove unused imports"})

-- override LSP for java, not using LSP there
vim.api.nvim_create_autocmd("FileType", {
  pattern = "java",
  callback=function(ev)
    vim.keymap.set('n', 'gd', ":lua require'code_compass'.find_definition()<cr>", {desc="code-compass jump to definition", silent=true, buffer=0})
    -- TODO drop clf
    vim.keymap.set('n', '<leader>clf', ":lua require'code_compass'.find_references()<cr>", {desc="code-compass find references", silent=true, buffer=0})
    vim.keymap.set('n', 'gr', ":lua require'code_compass'.find_references()<cr>", {desc="code-compass find references", silent=true, buffer=0})
    vim.keymap.set('n', '<leader>cll', ":lua quickfix_at_curpos()<cr>", {desc="Quickfix error on current line", silent=true, buffer=0})
  end})

-- MARKS
require 'key-menu'.set('n', '<Space>m', {desc='Marks'})
vim.keymap.set("n", "<leader>ma", ":lua add_global_mark()<cr>", {desc="Add mark"})

-- VIM
require 'key-menu'.set('n', '<Space>v', {desc='Vim'})
vim.keymap.set("n", "<leader>vc", ":let @+=@:<cr>", {desc="Yank last ex command text"})
vim.keymap.set("n", "<leader>vm", [[:let @+=substitute(execute('messages'), '\n\+', '\n', 'g')<cr>]], {desc="Yank vim messages output"})
vim.keymap.set("n", "<leader>vz", ":let g:neovide_scale_factor = ", {desc="neovide zoom"})

-- JOBS
require 'key-menu'.set('n', '<Space>j', {desc='Jobs'})
vim.keymap.set("n", "<leader>jt", ":lua overseer_popup_running_task()<cr>", {desc="open running job Terminal"})
vim.keymap.set("n", "<leader>js", ":lua overseer_show_running_task()<cr>", {desc="show running job Terminal"})
vim.keymap.set("n", "<leader>jlt", function() vim.cmd[[OverseerToggle]]; vim.defer_fn(function() vim.cmd[[execute "normal \<C-w>="]] end, 50) end, {desc="Jobs List Toggle"})
vim.keymap.set("n", "<leader>jlo", function() vim.cmd[[OverseerOpen]]; vim.defer_fn(function() vim.cmd[[execute "normal \<C-w>="]] end, 50) end, {desc="Jobs List Open"})
vim.keymap.set("n", "<leader>jr", "<cmd>OverseerRun<CR>", {desc="Run job"})
vim.keymap.set("n", "<leader>jC", "<cmd>OverseerClearCache<CR>", {desc="Clear tasks cache"})
vim.keymap.set("n", "<leader>jd", ":lua overseer_dispose_completed_jobs()<cr>", {desc="Dispose completed jobs"})
vim.keymap.set("n", "<leader>ja", ":lua overseer_rerun_last_job()<cr>", {desc="run last job Again"})
vim.keymap.set("n", "<leader>jf", ":lua overseer_open_float_last_job()<cr>", {desc="open last job in Float"})

-- vim: ts=2 sts=2 sw=2 et
