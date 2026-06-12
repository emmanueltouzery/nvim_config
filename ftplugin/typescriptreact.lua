-- https://www.reddit.com/r/neovim/comments/ykpnob/comment/iuy3lea/
vim.cmd.runtime({"ftplugin/typescript.lua",  bang = true })

-- Set specific surrounding in 'mini.surround'
-- depends on custom after/queries/tsx/textobjects.scm
local ts_input = require('mini.surround').gen_spec.input.treesitter
vim.b.minisurround_config = {
  custom_surroundings = {
    t = {
      input = ts_input({ outer = '@tag.outer', inner = '@tag.inner' }),
    },
    T = {
      input = ts_input({ outer = '@tag_name.outer', inner = '@tag_name.inner' }),
      output = function()
        local tag_name = MiniSurround.user_input('Tag name')
        return { left = tag_name, right = tag_name }
      end,
    },
  },
}

local function wrap_jsx_comment(start_line, end_line)
  local bufnr = 0

  local lines = vim.api.nvim_buf_get_lines(bufnr, start_line - 1, end_line, false)

  for i, line in ipairs(lines) do
    -- skip empty lines if you want (optional)
    if line:match("%S") then
      lines[i] = "{/* " .. line .. " */}"
    end
  end

  vim.api.nvim_buf_set_lines(bufnr, start_line - 1, end_line, false, lines)
end

-- we previously commented "normally" but should have JSX commented
-- => reselect the previous, uncomment, reselect and JSX comment
--
-- if the commenting was done through visual mode, this could be done through 'gv'
-- (reselect), uncomment, change comment string, comment, restore comment string.
--
-- if the commenting was done through normal mode (gcap), this could be done through
-- undo, change comment string, dot-repeat, restore comment string.
--
-- but i don't know which one it was. so i undo, collect the list of modified lines
-- change comment string, comment the same lines, restore comment string.
local function recomment_last_selection_jsx()
  local buffer_after_lines = vim.api.nvim_buf_get_lines(0, 0, -1, false) or {}

  vim.cmd("silent undo")
  local buffer_before_lines = vim.api.nvim_buf_get_lines(0, 0, -1, false) or {}

  local touched_lines_start = nil
  local touched_lines_end = nil
  for i, line_after in ipairs(buffer_after_lines) do
    if line_after ~= buffer_before_lines[i] then
      if touched_lines_start == nil then
        touched_lines_start = i
      end
      touched_lines_end = i
    end
  end
  if touched_lines_start ~= nil and touched_lines_end ~= nil then
    wrap_jsx_comment(touched_lines_start, touched_lines_end)
  end
end

vim.keymap.set('n', 'gR', recomment_last_selection_jsx, { noremap = true, silent = true })
