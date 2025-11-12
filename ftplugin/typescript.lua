local function extract_type()
  local parser = vim.treesitter.get_parser(0, nil, {error=false})
  if parser == nil then
    return
  end
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
  local parser = vim.treesitter.get_parser(0, nil, {error=false})
  if parser == nil then
    return
  end
  parser:parse()
  local ts_node = parser:named_node_for_range({vim.fn.line('.')-1, vim.fn.col('.')-1, vim.fn.line('.')-1, vim.fn.col('.')-1})
  if ts_node:type() == "formal_parameters" or ts_node:type() == "arguments" then
    -- the cursor is on an indentation space outside of the main parameter.
    -- just move to the next word and re-trigger
    vim.cmd("norm! w")
    ts_node = parser:named_node_for_range({vim.fn.line('.')-1, vim.fn.col('.')-1, vim.fn.line('.')-1, vim.fn.col('.')-1})
  end
  local parent = ts_node
  local required_param = nil
  local is_final_selector = nil
  local param_idx = nil
  while parent do
    if parent:type() == "call_expression" then
      local fn_identifier = vim.treesitter.get_node_text(parent:named_child(0), 0)
      if fn_identifier == "createSelector" then
        break
      end
    elseif parent:type() == "required_parameter" then
      required_param = parent
    elseif parent:type() == "arrow_function" then
      -- were we in the injected params or the params of the final selector?
      is_final_selector = parent:next_named_sibling() == nil
      if not is_final_selector then
        local cur_param = parent
        param_idx = 1
        while cur_param ~= nil do
          cur_param = cur_param:prev_named_sibling()
          if cur_param ~= nil and cur_param:type() == "arrow_function" then
            param_idx = param_idx + 1
          end
        end
        print("Param index is " .. param_idx)
      end
    end
    local p = parent:parent()
    parent = p
  end
  local fn_identifier = vim.treesitter.get_node_text(parent:named_child(0), 0)
  if fn_identifier ~= "createSelector" then
    notif({"Not a redux selector param"})
    return
  end
  if is_final_selector then
    -- which param index are we?
    local cur_param = required_param
    local param_idx = 1
    while cur_param ~= nil do
      cur_param = cur_param:prev_named_sibling()
      if cur_param ~= nil and cur_param:type() == "required_parameter" then
        param_idx = param_idx + 1
      end
    end
    print("Param index is " .. param_idx)

    -- go to target
    -- i would like to say named_child(param_idx) but for instance
    -- if there are comments, they are named nodes too and will
    -- shift parameters. rather count the nodes of the arrow_function type.
    local target = parent:named_child(1):named_child(0)
    local i = 0
    while i < param_idx do
      -- print("target => " .. vim.treesitter.get_node_text(target, 0))
      if target:type() == "arrow_function" then
        i = i + 1
      end
      -- print("final target => " .. vim.treesitter.get_node_text(target, 0))
      target = target:next_named_sibling()
    end
    local start_row, _, _, _ = target:range(target)
    vim.cmd("normal! m'") -- add to jump list
    vim.cmd(":" .. start_row)
  else
    -- go to target
    local params = parent:named_child(1)
    local selector_callback = params:named_child(params:named_child_count()-1)
    -- i would like to say named_child(param_idx) but for instance
    -- if there are comments, they are named nodes too and will
    -- shift parameters. rather count the nodes of the arrow_function type.
    local target = selector_callback:named_child(0):named_child(0)
    local i = 0
    while i < param_idx-1 do
      if target:type() == "required_parameter" then
        i = i + 1
      end
      target = target:next_named_sibling()
    end

    local start_row, _, _, _ = target:range()
    vim.cmd("normal! m'") -- add to jump list
    vim.cmd(":" .. (start_row + 1))
  end
end

vim.keymap.set('n', '<localleader>jp', jump_param, { buffer = true, desc = "redux selector jump to matching param"})

-- see elixir_insert_inspect_param
local function typescript_insert_inspect_param()
  winid = vim.api.nvim_get_current_win()
  local cur_line = vim.fn.line('.')
  local cur_col = vim.fn.col('.')
  local param_name = vim.fn.expand("<cword>")
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
      vim.cmd('norm! aconsole.log(`' .. param_name .. ': ${JSON.stringify(' .. param_name .. ', null, 2)}`)')
      -- position the cursor in the quotes to enable quick rename
      vim.cmd('norm! 0')
      vim.cmd('norm! 13l')
      vim.cmd('startinsert')
    end
  }
end
vim.keymap.set('n', '<localleader>ip', typescript_insert_inspect_param, { buffer = true, desc = "console inspect parameter"})

-- see  elixir_insert_inspect_label
local function typescript_insert_inspect_label()
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
      vim.cmd("norm! aconsole.log('');")
      -- position the cursor in the quotes to enable quick rename
      vim.cmd('norm! 2h')
      vim.cmd('startinsert')
    end
  }
end

vim.keymap.set('n', '<localleader>il', typescript_insert_inspect_label, {desc="add inspect label", buffer = true})
