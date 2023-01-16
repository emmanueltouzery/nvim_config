local Job = require'plenary.job'
local strings = require'plenary.strings'

function _G.my_open_tele(cur_folder_only)
    local w = vim.fn.expand('<cword>')
    local params = {}
    if cur_folder_only then
      local folder = vim.fn.expand('%:h')
      params.cwd = folder
    end
    require("telescope").extensions.live_grep_raw.live_grep_raw(params)
    vim.fn.feedkeys(w)
end

function _G.my_open_tele_sel(cur_folder_only)
    local w = get_visual_selection()
    local params = {}
    if cur_folder_only then
      local folder = vim.fn.expand('%:h')
      params.cwd = folder
    end
    require("telescope").extensions.live_grep_raw.live_grep_raw(params)
    vim.fn.feedkeys(w)
end

function _G.copy_to_clipboard(to_copy)
    vim.fn.setreg('+', to_copy)
end

function _G.to_file_path_in_project(full_path)
    for _, project in pairs(get_project_objects()) do
        if full_path:match("^" .. escape_pattern(project.path)) then
            return {project.path, full_path:gsub("^" .. escape_pattern(project.path .. "/"), "")}
        end
    end
    return nil
end

function _G.cur_file_path_in_project()
    local full_path = vim.fn.expand("%:p")
    local project_info = to_file_path_in_project(full_path)
    -- if no project that matches, return the relative path
    return project_info and project_info[2] or vim.fn.expand("%")
end

-- if you have a git project that has subfolders..
-- in a subfolder there is a package.json.. then vim-rooter
-- will set the cwd to that subfolder -- not the git repo root.
-- with this we get the actual git repo root.
function _G.cur_file_project_root()
    local full_path = vim.fn.expand("%:p")
    for _, project in pairs(get_project_objects()) do
      if full_path:match("^" .. escape_pattern(project.path) .. '/') 
        and vim.fn.isdirectory(project.path .. "/.git") ~= 0 then
        return project.path
      end
    end
    -- no project that matches, return the current folder
    return vim.fn.getcwd()
end

-- https://stackoverflow.com/a/34953646/516188
function escape_pattern(text)
  return text:gsub("([^%w])", "%%%1")
end

function _G.get_file_line()
    local file_path = cur_file_path_in_project()
    local line = vim.fn.line(".")
    return "`" .. file_path .. ":" .. line .. "`"
end

function _G.copy_file_line()
    local to_copy = get_file_line()
    vim.fn.setreg('+', to_copy)
    print(to_copy)
end

function get_visual_selection()
  -- https://github.com/neovim/neovim/pull/13896#issuecomment-774680224
  -- local s_start = vim.fn.getpos("'<")
  -- local s_end = vim.fn.getpos("'>")
  local s_start = vim.fn.getpos("v")
  local s_end = vim.fn.getcurpos()
  if s_end[2] < s_start[2] or (s_end[2] == s_start[2] and s_end[3] < s_start[3]) then
    e = s_start
    s_start = s_end
    s_end = e
  end
  local n_lines = math.abs(s_end[2] - s_start[2]) + 1
  local lines = vim.api.nvim_buf_get_lines(0, s_start[2] - 1, s_end[2], false)
  print(vim.inspect(s_start) .. " / " .. vim.inspect(s_end) .. " / " .. vim.inspect(lines))
  lines[1] = string.sub(lines[1], s_start[3], -1)
  if n_lines == 1 then
    lines[n_lines] = string.sub(lines[n_lines], 1, s_end[3] - s_start[3] + 1)
  else
    lines[n_lines] = string.sub(lines[n_lines], 1, s_end[3])
  end
  return table.concat(lines, '\n')
end

function _G.get_file_line_sel()
    local file_path = cur_file_path_in_project()
    -- https://github.com/neovim/neovim/pull/13896#issuecomment-774680224
    local start_line = vim.fn.getpos("v")[2]
    local end_line = vim.fn.getcurpos()[2]
    -- local start_line = vim.fn.line("'<")
    -- local end_line = vim.fn.line("'>")
    return "`" .. file_path .. ":" .. start_line .. "-" .. end_line .. "`"
end

function _G.copy_file_line_sel()
    local to_copy = get_file_line_sel()
    vim.fn.setreg('+', to_copy)
    print(to_copy)
end

