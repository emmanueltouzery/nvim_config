return {
  desc = "job display info",
  params = {
    message = {
      type = "string",
    }
  },
  constructor = function(params)
    return {
      on_start = function(self, task)
        local msg_id = vim.api.nvim_echo({{params.message}}, true, {
          kind='progress', status='running', title=params.message, source='Job status', percent = nil
        })
      end,
      on_reset = function(self, task)
        local msg_id = vim.api.nvim_echo({{params.message}}, true, {
          kind='progress', status='running', title=params.message, source='Job status', percent = nil
        })
      end,
      on_exit = function(self, task, status)
        vim.api.nvim_echo({{'Done'}}, true, {
          id = msg_id, kind='progress', status=status, source='Job status', title=params.message
        })
      end,
    }
  end,
}
