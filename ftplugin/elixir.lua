
require 'key-menu'.set('n', '<localleader>i', {desc='Inspect...', buffer = true})

local function elixir_insert_inspect_value()
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
        vim.cmd('norm! a|> IO.inspect(label: "", charlists: :as_lists, limit: 50)')
      else
        vim.cmd('norm! i|> IO.inspect(label: "", charlists: :as_lists, limit: 50)')
      end
      -- position the cursor in the quotes to enable quick rename
      vim.cmd('norm! 34h')
      vim.cmd('startinsert')
    end
  }
end
vim.keymap.set('n', '<localleader>iv', elixir_insert_inspect_value, {desc="elixir add inspect value", buffer = true})

-- see  typescript_insert_inspect_param
local function elixir_insert_inspect_param()
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
        vim.cmd('norm! aIO.inspect("' .. param_name .. '", charlists: :as_lists, limit: 50)')
      else
        vim.cmd('norm! aIO.inspect(' .. param_name .. ', label: "' .. param_name .. '", charlists: :as_lists, limit: 50)')
      end
      -- position the cursor in the quotes to enable quick rename
      vim.cmd('norm! 34h')
      vim.cmd('startinsert')
    end
  }
end
vim.keymap.set('n', '<localleader>ip', elixir_insert_inspect_param, {desc="elixir add inspect parameter", buffer = true})

local function elixir_insert_inspect_label()
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
vim.keymap.set('n', '<localleader>il', elixir_insert_inspect_label, {desc="elixir add inspect label", buffer = true})

local function elixir_insert_inspect_field()
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
            vim.cmd('norm! a|> tap(&IO.inspect(&1.' .. field .. ', label: "' .. field .. '", charlists: :as_lists, limit: 50))')
          else
            vim.cmd('norm! i|> tap(&IO.inspect(&1.' .. field .. ', label: "' .. field .. '", charlists: :as_lists, limit: 50))')
          end
          -- position the cursor in the quotes to enable quick rename
          vim.cmd('norm! 2h')
          vim.cmd('startinsert')
        end
      }
    end
  end)
end

vim.keymap.set('n', '<localleader>if', elixir_insert_inspect_field, {desc="elixir add inspect field", buffer = true})

require 'key-menu'.set('n', '<localleader>a', {desc='API', buffer = true})
vim.keymap.set('n', '<localleader>ac', ":lua require'elixir-extras'.elixir_view_docs({})<cr>", {desc="elixir apidocs (core only)", buffer = true})
vim.keymap.set('n', '<localleader>aa', ":lua require'elixir-extras'.elixir_view_docs({include_mix_libs=true})<cr>", {desc="elixir apidocs (all)", buffer = true})
require 'key-menu'.set('n', '<localleader>o', {desc='Open...', buffer = true})
vim.keymap.set('n', '<localleader>os', ":lua telescope_elixir_stacktrace({})<cr>", {desc="elixir open stacktrace", buffer = true})
require 'key-menu'.set('n', '<localleader>m', {desc='module...', buffer = true})
vim.keymap.set('n', '<localleader>mc', ":lua require'elixir-extras'.module_complete()<cr>", {desc="elixir module complete", buffer = true})

require 'key-menu'.set('n', '<localleader>n', {desc='iNdent', buffer = true})
vim.keymap.set('n', '<localleader>nm', ":lua elixir_match_error_details_indent({})<cr>", {desc="elixir indent match error details", buffer = true})
vim.keymap.set('n', '<localleader>nv', ":lua elixir_indent_output_val()<cr>", {desc="elixir indent output value", buffer = true})

local function elixir_add_stack_to_qf_lines(lines)
  vim.fn.setqflist({}, 'r')
  for _, line in ipairs(lines) do
    local match = vim.fn.matchlist(line, [[\v<((\w|_|/)+\.ex):(\d+)]])
    if #match > 0 then
      vim.fn.setqflist({}, 'a', {
        items = {
          {
            filename = match[2],
            lnum = match[4],
            col = 1,
            text = match[2] .. ":" .. match[4],
          },
        },
      })
    end
  end
  telescope_quickfix_locations{}
end

local function elixir_add_stack_to_qf()
  local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
  elixir_add_stack_to_qf_lines(lines)
end

local function elixir_add_stack_to_qf_sel()
  local start_pos = vim.fn.getpos("'<")
  local end_pos = vim.fn.getpos("'>")
  local lines = vim.fn.getline(start_pos[2], end_pos[2])
  elixir_add_stack_to_qf_lines(lines)
end

vim.keymap.set('n', '<localleader>cqa', elixir_add_stack_to_qf, {desc = "add stacktrace to quickfix", buffer = true})
vim.keymap.set('v', '<leader>cqa', elixir_add_stack_to_qf_sel, {desc = "add stacktrace to quickfix"})
