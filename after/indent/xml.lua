local function get_node_elt(node, this_line_only)
  local start_line, _, _, _ = node:range()
  while node:parent():type() ~= "element" and node:type() ~= "Comment" do
    if this_line_only then
      local cur_start_line, _, _, _ = node:parent():range()
      if cur_start_line ~= start_line then
        return node
      end
    end
    node = node:parent()
  end
  return node
end

local function xml_indent_offset_for_lnum(parser, lnum, mode, nodes_on_line_previous)
  local line_contents = vim.api.nvim_buf_get_lines(0, lnum, lnum+1, false) or {""}
  -- print(vim.inspect(line_contents))
  local m = string.match(line_contents[1], "^%s+")
  local first_char_offset = 0
  if m ~= nil then
    first_char_offset = #m
  end
  -- print("first_char_offset for " .. line_contents[1] .. ": " .. first_char_offset)

  local ts_node = get_node_elt(parser:named_node_for_range({lnum, first_char_offset, lnum, first_char_offset}), mode == "cur_line")
  -- find all the named nodes on that line
  local first_node = ts_node
  local _, first_col, _, _ = ts_node:range()
  local nodes_on_line = {ts_node}
  while true do
    first_node = first_node:prev_named_sibling()
    if first_node == nil then
      break
    end
    local start_row, start_col, _, _ = first_node:range()
    if start_row ~= lnum then
      break
    end
    first_col = start_col
    table.insert(nodes_on_line, first_node)
  end
  local last_node = ts_node
  while true do
    last_node = last_node:next_named_sibling()
    if last_node == nil then
      break
    end
    local start_row, _, _, _ = last_node:range()
    if start_row ~= lnum then
      break
    end
    table.insert(nodes_on_line, last_node)
  end

  -- print("nodes on line: " .. #nodes_on_line)

  local indent_level_change = 0
  local had_stag = false
  for _, node in ipairs(nodes_on_line) do
    if node:type() ~= "content" then
      -- print(node:type() .. "=>" .. vim.treesitter.get_node_text(node, 0))
      if mode == "previous_line" then
        local _, _, cur_end_row, _ = node:range()
        -- the if check is to make sure that the previous line node doesn't
        -- span over the current line. For instance:
        -- <tag
        --    attribute=..
        -- tag would be on the previous line, attribute on the current line.
        -- we don't want to count the indentation due to "tag" then, because
        -- it's already taken into account by the attribute indentation.
        if cur_end_row <= lnum then
          if node:type() == "STag" then
            indent_level_change = indent_level_change + vim.bo.shiftwidth
          end
          if node:type() == "ETag" and indent_level_change > 0 then
            -- compensate the previous STag since it got closed
            indent_level_change = indent_level_change - vim.bo.shiftwidth
          end
        end
      elseif mode == "cur_line" then
        if node:type() == "STag" then
          had_stag = true
        end
        if node:type() == "ETag" then
          if had_stag then
            had_stag = false
          else
            indent_level_change = indent_level_change - vim.bo.shiftwidth
          end
        end
        if node:type() == "Attribute" and nodes_on_line_previous[1]:type() ~= "Attribute" then
          indent_level_change = indent_level_change + vim.bo.shiftwidth
        end
      end
    end
  end

  return first_col, nodes_on_line, indent_level_change
end

function _G.xml_get_indent(lnum)
  -- print("lnum: " .. (lnum or "nil"))
  local parser = vim.treesitter.get_parser(0, nil, {error=false})
  if parser == nil then
    return
  end
  parser:parse()

  local first_col_previous, nodes_on_line_previous, indent_offset_previous_line = xml_indent_offset_for_lnum(parser, lnum-2, "previous_line")
  -- print("first_col_previous " .. first_col_previous)
  -- print("indent_offset_previous_line: " .. indent_offset_previous_line)
  local first_col_cur, _, indent_offset_cur_line = xml_indent_offset_for_lnum(parser, lnum-1, "cur_line", nodes_on_line_previous)
  -- print("indent_offset_cur_line: " .. indent_offset_cur_line)

  -- local previous_line = vim.api.nvim_buf_get_lines(0, lnum-2,lnum-1, false) or {""}
  -- print("previous_line: " .. vim.inspect(previous_line))
  -- local previous_indent = 0
  -- local m = string.match(previous_line[1], "^%s+")
  -- if m ~= nil then
  --   previous_indent = #m
  -- end
  -- print("previous_indent: " .. previous_indent)
  -- print("res " .. tostring(first_col_previous + indent_offset_previous_line + indent_offset_cur_line))
  return tostring(first_col_previous + indent_offset_previous_line + indent_offset_cur_line)
end

vim.api.nvim_exec([[
function! s:xml_mine_indent() abort
  return luaeval(printf("xml_get_indent(%d)", v:lnum))
endfunction

set indentexpr=<SID>xml_mine_indent()
]], false)

-- https://github.com/nvim-treesitter/nvim-treesitter/issues/6723#issuecomment-2151597595
-- better than the builtin XML indent, although still not perfect
-- vim.bo.indentexpr = "nvim_treesitter#indent()"
-- vim.bo.indentexpr = s:xml_mine_indent()

