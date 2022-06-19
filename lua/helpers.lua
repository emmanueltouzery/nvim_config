local Job = require'plenary.job'
local strings = require'plenary.strings'

function _G.my_open_tele()
    local w = vim.fn.expand('<cword>')
    -- require('telescope.builtin').live_grep()
    require("telescope").extensions.live_grep_raw.live_grep_raw()
    vim.fn.feedkeys(w)
end

function _G.copy_to_clipboard(to_copy)
    vim.cmd("let @+ = '" .. to_copy .. "'")
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
      if full_path:match("^" .. escape_pattern(project.path)) then
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
    vim.cmd("let @+ = '" .. to_copy .. "'")
    print(to_copy)
end

function _G.get_file_line_sel()
    local file_path = cur_file_path_in_project()
    -- local start_line = vim.fn.getpos("v")[2]
    -- local end_line = vim.fn.getcurpos()[2]
    local start_line = vim.fn.line("'<")
    local end_line = vim.fn.line("'>")
    return "`" .. file_path .. ":" .. start_line .. "-" .. end_line .. "`"
end

function _G.copy_file_line_sel()
    local to_copy = get_file_line_sel()
    vim.cmd("let @+ = '" .. to_copy .. "'")
    print(to_copy)
end

function _G.goto_fileline()
    local input = vim.fn.input("Enter file:line please: ")
    vim.cmd("redraw") -- https://stackoverflow.com/a/44892301/516188
    local fname = input:match("[^:]+")
    local line = input:gsub("[^:]+:", "")
    for _, project in pairs(get_project_objects()) do
        if vim.fn.filereadable(project.path .. "/" .. fname) == 1 then
            vim.cmd(":e " .. project.path .. "/" .. fname)
            vim.cmd(":" .. line)
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

function _G.ShowCommitAtLine()
    local commit_sha = require"agitator".git_blame_commit_for_line()
    vim.cmd("DiffviewOpen " .. commit_sha .. "^.." .. commit_sha)
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
    if text ~= nil then
      -- search for the text, zz to center, select the line
      vim.fn.feedkeys("/" .. text:gsub('/', '.') .. "\rzz")
      -- vim.cmd("match Search /\%'.line('.').'l/'")
    end
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
    -- yes, open the buffer in the current window
    vim.cmd(":b" .. vim.g.test_term_buf_id)
    if text ~= nil then
      -- search for the text, zz to center, select the line
      vim.fn.feedkeys("/" .. text:gsub('/', '.') .. "\rzz")
      -- vim.cmd("match Search /\%'.line('.').'l/'")
    end
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
    -- consider maybe changing to >=1, to be seen
    if loc.lnum > 1 and vim.fn.filereadable(filename) == 1 then
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
  local sorted_qf_locations = get_sorted_qf_locations()

  -- find the first record for my filename
  local fname = vim.fn.expand('%:p')
  local lnum = vim.fn.line('.')
  local pick_next_fname = false
  for i, entry in ipairs(sorted_qf_locations) do
    local cur_fname = entry.filename or vim.api.nvim_buf_get_name(entry.bufnr)
    if cur_fname == fname then
      pick_next_fname = true
      if entry.lnum > lnum then
        vim.cmd(':' .. entry.lnum)
        return
      end
    elseif pick_next_fname then
      vim.cmd('e ' .. cur_fname)
      vim.cmd(':' .. entry.lnum)
      return
    end
  end
end

function _G.previous_quickfix()
  local sorted_qf_locations = get_sorted_qf_locations()

  -- find the first record for my filename
  local fname = vim.fn.expand('%:p')
  local lnum = vim.fn.line('.')
  local pick_next_fname = false
  for i = #sorted_qf_locations, 1, -1 do
    entry = sorted_qf_locations[i]
    local cur_fname = entry.filename or vim.api.nvim_buf_get_name(entry.bufnr)
    if cur_fname == fname then
      pick_next_fname = true
      if entry.lnum < lnum then
        vim.cmd(':' .. entry.lnum)
        return
      end
    elseif pick_next_fname then
      vim.cmd('e ' .. cur_fname)
      vim.cmd(':' .. entry.lnum)
      return
    end
  end
end

-- vim: ts=2 sts=2 sw=2 et
