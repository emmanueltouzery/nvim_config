local constants = require("overseer.constants")
local STATUS = constants.STATUS

local function get_level_from_status(status)
  if status == STATUS.FAILURE then
    return vim.log.levels.ERROR
  elseif status == STATUS.CANCELED then
    return vim.log.levels.WARN
  else
    return vim.log.levels.INFO
  end
end

return {
  desc = "notif when task is completed",
  params = { },
  constructor = function(params)
    return {
      last_status = nil,
      on_complete = function(self, task, status)
        if status == self.last_status then
          return
        end
        self.last_status = status
        local level = get_level_from_status(status)
        local message = string.format("%s %s", status, task.name)
        notif({ message }, level)
      end,
    }
  end,
}
