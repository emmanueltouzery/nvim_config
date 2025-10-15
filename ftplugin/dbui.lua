local function jump_to_dbout()
  local dbout_win, dbout_buf = get_dbout_win_buf()
  vim.cmd(dbout_win .. ' wincmd w')
end
vim.keymap.set("n", "<leader>q", jump_to_dbout, {buffer = true, desc="Jump to the sql output window"})

local function open_table_def()
  local line_drawer_info = vim.fn['db_ui#drawer#get']().content[vim.fn.line('.')]
  local schema, table_name = string.match(line_drawer_info.type, "([%w_]+)%->tables%->items%->([%w_]+)$")
  if table_name then
    local cols_query = vim.tbl_values(vim.fn['db_ui#drawer#get']().dbui.dbs)[1].table_helpers.Columns
      :gsub("{table}", table_name):gsub("{schema}", schema)

    local url = vim.tbl_values(vim.fn['db_ui#drawer#get']().dbui.dbs)[1].url 

    if vim.startswith(url, "postgresql://") then
      cols_query = cols_query:gsub("%*", "column_name, column_default, is_nullable, data_type, character_maximum_length")

      local db_name = vim.tbl_values(vim.fn['db_ui#drawer#get']().dbui.dbs)[1].db_name

      -- trying to run the query through dadbod lead nowhere. it's just not extensible..
      -- vim.cmd("topleft DB " .. vim.tbl_values(vim.fn['db_ui#drawer#get']().dbui.dbs)[1].url .. " " .. cols_query)

      vim.system({
        "psql", "-d", db_name, "-c", cols_query
      }, {text=true}, vim.schedule_wrap(function(res)
        local records = vim.split(res.stdout, "\n")

        local max_length = 0
        for _, rec in ipairs(records) do
          if vim.api.nvim_strwidth(rec) > max_length then
            max_length = vim.api.nvim_strwidth(rec)
          end
        end
        print(max_length)

        local popup_buf = vim.api.nvim_create_buf(false, true)
        local width = max_length -- vim.o.columns-6
        local height = #records -- vim.o.lines-6
        local win_opts = {
          focusable = false,
          style = "minimal",
          border = "rounded",
          relative = "editor",
          width = width,
          height = height,
          anchor = "NW",
          row = req_row or 3,
          col = req_col or 3,
          noautocmd = true,
        }
        local popup_win = vim.api.nvim_open_win(popup_buf, true, win_opts)
        vim.keymap.set("n", "q", function()
          vim.api.nvim_win_close(vim.api.nvim_get_current_win(), false)
        end, {buffer = true, desc="Close"})

        vim.api.nvim_buf_set_lines(popup_buf, 0, -1, false, {table_name, ""})
        vim.api.nvim_buf_set_lines(popup_buf, 2, -1, false, records)

        require("zebrazone").start()
      end))
    else
      print("Unsupported DB")
    end
  end
end
vim.keymap.set("n", "<tab>", open_table_def, {buffer = true, desc="Open table definition"})
