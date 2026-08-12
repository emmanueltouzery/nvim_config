-- based on code in runtime/lua/vim/ui.lua

---@type table<integer, ProgressMessage>
local progress = {}

local progress_group, progress_autocmd = nil, nil

---Initialize progress event listeners
local function progress_init()
  progress_group = vim.api.nvim_create_augroup('nvim.ui.progress_status', { clear = true })
  progress_autocmd = vim.api.nvim_create_autocmd('Progress', {
    group = progress_group,
    desc = 'Tracks progress messages for vim.ui.progress_status()',
    ---@param ev {data: {id: integer, title: string, status: string, percent: integer}}
    callback = function(ev)
      if not ev.data or not ev.data.id then
        return
      end
      progress[ev.data.id] = {
        id = ev.data.id,
        title = ev.data.title,
        status = ev.data.status,
        percent = ev.data.percent or 0,
      }

      if
        ev.data.status == 'success'
        or ev.data.percent == 100
        or ev.data.status == 'failed'
        or ev.data.status == 'cancel'
      then
        progress[ev.data.id] = nil
        notif({"Task completed", ev.data.title})
      end
    end,
  })
end

local function format_item(progress_item)
  if progress_item.title == nil then
    return string.format('%d%%%% ', progress_item.percent or 0)
  end
  if progress_item.percent == nil or progress_item.percent == 0 then
    return " " .. progress_item.title
  end
  return string.format('%s: %d%%%% ', progress_item.title, progress_item.percent)
end

---@param running ProgressMessage[]
---@return string
local function progress_status_fmt(running)
  local count = #running
  if count == 0 then
    return '' -- nothing to show
  elseif count == 1 then
    return format_item(running[1])
  else
    return string.format(' %d tasks: %s, ...', count, format_item(running[1]))
  end
end

--- Gets the status of currently running progress messages, in a format
--- convenient for inclusion in 'statusline'.
---@return string formatted text of progress status for statusline
function _G.progress_status()
  -- Create progress event listener on first call
  if progress_autocmd == nil then
    progress_init()
  end

  local running = vim.tbl_values(progress)
  return progress_status_fmt(running) or ''
end
