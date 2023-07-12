local function winnr()
  local nr = vim.fn.winnr()
  if nr == 1 then return '󰎦'
  elseif nr == 2 then return '󰎩'
  elseif nr == 3 then return '󰎬'
  elseif nr == 4 then return '󰎮'
  elseif nr == 5 then return '󰎰'
  elseif nr == 6 then return '󰎵'
  elseif nr == 7 then return '󰎸'
  elseif nr == 8 then return '󰎻'
  elseif nr == 9 then return '󰎾'
  else return ''
  end
end

function _G.lualine_project()
  -- return ' ' .. vim.fn.getcwd():match("[^/]+$");
  return vim.fn.getcwd(vim.fn.winnr()):match("[^/]+$");
end

-- https://stackoverflow.com/a/34953646/516188
function escape_pattern(text)
  return text:gsub("([^%w])", "%%%1")
end

-- lualine's builtin filename function breaks down for non-focused
-- windows. instead of showing the relative path in the module, it
-- shows the relative path from the home dir... do it by hand.
local function inactiveRelativePath()
  local fname = vim.fn.expand('%:p'):gsub(escape_pattern(vim.fn.getcwd(vim.fn.winnr())) .. "/", "")
  if vim.bo.modified then
    fname = fname .. "[+]"
  end
  return fname
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

local function conflict_status()
  if vim.b.conflict_status == 'deleted' then
    return DELETED_ICON
  end
  if vim.b.conflict_status == 'conflict' then
    return CONFLICT_ICON
  end
  return ''
end

local function qf_errors()
  local qflist = vim.fn.getqflist()
  local err_count = 0
  for i, qfentry in ipairs(qflist) do
    if qfentry.type == 'E' then
      err_count = err_count + 1
    end
  end
  if err_count > 0 then
    return "󰐾 " .. err_count
  end
  return ''
end

local lualine = require('lualine')
if lualine then
  lualine.setup {
    options = { 
      disabled_filetypes = {
        'NeogitStatus', -- perf issues over sshfs
        'dashboard',
        'alpha',
        'NvimTree',
        'Outline',
        'NeogitCommitMessage',
        'DiffviewFiles',
        'packer',
        'cheat40',
        'OverseerList',
        'aerial'
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
      lualine_b = {'branch', {'diff', symbols = {added = ' ', modified = ' ', removed = ' '}, }, 'diagnostics', {qf_errors, color={fg='#eabd7a'}}},
      lualine_c = {lualine_project, {conflict_status, color={fg='#ff6c6b', gui='bold'}}, {'filename', path=1}}, -- path=1 => relative filename
      -- lualine_x = { 'encoding', 'fileformat', 'filetype'},
      -- don't color the filetype icon, else it's not always visible with the 'nord' theme.
      lualine_x = { 'filesize', {'filetype', colored = false, icon_only = true}},
      lualine_y = {'progress', scroll_indicator, {
        'lsp_progress', 
        display_components = { 
          -- 'spinner', 'lsp_client_name', {'percentage'},
          'spinner', 'lsp_client_name',
        },
        spinner_symbols = { "⠋", "⠙", "⠹", "⠸", "⠼", "⠴", "⠦", "⠧", "⠇", "⠏" },
      }},
      -- lualine_z = {'location'}
      lualine_z = {
        { 'location', separator = { right = '' }, left_padding = 2 },
      },
    },
    inactive_sections = {
      lualine_b = {
        {winnr, separator = { left = ''}, color = {bg='#4c566a'}},
        {'branch', color = {bg='#4c566a'}},
        {'diff', color = {bg='#4c566a'}, symbols = {added = ' ', modified = ' ', removed = ' '}, },
        {'diagnostics', color = {bg='#4c566a'} },
        {function(str) return "" end, color = {fg='#4c566a'}, padding=0 }
      },
      lualine_c = {lualine_project, inactiveRelativePath},
      lualine_x = { 'filesize', {'filetype', colored = false, icon_only = true}},
      lualine_y = {'progress', scroll_indicator},
      lualine_z = {
        { 'location', separator = { left = '', right = '' }, left_padding = 2, color = {bg='#4c566a', fg='white'} },
      },
    },
  }
end

-- vim: ts=2 sts=2 sw=2 et