function _G.filter_lsp_symbols(query)
  if #vim.lsp.buf_get_clients() == 0 then
    -- no LSP clients. I'm probably in a floating window.
    -- close it so we focus on the parent window that has a LSP
    if vim.api.nvim_win_get_config(0).zindex > 0 then
      vim.api.nvim_win_close(0, false)
    end
  end
  require'telescope.builtin'.lsp_workspace_symbols {query=query}
end

function _G.goto_fileline()
  vim.ui.input({prompt="Enter file:line please: ", kind="center_win"}, function(input)
    if input ~= nil then
      vim.cmd("redraw") -- https://stackoverflow.com/a/44892301/516188
      local fname = input:match("[^:]+")
      local line = input:gsub("[^:]+:", "")
      for _, project in pairs(get_project_objects()) do
        if vim.fn.filereadable(project.path .. "/" .. fname) == 1 then
          vim.cmd(":e " .. project.path .. "/" .. fname)
          if string.match(line, "^%d+$") then
            vim.cmd(":" .. line)
          end
          return
        end
      end
      -- didn't go the easy way.. let's try to be more tolerant.
      -- maybe we got a subpath, not rooted. eg only a filename,
      -- or only like app/win.rs instead of src/app/win.rs
      -- we can leverage 'fd' for that.
      for _, project in pairs(get_project_objects()) do
        local output = nil
        Job:new({
          command = 'fd',
          args = { '-p', fname },
          cwd = project.path,
          on_exit = function(j, return_val)
            output = j:result()
          end,
        }):sync()
        if output ~= nil and #output > 0 and vim.fn.filereadable(project.path .. "/" .. output[1]) == 1 then
          vim.cmd(":e " .. project.path .. "/" .. output[1])
          vim.cmd(":" .. line)
          return
        end
      end
      vim.cmd("echoh WarningMsg | echo \"Can't find file in any project: " .. fname .. "\" | echoh None")
    end
  end)
end

function _G.ShowCommitAtLine()
    local commit_sha = require"agitator".git_blame_commit_for_line()
    vim.cmd("DiffviewOpen " .. commit_sha .. "^.." .. commit_sha .. "  --selected-file=" .. vim.fn.expand("%:p"))
end

-- TELESCOPE-PROJECT START
-- lifted from https://github.com/nvim-telescope/telescope-project.nvim/blob/master/lua/telescope/_extensions/project/utils.lua
telescope_projects_file = vim.fn.stdpath('data') .. '/telescope-projects.txt'

-- Get project info for all (de)activated projects
get_project_objects = function()
  local projects = {}
  for line in io.lines(telescope_projects_file) do
    local project = parse_project_line(line)
    table.insert(projects, project)
  end
  return projects
end

-- Extracts information from telescope projects line
parse_project_line = function(line)
  local title, path, workspace, activated = line:match("^(.-)=(.-)=(.-)=(.-)$")
  if not workspace then
    title, path = line:match("^(.-)=(.-)$")
    workspace = 'w0'
  end
  if not activated then
    title, path, workspace = line:match("^(.-)=(.-)=(.-)$")
    activated = 1
  end
  return {
    title = title,
    path = path,
    workspace = workspace,
    activated = activated
  }
end

-- 
-- TELESCOPE-PROJECT END

function _G.select_current_qf(also_print)
    local qf_entries = vim.fn.getqflist()
    local i = 1
    local cur_text = ""
    while qf_entries[i] do
        local qf_entry = qf_entries[i]
        if qf_entry.lnum == 0 then
            cur_text = cur_text .. "\n" .. qf_entry.text
        elseif qf_entry.lnum == vim.fn.line('.') and qf_entry.bufnr == vim.fn.bufnr() then
            if also_print then
                print(cur_text)
            end
            vim.cmd(":cc " .. i)
            cur_text = ""
        else
            -- new message, reset
            cur_text = ""
        end
        i = i+1
    end
end

