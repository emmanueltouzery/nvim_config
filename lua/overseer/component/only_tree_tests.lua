-- https://github.com/stevearc/overseer.nvim/blob/master/doc/guides.md#custom-components
return {
  desc = "only_tree_tests",
  params = { },
  constructor = function(params)
    return {
      on_exit = function(self, task, status)
        local overseer = require('overseer')
        local tasks = overseer.list_tasks({ recent_first = true })
        local test_jobs = 0
        for _, task in ipairs(tasks) do
          if task.metadata and task.metadata.type == "test" then
            test_jobs = test_jobs + 1
            if test_jobs > 3 then
              task:dispose(true)
            end
          end
        end
      end,
    }
  end,
}
