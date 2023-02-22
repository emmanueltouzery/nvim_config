local constants = require("overseer.constants")
local STATUS = constants.STATUS

return {
  desc = "notif when test is started",
  params = { },
  constructor = function(params)
    return {
      on_start = function(self, task)
        notif({ "Test started!" }, vim.log.levels.INFO)
        overseer_follow_test()
      end,
      on_complete = function(self, task, status)
        -- if status == 'SUCCESS' then
          if vim.g.neotest_output_winnr ~= nil then
            vim.api.nvim_win_close(vim.g.neotest_output_winnr, false)
            vim.g.neotest_output_winnr = nil
          end
        -- end
      end,
    }
  end,
}
