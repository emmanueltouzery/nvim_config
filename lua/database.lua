function _G.open_local_postgres_db(db_name)
  vim.g.dbs = {
    [db_name] = "postgresql://postgres@localhost/" .. db_name
  }
  vim.cmd[[tabnew]]
  vim.fn['db_ui#reset_state']()
  vim.b.dbui_db_key_name = db_name .. "_g:dbs"
  vim.cmd[[DBUIFindBuffer]]
  vim.cmd('DBUI')
  -- open the tables list and get back where i was
  vim.cmd('norm jjojjjjokkkkkk')
  -- go twice up and select "new buffer". didn't find a nicer way
  vim.cmd('norm kko')
end

function _G.pick_local_pg_db()
  local db_names = {}
  vim.fn.jobstart({"sh", "-c", "psql -l | grep $(whoami) | awk '{print $1}'"}, {
    on_stdout = vim.schedule_wrap(function (j, output)
      for _, line in ipairs(output) do
        table.insert(db_names, line)
      end
    end),
    on_exit = vim.schedule_wrap(function(j, output)
      vim.ui.select(db_names, {prompt="Pick the database to open", kind="center_win"}, function(choice)
        if choice ~= nil then
          open_local_postgres_db(choice)
        end
      end)
    end)
  })
end

require 'key-menu'.set('n', '<Space>d', {desc='Database'})
vim.keymap.set("n", "<leader>do", ":tabnew | :DBUIToggle<cr>", {desc="Database open"})
vim.keymap.set("n", "<leader>dp", ":lua pick_local_pg_db()<cr>", {desc="open local Postgres Database"})
