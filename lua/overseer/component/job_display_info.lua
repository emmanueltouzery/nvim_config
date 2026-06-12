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
        vim.g.job_info = params.message
      end,
      on_reset = function(self, task)
        vim.g.job_info = params.message
      end,
      on_exit = function(self, task, status)
        vim.g.job_info = ""
      end,
    }
  end,
}
