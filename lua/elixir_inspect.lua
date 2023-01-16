function _G.elixir_add_inspect()
  local line = vim.fn.line('.')
  local parser = require('nvim-treesitter.parsers').get_parser(0)
  local ts_node = parser
  :named_node_for_range({line-1, vim.fn.col('.'), line-1, vim.fn.col('.')})
  local node_type = ts_node:type()
  local is_identifier = nil
  while ts_node ~= nil do
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
  is_identifier = is_identifier or
    (node_type == "identifier" and line:match("^%s*" .. name .. "%s*="))
  if is_identifier then
    vim.cmd('norm! oIO.inspect(' .. name .. ', label: "' .. name .. '")')
  else
    -- if line:match("^%s+|>") then
    local name = line:gsub("^%s+", "")
      -- vim.ui.input({prompt="Enter a name for the inspect:", default=line:gsub("^%s+", "")}, function(name)
        -- if name then
          vim.cmd('norm! o|> IO.inspect(label: "' .. name .. '")')
          -- position the cursor in the quotes to enable quick rename
          vim.cmd('norm! 4h')
      --   end
      -- end)
    -- else
    --   print "non chain"
    -- end
  end
end
