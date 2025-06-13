local function extract_type()
  local parser = require('nvim-treesitter.parsers').get_parser(0)
  parser:parse()
  local ts_node = parser:named_node_for_range({vim.fn.line('.')-1, vim.fn.col('.')-1, vim.fn.line('.')-1, vim.fn.col('.')-1})
  local parent = ts_node
  while parent do
    local p = parent:parent()
    if p == nil or p:type() == 'program' or p:type() == 'lexical_declaration' or p:type() == 'statement_block' or p:type() == 'required_parameter' then
      goto done
    end
    parent = p
  end
  ::done::
  if parent then
    if parent:parent() and parent:parent():type() == 'required_parameter' then
      -- this is a function parameter

      -- find the parameter index
      local param = parent:parent()
      local param_index = 0
      while param do
        param = param:prev_named_sibling()
        if param then
          local param_name = vim.treesitter.get_node_text(param:named_child('pattern'), 0)
          if param_name ~= 'this' then
            -- don't count the special fake parameter type annotation 'this'
            -- https://www.typescriptlang.org/docs/handbook/2/classes.html#this-parameters
            param_index = param_index + 1
          end
        end
      end

      -- find the function start location
      local row_node = parent
      while row_node do
        local p = row_node:parent()
        if p == nil or p:type() == 'program' or p:type() == 'lexical_declaration' then
          goto done
        end
        row_node = p
      end
      ::done::

      local declaration = "type T = Parameters<typeof " .. require'aerial'.get_location()[1].name .. ">[" .. param_index .. "]"

      -- is this by any chance an object pattern matching?
      -- function({field1, field2})
      if parent:type() == 'object_pattern' then
        declaration = declaration .. "['" .. vim.fn.expand('<cword>') .. "']"
      end

      local row = row_node:start()
      vim.api.nvim_buf_set_lines(0, row, row, false, {declaration .. ";"})
      vim.api.nvim_win_set_cursor(0, {row+1, 5}) -- 5="type >T<"
    else
      -- normal variable
      local row = parent:start()
      vim.api.nvim_buf_set_lines(0, row, row, false, {"type T = typeof " .. vim.fn.expand('<cword>') .. ";"})
      vim.api.nvim_win_set_cursor(0, {row+1, 5}) -- 5="type >T<"
    end
  end
end

-- tool for exploratory type programming. Extract a type T that can be explored with the LSP hover, K
vim.keymap.set('n', '<localleader>t', extract_type, { buffer = true, desc = "Extract type for K exploration" })

local function jump_param()
  local parser = require('nvim-treesitter.parsers').get_parser(0)
  parser:parse()
  local ts_node = parser:named_node_for_range({vim.fn.line('.')-1, vim.fn.col('.')-1, vim.fn.line('.')-1, vim.fn.col('.')-1})
  local parent = ts_node
  local required_param = nil
  local is_final_selector = nil
  local param_idx = nil
  while parent do
    if parent:type() == "call_expression" then
      break
    elseif parent:type() == "required_parameter" then
      required_param = parent
    elseif parent:type() == "arrow_function" then
      -- were we in the injected params or the params of the final selector?
      is_final_selector = parent:next_named_sibling() == nil
      if not is_final_selector then
        local cur_param = parent:prev_named_sibling()
        param_idx = 1
        while cur_param ~= nil do
          cur_param = cur_param:prev_named_sibling()
          param_idx = param_idx + 1
        end
        print("Param index is " .. param_idx)
      end
    end
    local p = parent:parent()
    parent = p
  end
  local fn_identifier = vim.treesitter.get_node_text(parent:named_child(0), 0)
  if fn_identifier == "createSelector" then
  else
    notif({"Not a redux selector param"})
  end
  if is_final_selector then
    -- which param index are we?
    local cur_param = required_param:prev_named_sibling()
    local param_idx = 1
    while cur_param ~= nil do
      cur_param = cur_param:prev_named_sibling()
      param_idx = param_idx + 1
    end
    print("Param index is " .. param_idx)

    -- go to target
    -- i would like to say named_child(param_idx) but for instance
    -- if there are comments, they are named nodes too and will
    -- shift parameters. rather count the nodes of the arrow_function type.
    local target = parent:named_child(1):named_child(0)
    local i = 0
    while i < param_idx do
      if target:type() == "arrow_function" then
        i = i + 1
      end
      target = target:next_named_sibling()
    end
    local start_row, _, _, _ = target:range(target)
    vim.cmd("normal! m'") -- add to jump list
    vim.cmd(":" .. start_row)
  else
    -- go to target
    local params = parent:named_child(1)
    local selector_callback = params:named_child(params:named_child_count()-1)
    print(selector_callback:type())
    print(selector_callback:named_child(0):type())
    -- TODO could be comments or other nodes. should make a loop
    -- like with the other go to target
    local param = selector_callback:named_child(0):named_child(param_idx)
    local start_row, _, _, _ = param:range()
    vim.cmd("normal! m'") -- add to jump list
    vim.cmd(":" .. start_row)
  end
end

vim.keymap.set('n', '<localleader>jp', jump_param, { buffer = true, desc = "redux selector jump to matching param"})
