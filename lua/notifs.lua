-- i'm aware of rcarriga/nvim-notify but this is much smaller
-- i don't want to bloat my config

vim.cmd [[
hi def NotifInfo guifg=#80ff95
hi def NotifWarning guifg=#fff454
hi def NotifError guifg=#c44323
]]

function _G.notif(msg, level)
  vim.g.popup_buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_option(vim.g.popup_buf, 'buftype', 'nofile')
  vim.api.nvim_buf_set_option(vim.g.popup_buf, 'modifiable', true)

  local width = vim.fn.winwidth(0)
  local height = vim.fn.winheight(0)

  local opts = {
    focusable = false,
    style = "minimal",
    border = "rounded",
    relative = "win",
    width = #msg+2,
    height = 1,
    anchor = "SE",
    row = height,
    col = width,
  }

  vim.api.nvim_buf_set_lines(vim.g.popup_buf, 0, -1, false, {" " .. msg})

  vim.g.popup_win = vim.api.nvim_open_win(vim.g.popup_buf, false, opts)

  if level == nil or level == vim.log.levels.INFO then
    vim.api.nvim_win_set_option(vim.g.popup_win, "winhl", "Normal:NotifInfo,FloatBorder:NotifInfo")
  elseif level == vim.log.levels.WARN then
    vim.api.nvim_win_set_option(vim.g.popup_win, "winhl", "Normal:NotifWarning,FloatBorder:NotifWarning")
  else
    vim.api.nvim_win_set_option(vim.g.popup_win, "winhl", "Normal:NotifError,FloatBorder:NotifError")
  end

  vim.defer_fn(function() 
    if vim.api.nvim_win_is_valid(vim.g.popup_win) then
      vim.api.nvim_win_close(vim.g.popup_win, true)
    end
    if vim.api.nvim_buf_is_valid(vim.g.popup_buf) then
      vim.api.nvim_buf_delete(vim.g.popup_buf, {force=true})
    end
  end, 1000)
end
