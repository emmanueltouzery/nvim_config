local Str = require'plenary.strings'

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

  -- unicode alternative
  -- if nr == 1 then return '①'
  -- elseif nr == 2 then return '②'
  -- elseif nr == 3 then return '③'
  -- elseif nr == 4 then return '④'
  -- elseif nr == 5 then return '⑤'
  -- elseif nr == 6 then return '⑥'
  -- elseif nr == 7 then return '⑦'
  -- elseif nr == 8 then return '⑧'
  -- elseif nr == 9 then return '⑨'
  else return ''
  end
end

local function tabnr_display(nr)
  -- rendering with nerdfonts...
  if nr == 1 then return '󰯭 '
  elseif nr == 2 then return '󰯰 '
  elseif nr == 3 then return '󰯳 '
  elseif nr == 4 then return '󰯶 '
  elseif nr == 5 then return '󰯹 '
  elseif nr == 6 then return '󰯼 '
  elseif nr == 7 then return '󰯿 '
  elseif nr == 8 then return '󰰂 '
  elseif nr == 9 then return '󰰅 '
  else return nr
  end
  
  -- square unicode also less good
  -- if nr == 1 then return '🄰 '
  -- elseif nr == 2 then return '🄱 '
  -- elseif nr == 3 then return '🄲 '
  -- elseif nr == 4 then return '🄳 '
  -- elseif nr == 5 then return '🄴 '
  -- elseif nr == 6 then return '🄵 '
  -- elseif nr == 7 then return '🄶 '
  -- elseif nr == 8 then return '🄷 '
  -- elseif nr == 9 then return '🄸 '

  -- circle unicode also less good
  -- if nr == 1 then return 'Ⓐ '
  -- elseif nr == 2 then return 'Ⓑ '
  -- elseif nr == 3 then return 'Ⓒ '
  -- elseif nr == 4 then return 'Ⓓ '
  -- elseif nr == 5 then return 'Ⓔ '
  -- elseif nr == 6 then return 'Ⓕ '
  -- elseif nr == 7 then return 'Ⓖ '
  -- elseif nr == 8 then return 'Ⓗ '
  -- elseif nr == 9 then return 'Ⓘ '
  -- else return nr
  -- end
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

-- when there are lots of QF entry i've seen perf issues
-- throttle to compute only every few seconds
-- relevant: https://github.com/vim/vim/pull/16216
vim.g.my_lualine_qf_errors_count = ''
vim.g.my_lualine_qf_error_last_computed = 0
local function qf_errors()
  local elapsed_ms = (vim.loop.hrtime() - vim.g.my_lualine_qf_error_last_computed) / 1e6
  if elapsed_ms > 3000 then
    local qflist = vim.fn.getqflist()
    local err_count = 0
    for i, qfentry in ipairs(qflist) do
      if qfentry.type == 'E' then
        err_count = err_count + 1
      end
    end
    if err_count > 0 then
      vim.g.my_lualine_qf_errors_count = "󰐾 " .. err_count
    else
      vim.g.my_lualine_qf_errors_count = ''
    end
    vim.g.my_lualine_qf_error_last_computed = vim.loop.hrtime()
  end
  return vim.g.my_lualine_qf_errors_count
end

local function minidiff_diff_source()
  local minidiff = MiniDiff.get_buf_data(0)
  if minidiff == nil then
    return nil
  end
  return {
    added = minidiff.summary.add,
    modified = minidiff.summary.change,
    removed = minidiff.summary.delete,
  }
end

local buffer_repo_cache = {}
local repo_branch_cache = {}

local function git_branch_from_path(git_path)
  -- print("get git branch")
  local head_path = git_path .. "/.git/HEAD"
  local f_head = io.open(head_path)
  if f_head == nil then
    -- had this happen to me when switching branches
    return ""
  end
  local head = f_head:read()
  local branch = head:match('ref: refs/heads/(.+)$')
  if not branch then
    branch = head:sub(1, 6)
  end
  f_head:close()
  return branch
end

local function git_branch_changed(git_path)
  local prev_watcher = repo_branch_cache[git_path] and repo_branch_cache[git_path][2]
  if prev_watcher then
    -- print("close previous watcher")
    prev_watcher:close()
  end

  local branch = git_branch_from_path(git_path)
  local watcher = vim.loop.new_fs_event()
  repo_branch_cache[git_path] = { branch, watcher }

  watcher:start(git_path .. "/.git/HEAD", {}, vim.schedule_wrap(function(err, fname, evts)
    if evts.change then
      git_branch_changed(git_path)
    end
  end))

  return branch
end

-- made my own git_branch lualine component as the official one didn't properly
-- update for non-focused buffers on branch change for me.
local function git_branch()
  local cur_bufnr = vim.api.nvim_get_current_buf()
  local cached_repo = buffer_repo_cache[cur_bufnr]
  if cached_repo then
    return repo_branch_cache[cached_repo][1]
  end
  local path = vim.fn.expand('%:p')
  -- print("get git path")
  local git_path = vim.fs.root(path, '.git')
  buffer_repo_cache[cur_bufnr] = git_path

  if repo_branch_cache[git_path] then
    return repo_branch_cache[git_path][1]
  end

  return git_branch_changed(git_path)
