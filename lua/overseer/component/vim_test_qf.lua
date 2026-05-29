-- https://github.com/stevearc/overseer.nvim/blob/master/doc/guides.md#custom-components
return {
  desc = "vim-test-qf",
  params = { },
  constructor = function(params)
    return {

      on_init = function(self, task)
        vim.fn.setqflist({})
      end,

      on_output_lines = function(self, task, lines)
        if vim.startswith(task.cmd, "mix ") then
          -- for now tested with elixir only
          for _, line in ipairs(lines) do
            local filename, line_num = string.match(line, "([%w-_./]+):(%d+): %(test%)")
            if filename and line_num then
              vim.fn.setqflist({{filename = filename, lnum = line_num, col = 1, type = 'E'}}, 'a')
            end
          end
        end
      end,
    }
  end,
}
