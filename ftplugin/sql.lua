vim.keymap.set('n', '<localleader>g', ':normal vip<CR><PLUG>(DBUI_ExecuteQuery)', { buffer = true, desc = "run query under cursor (mnemonic: Go)" })

local function trigger_query_selected()
  -- https://www.reddit.com/r/neovim/comments/17x8tso/comment/k9moruv/
  local t = function(keycode) return vim.api.nvim_replace_termcodes(keycode, true, false, true) end
  vim.api.nvim_feedkeys(t "<Plug>(DBUI_ExecuteQuery)", 'n', true)
end

-- temporary, just for this query
local function toggle_expanded_results_display()
  local dbout_win, dbout_buf = get_dbout_win_buf()
  vim.api.nvim_buf_call(dbout_buf, function()
    vim.fn['db_ui#dbout#toggle_layout']()
  end)
end
vim.keymap.set('n', '<localleader>X', toggle_expanded_results_display, { buffer = true, desc = "Toggle expanded results display" })

-- write in the SQL, will stay
function toggle_expanded_results_marker()
  local marker = '\\x'
  if vim.b.db:match("sqlite") then
    marker = '.mode line'
  end

  local curline = vim.fn.line('.')
  local buffer_lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
  -- find paragraph start (which may be the buffer start)
  while curline > 0 and buffer_lines[curline] ~= '' do
    curline = curline - 1
  end
  if buffer_lines[curline+1] == marker then
    vim.api.nvim_buf_set_lines(0, curline, curline+1, false, {})
  else
    vim.api.nvim_buf_set_lines(0, curline, curline, false, {marker})
  end
  -- re-run the query
  vim.cmd[[:normal vip]]
  trigger_query_selected()
end
vim.keymap.set('n', '<localleader>x', toggle_expanded_results_marker, { buffer = true, desc = "Toggle expanded results marker" })

vim.keymap.set('v', '<localleader>g', trigger_query_selected, { buffer = true, desc = "Trigger query for selected text" })

local function jump_to_dbout()
  local dbout_win, dbout_buf = get_dbout_win_buf()
  vim.cmd(dbout_win .. ' wincmd w')
end
vim.keymap.set("n", "<leader>q", jump_to_dbout, {buffer = true, desc="Jump to the sql output window"})

-- yeah, that regex... https://stackoverflow.com/questions/21148467/ is a negative lookbehind.
-- so \(;\|\n\)\@<! means that the rest must NOT be preceded by a newline or ;
-- and that also declares a first capture group (;|\n)
-- then we have... \(\n\n\+\) a series of at least two newlines -- and the second capture group
-- this is then replaced by ;\2 -- ; and the second capture group
-- so we append ; to the end of each query if it wasn't there
vim.keymap.set("n", '<localleader>s', [[<cmd>%s/\(;\|\n\)\@<!\(\n\n\+\)/;\2<cr>]], {buffer = true, desc="Insert sql statement Separators (;)"})

-- ge Backward to end of previous word
-- w next word
-- (gew makes sure we're at the start of the word whether we were in or just before the word)
-- You Surround A Word with (
--b backward
-- insert
vim.keymap.set("n", '<localleader>j', [[:normal gewysaw(bijsonb_pretty<cr>]], {buffer = true, desc="Wrap in jsonb_pretty"})

-- start similar to -j. wrap in two levels of brackets, use % to switch to the other bracket, esc to exit insert mode
vim.keymap.set("n", '<localleader>a', [[:normal gewysaw(ysaw(biarray_to_json<esc>bbijsonb_pretty<esc>%hi::jsonb<esc>]], {buffer = true, desc="Pretty display for array"})
