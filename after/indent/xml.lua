local function get_node_elt(node)
  while node:parent():type() ~= "element" do
    node = node:parent()
  end
  return node
end

local function xml_indent_offset_for_lnum(parser, lnum, indent_map)
  local line_contents = vim.api.nvim_buf_get_lines(0, lnum, lnum+1, false) or {""}
  -- print(vim.inspect(line_contents))
  local m = string.match(line_contents[1], "^%s+")
  local first_char_offset = 0
  if m ~= nil then
    first_char_offset = #m
  end
  -- print("first_char_offset for " .. line_contents[1] .. ": " .. first_char_offset)

  local ts_node = get_node_elt(parser:named_node_for_range({lnum, first_char_offset, lnum, first_char_offset}))
  -- find all the named nodes on that line
  local first_node = ts_node
  local nodes_on_line = {ts_node}
  while true do
    first_node = first_node:prev_named_sibling()
    if first_node == nil then
      break
    end
    local start_row, _, _, _ = first_node:range()
    if start_row ~= lnum then
      break
    end
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

  print("on line: " .. #nodes_on_line)

  local indent_level_change = 0
  for _, node in ipairs(nodes_on_line) do
      print(node:type() .. "=>" .. vim.treesitter.get_node_text(node, 0))
    if node:type() ~= "content" then
      indent_level_change = indent_level_change + (indent_map[node:type()] or 0)
    end
  end

  return indent_level_change
end

function _G.xml_get_indent(lnum)
  print("lnum: " .. (lnum or "nil"))
  local parser = require('nvim-treesitter.parsers').get_parser(0)
  parser:parse()

  -- the previous line can only ADD offset
  local indent_offset_previous_line = math.max(0, xml_indent_offset_for_lnum(parser, lnum-2, {
    STag = vim.bo.shiftwidth,
    ETag = -vim.bo.shiftwidth,
  }))
  print("indent_offset_previous_line: " .. indent_offset_previous_line)
  -- the current line can only SUBTRACT offset
  local indent_offset_cur_line = math.min(0, xml_indent_offset_for_lnum(parser, lnum-1, {
    STag = vim.bo.shiftwidth,
    ETag = -vim.bo.shiftwidth,
  }))
  print("indent_offset_cur_line: " .. indent_offset_cur_line)

  local previous_line = vim.api.nvim_buf_get_lines(0, lnum-2,lnum-1, false) or {""}
  print("previous_line: " .. vim.inspect(previous_line))
  local previous_indent = 0
  local m = string.match(previous_line[1], "^%s+")
  if m ~= nil then
    previous_indent = #m
  end
  print("previous_indent: " .. previous_indent)
  print("res " .. tostring(previous_indent + indent_offset_previous_line + indent_offset_cur_line))
  return tostring(previous_indent + indent_offset_previous_line + indent_offset_cur_line)
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

