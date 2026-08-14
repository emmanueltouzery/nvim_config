return {
  desc = "job display info",
  params = {
    message = {
      type = "string",
    }
  },
  constructor = function(params)
    local msg_id = nil
    return {
      on_start = function(self, task)
        msg_id = vim.api.nvim_echo({{params.message}}, true, {
          kind='progress', status='running', title=params.message, source='Job status', percent = nil
        })
      end,
      on_reset = function(self, task)
        if msg_id ~= nil then
          vim.api.nvim_echo({{'Done'}}, true, {
            id = msg_id, kind='progress', status='success', source='Job status', title=params.message
          })
        end
        msg_id = vim.api.nvim_echo({{params.message}}, true, {
          kind='progress', status='running', title=params.message, source='Job status', percent = nil
        })
      end,
      on_exit = function(self, task, status)
        vim.api.nvim_echo({{'Done'}}, true, {
          id = msg_id, kind='progress', status='success', source='Job status', title=params.message
        })
        msg_id = nil
      end,
    }
  end,
}
