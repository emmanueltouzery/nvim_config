vim.keymap.set('n', '<localleader>g', ':normal vip<CR><PLUG>(DBUI_ExecuteQuery)', { buffer = true, desc = "run query under cursor (mnemonic: Go)" })

local function get_dbout_win_buf()
  for _, w in pairs(vim.api.nvim_list_wins()) do
    local buf = vim.api.nvim_win_get_buf(w)
    if vim.api.nvim_buf_get_option(buf, "ft") == "dbout" then
      return vim.api.nvim_win_get_number(w), buf
    end
  end
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
  local curline = vim.fn.line('.')
  local buffer_lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
  -- find paragraph start (which may be the buffer start)
  while curline > 0 and buffer_lines[curline] ~= '' do
    curline = curline - 1
  end
  if buffer_lines[curline+1] == '\\x' then
    vim.api.nvim_buf_set_lines(0, curline, curline+1, false, {})
  else
    vim.api.nvim_buf_set_lines(0, curline, curline, false, {"\\x"})
  end
end
vim.keymap.set('n', '<localleader>x', toggle_expanded_results_marker, { buffer = true, desc = "Toggle expanded results marker" })

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

vim.keymap.set("n", '<localleader>j', [[:normal ysaw(wijsonb_pretty<cr>]], {buffer = true, desc="Wrap in jsonb_pretty"})
