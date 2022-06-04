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

-- -- https://www.reddit.com/r/neovim/comments/uy3lnh/how_can_i_display_lsp_loading_in_my_statusline/
-- -- alternative: https://github.com/arkav/lualine-lsp-progress
-- function lsp_progress()
--   print("call " .. vim.loop.hrtime())
--   progress_per_name = {}
--   for _, lsp in ipairs(vim.lsp.util.get_progress_messages()) do
--     local name = lsp.name or ""
--     local percentage = lsp.percentage or 0
--     local existing = progress_per_name[name]
--     if existing == nil or percentage < existing then
--       progress_per_name[name] = percentage
--     end
--   end
--   local msg = ""
--   for name, percentage in pairs(progress_per_name) do
--     if percentage < 100 then -- don't want it to keep displaying 100% when it's done
--       msg = msg .. " " .. string.format("%%<%s: %s%%%%", name, percentage)
--     end
--   end
--   if strings.strdisplaywidth(msg) > 0 then
--     local spinners = { "⠋", "⠙", "⠹", "⠸", "⠼", "⠴", "⠦", "⠧", "⠇", "⠏" }
--     local ms = vim.loop.hrtime() / 1000000
--     local frame = math.floor(ms / 120) % #spinners
--     return "ﮒ " .. spinners[frame + 1] .. msg -- ﬥ
--   end
--   return ""
-- end
--   -- local lsp = vim.lsp.util.get_progress_messages()[1]
--   -- if lsp then
--   --   local name = lsp.name or ""
--   --   local msg = lsp.message or ""
--   --   local percentage = lsp.percentage or 0
--   --   local title = lsp.title or ""
--   --   -- return string.format(" %%<%s: %s %s (%s%%%%) ", name, title, msg, percentage)
--   --   return string.format("ﮒ %%<%s: %s%%%%", name, percentage) -- ﬥ
--   -- end
--   -- return lsp.name

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
