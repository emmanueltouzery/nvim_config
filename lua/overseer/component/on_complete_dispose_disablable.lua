local uv = vim.uv or vim.loop
local constants = require("overseer.constants")
local log = require("overseer.log")
local STATUS = constants.STATUS
local timeout = 900

---@type overseer.ComponentFileDefinition
local comp = {
  desc = "After task is completed, dispose it after a timeout",
  constructor = function(opts)
    opts = opts or {}
    return {
      timer = nil,

      _stop_timer = function(self)
        if self.timer then
          self.timer:close()
          self.timer = nil
        end
      end,
      _start_timer = function(self, task)
        self:_stop_timer()
        log:debug(
          "task(%s)[on_complete_dispose] starting dispose timer for %ds",
          task.id,
          timeout
        )
        self.timer = uv.new_timer()
        -- Start a repeating timer because the dispose could fail with a
        -- temporary reason (e.g. the task buffer is open, or the action menu is
        -- displayed for the task)
        self.timer:start(
          1000 * timeout,
          1000 * timeout,
          vim.schedule_wrap(function()
            log:debug("task(%s)[on_complete_dispose] attempt dispose", task.id)
            task:dispose()
          end)
        )
      end,

      on_complete = function(self, task, status)
        local bufnr = task:get_bufnr()
        if not vim.g.overseer_disable_autodispose then
          self:_start_timer(task)
        end
      end,
      on_reset = function(self, task)
        self:_stop_timer()
      end,
      on_dispose = function(self, task)
        self:_stop_timer()
      end,
    }
  end,
}

return comp
