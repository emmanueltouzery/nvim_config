vim.keymap.set('n', '<localleader>g', ':normal vip<CR><PLUG>(DBUI_ExecuteQuery)', { buffer = true, desc = "run query under cursor (mnemonic: Go)" })

local function trigger_query_selected()
  -- https://www.reddit.com/r/neovim/comments/17x8tso/comment/k9moruv/
  local t = function(keycode) return vim.api.nvim_replace_termcodes(keycode, true, false, true) end
  vim.api.nvim_feedkeys(t "<Plug>(DBUI_ExecuteQuery)", 'n', true)
end

-- temporary, just for this query
local function toggle_expanded_results_display()
  local dbout_win, dbout_buf = get_dbout_win_buf()
  vim.api.nvim_buf_call(dbout_buf, function()
    vim.fn['db_ui#dbout#toggle_layout']()
  end)
end
vim.keymap.set('n', '<localleader>X', toggle_expanded_results_display, { buffer = true, desc = "Toggle expanded results display" })

-- write in the SQL, will stay
function toggle_expanded_results_marker()
  local marker = '\\x'
  if vim.b.db:match("sqlite") then
    marker = '.mode line'
  end

  local curline = vim.fn.line('.')
  local buffer_lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
  -- find paragraph start (which may be the buffer start)
  while curline > 0 and buffer_lines[curline] ~= '' do
    curline = curline - 1
  end
  if buffer_lines[curline+1] == marker then
    vim.api.nvim_buf_set_lines(0, curline, curline+1, false, {})
  else
    vim.api.nvim_buf_set_lines(0, curline, curline, false, {marker})
  end
  -- re-run the query
  vim.cmd[[:normal vip]]
  trigger_query_selected()
end
vim.keymap.set('n', '<localleader>x', toggle_expanded_results_marker, { buffer = true, desc = "Toggle expanded results marker" })

vim.keymap.set('v', '<localleader>g', trigger_query_selected, { buffer = true, desc = "Trigger query for selected text" })
vim.keymap.set('v', '<localleader>G', function()
  trigger_query_selected()
  vim.defer_fn(function()
    vim.api.nvim_feedkeys("gv", "n", false) -- reselect
  end, 50)
end, { buffer = true, desc = "Trigger query for selected text, keeping the selection" })

local function jump_to_dbout()
  local dbout_win, dbout_buf = get_dbout_win_buf()
  vim.cmd(dbout_win .. ' wincmd w')
end
vim.keymap.set("n", "<leader>q", jump_to_dbout, {buffer = true, desc="Jump to the sql output window"})