-- when running tests, i have the output in quickfix and in a terminal buffer
-- thanks to my fork of dispatch-neovim. When the cursor is on top of a line
-- with a failing test, open a popup centered on the relevant line in the text
-- output.
function _G.test_output_in_popup()
  -- if a popup is already open, close it and exit
  if vim.b.popup_win ~= nil and vim.api.nvim_win_is_valid(vim.b.popup_win) then
    vim.api.nvim_win_close(vim.b.popup_win, true)
    vim.b.popup_win = nil
    return
  end

  -- collect the quickfix text for this line so i can search for it in the popup
  local qf_entries = vim.fn.getqflist()
  local i = 1
  local text = nil
  while qf_entries[i] do
    local qf_entry = qf_entries[i]
    if qf_entry.lnum == vim.fn.line('.') and qf_entry.bufnr == vim.fn.bufnr() then
      text = qf_entry.text
      break
    end
    i = i+1
  end
  -- is there a terminal to embed?
  if vim.g.test_term_buf_id ~= nil and vim.fn.bufexists(vim.g.test_term_buf_id) == 1 then
    -- yes, work on positioning the popup
    local current_top_line = vim.fn.line('w0')
    local current_bottom_line = vim.fn.line('w$')
    local current_line = vim.fn.line('.')
    local anchor = "NW"
    if current_line - current_top_line > current_bottom_line - current_line then
      -- we're closer to the bottom of the screen than to the top...
      anchor = "SW"
    end
    local opts = {
      focusable = true,
      style = "minimal",
      border = "rounded",
      relative = "cursor",
      width = 120,
      height = 20,
      anchor = anchor,
      row = 2,
      col = 30,
    }

    vim.b.popup_win = vim.api.nvim_open_win(vim.g.test_term_buf_id, false, opts)
    -- set the focus to the popup, add shortcuts to close it
    vim.api.nvim_set_current_win(vim.b.popup_win)
    vim.cmd("nmap <buffer> q <C-W>c")
    vim.cmd("nmap <buffer> <Esc> <C-W>c")
    -- search for :line_num\b, zz to center
    vim.fn.feedkeys("/" .. ":" .. current_line .. "\\>\rzz")
    -- if text ~= nil then
    -- vim.fn.feedkeys("/" .. text:gsub("([^%w])", '.') .. "\\|:" .. current_line .. "\rzz")
    -- vim.cmd("match Search /\%'.line('.').'l/'")
    -- end
  end
end

-- when running tests, i have the output in quickfix and in a terminal buffer
-- thanks to my fork of dispatch-neovim. When the cursor is on top of a line
-- with a failing test, open the text output in the current window.
function _G.test_output_open()
  -- collect the quickfix text for this line so i can search for it in the popup
  local qf_entries = vim.fn.getqflist()
  local i = 1
  local text = nil
  while qf_entries[i] do
    local qf_entry = qf_entries[i]
    if qf_entry.lnum == vim.fn.line('.') and qf_entry.bufnr == vim.fn.bufnr() then
      text = qf_entry.text
      break
    end
    i = i+1
  end
  -- is there a terminal to embed?
  if vim.g.test_term_buf_id ~= nil and vim.fn.bufexists(vim.g.test_term_buf_id) == 1 then
    local current_line = vim.fn.line('.')
    -- yes, open the buffer in the current window
    vim.cmd(":b" .. vim.g.test_term_buf_id)
    -- search for :line_num\b, zz to center
    vim.fn.feedkeys("/" .. ":" .. current_line .. "\\>\rzz")
    -- if text ~= nil then
    -- vim.fn.feedkeys("/" .. text:gsub("([^%w])", '.') .. "\\|:" .. current_line .. "\rzz")
    -- vim.cmd("match Search /\%'.line('.').'l/'")
    -- end
  end
end

function is_diff_line(line_no)
    -- https://www.reddit.com/r/vim/comments/k2r7b/how_do_i_execute_a_command_on_all_differences_in/c2hee5z/
    -- https://stackoverflow.com/a/20010859/516188
    return vim.fn.diff_hlID(line_no, 1) > 0
end

function diff_get_start_end_line()
    -- https://vi.stackexchange.com/a/36854/38754
    local line = vim.fn.line(".")
    local startline = line
    while (is_diff_line(startline - 1))
    do
        startline = startline - 1
    end
    local endline = line
    while (is_diff_line(endline + 1))
    do
        endline = endline + 1
    end
    return startline, endline
end

