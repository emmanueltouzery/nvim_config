vim.keymap.set('n', '<localleader>g', ':normal vip<CR><PLUG>(DBUI_ExecuteQuery)', { buffer = true, desc = "run query under cursor (mnemonic: Go)" })

local function get_dbout_win_buf()
  for _, w in pairs(vim.api.nvim_list_wins()) do
    local buf = vim.api.nvim_win_get_buf(w)
    if vim.api.nvim_buf_get_option(buf, "ft") == "dbout" then
      return vim.api.nvim_win_get_number(w), buf
    end
  end
end

local function toggle_expanded_results_display()
  local dbout_win, dbout_buf = get_dbout_win_buf()
  vim.api.nvim_buf_call(dbout_buf, function()
    vim.fn['db_ui#dbout#toggle_layout']()
  end)
end
vim.keymap.set('n', '<localleader>x', toggle_expanded_results_display, { buffer = true, desc = "Toggle expanded results display" })

local function jump_to_dbout()
  local dbout_win, dbout_buf = get_dbout_win_buf()
  vim.cmd(dbout_win .. ' wincmd w')
end
vim.keymap.set("n", "<leader>q", jump_to_dbout, {buffer = true, desc="Jump to the sql output window"})
