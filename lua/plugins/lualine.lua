local function winnr()
  local nr = vim.fn.winnr()
  if nr == 1 then return ''
  elseif nr == 2 then return ''
  elseif nr == 3 then return ''
  elseif nr == 4 then return ''
  elseif nr == 5 then return ''
  elseif nr == 6 then return ''
  elseif nr == 7 then return ''
  elseif nr == 8 then return ''
  elseif nr == 9 then return ''
  else return ''
  end
end

local function project()
  -- return ' ' .. vim.fn.getcwd():match("[^/]+$");
  return vim.fn.getcwd(vim.fn.winnr()):match("[^/]+$");
end

function _G.toggle_comment_custom_commentstring_curline()
  startline = vim.fn.line('.')
  endline = vim.fn.line('.')
  _G.toggle_comment_custom_commentstring(startline, endline)
end

function _G.toggle_comment_custom_commentstring_sel()
  local startline = vim.fn.line("'<")
  local endline = vim.fn.line("'>")
  _G.toggle_comment_custom_commentstring(startline, endline)
end

-- https://github.com/b3nj5m1n/kommentary/issues/11
--[[ This is our custom function for toggling comments with a custom commentstring,
it's based on the default toggle_comment, but before calling the function for
toggling ranges, it sets the commenstring to something else. After it is done,
it sets it back to what it was before. ]]
function _G.toggle_comment_custom_commentstring(startline, endline)
  -- Save the current value of commentstring so we can restore it later
  local commentstring = vim.bo.commentstring
  -- Set the commentstring for the current buffer to something new
  vim.bo.commentstring =  "{/*%s*/}"
  --[[ Call the function for toggling comments, which will resolve the config
    to the new commentstring and proceed with that. ]]
  require('kommentary.kommentary').toggle_comment_range(startline, endline,
    require('kommentary.config').get_modes().normal)
  -- Restore the original value of commentstring
  vim.api.nvim_buf_set_option(0, "commentstring", commentstring)
end

-- https://stackoverflow.com/a/34953646/516188
function escape_pattern(text)
  return text:gsub("([^%w])", "%%%1")
end

-- lualine's builtin filename function breaks down for non-focused
-- windows. instead of showing the relative path in the module, it
-- shows the relative path from the home dir... do it by hand.
local function inactiveRelativePath()
  return vim.fn.expand('%:p'):gsub(escape_pattern(vim.fn.getcwd(vim.fn.winnr())) .. "/", "")
end

local function scroll_indicator()
  local current_line = vim.fn.line('w0')
  local current_bottom_line = vim.fn.line('w$')
  local total_lines = vim.fn.line('$')
  local scroll_ratio = current_line / total_lines
  local height = vim.fn.winheight(0)
  local display_ratio = height / total_lines
  local display_ratio_step1 = 0.10
  local display_ratio_step2 = 0.25
  if height >= total_lines then
    return "⣿⣿"
  end
  if display_ratio < display_ratio_step1 then
    -- indicator is 1 row tall
    if current_line == 1 then
      return "⠉⠉"
    elseif scroll_ratio < 0.4 then
      return "⠒⠒"
    elseif current_bottom_line < total_lines then
      return "⠤⠤"
    else
      return "⣀⣀"
    end
  elseif display_ratio < display_ratio_step2 then
    -- indicator is 2 rows tall
    if current_line == 1 then
      return "⠛⠛"
    elseif current_bottom_line < total_lines then
      return "⠶⠶"
    else
      return "⣤⣤"
    end
  else 
    -- indicator is 3 rows tall
    if scroll_ratio < 0.4 then
      return "⠿⠿"
    else
      return "⣶⣶"
    end
  end
end

local lualine = require('lualine')
if lualine then
  lualine.setup {
    options = { 
      disabled_filetypes = {
        'NeogitStatus', -- perf issues over sshfs
        'dashboard',
        'NvimTree',
        'Outline',
        'NeogitCommitMessage',
        'DiffviewFiles',
        'packer',
        'cheat40',
      },
      theme = 'nord',
      component_separators = '|',
      section_separators = { left = '', right = '' },
    }, 
    sections = {
      lualine_a = {
        { winnr, padding = 0, separator = { left = '' }},
        { 'mode', fmt = function(str) return str:sub(1,3) end , separator = {left=nil, right=''} },
      },
      -- lualine_a = {'mode'},
      lualine_b = {'branch', 'diff', 'diagnostics'},
      lualine_c = {project, {'filename', path=1}}, -- path=1 => relative filename
      -- lualine_x = { 'encoding', 'fileformat', 'filetype'},
      -- don't color the filetype icon, else it's not always visible with the 'nord' theme.
      lualine_x = { 'filesize', {'filetype', colored = false, icon_only = true}},
      lualine_y = {'progress', scroll_indicator},
      -- lualine_z = {'location'}
      lualine_z = {
        { 'location', separator = { right = '' }, left_padding = 2 },
      },
    },
    inactive_sections = {
      lualine_b = {
        {winnr, separator = { left = ''}, color = {bg='#4c566a'}},
        {'branch', color = {bg='#4c566a'}},
        {'diff', color = {bg='#4c566a'}},
        {'diagnostics', color = {bg='#4c566a'} },
        {function(str) return "" end, color = {fg='#4c566a'}, padding=0 }
      },
      lualine_c = {project, inactiveRelativePath},
      lualine_x = { 'filesize', {'filetype', colored = false, icon_only = true}},
      lualine_y = {'progress', scroll_indicator},
      lualine_z = {
        { 'location', separator = { left = '', right = '' }, left_padding = 2, color = {bg='#4c566a', fg='white'} },
      },
    },
  }
end

-- vim: ts=2 sts=2 sw=2 et
