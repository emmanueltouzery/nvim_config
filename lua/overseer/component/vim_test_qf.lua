-- https://github.com/stevearc/overseer.nvim/blob/master/doc/guides.md#custom-components
return {
  desc = "vim-test-qf",
  params = { },
  constructor = function(params)
    return {

      on_init = function(self, task)
        vim.fn.setqflist({})
        if not vim.g.hide_test_output then
          task:subscribe("on_start", function()
            local task_bufnr = task:get_bufnr()
            if vim.g.tests_winnr ~= nil and vim.api.nvim_win_is_valid(vim.g.tests_winnr) then
              vim.api.nvim_win_set_buf(vim.g.tests_winnr, task_bufnr)
            else
              vim.cmd("botright 20split")
              vim.g.tests_winnr = vim.api.nvim_get_current_win()
              vim.api.nvim_win_set_buf(0, task_bufnr)
              vim.cmd[[norm! G]] -- scroll to end
              vim.cmd("wincmd p") -- go back to the previous window
            end
          end)
        end
      end,

      on_output_lines = function(self, task, lines)
        -- for now implemented with elixir only
        if vim.startswith(task.cmd, "mix ") then
          local previous_is_stacktrace = false
          for _, line in ipairs(lines) do
            -- test error
            local filename, line_num = string.match(line, "([%w-_./]+):(%d+): %(test%)")
            if filename and line_num then
              vim.fn.setqflist({{filename = filename, lnum = line_num, col = 1, type = 'E'}}, 'a')
            end

            -- runtime error
            if previous_is_stacktrace then
              local filename, line_num = string.match(line, "%([^)]+%)[ \t]+([%w-_./]+):(%d+):")
              if filename and line_num then
                vim.fn.setqflist({{filename = filename, lnum = line_num, col = 1, type = 'E'}}, 'a')
              end
            end

            -- build error
            local filename, line_num = string.match(line, "└─ ([%w-_./]+):(%d+):")
            if filename and line_num then
              vim.fn.setqflist({{filename = filename, lnum = line_num, col = 1, type = 'E'}}, 'a')
            end

            previous_is_stacktrace = string.match(line, "^[ \t]+stacktrace:$")
          end
        end
      end,
    }
  end,
}