function diffget_and_keep(put_after)
    -- go to the start of my diff. if lines were deleted and the
    -- the matching diff on the other side is shorter, i must go
    -- to the start of my diff to really end up in the other diff
    -- otherwise i end up AFTER the matching area on the right.
    local startline_here, endline_here = diff_get_start_end_line()
    vim.cmd(":" .. startline_here)

    -- switch to other window
    vim.cmd('wincmd l')
    if not is_diff_line(vim.fn.line(".")) then
      -- i ended up on a non-diff line on the other side
      -- that can't be right, work around, assume the real
      -- one is the previous line
      vim.cmd(":" .. (vim.fn.line('.')-1))
    end
    local startline_other, endline_other = diff_get_start_end_line()
    -- go to the start line of the hunk to simplify things
    -- vim.fn.feedkeys(startline .. 'G')
    -- yank relevant lines into register f
    vim.cmd(startline_other .. ',' .. endline_other .. 'y f')

    -- back to where i was
    vim.cmd('wincmd h')

    if put_after then
        -- to paste after, we must move to the end of the block
        local hunk_lines = endline_here - startline_here
        for i=1,hunk_lines do
            vim.fn.feedkeys('j')
        end
        vim.fn.feedkeys('"fp')
    else
        vim.fn.feedkeys('k"fp')
    end
end

function _G.diffget_and_keep_before()
    diffget_and_keep(false)
end

function _G.diffget_and_keep_after()
    diffget_and_keep(true)
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

function _G.toggle_highlight_global_marks()
  -- https://stackoverflow.com/a/39584989/516188
  vim.cmd("highlight GlobalMarks ctermbg=darkred guibg=darkred")
  if vim.g.global_marks_highlight_is_on then
    vim.cmd("windo match GlobalMarks //")
    vim.g.global_marks_highlight_is_on = false
  else
    vim.cmd([[windo match GlobalMarks /\v.*(%'A|%'B|%'C|%'D|%'E|%'F|%'G|%'H|%'I|%'J|%'K|%'L|%'M|%'N|%'O|%'P|%'Q|%'R|%'S|%'T|%'U|%'V|%'W|%'X|%'Y|%'Z).*/]])
    vim.g.global_marks_highlight_is_on = true
  end
end

function _G.add_global_mark()
  -- find a free mark name
  used_marks = {}
  for i, mark in ipairs(vim.fn.getmarklist()) do
    if mark.mark:match("[A-Z]") then
      used_marks[strings.strcharpart(mark.mark, 1, 1)] = true
    end
  end
  for i, mark in ipairs({'A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M', 
                        'N', 'O', 'P', 'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z'}) do
    if used_marks[mark] == nil then
      vim.fn.feedkeys("m" .. mark)
      vim.cmd("redraw!")
      vim.cmd("wshada!")
      return
    end
  end
  print("All marks are used up!")
end

CONFLICT_ICON = '' -- semantically 罹 was a better option, but it's smaller
DELETED_ICON = 'ﰸ'

function _G.handleFileChanged()
  -- position the popup bottom-right of the window
  local width = vim.fn.winwidth(0)
  local height = vim.fn.winheight(0)

  local popup_buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_option(popup_buf, 'buftype', 'nofile')
  vim.api.nvim_buf_set_option(popup_buf, 'modifiable', true)

  local opts = {
    focusable = false,
    style = "minimal",
    border = "rounded",
    relative = "win",
    width = 55,
    height = 5,
    anchor = "SE",
    row = height,
    col = width,
  }

  local popup_win = vim.api.nvim_open_win(popup_buf, false, opts)

  local reasonDesc = "because there was a conflict"
  local icon = CONFLICT_ICON
  if vim.v.fcs_reason == "deleted" then
    reasonDesc = "because it was deleted"
    icon = DELETED_ICON
  end

  local lines = {
    icon .. " WARNING", 
    "The file for this buffer was edited elsewhere", 
    "Cannot update the file automatically",
    reasonDesc,
    "Reload the file with :e! or force write it with :w!"
  }
  vim.api.nvim_buf_set_lines(popup_buf, 0, -1, false, lines)

  vim.api.nvim_buf_add_highlight(popup_buf, -1, "Identifier", 0, 0, -1);
  vim.api.nvim_buf_add_highlight(popup_buf, -1, "PreProc", 1, 0, -1);
  vim.defer_fn(function()
    vim.api.nvim_win_close(popup_win, true)
  end, 5000)  
end

function _G.get_qf_locations(opts)
  local qf_identifier = opts.id or vim.F.if_nil(opts.nr, "$")
  local all_locations = vim.fn.getqflist({ [opts.id and "id" or "nr"] = qf_identifier, items = true }).items
  local locations = {}
  for _, loc in ipairs(all_locations) do
    local filename = loc.filename or vim.api.nvim_buf_get_name(loc.bufnr)
    -- the lnum > 1 is a heuristic: in general things at the first line are useless.
    -- consider maybe changing to >=1, to be seen (EDIT: changed)
    if loc.lnum >= 1 and vim.fn.filereadable(filename) == 1 then
      table.insert(locations, loc)
    end
  end
  return locations
