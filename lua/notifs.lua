-- i'm aware of rcarriga/nvim-notify but this is much smaller
-- i don't want to bloat my config or modify the behavior of builtin messages

local Str = require'plenary.strings'

local aug = vim.api.nvim_create_augroup("Notifs", {})
vim.api.nvim_create_autocmd("FocusGained", {
  desc = "Track editor focus for notifs",
  group = aug,
  callback = function()
    vim.g.notifs_focused = true
  end,
})
vim.api.nvim_create_autocmd("FocusLost", {
  desc = "Track editor focus for notifs",
  group = aug,
  callback = function()
    vim.g.notifs_focused = false
  end,
})

vim.cmd [[
hi def NotifInfo guifg=#528aa8
hi def NotifWarning guifg=#fff454
hi def NotifError guifg=#c44323
]]
vim.g.active_notifs = {}

max_length = 60

function _G.notif_max_offset()
  max = -1
  for i, n in pairs(vim.g.active_notifs) do
    if n.offset > max then
      max = n.offset
    end
  end
  return max
end

function _G.notif_length(msg)
  max = 0
  for i, m in pairs(msg) do
    if #m > max then
      max = math.min(#m, max_length)
    end
  end
  return max
end

local function force_length(msg, len)
    if Str.strdisplaywidth(msg) > len then
        return Str.truncate(msg, len)
    else
        return Str.align_str(msg, len, false)
    end
end

function _G.notif_format_msg(msg)
  local res = {}
  for i, m in ipairs(msg) do
    table.insert(res, " " .. force_length(m, max_length))
  end
  return res
end

function _G.notif(msg, level, opts)
  if not vim.g.notifs_focused then
    local system_notif_msg = {unpack(msg)}
    local title = table.remove(system_notif_msg, 1)
    vim.fn.jobstart({"notify-send", title, table.concat(system_notif_msg, "\n"), "--icon=dialog-information"})
  end
  local popup_buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_option(popup_buf, 'buftype', 'nofile')
  vim.api.nvim_buf_set_option(popup_buf, "bufhidden", "hide")
  vim.api.nvim_buf_set_option(popup_buf, "swapfile", false)
  vim.api.nvim_buf_set_option(popup_buf, 'modifiable', true)

  local width = vim.api.nvim_get_option("columns")
  local height = vim.api.nvim_get_option("lines") - vim.o.cmdheight - 1
  local msg_width = notif_length(msg)+2

  local offset = notif_max_offset()+1
  local win_opts = {
    focusable = false,
    style = "minimal",
    border = "rounded",
    relative = "editor",
    width = msg_width,
    height = #msg,
    anchor = "SE",
    row = height - offset*3,
    col = width,
    noautocmd = true,
  }

  vim.api.nvim_buf_set_lines(popup_buf, 0, -1, false, notif_format_msg(msg))
  vim.api.nvim_buf_set_option(popup_buf, 'modifiable', false)
  vim.api.nvim_buf_set_option(popup_buf, "readonly", true)

  popup_win = vim.api.nvim_open_win(popup_buf, false, win_opts)

  if level == nil or level == vim.log.levels.INFO then
    vim.api.nvim_win_set_option(popup_win, "winhl", "Normal:NotifInfo,FloatBorder:NotifInfo")
  elseif level == vim.log.levels.WARN then
    vim.api.nvim_win_set_option(popup_win, "winhl", "Normal:NotifWarning,FloatBorder:NotifWarning")
  else
    vim.api.nvim_win_set_option(popup_win, "winhl", "Normal:NotifError,FloatBorder:NotifError")
  end

  local active_notifs = vim.g.active_notifs
  active_notifs[popup_win .. ""] = {
    popup_win = popup_win,
    popup_buf = popup_buf,
    offset = offset
  }
  vim.g.active_notifs = active_notifs

  -- seems like numbers don't get copied to the defer_fn closure
  -- if i don't transform to string, the closure gets the latest value,
  -- not the scheduled one
  local popup_win_closure = popup_win .. ""

  function hide_closure()
    local notif = vim.g.active_notifs[popup_win_closure]
    if vim.api.nvim_win_is_valid(notif.popup_win) then
      vim.api.nvim_win_close(notif.popup_win, true)
    end
    if vim.api.nvim_buf_is_valid(notif.popup_buf) then
      vim.api.nvim_buf_delete(notif.popup_buf, {force=true})
    end
    local active_notifs = vim.g.active_notifs
    active_notifs[popup_win_closure] = nil
    vim.g.active_notifs = active_notifs
  end
  if not (opts or {}).dont_hide then
    vim.defer_fn(hide_closure, 2000)
  else
    return hide_closure
  end
end

vim.notify = function(msg, level, opts)
  if opts and opts.title == "Neogit" then
    notif({msg}, level)
  elseif level == vim.log.levels.ERROR then
    notif({msg}, level)
    print(msg) -- notif truncates/can't recall it
  else
    print(msg)
  end
end
