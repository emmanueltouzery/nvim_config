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
        table.insert(targets, { pos = { cur_line, idx-1 } }) -- before
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
        vim.cmd('norm! a|> IO.inspect(label: "", charlists: :as_lists)')
      else
        vim.cmd('norm! i|> IO.inspect(label: "", charlists: :as_lists)')
      end
      -- position the cursor in the quotes to enable quick rename
      vim.cmd('norm! 23h')
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

  -- beginning of previous 2 lines
  for idx = math.max(0, cur_line-3), cur_line do
    local idx_line_str = vim.api.nvim_buf_get_lines(0, idx-1, idx, false)[1]
    if idx_line_str == nil then break end
    table.insert(targets, { pos = { idx+1, 1 }})
  end

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
        vim.cmd('norm! aIO.inspect("' .. param_name .. '", charlists: :as_lists)')
      else
        vim.cmd('norm! aIO.inspect(' .. param_name .. ', label: "' .. param_name .. '", charlists: :as_lists)')
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
            vim.cmd('norm! a|> tap(&IO.inspect(&1.' .. field .. ', label: "' .. field .. '", charlists: :as_lists))')
          else
            vim.cmd('norm! i|> tap(&IO.inspect(&1.' .. field .. ', label: "' .. field .. '", charlists: :as_lists))')
          end
          -- position the cursor in the quotes to enable quick rename
          vim.cmd('norm! 2h')
          vim.cmd('startinsert')
        end
      }
    end
  end)
end

_G.telescope_elixir_stacktrace = function(opts)
  local lines = vim.api.nvim_buf_get_lines(0, vim.fn.line('.')-1, vim.fn.line('.'), false)
  if string.match(lines[1], "stacktrace:") then
    -- positioned on top of a stacktrace, read it
    lines = vim.api.nvim_buf_get_lines(0, vim.fn.line('.'), vim.fn.line('.')+30, false)
    telescope_elixir_stacktrace_display(lines)
  else
    -- get the terminal buffer
    local b = vim.g.test_term_buf_id
    -- for _, b in pairs(vim.api.nvim_list_bufs()) do
    --   if vim.api.nvim_buf_is_loaded(b) and string.match(vim.api.nvim_buf_get_name(b), "^term://") then
        all_term_lines = vim.api.nvim_buf_get_lines(b, 0, -1, false)
        for i, l in pairs(all_term_lines) do
          if string.match(l, "stacktrace:") then
            -- found the stacktrace in the terminal buffer
            lines = vim.api.nvim_buf_get_lines(b, i, i+30, false)
            telescope_elixir_stacktrace_display(lines)
            return
          end
        end
    --   end
    -- end
  end
end

function _G.telescope_elixir_stacktrace_display(lines)
  local stack_items = {}
  local i = 1
  while i <= #lines do
    line = lines[i]
    if string.match(line, "^%s*$") then
      -- blank line, done with the stacktrace
      break
    end
    
    -- the line may have been truncated. in that case it'll continue next line, from column 0.
    if i+1 <= #lines and string.match(lines[i+1], "^[^%s]") then
      line = line .. lines[i+1]
      i = i + 1
    end

    local _, _, package, path, line_nr, fnction = string.find(line, "(%([^%)]+%))%s([^:]+):(%d+):%s([^%s]+)")
    if package == nil then
      -- sometimes the package is not listed...
      _, _, path, line_nr, fnction = string.find(line, "%s*([^:]+):(%d+):%s([^%s]+)")
    end
    -- sometimes only package+function are listed. can't do anything without a path
    if path ~= nil then
      local buffer = nil
      for _, b in pairs(vim.api.nvim_list_bufs()) do
        if vim.api.nvim_buf_is_loaded(b) and string.match(vim.api.nvim_buf_get_name(b), path) then
          buffer = b
        end
      end
      if buffer == nil then
        if vim.fn.filereadable(path) == 1 then
          vim.cmd(":e " .. path)
          -- yeah, copy-paste the loop...
          for _, b in pairs(vim.api.nvim_list_bufs()) do
            if vim.api.nvim_buf_is_loaded(b) and string.match(vim.api.nvim_buf_get_name(b), path) then
              buffer = b
            end
          end
        end
      end
      if buffer ~= nil then
        table.insert(stack_items, {bufnr = buffer, lnum = tonumber(line_nr), valid = 1, text = string.match(fnction, "[^%.]+$")})
      end
    end
    i = i + 1
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

function _G.elixir_match_error_details_indent()
  vim.cmd[[set ft=elixir]]
  vim.cmd[[:%s/\n//ge]]
  vim.cmd[[:%s/\r//ge]]
  -- the contents are now on a single line
  local line = vim.tbl_filter(function(l) return l ~= nil end, vim.api.nvim_buf_get_lines(0, 0, 10, false))[1]
  -- "objects" are things like #Thing<x="details">
  local with_fixed_objects = string.gsub(line, "(#[%w%.]+<[^>]*>)", function(s)
    -- #Thing<x="details"> -> "#Thing<x='details'>"
    return "\"" .. string.gsub(s, "\"", "'") .. "\""
  end)
  vim.api.nvim_buf_set_lines(0, 0, 1, false, {with_fixed_objects})
  vim.cmd(':%!mix format -')
end
