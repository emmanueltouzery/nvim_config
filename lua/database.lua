function _G.get_dbout_filetype()
  local db_url = vim.tbl_values(vim.g.dbs)[1]
  -- if vim.b.dbui_db_key_name ~= nil then
  --   local dbs_key = vim.b.dbui_db_key_name:gsub("_g:dbs$", "")
  --   db_url = vim.g.dbs[dbs_key]
  -- end
  if db_url:match("^jq:") then
    return "json"
  end
  return "dbout"
end

function _G.get_dbout_win_buf()
  local out_filetype = get_dbout_filetype()

  return get_tab_win_buf_by_ft(out_filetype)
end

function _G.get_tab_win_buf_by_ft(ft)
  for _, w in pairs(vim.api.nvim_list_wins()) do
    local buf = vim.api.nvim_win_get_buf(w)
    if vim.api.nvim_buf_get_option(buf, "ft") == ft then
      return vim.api.nvim_win_get_number(w), buf
    end
  end
end


function _G.open_local_postgres_db(db_name)
  vim.g.dbs = {
    [db_name] = "postgresql://postgres@localhost/" .. db_name
  }
  open_db_common(db_name)
end

function _G.open_json()
  local db_name = vim.fn.expand('%')
  vim.g.dbs = {
    [db_name] = "jq:" .. db_name
  }
  open_db_common(db_name, {'.'})
  vim.defer_fn(function()
      vim.cmd[[resize 20]] -- reduce vertical height, i need height for the output json
  end, 100)
  vim.bo.filetype = 'jq'
  vim.g.db_query_rows_limit = 20000
end

function _G.db_open_csv(csv, custom_query, extra_statements, csv_folder)
  local csv_name = csv or vim.fn.expand('%')
  local sqlite_name = (csv_folder or "") .. csv_name:gsub("%.csv$", ".sqlite")
  local table_name = csv_name:gsub("%.csv$", ""):gsub(" ", "_")

  local csv_mtime = vim.uv.fs_stat(csv_name).mtime.sec
  local sqlite_mtime = 0
  local sqlite_stat = vim.uv.fs_stat(sqlite_name)
  if sqlite_stat == nil or csv_mtime > sqlite_stat.mtime.sec then
    vim.uv.fs_unlink(sqlite_name)
    vim.system({"sqlite3", "-separator", ",", sqlite_name,
    '.import "' .. csv_name .. '" ' .. table_name,
    extra_statements and extra_statements(csv_name) or ""}):wait()
  end
  open_sqlite(sqlite_name, custom_query and custom_query(table_name) or ({"select * from " .. table_name}))
end

function _G.open_sqlite(db_name, initial_query)
  vim.g.dbs = {
    [db_name] = "sqlite:" .. db_name
  }
  open_db_common(db_name, initial_query)
end

function _G.open_adb_sqlite(db_name, flag)
  local url = "adbsqlite:" .. db_name
  if flag ~= nil then
    url = url .. "?adb_flag=" .. flag
  end
  vim.g.dbs = {
    [db_name] = url
  }
  open_db_common(db_name)
end

function _G.open_db_common(db_name, initial_query)
  vim.g.db_query_rows_limit = 10000 -- restore the default, a jq query may have overridden it
  vim.cmd[[tabnew]]
  vim.fn['db_ui#reset_state']()
  vim.b.dbui_db_key_name = db_name .. "_g:dbs"

  pcall(vim.cmd, 'DBUIFindBuffer') -- pcall, for nice error handling if the DB does not exist
  vim.cmd('DBUI')
  -- open the tables list and get back where i was
  vim.cmd('norm jjojjjjokkkkkk')
  -- go three times down and select "new buffer". didn't find a nicer way
  vim.cmd('norm 1G3jo')
  if initial_query ~= nil then
    vim.api.nvim_buf_set_lines(0, 0, 0, false, initial_query)
    vim.cmd[[norm! 1G]]

    -- for some reason for json, for the '.' nop filter saving works but selecting+running with
    -- DBUI_ExecuteQuery doesn't.
    -- vim.cmd[[w]]
    -- vim.cmd[[:normal vip]]
    -- -- https://www.reddit.com/r/neovim/comments/17x8tso/comment/k9moruv/
    local t = function(keycode) return vim.api.nvim_replace_termcodes(keycode, true, false, true) end
    vim.api.nvim_feedkeys(t "<Plug>(DBUI_ExecuteQuery)", 'n', true)
  end
