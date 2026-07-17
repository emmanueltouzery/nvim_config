-- START check for String.format invocations.

local namespace = vim.api.nvim_create_namespace("string_format_checker")

local function check_string_format(bufnr)
  -- Clear previous format errors for this buffer
  vim.diagnostic.set(namespace, bufnr, {})

  local parser = vim.treesitter.get_parser(bufnr, "java")
  if not parser then return end
  local tree = parser:parse()[1]
  local root = tree:root()

  local query_string = [[
    (method_invocation
      object: (identifier) @obj (#eq? @obj "String")
      name: (identifier) @method (#eq? @method "format")
      arguments: (argument_list) @args)
  ]]
  local query = vim.treesitter.query.parse("java", query_string)

  local diagnostics = {}

  for id, node, metadata in query:iter_captures(root, bufnr, 0, -1) do
    if query.captures[id] == "args" then
      local total_params = node:named_child_count()
      if total_params > 0 then
        local first_param_node = node:named_child(0)
        local first_param_text = vim.treesitter.get_node_text(first_param_node, bufnr)

        -- 1. Ensure it's actually a string literal (starts and ends with quotes)
        if first_param_text:sub(1, 1) == '"' and first_param_text:sub(-1, -1) == '"' then

          -- 2. Remove all escaped percentages "%%" 
          local sanitized_string = first_param_text:gsub("%%%%", "")

          -- 3. Count the remaining single '%' characters
          local _, specifier_count = sanitized_string:gsub("%%", "")

          -- Get row/col for placing diagnostics later
          local start_row, start_col, end_row, end_col = node:range()

          if specifier_count ~= total_params -1 then
            table.insert(diagnostics, {
              bufnr = bufnr,
              lnum = start_row,
              col = start_col,
              end_lnum = end_row,
              end_col = end_col,
              severity = vim.diagnostic.severity.ERROR,
              message = string.format("String.format argument count mismatch! %d != %d", specifier_count, total_params-1),
              source = "java ftplugin validation",
            })
          end
        end
      end
    end
  end

  -- Set the diagnostics to make them visible in the UI
  vim.diagnostic.set(namespace, bufnr, diagnostics)
end

-- Plug it into the save event
vim.api.nvim_create_autocmd("BufWritePost", {
  pattern = "*.java",
  callback = function(args)
    check_string_format(args.buf)
  end,
})

-- END check for String.format invocations.

-- see elixir_insert_inspect_param
local function java_insert_inspect_param(v)
  winid = vim.api.nvim_get_current_win()
  local cur_line = vim.fn.line('.')
  local cur_col = vim.fn.col('.')
  local param_name = v or vim.fn.expand("<cword>")
  local cur_line_str = vim.api.nvim_buf_get_lines(0, cur_line-1, cur_line, false)[1]
  local is_function_name = string.match(cur_line_str, "^%s*def%s+" .. param_name .. "%(")
  require('leap').leap {
    target_windows = { winid },
    targets = inspect_point_candidate_param(winid),
    action = function(target)
      vim.api.nvim_win_set_cursor(0, target.pos)
      if target.pos[2] == 1 then
        -- setting 'set paste' to fix an issue where the first line of the function
        -- is a comment, and without the set paste, here vim would insert a new
        -- COMMENTED line.
        -- https://superuser.com/a/963068/214371
        vim.cmd[[set paste]]
        vim.cmd("norm! O")
        vim.cmd[[set nopaste]]
      end
      vim.cmd('norm! aLog.i(TAG, "' .. param_name .. ' :" + ' .. param_name .. ');')
      -- position the cursor in the quotes to enable quick rename
      vim.cmd('norm! 0')
      vim.cmd('norm! 25l')
      vim.cmd('startinsert')
    end
  }
end
vim.keymap.set('n', '<localleader>ip', java_insert_inspect_param, { buffer = true, desc = "log variable value"})

vim.keymap.set('v', '<localleader>ip', function()
  local txt = get_visual_selection()
  -- Exit visual mode back to normal mode
  vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Esc>", true, false, true), "x", true)
  java_insert_inspect_param(txt)
end, { buffer = true, desc = "log selection value"})

local function java_insert_inspect_label()
  winid = vim.api.nvim_get_current_win()
  local cur_line = vim.fn.line('.')
  local cur_col = vim.fn.col('.')
  local cur_line_str = vim.api.nvim_buf_get_lines(0, cur_line-1, cur_line, false)[1]
  require('leap').leap {
    target_windows = { winid },
    targets = inspect_point_candidate_label(winid),
    action = function(target)
      vim.api.nvim_win_set_cursor(0, target.pos)
      if target.pos[2] == 1 then
        -- setting 'set paste' to fix an issue where the first line of the function
        -- is a comment, and without the set paste, here vim would insert a new
        -- COMMENTED line.
        -- https://superuser.com/a/963068/214371
        vim.cmd[[set paste]]
        vim.cmd("norm! O")
        vim.cmd[[set nopaste]]
      end
      vim.cmd('norm! aLog.i(TAG, "");')
      -- position the cursor in the quotes to enable quick rename
      vim.cmd('norm! 2h')
      vim.cmd('startinsert')
    end
  }
end
vim.keymap.set('n', '<localleader>il', java_insert_inspect_label, {desc="java add log label", buffer = true})
