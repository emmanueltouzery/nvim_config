local function find_local_declarations_java()
  local word = vim.fn.expand('<cword>')
  local bufnr = 0

  local q = vim.treesitter.query.parse("java", [[
(local_variable_declaration
  declarator:
    (variable_declarator
      name: (identifier) @identifier (#eq? @identifier "]] .. word .. [[")))

(field_declaration
  declarator:
    (variable_declarator
      name: (identifier) @identifier (#eq? @identifier "]] .. word .. [[")))

(formal_parameter
  name: (identifier) @identifier (#eq? @identifier "]] .. word .. [["))

(catch_formal_parameter
  name: (identifier) @identifier (#eq? @identifier "]] .. word .. [["))

(inferred_parameters
  (identifier) @identifier (#eq? @identifier "]] .. word .. [[")) ; (x,y) -> ...

(lambda_expression
  parameters: (identifier) @identifier (#eq? @identifier "]] .. word .. [[")) ; x -> ...
  ]])

  local parser = require('nvim-treesitter.parsers').get_parser(bufnr, "java")
  local syntax_tree = parser:parse()[1]
  local iter = q:iter_captures(syntax_tree:root(), bufnr, 0, -1)
  local module_fnames = {vim.fn.expand('%:p')} -- immediately add the current file
  local matches = {}
  for _capture, node, _metadata in iter do
    local row1, col1, row2, col2 = node:range()
    table.insert(matches, {
      lnum = row1+1,
      col = col1,
      path = vim.fn.expand('%'),
      fname = vim.fn.expand('%:p'),
      line = vim.api.nvim_buf_get_lines(bufnr, row1, row1+1, false)[1]
    })
  end
  return matches
end

function _G.find_local_declarations()
  local matches = {}
  if vim.bo.filetype == "java" then
    matches = find_local_declarations_java()
  end
  local filtered_matches = {}
  local cur_line = vim.fn.line('.')
    print(cur_line)
  for _, match in ipairs(matches) do
    print(match.lnum)
    if match.lnum <= cur_line then
      table.insert(filtered_matches, match)
    end
  end
  return filtered_matches
end