end

local function pick_local_pg_db_and(prompt, cb)
  local db_names = {}
  vim.fn.jobstart({"sh", "-c", "psql -l | grep $(whoami) | awk '{print $1}'"}, {
    on_stdout = vim.schedule_wrap(function (j, output)
      for _, line in ipairs(output) do
        table.insert(db_names, line)
      end
    end),
    on_exit = vim.schedule_wrap(function(j, output)
      vim.ui.select(db_names, {prompt=prompt, kind="center_win"}, function(choice)
        if choice ~= nil then
          cb(choice)
        end
      end)
    end)
  })
end

function _G.pick_local_pg_db()
  pick_local_pg_db_and("Pick the database to open", open_local_postgres_db)
end

function _G.drop_local_pg_db()
  pick_local_pg_db_and("Pick the database to DROP", function(db)
    print("psql -U postgres -c 'drop database " .. db .. "'")
    vim.system({"psql", "-U", "postgres", "-c", "drop database " .. db}, {text = true}, vim.schedule_wrap(function(r)
      notif({r.stdout})
    end))
  end)
end


function _G.open_saved_query()
  local folder = string.gsub(vim.g.db_ui_save_location, '~', vim.loop.os_homedir())
  local sd = vim.loop.fs_scandir(folder)
  local saved_queries = {}
  while true do
    local name, type = vim.loop.fs_scandir_next(sd)
    if name == nil then break end
    if type == 'directory' then
      local nested_path = folder .. "/" .. name
      local nested_sd = vim.loop.fs_scandir(nested_path)
      while true do
        local nested_name, nested_type = vim.loop.fs_scandir_next(nested_sd)
        if nested_name == nil then break end
        table.insert(saved_queries, name .. "/" .. nested_name)
      end
    end
  end

  local pickers = require "telescope.pickers"
  local previewers = require "telescope.previewers"
  local finders = require "telescope.finders"
  local conf = require("telescope.config").values
  local actions = require("telescope.actions")
  local putils = require("telescope.previewers.utils")
  local opts = {}

  pickers.new(opts, {
    prompt_title = "Saved queries",
    finder = finders.new_table {
      results = saved_queries,
      entry_maker = function(val)
        entry = {}
        entry.value = folder .. "/" .. val
        entry.ordinal = val
        entry.display = val
        return entry
      end,
    },
    -- previewer = conf.file_previewer(opts),
    previewer = previewers.new_buffer_previewer {
      title = "Query",

      get_buffer_by_name = function(_, entry)
        return entry.value
      end,

      define_preview = function(self, entry)
        conf.buffer_previewer_maker(entry.value, self.state.bufnr, {
          bufname = self.state.bufname,
          winid = self.state.winid,
          callback = function(bufnr)
            putils.highlighter(bufnr, "sql")
          end,
        })
      end,
    },
    sorter = conf.generic_sorter(opts),
    attach_mappings = function(_, map)
      map('i', '<Cr>',  function(prompt_bufnr)
        local filename = require("telescope.actions.state").get_selected_entry(prompt_bufnr).value
        local Path = require("plenary.path")
        actions.close(prompt_bufnr)
        -- copy to the clipboard
        vim.fn.setreg('+', Path.new(filename):read())
      end)
      map('i', '<C-o>',  function(prompt_bufnr)
        local filename = require("telescope.actions.state").get_selected_entry(prompt_bufnr).value
        local Path = require("plenary.path")
        vim.fn.jobstart({"xdg-open", Path.new(filename):parent().filename})
      end)
      return true
    end,
  }):find()
end


require 'key-menu'.set('n', '<Space>d', {desc='Database'})
vim.keymap.set("n", "<leader>do", ":tabnew | :DBUIToggle<cr>", {desc="Database open"})
vim.keymap.set("n", "<leader>dp", ":lua pick_local_pg_db()<cr>", {desc="open local Postgres Database"})
vim.keymap.set("n", "<leader>dD", ":lua drop_local_pg_db()<cr>", {desc="drop local Postgres Database"})
vim.keymap.set("n", "<leader>ds", ":lua open_saved_query()<cr>", {desc="Database Saved query to clipboard"})
vim.keymap.set("n", "<leader>dj", ":lua open_json()<cr>", {desc="Database open current JSON file"})
vim.keymap.set("n", "<leader>dc", ":lua db_open_csv()<cr>", {desc="Database open current CSV file"})