end

function get_sorted_qf_locations()
  local locations = _G.get_qf_locations({})

  table.sort(locations, function(a,b) 
    local a_filename = a.filename or vim.api.nvim_buf_get_name(a.bufnr)
    local b_filename = b.filename or vim.api.nvim_buf_get_name(b.bufnr)
    if a_filename < b_filename then
      return true
    end
    if a_filename > b_filename then
      return false
    end
    -- same file
    return a.lnum < b.lnum
  end)
  return locations
end

function _G.next_quickfix()
  next_quickfix()
end

function next_quickfix()
  local sorted_qf_locations = get_sorted_qf_locations()

  -- find the first record for my filename
  local fname = vim.fn.expand('%:p')
  local lnum = vim.fn.line('.')
  local pick_next_fname = false

  -- if the current file is not one of the quickfix files, pick the first match we find
  local cur_fname_in_list = false
  for i, entry in ipairs(sorted_qf_locations) do
    local cur_fname = entry.filename or vim.api.nvim_buf_get_name(entry.bufnr)
    if cur_fname == fname then
      cur_fname_in_list = true
    end
  end
  if not cur_fname_in_list then
    pick_next_fname = true
  end

  for i, entry in ipairs(sorted_qf_locations) do
    local cur_fname = entry.filename or vim.api.nvim_buf_get_name(entry.bufnr)
    if cur_fname == fname then
      pick_next_fname = true
      if entry.lnum > lnum then
        vim.cmd(':' .. entry.lnum)
        select_current_qf(false)
        return
      end
    elseif pick_next_fname then
      vim.cmd('e ' .. cur_fname)
      vim.cmd(':' .. entry.lnum)
      select_current_qf(false)
      return
    end
  end
  -- no match, wraparound
  if #sorted_qf_locations > 0 then
    local entry = sorted_qf_locations[1]
    local cur_fname = entry.filename or vim.api.nvim_buf_get_name(entry.bufnr)
    vim.cmd('e ' .. cur_fname)
    vim.cmd(':' .. entry.lnum)
    select_current_qf(false)
  end
end

function _G.previous_quickfix()
  previous_quickfix()
end

