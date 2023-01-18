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

function _G.elixir_add_inspect_sel()
  local line = vim.fn.line('.')
  local line = vim.api.nvim_buf_get_lines(0, line-1, line, false)[1]
  local startcol = vim.fn.virtcol("'<")
  local endcol = vim.fn.virtcol("'>")
  local seltext = line:sub(startcol, endcol)
  vim.cmd('norm! ' .. endcol .. '|a |> IO.inspect(label: "' .. seltext .. '")')
end

-- in theory I should load modules through -S mix but.. i couldn't make it work
-- from neovim, it's slow and so on. In the end besides the stdlib i care about ecto...
ECTO_MIX_FOLDER = './_build/dev/lib/ecto/ebin/'

function _G.elixir_view_docs(opts)
  modules = {}
  if vim.fn.isdirectory(ECTO_MIX_FOLDER) == 1 then
    -- the downside of the -pa loading of ecto modules is that it's on-demand loading, so
    -- the modules are not discovered => list them by hand
    -- https://elixirforum.com/t/by-what-mechanism-does-iex-load-beam-files/37102
    modules = {'Ecto', 'Ecto.Association', 'Ecto.Association.BelongsTo', 'Ecto.Association.Has', 'Ecto.Association.ManyToMany', 'Ecto.Changeset', 'Ecto.Changeset.Relation',
    'Ecto.Embedded', 'Ecto.Multi', 'Ecto.Query', 'Ecto.Query.Builder', 'Ecto.Query.Builder.Filter', 'Ecto.Query.Builder.From', 'Ecto.Query.Builder.Join',
    'Ecto.Query.Builder.Preload', 'Ecto.Query.Builder.Select', 'Ecto.Query.Builder.Update', 'Ecto.Query.Planner', 'Ecto.Queryable', 'Ecto.Queryable.Atom',
    'Ecto.Queryable.Ecto.Query', 'Ecto.Repo.Assoc', 'Ecto.Repo.Preloader', 'Ecto.Repo.Queryable', 'Ecto.Repo.Registry', 'Ecto.Repo.Schema', 'Ecto.Repo.Supervisor',
    'Ecto.Repo.Transaction', 'Ecto.Schema.Loader', 'Ecto.Type', 'EctoEnum.Mixfile', 'EctoEnum.Type'}
  end
  -- https://stackoverflow.com/questions/58461572/get-a-list-of-all-elixir-modules-in-iex#comment103267199_58462672
  vim.fn.jobstart({ "elixir", "-pa", ECTO_MIX_FOLDER, "-e", ":erlang.loaded() |> Enum.sort() |> inspect(limit: :infinity) |> IO.puts" }, {
    cwd='.',
    stdout_buffered = true,
    on_stdout = vim.schedule_wrap(function(j, output)
      for mod in string.gmatch(output[1], "([^,%s%[%]]+)") do
        if mod:match("^[A-Z]") then
          table.insert(modules, mod)
        end
      end
    end),
    on_exit = vim.schedule_wrap(function(j, output)
      table.sort(modules)
      vim.ui.select(modules, {prompt="Pick the module to view:"}, function(choice) 
        if choice then
          elixir_view_module_docs(choice, opts)
        end
      end)
    end)
  })
end

function _G.elixir_view_module_docs(mod, opts)
  exports = {mod}
  -- https://stackoverflow.com/questions/52670918
  vim.fn.jobstart({ "elixir", "-pa", ECTO_MIX_FOLDER, "-e", "require IEx.Helpers; IEx.Helpers.exports(" .. mod .. ")" }, {
    cwd='.',
    stdout_buffered = true,
    on_stdout = vim.schedule_wrap(function(j, output)
      for _, line in ipairs(output) do
        for export in string.gmatch(line, "([^%s]+)") do
          table.insert(exports, mod .. "." .. export)
        end
      end
    end),
    on_exit = vim.schedule_wrap(function(j, output)
      vim.ui.select(exports, {prompt="Pick the function to view:"}, function(choice)
        if choice then
          elixir_view_export_docs(choice, opts)
        end
      end)
    end)
  })
end

function _G.elixir_view_export_docs(export, opts)
  if opts and opts.popup then
    local popup_buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_option(popup_buf, 'buftype', 'nofile')
    vim.api.nvim_buf_set_option(popup_buf, "bufhidden", "hide")
    vim.api.nvim_buf_set_option(popup_buf, "swapfile", false)
    vim.api.nvim_buf_set_option(popup_buf, 'modifiable', false)

    local width = vim.api.nvim_get_option("columns")
    local height = vim.api.nvim_get_option("lines") - vim.o.cmdheight - 1
    local popup_width = 90
    local popup_height = 50

    local win_opts = {
      focusable = true,
      style = "minimal",
      border = "rounded",
      relative = "editor",
      width = popup_width,
      height = popup_height,
      anchor = "NW",
      row = (height-popup_height)/2,
      col = (width-popup_width)/2,
      noautocmd = true,
    }
    popup_win = vim.api.nvim_open_win(popup_buf, true, win_opts)
  end
  vim.fn.termopen("elixir -pa " .. ECTO_MIX_FOLDER .. " -e 'require IEx.Helpers; IEx.Helpers.h(" .. export .. ")'")
end
