-- in theory I should load modules through -S mix but.. i couldn't make it work
-- from neovim, it's slow and so on. In the end besides the stdlib i care about ecto...
EXTRA_MIX_FOLDERS = {'./_build/dev/lib/ecto/ebin/'}

function _G.elixir_pa_flags(flags)
  res = {"elixir"}
  for _, f in ipairs(EXTRA_MIX_FOLDERS) do
    table.insert(res, "-pa")
    table.insert(res, f)
  end
  for _, f in ipairs(flags) do
    table.insert(res, f)
  end
  return res
end

function _G.elixir_view_docs(opts)
  modules = {}
  for _, folder in ipairs(EXTRA_MIX_FOLDERS) do
    if vim.fn.isdirectory(folder) == 1 then
      -- the downside of the -pa loading of ecto modules is that it's on-demand loading, so
      -- the modules are not discovered => list them by hand
      -- https://elixirforum.com/t/by-what-mechanism-does-iex-load-beam-files/37102
      local sd = vim.loop.fs_scandir(folder)
      while true do
        local name, type = vim.loop.fs_scandir_next(sd)
        if name == nil then break end
        if name:match("%.beam$") then
          local module = name:gsub("%.beam$", ""):gsub("^Elixir%.", "")
          table.insert(modules, module)
        end
      end
    end
  end
  -- https://stackoverflow.com/questions/58461572/get-a-list-of-all-elixir-modules-in-iex#comment103267199_58462672
  -- vim.fn.jobstart(elixir_pa_flags({ "-e", ":erlang.loaded() |> Enum.sort() |> inspect(limit: :infinity) |> IO.puts" }), {
  -- https://github.com/elixir-lang/elixir/blob/60f86886c0f66c71790e61d754eada4e9fa0ace5/lib/iex/lib/iex/autocomplete.ex#L507
  vim.fn.jobstart(elixir_pa_flags({ "-e", ":application.get_key(:elixir, :modules) |> inspect(limit: :infinity) |> IO.puts" }), {
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
  vim.fn.jobstart(elixir_pa_flags({ "-e", "require IEx.Helpers; IEx.Helpers.exports(" .. mod .. ")" }), {
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
      elixir_view_behaviour_module_docs(mod, exports, opts)
    end)
  })
end

function _G.elixir_view_behaviour_module_docs(mod, exports, opts)
  vim.fn.jobstart(elixir_pa_flags({ "-e", "require IEx.Helpers; IEx.Helpers.b(" .. mod .. ")" }), {
    cwd='.',
    stdout_buffered = true,
    on_stdout = vim.schedule_wrap(function(j, output)
      local cur_callback_name = nil
      local cur_callback_param_count = 0
      local is_opening_bracket = false
      for _, line in ipairs(output) do
        if cur_callback_name == nil then
          if string.match(line, "^@callback ") then
            local end_idx = string.find(line, "%(")
            cur_callback_name = string.sub(line, 11, end_idx-1)
            if string.sub(line, end_idx+1, end_idx+1) == ')' then
              cur_callback_param_count = 0
              goto insert_callback
            elseif end_idx == #line then
              cur_callback_param_count = 0
              goto skip_to_next
            else
              cur_callback_param_count = 1
            end
            for idx = end_idx, #line do
              local char = string.sub(line, idx, idx)
              if char == ',' then
                cur_callback_param_count = cur_callback_param_count + 1
              elseif not is_opening_bracket and char == ')' then
                goto insert_callback
              end 
              is_opening_bracket = char == '('
            end
          end
        else
          if string.match(line, ",$") then
            cur_callback_param_count = cur_callback_param_count + 1
            goto skip_to_next
          else
            -- that was the last parameter
            cur_callback_param_count = cur_callback_param_count + 1
          end
        end
        ::insert_callback::
        if cur_callback_name ~= nil then
          table.insert(exports, "@" .. mod .. "." .. cur_callback_name .. "/" .. cur_callback_param_count)
          cur_callback_name = nil
        end
        ::skip_to_next::
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
  else
    vim.cmd("enew")
  end
  local command = "h"
  if string.match(export, "^@") then
    export = string.sub(export, 2)
    command = "b"
  end
  vim.fn.termopen(table.concat(elixir_pa_flags({
    " -e 'require IEx.Helpers; IEx.Helpers." .. command .. "(" .. export .. ")'"}), " "))
end

function _G.inspect_point_candidate(winid)
  local wininfo =  vim.fn.getwininfo(winid)[1]
  local cur_line = vim.fn.line('.')
  local cur_col = vim.fn.col('.')
  local cur_line_str = vim.api.nvim_buf_get_lines(0, cur_line-1, cur_line, false)[1]

  local targets = {}

  -- pick only the NEXT char
  local next_chars = {' '}
  for _, next_char in ipairs(next_chars) do
    -- before the next cur char on this line, if any
    for idx = cur_col, #cur_line_str do
      local char = string.sub(cur_line_str, idx, idx)
      if char == next_char then
        table.insert(targets, { pos = { cur_line, idx }})
        break
      end
    end
  end

  -- pick ALL chars in this line -- before only
  local next_chars = {','}
  for _, next_char in ipairs(next_chars) do
    -- before the next cur char on this line, if any
    for idx = cur_col, #cur_line_str do
      local char = string.sub(cur_line_str, idx, idx)
      if char == next_char then
        table.insert(targets, { pos = { cur_line, idx }, offset = -1 }) -- before
      end
    end
  end

  -- pick ALL chars in this line -- before and after
  local next_chars = {')', ']', '}'}
  for _, next_char in ipairs(next_chars) do
    -- before the next cur char on this line, if any
    for idx = cur_col, #cur_line_str do
      local char = string.sub(cur_line_str, idx, idx)
      if char == next_char then
        table.insert(targets, { pos = { cur_line, idx-1 } }) -- before
        table.insert(targets, { pos = { cur_line, idx }, offset = -1, append = true }) -- after
      end
    end
  end

  -- after the next ) up to 10 lines down
  for idx = cur_line, cur_line+10 do
    local idx_line_str = vim.api.nvim_buf_get_lines(0, idx-1, idx, false)[1]
    if idx_line_str == nil then break end
    local index_start = string.find(idx_line_str, "%)")
    if index_start ~= nil then
      table.insert(targets, { pos = { idx, index_start }, append = true})
      break
    end
  end

  -- end of the line
  table.insert(targets, { pos = { cur_line, #cur_line_str }, append = true})

  -- beginning of next line
  table.insert(targets, { pos = { cur_line+1, 1 }})

  -- before the next |> up to 10 lines down
  for idx = cur_line+1, cur_line+10 do
    local idx_line_str = vim.api.nvim_buf_get_lines(0, idx-1, idx, false)[1]
    if idx_line_str == nil then break end
    if string.match(idx_line_str, "^%s*%|>") then
      table.insert(targets, { pos = { idx, 1 }})
      break
    end
  end

  if #targets >= 1 then
    return targets
  end
end

function _G.elixir_insert_inspect_value()
  winid = vim.api.nvim_get_current_win()
  local cur_col = vim.fn.col('.')
  require('leap').leap {
    target_windows = { winid },
    targets = inspect_point_candidate(winid),
    action = function(target)
      if target.offset then
        target.pos[2] = target.pos[2] + target.offset
      end
      vim.api.nvim_win_set_cursor(0, target.pos)
      if target.pos[2] == 1 then
        vim.cmd("norm! O")
      end
      if target.append then
        vim.cmd('norm! a|> IO.inspect(label: "")')
      else
        vim.cmd('norm! i|> IO.inspect(label: "")')
      end
      -- position the cursor in the quotes to enable quick rename
      vim.cmd('norm! h')
      vim.cmd('startinsert')
    end
  }
end

function _G.inspect_point_candidate_param(winid)
  local wininfo =  vim.fn.getwininfo(winid)[1]
  local cur_line = vim.fn.line('.')
  local cur_col = vim.fn.col('.')
  local cur_line_str = vim.api.nvim_buf_get_lines(0, cur_line-1, cur_line, false)[1]

  local targets = {}

  -- beginning of next 10 lines
  for idx = cur_line, cur_line+10 do
    local idx_line_str = vim.api.nvim_buf_get_lines(0, idx-1, idx, false)[1]
    if idx_line_str == nil then break end
    table.insert(targets, { pos = { idx+1, 1 }})
  end

  if #targets >= 1 then
    return targets
  end
end

function _G.elixir_insert_inspect_param()
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
      if is_function_name then
        vim.cmd('norm! aIO.inspect("' .. param_name .. '")')
      else
        vim.cmd('norm! aIO.inspect(' .. param_name .. ', label: "' .. param_name .. '")')
      end
      -- position the cursor in the quotes to enable quick rename
      vim.cmd('norm! h')
      vim.cmd('startinsert')
    end
  }
end

function _G.inspect_point_candidate_label(winid)
  local wininfo =  vim.fn.getwininfo(winid)[1]
  local cur_line = vim.fn.line('.')
  local cur_col = vim.fn.col('.')
  local cur_line_str = vim.api.nvim_buf_get_lines(0, cur_line-1, cur_line, false)[1]

  local targets = {}

  -- beginning of next 10 lines
  for idx = cur_line-1, cur_line+10 do
    local idx_line_str = vim.api.nvim_buf_get_lines(0, idx-1, idx, false)[1]
    if idx_line_str == nil then break end
    table.insert(targets, { pos = { idx+1, 1 }})
  end

  if #targets >= 1 then
    return targets
  end
end

function _G.elixir_insert_inspect_label()
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
      vim.cmd('norm! aIO.inspect("")')
      -- position the cursor in the quotes to enable quick rename
      vim.cmd('norm! h')
      vim.cmd('startinsert')
    end
  }
end


function _G.elixir_insert_inspect_field()
  vim.ui.input({prompt="Enter field name please: ", kind="center_win"}, function(field)
    if field ~= nil then
      winid = vim.api.nvim_get_current_win()
      local cur_col = vim.fn.col('.')
      require('leap').leap {
        target_windows = { winid },
        targets = inspect_point_candidate(winid),
        action = function(target)
          vim.api.nvim_win_set_cursor(0, target.pos)
          if target.offset then
            target.pos[2] = target.pos[2] + target.offset
          end
          if target.pos[2] == 1 then
            vim.cmd("norm! O")
          end
          if target.append then
            vim.cmd('norm! a|> tap(&IO.inspect(&1.' .. field .. ', label: "' .. field .. '"))')
          else
            vim.cmd('norm! i|> tap(&IO.inspect(&1.' .. field .. ', label: "' .. field .. '"))')
          end
          -- position the cursor in the quotes to enable quick rename
          vim.cmd('norm! 2h')
          vim.cmd('startinsert')
        end
      }
    end
  end)
end

function _G.elixir_mark_multiple_clause_fns()
  vim.cmd[[sign define clause text=⡇ texthl=TSFunction]]
  vim.cmd[[sign define clauseStart text=⡏ texthl=TSFunction]]
  vim.cmd[[sign define clauseEnd text=⣇ texthl=TSFunction]]
  local query = require("nvim-treesitter.query")
  local parser = require('nvim-treesitter.parsers').get_parser(0)
  if parser == nil then
    -- getting this sometimes when displaying elixir code in popups or something
    return
  end
  local syntax_tree = parser:parse()[1]
  local lang = parser:lang()
  local prev_fname = nil
  local multi_clause_counts = {}
  for match in query.iter_group_results(0, "clauses", syntax_tree:root(), lang) do
    local fn_name = vim.treesitter.query.get_node_text(match.name.node, 0)
    if fn_name == prev_fname then
      if multi_clause_counts[fn_name] then
        multi_clause_counts[fn_name] = multi_clause_counts[fn_name] + 1
      else
        multi_clause_counts[fn_name] = 2
      end
    end
    prev_fname = fn_name
  end
  local fname = vim.fn.expand("%:p")
  local sign_id = 3094
  if vim.b.signs_count then
    for i=0,vim.b.signs_count,1 do
      vim.cmd("sign unplace " .. sign_id .. " file=" .. fname)
    end
  end
  local signs_count = 0
  local cur_fname = nil
  local count_for_fn = 0
  for match in query.iter_group_results(0, "clauses", syntax_tree:root(), lang) do
    local fn_name = vim.treesitter.query.get_node_text(match.name.node, 0)
    if multi_clause_counts[fn_name] then
      local line = vim.treesitter.get_node_range(match.name.node)+1
      if cur_fname ~= fn_name then
        -- first for this function
        vim.cmd("exe ':sign place " .. sign_id .. " line=" .. line .. " name=clauseStart file=" .. fname .. "'")
        count_for_fn = 1
      elseif count_for_fn + 1 == multi_clause_counts[fn_name] then
        -- last for this function
        vim.cmd("exe ':sign place " .. sign_id .. " line=" .. line .. " name=clauseEnd file=" .. fname .. "'")
      else
        vim.cmd("exe ':sign place " .. sign_id .. " line=" .. line .. " name=clause file=" .. fname .. "'")
        count_for_fn = count_for_fn + 1
      end
      cur_fname = fn_name
      signs_count = signs_count + 1
    end
  end
  vim.b.signs_count = signs_count
end
vim.cmd [[au BufWinEnter,BufWritePost *.ex lua elixir_mark_multiple_clause_fns()]]
vim.cmd [[au BufWinEnter,BufWritePost *.exs lua elixir_mark_multiple_clause_fns()]]

_G.telescope_elixir_stacktrace = function(opts)
  local lines = vim.api.nvim_buf_get_lines(0, vim.fn.line('.'), vim.fn.line('.')+30, false)
  local stack_items = {}
  for i, line in ipairs(lines) do
    if string.match(line, "^%s*$") then
      break
    end
    local _, _, package, path, line_nr, fnction = string.find(line, "(%([^%)]+%))%s([^:]+):(%d+):%s([^%s]+)")
    if package == nil then
      -- sometimes the package is not listed...
      _, _, path, line_nr, fnction = string.find(line, "%s*([^:]+):(%d+):%s([^%s]+)")
    end
    local buffer = nil
    for _, b in pairs(vim.api.nvim_list_bufs()) do
      if vim.api.nvim_buf_is_loaded(b) and string.match(vim.api.nvim_buf_get_name(b), path) then
        buffer = b
      end
    end
    if buffer == nil then
      vim.cmd(":e " .. path)
      -- yeah, copy-paste the loop...
      for _, b in pairs(vim.api.nvim_list_bufs()) do
        if vim.api.nvim_buf_is_loaded(b) and string.match(vim.api.nvim_buf_get_name(b), path) then
          buffer = b
        end
      end
    end
    table.insert(stack_items, {bufnr = buffer, lnum = tonumber(line_nr), valid = 1, text = string.match(fnction, "[^%.]+$")})
  end
  local pickers = require "telescope.pickers"
  local finders = require "telescope.finders"
  local conf = require("telescope.config").values

  pickers.new(opts, {
    prompt_title = "Stacktrace view",
    finder = finders.new_table {
      results = stack_items,
      entry_maker = opts.entry_maker or gen_from_quickfix(opts),
    },
    previewer = conf.qflist_previewer(opts),
    -- sorter = conf.generic_sorter(opts),
  }):find()
end