function previous_quickfix()
  local sorted_qf_locations = get_sorted_qf_locations()

  -- find the first record for my filename
  local fname = vim.fn.expand('%:p')
  local lnum = vim.fn.line('.')
  local pick_next_fname = false

  -- if the current file is not one of the quickfix files, pick the first match we find
  local cur_fname_in_list = false
  for i, entry in ipairs(sorted_qf_locations) do
    local cur_fname = entry.filename or vim.api.nvim_buf_get_name(entry.bufnr)
    if cur_fname == fname then
      cur_fname_in_list = true
    end
  end
  if not cur_fname_in_list then
    pick_next_fname = true
  end

  for i = #sorted_qf_locations, 1, -1 do
    entry = sorted_qf_locations[i]
    local cur_fname = entry.filename or vim.api.nvim_buf_get_name(entry.bufnr)
    if cur_fname == fname then
      pick_next_fname = true
      if entry.lnum < lnum then
        vim.cmd(':' .. entry.lnum)
        select_current_qf(false)
        return
      end
    elseif pick_next_fname then
      vim.cmd('e ' .. cur_fname)
      vim.cmd(':' .. entry.lnum)
        select_current_qf(false)
      return
    end
  end
  -- no match, wraparound
  if #sorted_qf_locations > 0 then
    local entry = sorted_qf_locations[#sorted_qf_locations]
    local cur_fname = entry.filename or vim.api.nvim_buf_get_name(entry.bufnr)
    vim.cmd('e ' .. cur_fname)
    vim.cmd(':' .. entry.lnum)
    select_current_qf(false)
  end
end

function _G.max_win_in_new_tab()
  local fname = vim.fn.expand('%:p')
  local lnum = vim.fn.line('.')
  vim.cmd(":tabnew")
  vim.cmd(":e " .. fname)
  vim.cmd(":" .. lnum)
end

function enable_diagnostics(diag)
  for i, ns in pairs(vim.diagnostic.get_namespaces()) do
    if ns.name == diag then
      vim.diagnostic.enable(0, i)
      vim.b['disabled_dg_' .. i] = false
    end
  end
end

function disable_diagnostics(diag)
  for i, ns in pairs(vim.diagnostic.get_namespaces()) do
    if ns.name == diag then
      vim.diagnostic.disable(0, i)
      vim.b['disabled_dg_' .. i] = true
    end
  end
end

function _G.telescope_enable_disable_diagnostics()
  local pickers = require "telescope.pickers"
  local finders = require "telescope.finders"
  local actions = require "telescope.actions"
  local action_state = require "telescope.actions.state"

  local buf_lsp_client_ids = {}
  for i, cl in pairs(vim.lsp.buf_get_clients()) do
    buf_lsp_client_ids[cl.id] = true
  end

  local diagnostic_signs = {}
  for i, ns in pairs(vim.diagnostic.get_namespaces()) do
    if ns.user_data.sign_group then
      local id = tonumber(ns.name:gmatch("%d+$")()) -- extract the LSP id ... xxx.yy.123 -- id is 123
      if buf_lsp_client_ids[id] ~= nil then
        if vim.b['disabled_dg_' .. i] then
          table.insert(diagnostic_signs, "Enable " .. ns.name)
        else
          table.insert(diagnostic_signs, "Disable " .. ns.name)
        end
      end
    end
  end

  local opts = {
    layout_config = {
      height = 0.3,
      width = 0.3,
    }
  }

  pickers.new(opts, {
    prompt_title = "LSP Diagnostics toggle",
    finder = finders.new_table {
      results = diagnostic_signs,
    },
    attach_mappings = function(prompt_bufnr, map)
      actions.select_default:replace(function()
        actions.close(prompt_bufnr)
        local selection = action_state.get_selected_entry()
        action_txt = selection[1]
        if action_txt:sub(1, #"Enable") == "Enable" then
          enable_diagnostics(strings.strcharpart(action_txt, #"Enable "))
        else
          disable_diagnostics(strings.strcharpart(action_txt, #"Disable "))
        end
      end)
      return true
    end,
  }):find()
end

-- https://www.reddit.com/r/neovim/comments/x4504j/popupfloating_window_partially_out_of_the_screen/?
function _G.clamp_windows()
  local screen_width = vim.api.nvim_eval('&columns')
  for i, w in pairs(vim.api.nvim_list_wins()) do
    local win_config = vim.api.nvim_win_get_config(w)
    if win_config.zindex ~= nil then
      local pos = vim.api.nvim_win_get_position(w)
      local col = pos[2]
      local width = vim.api.nvim_win_get_width(w)
      local height = vim.api.nvim_win_get_height(w)
      if col+width > screen_width then
        -- -- -2 due to popup borders
        vim.api.nvim_win_set_width(w, screen_width - col -2)
        -- increase height in case we need more due to text wrapping
        vim.api.nvim_win_set_height(w, vim.fn.round(height * 1.1) + 1)

        -- start of code to move the popup instead of resizing it.
        -- with relative=win i must compute the coords in the parent
        -- window, it gets annoying
        -- print(vim.inspect(vim.api.nvim_win_get_config(w)))
        -- vim.api.nvim_win_set_config(w, {
        --   relative= 'win',
        --   anchor = 'SW',
        --   col= screen_width - width,
        --   row = pos[1],
        --   win = win_config.win
        -- })
      end
    end
  end
end

function _G.clip_history()
  local hist = vim.fn['yoink#getYankHistory']()
  local select_hist = {}
  for i, w in ipairs(hist) do
    table.insert(select_hist, w.text)
  end
  vim.ui.select(select_hist, {prompt = 'Select item to copy'}, 
  function(choice, idx)
    if idx then
      vim.fn.setreg('+', hist[idx].text, hist[idx].type)
    end
  end)
end

-- based on https://github.com/nvim-telescope/telescope.nvim/blob/b5833a682c511885887373aad76272ad70f7b3c2/lua/telescope/builtin/__internal.lua#L1332
-- this version fixes a line number bug and adds the current location
function _G.telescope_jumplist()
  local pickers = require "telescope.pickers"
  local finders = require "telescope.finders"
  local make_entry = require "telescope.make_entry"
  local conf = require("telescope.config").values

  local jumplist = vim.fn.getjumplist()[1]

  -- reverse the list
  local sorted_jumplist = {}

  -- add the current cursor position
  local pos = vim.fn.getpos(".")
  table.insert(sorted_jumplist, {
    bufnr = vim.fn.bufnr(),
    col = pos[3],
    coladd = 0,
    lnum = pos[2],
    text = vim.api.nvim_buf_get_lines(vim.fn.bufnr(), pos[2]-1, pos[2], false)[1]
  })

  for i = #jumplist, 1, -1 do
    if vim.api.nvim_buf_is_valid(jumplist[i].bufnr) then
      jumplist[i].text = vim.api.nvim_buf_get_lines(jumplist[i].bufnr, jumplist[i].lnum-1, jumplist[i].lnum, false)[1]
        or ""
      table.insert(sorted_jumplist, jumplist[i])
    end
  end

  pickers
    .new({}, {
      prompt_title = "Jumplist",
      finder = finders.new_table {
        results = sorted_jumplist,
        entry_maker = make_entry.gen_from_quickfix({path_display={'tail'}}),
      },
      previewer = conf.qflist_previewer({}),
      sorter = conf.generic_sorter({}),
    })
    :find()
end

function _G.run_command(command, params)
  local error_msg = nil
  Job:new {
    command = command,
    args = params,
    on_stderr = function(error, data, self)
      if error_msg == nil then
        error_msg = data
      end
    end,
    on_exit = function(self, code, signal)
      vim.schedule_wrap(function()
        if code == 0 then
          notif({command .. " executed successfully"}, vim.log.levels.INFO)
        else
          local info = {command .. " failed!"}
          if error_msg ~= nil then
            table.insert(info, error_msg)
            print(error_msg)
          end
          notif(info, vim.log.levels.ERROR)
        end
      end)()
    end
  }:start()
  notif({command .. " launched..."}, vim.log.levels.INFO)
end

-- pasted and modified from telescope's lua/telescope/make_entry.lua
-- make_entry.gen_from_git_commits
function _G.custom_make_entry_gen_from_git_commits(opts)
  local entry_display = require "telescope.pickers.entry_display"
  opts = opts or {}

  local displayer = entry_display.create {
    separator = " ",
    -- hl_chars = { ["("] = "TelescopeBorder", [")"] = "TelescopeBorder" }, --
    items = {
      { width = 8 },
      { width = 16 },
      { width = 10 },
      { remaining = true },
    },
  }

  local make_display = function(entry)
    if entry.refs ~= nil then
      return displayer {
        { entry.value, "TelescopeResultsIdentifier" },
        entry.auth,
        entry.date,
        { entry.refs .. " " .. entry.msg, "TelescopeResultsVariable" },
      }
    else
      return displayer {
        { entry.value, "TelescopeResultsIdentifier" },
        entry.auth,
        entry.date,
        entry.msg,
      }
    end
  end

  return function(entry)
    if entry == "" then
      return nil
    end

    -- no optional regex groups in lua https://stackoverflow.com/questions/26044905
    -- no repeat count... https://stackoverflow.com/questions/32884090/
    -- can't hardcode the number of chars in the author due to lua regex multibyte snafu
    local sha, auth, date, refs, msg = string.match(entry, "([^ ]+) (.+) (%d%d%d%d%-%d%d%-%d%d) (%([^)]+%)) (.+)")
    if sha == nil then
      sha, auth, date, msg = string.match(entry, "([^ ]+) (.+) (%d%d%d%d%-%d%d%-%d%d) (.+)")
    end

    if not msg then
      sha = entry
      msg = "<empty commit message>"
    end

    return {
      value = sha,
      ordinal = sha .. " " .. msg,
      auth = auth,
      date = date,
      refs = refs,
      msg = msg,
      display = make_display,
      current_file = opts.current_file,
    }
  end
end

function _G.overseer_popup_running_task()
  overseer_running_task_action("open float")
end

function _G.overseer_show_running_task()
  overseer_running_task_action("open")
end

function _G.overseer_running_task_action(action)
  local overseer = require('overseer')
  local tasks = overseer.list_tasks({ status=overseer.STATUS.RUNNING })
  if #tasks > 1 then
    local names = {}
    for i, task in ipairs(tasks) do
      table.insert(names, task.name)
    end
    vim.ui.select(names, {prompt = 'Select job to open'}, 
    function(choice, idx)
      if idx then
        overseer.run_action(tasks[idx], action)
      end
    end)
  elseif #tasks == 1 then
    overseer.run_action(tasks[1], action)
  end
end

function _G.diffview_gf()
  -- https://github.com/sindrets/diffview.nvim/issues/230
  local file = require("diffview.lib").get_current_view():infer_cur_file()
  if file then
    vim.cmd[[:tabc]]
    if vim.fn.winnr('$') > 1 then
      vim.cmd[[ChooseWin]]
    end
    vim.cmd(":e " .. file.absolute_path)
  end
end

function _G.get_nvimtree_window()
  local wins = vim.api.nvim_list_wins()
  for i, win in ipairs(wins) do
    local buf = vim.api.nvim_win_get_buf(win)
    if vim.api.nvim_buf_get_option(buf, "ft") == "NvimTree" then
      return win
    end
  end
  return nil
end

function _G.open_file_cur_dir(with_children)
  local folder = vim.fn.expand('%:h')
  local params = {
    path_display = function(opts, p) 
      return string.gsub(p, escape_pattern(folder .. "/"), "") end
  }
  if with_children then
    params.search_dirs = {folder}
  else
    params.find_command = { "rg", "--files", "--max-depth", "1", "--files", folder }
  end
  require'telescope.builtin'.find_files(params)
end

function _G.lsp_restart_all()
  -- get clients that would match this buffer but aren't connected
  local other_matching_configs = require('lspconfig.util').get_other_matching_providers(vim.bo.filetype)

  -- first restart the existing clients
  for _, client in ipairs(require('lspconfig.util').get_managed_clients()) do
    client.stop()
    vim.defer_fn(function()
      require('lspconfig.configs')[client.name].launch()
    end, 500)
  end

  -- now restart those that were not connected
  for _, client in ipairs(other_matching_configs) do
    vim.defer_fn(function()
      require('lspconfig.configs')[client.name].launch()
    end, 500)
  end

  -- handle null-ls separately as it's not managed by lspconfig
  nullls_client = require'null-ls.client'.get_client()
  if nullls_client ~= nil then
    nullls_client.stop()
  end
  vim.defer_fn(function()
    require'null-ls.client'.try_add()
  end, 500)
  local current_top_line = vim.fn.line('w0')
  local current_line = vim.fn.line('.')

  if vim.bo.modified then
    vim.cmd[[echohl ErrorMsg | echo "Reload will work better if you save the file & re-trigger" | echohl None]]
  else
    vim.cmd[[edit]]
  end
  -- edit can move the scrollpos, restore it
  vim.cmd(":" .. current_top_line)
  vim.cmd("norm! zt") -- set to top of window
  vim.cmd(":" .. current_line)
end

function _G.convert_dos()
  if vim.bo.modified then
    vim.cmd(":%s/\r$//")
  else
    vim.cmd(":e ++ff=dos")
  end
end

function _G.print_lsp_path()
  if not require'nvim-navic'.is_available() then
    print("Not supported for this file type")
    return
  end
  local path = ""
  for _, p in ipairs(require'nvim-navic'.get_data()) do
    path = path .. "/" .. p.name
  end
  local val = path:sub(2) -- remove leading /
  vim.fn.setreg('+', val)
  print(val)
end

function _G.display_git_commit()
  vim.ui.input({prompt="Enter git commit id:", kind="center_win"}, function(input)
    if input ~= nil then
      vim.cmd(":DiffviewOpen " .. input .. "^.." .. input)
    end
  end)
end

-- if the quickfix window is open, go to the bottom of quickfix
-- if it's not open, search for a terminal window and go to the bottom of the terminal.
function _G.quickfix_goto_bottom()
  local term_winid = nil
  for _, w in pairs(vim.api.nvim_list_wins()) do
    local buf = vim.api.nvim_win_get_buf(w)
    if vim.api.nvim_buf_get_option(buf, "ft") == "qf" then
      -- yes => scroll quickfix to the bottom
      vim.cmd(":cbottom")
      return
    elseif string.match(vim.api.nvim_buf_get_name(buf), "^term://") then
      term_winid = w
    end
  end
  if term_winid ~= nil then
    vim.cmd(vim.api.nvim_win_get_number(term_winid) .. ' wincmd w')
    vim.cmd("norm! G")
    vim.api.nvim_command('wincmd p') -- return to the original window
  end
end
-- vim: ts=2 sts=2 sw=2 et
