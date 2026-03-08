-- see  typescript_insert_inspect_param
local function lua_insert_inspect_param()
  winid = vim.api.nvim_get_current_win()
  local cur_line = vim.fn.line('.')
  local cur_col = vim.fn.col('.')
  local param_name = vim.fn.expand("<cword>")
  local cur_line_str = vim.api.nvim_buf_get_lines(0, cur_line-1, cur_line, false)[1]
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
      vim.cmd('norm! aprint(vim.inspect(' .. param_name .. ')')
      -- position the cursor in the quotes to enable quick rename
      vim.cmd('startinsert')
    end
  }
end
vim.keymap.set('n', '<localleader>ip', lua_insert_inspect_param, {desc="lua add inspect parameter", buffer = true})

local function lua_insert_inspect_label()
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
      vim.cmd('norm! aprint("")')
      -- position the cursor in the quotes to enable quick rename
      vim.cmd('norm! h')
      vim.cmd('startinsert')
    end
  }
end
vim.keymap.set('n', '<localleader>il', lua_insert_inspect_label, {desc="lua add inspect label", buffer = true})

