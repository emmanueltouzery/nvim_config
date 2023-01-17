function _G.elixir_add_inspect()
  local line = vim.fn.line('.')
  local parser = require('nvim-treesitter.parsers').get_parser(0)
  local ts_node = parser
  :named_node_for_range({line-1, vim.fn.col('.'), line-1, vim.fn.col('.')})
  local node_type = ts_node:type()
  local is_identifier = nil
  while ts_node ~= nil do
    -- print(ts_node:type())
    if ts_node:type() == "arguments" then
      is_identifier = true
      break
    end
    if ts_node:type() == "call" then
      is_identifier = false
      break
    end
    ts_node = ts_node:parent()
  end
  local line = vim.api.nvim_buf_get_lines(0, line-1, line, false)[1]
  local name = vim.fn.expand('<cword>')
  local is_chain_line = line:match("^%s*%|>") -- |> ...
  is_identifier = is_identifier and not is_chain_line or
    (node_type == "identifier" and line:match("^%s*" .. name .. "%s*="))
  if is_identifier then
    vim.cmd('norm! oIO.inspect(' .. name .. ', label: "' .. name .. '")')
  else
    local is_do_statement_line = line:match(" do%s*$") -- function xx() do
    local is_assignment_line = line:match("^%s*[a-zA-Z_%d]+%s*=") -- xx = ...
    local no_chain = is_do_statement_line or is_assignment_line
    local name = line:gsub("^%s+", "")
          local chain = '|> '
          if no_chain then
            chain = ''
          end
          vim.cmd('norm! o' .. chain .. 'IO.inspect(label: "' .. name .. '")')
          -- position the cursor in the quotes to enable quick rename
          vim.cmd('norm! 4h')
    -- end
  end
end
