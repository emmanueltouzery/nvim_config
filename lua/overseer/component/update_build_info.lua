return {
  desc = "update build info",
  params = { },
  constructor = function(params)
    return {
      on_start = function(self, task)
        vim.g.build_info = " Build ongoing"
      end,
      on_reset = function(self, task)
        vim.g.build_info = " Build ongoing"
      end,
      on_exit = function(self, task, status)
        vim.g.build_info = ""
      end,
    }
  end,
}