local function insert_statement_separators()
  -- find blocks without trailing semicolons
  local buffer_lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
  local block_ok = nil
  local lines_to_add_semis = {}
  for lnum, line in ipairs(buffer_lines) do
    if block_ok == nil and #line > 0 then
      -- entering a block
      block_ok = false
    elseif block_ok == false and line == ";" then
      -- the block contains a pure ";" line
      block_ok = true
    elseif #line == 0 then
      -- end of the block

      -- we should schedule to add a ~ at this line?
      if not block_ok then
        table.insert(lines_to_add_semis, lnum + #lines_to_add_semis - 1)
      end
      block_ok = nil
    end
  end
  if not block_ok then
    table.insert(lines_to_add_semis, #buffer_lines + #lines_to_add_semis)
  end

  -- add trailing semicolons whereever they're missing
  for _, lnum in ipairs(lines_to_add_semis) do
    vim.api.nvim_buf_set_lines(0, lnum, lnum, false, {";"})
  end
end
vim.keymap.set("n", '<localleader>s', insert_statement_separators, {buffer = true, desc="Insert sql statement Separators (;)"})

-- the idea is to add command separators ";" automagically.
-- don't do anything if there is already a ";" separator after my
-- current line and without blank lines to it, i'm editing a single command.
-- else rebalance separators.
vim.keymap.set('n', 'o', function()
  local current_line = vim.api.nvim_win_get_cursor(0)[1]
  local has_semicolon_under = false
  local lines_below = vim.api.nvim_buf_get_lines(0, current_line, -1, false)

  if #lines_below == 0 then
    -- last line
    local cur_line_contents = vim.api.nvim_buf_get_lines(0, current_line-1, current_line, false)[1]
    if string.match(cur_line_contents, ";") then
      -- end of the last statement.
      -- add a new statement after this one (after the ; on the current line)
      vim.api.nvim_buf_set_lines(0, current_line, current_line, false, {";"})
      vim.cmd('normal! 2o')
      vim.cmd('startinsert')
    else
      -- non-concluded last statement.
      -- end this statement and add a new line to it (before the ; we add)
      vim.api.nvim_buf_set_lines(0, current_line, current_line, false, {";"})
      vim.cmd('normal! o')
      vim.cmd('startinsert')
    end
    return
  end

  for _, line in ipairs(lines_below) do
    if #vim.trim(line) == 0 then
      -- stop at the first blank line
      break
    end
    if line:find(';') then
      has_semicolon_under = true
      break
    end
  end
  if has_semicolon_under then
    -- don't do anything special
    vim.cmd('normal! o')
  else
    -- rebalance separators
    vim.cmd('normal! o')
    insert_statement_separators()
    vim.cmd('normal! o')
  end
  vim.cmd('startinsert')
end, { buffer = true, desc = "Open line below and insert separators" })

require 'key-menu'.set('n', '<localleader>w', {desc='Wrap field in function', buffer = true})

-- ge Backward to end of previous word
-- w next word
-- (gew makes sure we're at the start of the word whether we were in or just before the word)
-- You Surround A Word with (
--b backward
-- insert
vim.keymap.set("n", '<localleader>wj', [[:normal gewysaw(bijsonb_pretty<cr>]], {buffer = true, desc="Wrap in jsonb_pretty"})

-- start similar to -j. wrap in two levels of brackets, use % to switch to the other bracket, esc to exit insert mode
vim.keymap.set("n", '<localleader>wa', [[:normal gewysaw(ysaw(biarray_to_json<esc>bbijsonb_pretty<esc>%hi::jsonb<esc>]], {buffer = true, desc="Pretty display for array"})
vim.keymap.set("n", '<localleader>wA', [[:normal gewysaw(ysaw(biarray_to_json<esc>bbijsonb_pretty<esc>%i::jsonb<esc>]], {buffer = true, desc="Pretty display for json array"})

vim.keymap.set("n", '<localleader>wc', [[:normal gewysaw(bicount<cr>]], {buffer = true, desc="Wrap in count"})

local function run_sql(q)
  local db = vim.b.db or vim.g.db
  if not db and vim.b.dbui_db_key_name then
    db = vim.fn['db_ui#get_conn_info'](vim.b.dbui_db_key_name).url
  end
  if type(db) ~= "string" or db == "" then return print("No DB connection found") end

  local url = vim.fn['db#resolve'](db)
  local res = vim.fn.system({ 'psql', url, '-tAc', q })

  if vim.v.shell_error == 0 then
    return res
  else
    print("Failed: " .. vim.trim(res))
  end
end

local function insert_cols(tbl, alias)
  local q = ("SELECT string_agg('%s' || quote_ident(column_name) || ' as ' || quote_ident('%s' || column_name), ',|' ORDER BY ordinal_position) FROM information_schema.columns WHERE table_name = '%s';")
     :format(alias and alias .. "." or '', alias and alias .. '_' or '', tbl)
  local cols = run_sql(q)

  if cols then
    local lines = vim.split(vim.trim(cols), "|")
    table.insert(lines, "") -- add trailing newline
    vim.api.nvim_put(lines, 'c', true, true)
  end
end

local function get_sql_tables(bufnr)
  bufnr = bufnr or 0
  local parser = vim.treesitter.get_parser(bufnr, "sql")
  if not parser then return {} end

  local query = vim.treesitter.query.parse("sql", [[
    (relation
      (object_reference
        name: (identifier) @table)
      alias: (identifier)? @alias)
  ]])

  local tree = parser:parse()[1]

  local results = {}
  for _, match in query:iter_matches(tree:root(), bufnr) do
    local entry = {}
    for id, nodes in pairs(match) do
      local name = query.captures[id]
      local node = type(nodes) == "table" and nodes[1] or nodes
      entry[name] = vim.treesitter.get_node_text(node, bufnr)
    end
    if entry.table then
      table.insert(results, entry)
    end
  end

  return results
end

local function insert_table_cols()
  vim.ui.select(vim.tbl_map(function(e) return e.alias and string.format("%s %s", e.table, e.alias) or e.table end, get_sql_tables(0)), {prompt="Insert column names: pick table"}, function(choice)
    if choice ~= nil then
      local tbl, alias = unpack(vim.split(choice, " "))
      insert_cols(tbl, alias)
    end
  end)
end

vim.keymap.set("n", '<localleader>c', insert_table_cols, {buffer = true, desc="Insert table columns in query"})
