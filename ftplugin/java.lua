-- check for String.format invocations.

local namespace = vim.api.nvim_create_namespace("string_format_checker")

local function check_string_format(bufnr)
  -- Clear previous format errors for this buffer
  vim.diagnostic.set(namespace, bufnr, {})

  -- 1. Get the Java Tree-sitter parser and tree
  local parser = vim.treesitter.get_parser(bufnr, "java")
  if not parser then return end
  local tree = parser:parse()[1]
  local root = tree:root()

  -- 2. Define your Tree-sitter query to find String.format calls
  -- (Adjust this query to target the exact nodes you want)
  local query_string = [[
    (method_invocation
      object: (identifier) @obj (#eq? @obj "String")
      name: (identifier) @method (#eq? @method "format")
      arguments: (argument_list) @args)
  ]]
  local query = vim.treesitter.query.parse("java", query_string)

  local diagnostics = {}

  -- 3. Iterate through matches
  for id, node, metadata in query:iter_captures(root, bufnr, 0, -1) do
    if query.captures[id] == "args" then
      local total_params = node:named_child_count()
      if total_params > 0 then
        local first_param_node = node:named_child(0)
        local first_param_text = vim.treesitter.get_node_text(first_param_node, bufnr)

        -- 1. Ensure it's actually a string literal (starts and ends with quotes)
        if first_param_text:sub(1, 1) == '"' and first_param_text:sub(-1, -1) == '"' then

          -- 2. Remove all escaped percentages "%%" 
          -- (We use '%%' in Lua patterns because % is the escape character)
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

  -- 4. Set the diagnostics to make them visible in the UI
  vim.diagnostic.set(namespace, bufnr, diagnostics)
end

-- 5. Plug it into the save event
vim.api.nvim_create_autocmd("BufWritePost", {
  pattern = "*.java",
  callback = function(args)
    check_string_format(args.buf)
  end,
})
