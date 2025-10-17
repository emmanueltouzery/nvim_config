local function jump_to_dbout()
  local dbout_win, dbout_buf = get_dbout_win_buf()
  vim.cmd(dbout_win .. ' wincmd w')
end
vim.keymap.set("n", "<leader>q", jump_to_dbout, {buffer = true, desc="Jump to the sql output window"})

local function open_query_in_popup(db_name, title, query)
  vim.system({
    "psql", "-d", db_name, "-c", query
  }, {text=true}, vim.schedule_wrap(function(res)
    local records = vim.split(res.stdout, "\n")

    local max_length = 1
    for _, rec in ipairs(records) do
      if vim.api.nvim_strwidth(rec) > max_length then
        max_length = vim.api.nvim_strwidth(rec)
      end
    end

    local popup_buf = vim.api.nvim_create_buf(false, true)
    if max_length > vim.o.columns-6 then
      max_length = vim.o.columns - 6
    end
    local width = max_length
    local height = #records
    if height > vim.o.lines-6 then
      height = vim.o.lines-6
    end

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

    vim.api.nvim_buf_set_lines(popup_buf, 0, -1, false, {title, ""})
    vim.api.nvim_buf_set_lines(popup_buf, 2, -1, false, records)

    require("zebrazone").start()
  end))
end

local function open_table_def()
  local line_drawer_info = vim.fn['db_ui#drawer#get']().content[vim.fn.line('.')]
  local url = vim.tbl_values(vim.fn['db_ui#drawer#get']().dbui.dbs)[1].url 

  if not vim.startswith(url, "postgresql://") then
    print("Unsupported DB")
  end

  local db_name = vim.tbl_values(vim.fn['db_ui#drawer#get']().dbui.dbs)[1].db_name

  local schema, table_name = string.match(line_drawer_info.type, "([%w_]+)%->tables%->items%->([%w_]+)$")
  if table_name then
    local cols_query = vim.tbl_values(vim.fn['db_ui#drawer#get']().dbui.dbs)[1].table_helpers.Columns
    :gsub("{table}", table_name):gsub("{schema}", schema)


    cols_query = cols_query:gsub("%*", "column_name, column_default, is_nullable, data_type, character_maximum_length")

    -- trying to run the query through dadbod lead nowhere. it's just not extensible..
    -- vim.cmd("topleft DB " .. vim.tbl_values(vim.fn['db_ui#drawer#get']().dbui.dbs)[1].url .. " " .. cols_query)

    open_query_in_popup(db_name, table_name, cols_query)
  elseif line_drawer_info.type == "table" and line_drawer_info.action == "open" then
    local query = line_drawer_info.content
    :gsub("{table}", line_drawer_info.table)
    :gsub("{optional_schema}", line_drawer_info.schema .. ".")
    :gsub("{schema}", line_drawer_info.schema) .. ";"
    copy_to_clipboard(query)
    open_query_in_popup(db_name, line_drawer_info.table, query)
    notif({"Copied query to clipboard", query}, vim.log.levels.INFO)
  end
end
vim.keymap.set("n", "<tab>", open_table_def, {buffer = true, desc="Apply DB action in popup"})