end

local function adb_status()
  return vim.g.adb_status or ""
end

local function dap_status()
  local dap_sessions = vim.fn.join(
    vim.tbl_map(
      function(s) return s.config.name end,
      vim.tbl_filter(function(s) return s ~= nil end, require'dap'.sessions())
    ),
    ", ")
  if #dap_sessions > 0 then
    return " " .. dap_sessions
  else
    return dap_sessions
  end
end

local function lsp_pending()
  return vim.g.lualine_lsp_pending or ""
end

function setup_lualine()
  local lualine = require('lualine')

  local active_lsp_requests = {}
  vim.api.nvim_create_autocmd('LspRequest', {
    callback = function(args)
      local request = args.data.request
      local request_id = args.data.request_id
      -- print(request.type .. " " .. request_id)
      if request.type == 'pending' then
        active_lsp_requests[request_id] = true
      elseif request.type == 'cancel' then
        active_lsp_requests[request_id] = nil
      elseif request.type == 'complete' then
        active_lsp_requests[request_id] = nil
      else
        print("Unknown LSP request type: " .. request.type)
        notif({"Unknown LSP request type: " .. request.type})
      end
      -- print(vim.inspect(active_lsp_requests))
      local active_lsp_requests = vim.tbl_count(active_lsp_requests)
      if active_lsp_requests > 0 then
        vim.g.lualine_lsp_pending = "󰘦 Pending LSP requests: " .. active_lsp_requests
      else
        vim.g.lualine_lsp_pending = ""
      end
    end
  })
  if lualine then
    -- these extra entries are defined in my private configuration
    local lualine_tabline_end = vim.g.lualine_extra_entries and vim.g.lualine_extra_entries() or {}
    table.insert(lualine_tabline_end,
      {dap_status, color = "@comment.todo"}
    )
    table.insert(lualine_tabline_end,
    {
      adb_status,
    })
    table.insert(lualine_tabline_end, {
      "overseer",
      name = vim.g.lualine_extra_entries_names or "",
      name_not = true,
    })

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
          'aerial',
          'agitator',
          'dbui',
          'dapui_watches',
          'dapui_stacks',
          'dapui_breakpoints',
          'dapui_scopes',
        },
        theme = 'nord',
        component_separators = '|',
        section_separators = { left = '', right = '' },
        always_show_tabline = false,
        refresh = {
          -- the default refresh rate is every 100ms which I think is a little excessive
          statusline = 250,
          tabline = 250,
          winbar = 250,
        }
      },
      sections = {
        lualine_a = {
          { winnr, padding = 0, separator = { left = '' }},
          { 'mode', fmt = function(str) return str:sub(1,3) end , separator = {left=nil, right=''} },
        },
        -- lualine_a = {'mode'},
        lualine_b = {git_branch, {'diff', symbols = {added = ' ', modified = ' ', removed = ' '}, source = minidiff_diff_source }, 'diagnostics'},
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
          {git_branch, color = {bg='#4c566a'}},
          {'diff', color = {bg='#4c566a'}, symbols = {added = ' ', modified = ' ', removed = ' '}, source = minidiff_diff_source },
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
      tabline = {
        lualine_a = {
          {qf_errors, color={bg='#4c566a', fg='#eabd7a'}},
        },
        lualine_b = {
          {'tabs',
          tabs_color = { active = 'lualine_a_normal', inactive = 'lualine_c_normal' },
          fmt = function(label, tab)
            local ok, w = pcall(vim.api.nvim_tabpage_get_win, tab.tabId)
            if ok then
              local b = vim.api.nvim_win_get_buf(w)
              local ft = vim.api.nvim_buf_get_option(b, 'ft')
              if label == "[No Name]" then
                label = ft
              end
              if ft == "sql" or ft == "dbui" or ft == "dbout" then
                label = " " .. label
              elseif ft == "DiffviewFilePanel" or ft == "DiffviewFiles" or ft == "NeogitStatus" then
                label = "󰊢 " .. label
              else
                label = require("nvim-web-devicons").get_icon_by_filetype(ft, {default = true}) .. " " .. label
              end
            end
            if Str.strdisplaywidth(label) > 25 then
              -- tab_max_length is supposed to allow that but it didn't seem to work
              label = Str.truncate(label, 25)
            end
            return tabnr_display(tab.tabnr) .. ' ' .. label
          end,
          section_separators = { left = "", right = "" },
          mode=1},
        },
        lualine_c = {
          {lsp_pending, color = 'Comment'}
        },
        lualine_x = lualine_tabline_end,
      },
    }
  end
end
-- vim: ts=2 sts=2 sw=2 et
