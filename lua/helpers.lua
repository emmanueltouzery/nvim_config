local Job = require'plenary.job'
local strings = require'plenary.strings'

function _G.my_open_tele(cur_folder_only)
    local w = vim.fn.expand('<cword>')
    local params = {}
    if cur_folder_only then
      local folder = vim.fn.expand('%:h')
      params.cwd = folder
    end
    require("telescope").extensions.live_grep_args.live_grep_args(params)
    vim.fn.feedkeys(w)
end

function _G.my_open_tele_sel(cur_folder_only)
    local w = get_visual_selection()
    local params = {}
    if cur_folder_only then
      local folder = vim.fn.expand('%:h')
      params.cwd = folder
    end
    require("telescope").extensions.live_grep_args.live_grep_args(params)
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
  -- with neovim 0.11, lsp says there are clients even from the popup,
  -- but telescope fails. So not even check for the lsp but only for the zindex.
  -- local no_lsp = true
  -- if vim.fn.has("nvim-0.11") == 1 then
  --   no_lsp = #vim.lsp.get_clients({ buffer = vim.api.nvim_get_current_buf() }) == 0
  -- else
  --   no_lsp = #vim.lsp.buf_get_clients() == 0
  -- end
  -- if no_lsp then
    -- no LSP clients. I'm probably in a floating window.
    -- close it so we focus on the parent window that has a LSP
    if vim.api.nvim_win_get_config(0).zindex ~= nil and vim.api.nvim_win_get_config(0).zindex > 0 then
      vim.api.nvim_win_close(0, false)
    end
  -- end
  require'telescope.builtin'.lsp_workspace_symbols {query=query,
      fname_width = 45,
      path_display = function(_, path)
        local Str = require'plenary.strings'
        return Str.truncate(path, 45, nil, -1)
      end,
}
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
            vim.cmd("norm! zz") -- center on screen
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
          vim.cmd("norm! zz") -- center on screen
          return
        end
      end
      vim.cmd("echoh WarningMsg | echo \"Can't find file in any project: " .. fname .. "\" | echoh None")
    end
  end)
end

function _G.ShowCommitAtLine()
  local commit_sha = nil
  if vim.fn.expand("%"):match("^diffview:") then
    local merge_ctx = require'diffview.lib'.get_current_view().cur_entry.merge_ctx
    local fname = require'diffview.lib'.get_current_view().cur_entry.path
    if vim.wo.winbar:match("OURS") then
      commit_sha = require"agitator".git_blame_commit_for_line({fname = fname, as_of_commit = merge_ctx.ours.hash})
    elseif vim.wo.winbar:match("THEIRS") then
      commit_sha = require"agitator".git_blame_commit_for_line({fname = fname, as_of_commit = merge_ctx.theirs.hash})
    end
  else
    commit_sha = require"agitator".git_blame_commit_for_line()
  end
  if commit_sha:sub(1, 1) == '^' then
    -- https://stackoverflow.com/questions/13105858/
    -- https://stackoverflow.com/a/40884093/516188
    vim.cmd("DiffviewOpen 4b825dc642cb6eb9a060e54bf8d69288fbee4904.." .. commit_sha:gsub("^%^", "") .. "  --selected-file=" .. vim.fn.expand("%:p"))
  else
    show_commit(commit_sha)
  end
end

function _G.show_commit(commit_sha)
  if vim.fn.expand("%"):match("^diffview:")  then
    vim.cmd("DiffviewOpen " .. commit_sha .. "^.." .. commit_sha .. "  --selected-file=" .. require'diffview.lib'.get_current_view().cur_entry.path)
  else
    vim.cmd("DiffviewOpen " .. commit_sha .. "^.." .. commit_sha .. "  --selected-file=" .. vim.fn.expand("%:p"))
  end
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
  require('kommentary.kommentary').comment_out_range_single(startline, endline,
      require('kommentary.config').get_config(0)) -- uncomment if possible/needed
  _G.toggle_comment_custom_commentstring(startline, endline)
end

function _G.toggle_comment_custom_commentstring_sel()
  local startline = vim.fn.line("'<")
  local endline = vim.fn.line("'>")
  _G.toggle_comment_custom_commentstring(startline, endline)
end

-- we previously commented "normally" but should have used the alternate
-- commenting => reselect the previous, uncomment, reselect and comment with alternate
--
-- if the commenting was done through visual mode, this could be done through 'gv'
-- (reselect), uncomment, change comment string, comment, restore comment string.
--
-- if the commenting was done through normal mode (gcap), this could be done through
-- undo, change comment string, dot-repeat, restore comment string.
--
-- but i don't know which one it was. so i undo, collect the list of modified lines
-- change comment string, comment the same lines, restore comment string.
function _G.recomment_last_selection_custom_commentstring()
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
    _G.toggle_comment_custom_commentstring(touched_lines_start, touched_lines_end)
  end
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

CONFLICT_ICON = '' -- semantically 󰓧 was a better option, but it's smaller
DELETED_ICON = '󰜺'

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
    if vim.api.nvim_win_is_valid(popup_win) then
      vim.api.nvim_win_close(popup_win, true)
    end
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
    if loc.lnum >= 1 and (vim.fn.filereadable(filename) == 1 or loc.bufnr) then
      table.insert(locations, loc)
    end
  end
  return locations
end

function _G.max_win_in_new_tab()
  local buf = vim.api.nvim_win_get_buf(0)
  local lnum = vim.fn.line('.')
  vim.cmd(":tabnew")
  vim.cmd(":b " .. buf)
  vim.cmd(":" .. lnum)
end

function _G.toggle_linting()
  local lint_aucmds = vim.api.nvim_get_autocmds({group = "Lint"})
  local is_disable = lint_aucmds ~= nil and #lint_aucmds > 0
  if is_disable then
    notif({"Disabling linting"})
  else
    notif({"Enabling linting"})
  end

  if is_disable then
    -- the reason i do app-wide and not buffer-wide is because of this,
    -- can't disable autocmds only for the current buffer that i can see.
    -- probably should use nvim_del_augroup_by_name() as well, but for now this works
    vim.cmd("au! Lint")
    for i, ns in pairs(vim.diagnostic.get_namespaces()) do
      if not string.match(ns.name, "vim.lsp") then
        -- https://github.com/neovim/neovim/issues/25131
        vim.diagnostic.reset(i)
      end
    end
  else
    nvim_lint_create_autocmds()
    vim.api.nvim_exec_autocmds("BufEnter", {group = "Lint"})
  end
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

        -- the highlight version is slower to show the first time...
        -- if it'll be too slow revert to the version without highlights
        entry_maker = my_gen_from_quickfix({

          -- i think it makes sense. for recent i don't need the full path, i should know,
          -- and the highlighted code previous is useful.
          telescope_entry_fullpath_display = false,

        -- entry_maker = make_entry.gen_from_quickfix({

          -- path_display={'tail'}
          path_display=function(opts, transformed_path)
            -- compared to the basic strategy, also display icons
            p = require'telescope.utils'.path_tail(transformed_path)
            return require'telescope.utils'.transform_devicons(transformed_path ,p)
          end
        }),
      },
      previewer = conf.qflist_previewer({}),
      sorter = conf.generic_sorter({}),
    })
    :find()
end

function _G.run_command(command, params, cb)
  local error_msg = nil
  local git_root = vim.fs.root(vim.fn.getcwd(), ".git")
  Job:new {
    command = command,
    cwd = git_root,
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
          if cb then
            cb()
          end
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

function _G.overseer_dispose_completed_jobs()
  local overseer = require('overseer')
  local tasks = overseer.list_tasks({ status={overseer.STATUS.SUCCESS, overseer.STATUS.CANCELED, overseer.STATUS.FAILURE} })
  for i, task in ipairs(tasks) do
    task:dispose(true)
  end
end

function _G.overseer_rerun_last_job()
  local overseer = require('overseer')
  local tasks = overseer.list_tasks({ recent_first = true })
  if #tasks > 0 then
    overseer.run_action(tasks[1], 'restart')
  else
    notif({"No job to re-run"}, vim.log.levels.ERROR)
  end
end

function _G.overseer_open_float_last_job()
  local overseer = require('overseer')
  local tasks = overseer.list_tasks({ recent_first = true })
  if #tasks > 0 then
    overseer.run_action(tasks[1], 'open float')
  else
    notif({"No job to open in float"}, vim.log.levels.ERROR)
  end
end


function _G.diffview_gf()
  -- https://github.com/sindrets/diffview.nvim/issues/230
  local file = require("diffview.lib").get_current_view():infer_cur_file()
  if file then
    vim.cmd[[:tabc]]
    local tab = vim.api.nvim_get_current_tabpage()
    if tabpage_is_sql(tab) or tabpage_is_terminal(tab) then
      vim.api.nvim_set_current_tabpage(1)
    end
    if vim.fn.winnr('$') > 1 then
      vim.cmd[[ChooseWin]]
    end
    vim.cmd(":e " .. file.absolute_path)
  end
end

function _G.diffview_conflict_view_commit(which)
  local merge_ctx = require("diffview.lib").get_current_view().merge_ctx
  if merge_ctx then
    show_commit(merge_ctx[which].hash)
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
      local path = string.gsub(p, escape_pattern(folder .. "/"), "")
      local highlights = {}
      return path, highlights
    end,
      prompt_title = "Find files in " .. folder .. " (with children: " .. vim.inspect(with_children) .. ")",
  }
  if with_children then
    params.search_dirs = {folder}
  else
    params.find_command = { "rg", "--files", "--max-depth", "1", "--files", folder }
  end
  require'telescope.builtin'.find_files(params)
end

function _G.reopen_buffer()
  if vim.bo.modified then
    vim.cmd[[echohl ErrorMsg | echo "Refusing to reopen a modified buffer" | echohl None]]
    return
  end
  local buf_name = vim.api.nvim_buf_get_name(0)
  if buf_name == '' or buf_name == nil then
    vim.cmd[[echohl ErrorMsg | echo "Refusing to reopen a buffer not tied to a file" | echohl None]]
    return
  end
  -- get the id of the current buffer, to delete it later
  local prev_bufnr = vim.api.nvim_win_get_buf(0)

  -- display a blank buffer instead of the current one
  vim.cmd(":enew")
  -- get the id of the blank buffer, to delete it later
  local blank_bufnr = vim.api.nvim_win_get_buf(0)

  -- delete the prev buffer, possible now that we display a blank buffer
  vim.api.nvim_buf_delete(prev_bufnr, {force=true})

  -- wait a little, or else gitsigns and LSP get confused that
  -- the buffer for a file changed under their feet
  vim.defer_fn(function()
    -- now reopen the buffer as we wanted...
    vim.cmd(":e " .. buf_name)
    -- and now delete the blank buffer
    vim.api.nvim_buf_delete(blank_bufnr, {force=true})
  end, 50)

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
  -- nullls_client = require'null-ls.client'.get_client()
  -- if nullls_client ~= nil then
  --   nullls_client.stop()
  -- end
  -- vim.defer_fn(function()
  --   require'null-ls.client'.try_add()
  -- end, 500)
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

function _G.print_lsp_path(retry)
  local backends = require("aerial.backends")
  local data = require("aerial.data")
  local backend = backends.get()
  if backend and not data.has_symbols(0) then
    -- this is needed for the json output of dadbod queries,
    -- elsewhere not needed. not sure why.
    backend.fetch_symbols_sync(0, {})
  end

  local path_components = require'aerial'.get_location()
  if #path_components == 0 then
    if retry == nil then
      vim.defer_fn(function()
        print_lsp_path(true)
      end, 50)
      return
    else
      notif({"spc-cp: indentation fallback"})
      -- manual fallback: indentation-based printing
      local l = vim.fn.line(".")
      local lines = vim.api.nvim_buf_get_lines(0, 0, l + 1, false)
      local line = lines[l]
      local levels = {line:gmatch("[%w_?%.%%{]+")()}
      local indent_level = #line:gmatch(" +")()
      while l > 1 do
        l = l - 1
        line = lines[l]
        local leading_spaces = line:gmatch(" +")()
        local cur_indent_level = 0
        if leading_spaces then
          cur_indent_level = #leading_spaces
        end
        if cur_indent_level < indent_level then
          indent_level = cur_indent_level
          local first_word = line:gmatch("[%w_?%.%%{]+")()
          if first_word ~= nil then
            table.insert(levels, 1, first_word)
          end
        end
      end
      print(vim.fn.join(levels, "/"))
      return
    end
  end
  -- if #path_components == 0 then
  --   -- it doesn't work for json without the false. not sure why.
  --   path_components = require'aerial'.get_location(false)
  -- end
  local path = ""
  for _, p in ipairs(path_components) do
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

function _G.win_bring_qf_here()
  local qf_buf_id = nil
  for _, b in pairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_get_option(b, "ft") == "qf" then
      qf_buf_id = b
      break
    end
  end
  if qf_buf_id ~= nil then
    for _, w in pairs(vim.api.nvim_list_wins()) do
      local buf = vim.api.nvim_win_get_buf(w)
      if buf == qf_buf_id then
        vim.api.nvim_win_close(w, true)
      end
    end
    vim.api.nvim_win_set_buf(0, qf_buf_id)
  else
    -- no QF.. open it
    vim.cmd("copen")
    win_bring_qf_here()
  end
end

function _G.jump_to_qf()
  for _, w in pairs(vim.api.nvim_list_wins()) do
    local buf = vim.api.nvim_win_get_buf(w)
    if vim.api.nvim_buf_get_option(buf, "ft") == "qf" then
      vim.cmd(vim.api.nvim_win_get_number(w) .. ' wincmd w')
      return
    end
  end
  -- no QF.. do we have an open tests terminal?
  -- i'm doing that because when running tests i'm first running them
  -- in a terminal and later i rather display the QF. So I'd like the
  -- same shortcut to work for QF & terminal, as they get "switched"
  for _, w in pairs(vim.api.nvim_list_wins()) do
    local buf = vim.api.nvim_win_get_buf(w)
    if string.match(vim.api.nvim_buf_get_name(buf), "^term://") then
      vim.cmd(vim.api.nvim_win_get_number(w) .. ' wincmd w')
      return
    end
  end
  -- no QF, and no tests terminal. Open the QF.
  vim.cmd("copen")
  jump_to_qf()
end

---copy-pasted and modified from neovim 0.11 share/nvim/runtime/lua/vim/lsp/buf.lua
---@param method string
---@param opts? vim.lsp.LocationOpts
local function get_locations(method, opts)
  local api = vim.api
  local lsp = vim.lsp
  local util = vim.lsp.util

  opts = opts or {}
  local bufnr = api.nvim_get_current_buf()
  local clients = lsp.get_clients({ method = method, bufnr = bufnr })
  if not next(clients) then
    vim.notify(lsp._unsupported_method(method), vim.log.levels.WARN)
    return
  end
  local win = api.nvim_get_current_win()
  local from = vim.fn.getpos('.')
  from[1] = bufnr
  local tagname = vim.fn.expand('<cword>')
  local remaining = #clients

  ---@type vim.quickfix.entry[]
  local all_items = {}

  ---@param result nil|lsp.Location|lsp.Location[]
  ---@param client vim.lsp.Client
  local function on_response(_, result, client)
    local locations = {}
    if result then
      locations = vim.islist(result) and result or { result }
    end
    local items = util.locations_to_items(locations, client.offset_encoding)
    vim.list_extend(all_items, items)
    remaining = remaining - 1
    if remaining == 0 then
      if vim.tbl_isempty(all_items) then
        vim.notify('No locations found', vim.log.levels.INFO)
        return
      end

      local title = 'LSP locations'
      if opts.on_list then
        assert(vim.is_callable(opts.on_list), 'on_list is not a function')
        opts.on_list({
          title = title,
          items = all_items,
          context = { bufnr = bufnr, method = method },
        })
        return
      end

      if #all_items == 1 then
        local item = all_items[1]
        local b = item.bufnr or vim.fn.bufadd(item.filename)

        -- Save position in jumplist
        vim.cmd("normal! m'")
        -- Push a new item into tagstack
        local tagstack = { { tagname = tagname, from = from } }
        vim.fn.settagstack(vim.fn.win_getid(win), { items = tagstack }, 't')

        vim.bo[b].buflisted = true
        local w = opts.reuse_win and vim.fn.win_findbuf(b)[1] or win
        api.nvim_win_set_buf(w, b)
        api.nvim_win_set_cursor(w, { item.lnum, item.col - 1 })
        vim._with({ win = w }, function()
          -- Open folds under the cursor
          vim.cmd('normal! zv')
          -- MY CHANGE HERE: CENTER
          vim.cmd('normal! zz')
        end)
        return
      end
      if opts.loclist then
        vim.fn.setloclist(0, {}, ' ', { title = title, items = all_items })
        vim.cmd.lopen()
      else
        vim.fn.setqflist({}, ' ', { title = title, items = all_items })
        -- vim.cmd('botright copen')
        telescope_quickfix_locations{}
      end
    end
  end
  for _, client in ipairs(clients) do
    local params = util.make_position_params(win, client.offset_encoding)
    client:request(method, params, function(_, result)
      on_response(_, result, client)
    end)
  end
end

-- https://github.com/neovim/neovim/pull/22413
function _G.lsp_goto_def_center()
  if vim.fn.has("nvim-0.11") == 1 then
    get_locations( 'textDocument/definition', opts)
  else
    local params = vim.lsp.util.make_position_params()
    vim.lsp.buf_request(0, 'textDocument/definition', params, function(err, result, ctx, config)
      local client = vim.lsp.get_client_by_id(ctx.client_id)
      local handler = client.handlers['textDocument/definition'] or vim.lsp.handlers['textDocument/definition']
      handler(err, result, ctx, config)
      vim.cmd[[norm! zz]]
    end)
  end
end

function _G.close_nonvisible_buffers()
  visible_bufs = {}
  for _, w in pairs(vim.api.nvim_list_wins()) do
    local buf = vim.api.nvim_win_get_buf(w)
    table.insert(visible_bufs, buf)
  end
  deleted_count = 0
  for _, b in pairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_loaded(b) and not vim.tbl_contains(visible_bufs, b) then
      local force = vim.api.nvim_buf_get_option(b, "buftype") == "terminal"
      local ok = pcall(vim.api.nvim_buf_delete, b, { force = force })
      if ok then
        deleted_count = deleted_count + 1
      end
    end
  end
  print("Deleted " .. deleted_count .. " buffers")
end

function _G.test_all_bg_run()
  local all_jobs = vim.api.nvim_list_chans()
  local all_job_ids_before = vim.tbl_map(function(ch) return ch.id end, all_jobs)
  vim.cmd[[:TestSuite -strategy=dispatch_background]]
  local all_jobs = vim.api.nvim_list_chans()
  local all_job_ids_after = vim.tbl_map(function(ch) return ch.id end, all_jobs)
  local jobid = nil
  for _, id in pairs(all_job_ids_after) do
    if not vim.tbl_contains(all_job_ids_before, id) then
      jobid = id
      break
    end
  end
  vim.g.test_bg_jobid = jobid
  hide_test_running_notif = notif(
  {" Tests running..."}, 
  vim.log.levels.INFO, {dont_hide = true})
  vim.defer_fn(function()
    test_all_bg_run_check_completion(jobid, hide_test_running_notif)
  end, 1000)
end

function _G.test_all_bg_run_check_completion(jobid, hide_test_running_notif)
  local success, _ = pcall(vim.fn.jobpid, jobid)
  if not success then
    -- the job doesn't exist anymore, done
    hide_test_running_notif()
  else
    -- not done
    vim.defer_fn(function()
      test_all_bg_run_check_completion(jobid, hide_test_running_notif)
    end, 1000)
  end
end

-- function _G.lsp_check_capabilities(feature, bufnr)
--   local clients = vim.lsp.buf_get_clients(bufnr)
--   for _, client in pairs(clients) do
--     if client.server_capabilities[feature] then
--       return true
--     end
--   end
--   return false
-- end

function _G.reload_all()
  vim.cmd("checktime")
  -- vim.cmd("Gitsigns refresh")
end

function _G.search_code_deps()
  if vim.fn.isdirectory("node_modules") then
    require('telescope').extensions.live_grep_args.live_grep_args({cwd="node_modules"})
  else
    vim.cmd[[echohl ErrorMsg | echo "Not handled for this project type" | echohl None]]
  end
end

DiffExcludeFTs = {"NvimTree", "packer", "cheat40", "OverseerList", "aerial", "AgitatorTimeMachine", "qf", "DiffviewFiles"}

function _G.toggle_diff()
  -- remember which is the current window
  local cur_win = vim.api.nvim_get_current_win()

  -- some windows may not be in diff mode, these that I ignore in this function
  -- => check if any window is in diff mode
  local has_diff = false
  local wins = vim.api.nvim_list_wins()
  for i, win in pairs(wins) do
    has_diff = has_diff or vim.api.nvim_win_call(win, function() return vim.opt.diff:get() end)
  end

  if has_diff then
    vim.cmd("windo diffoff")
  else
    -- used to do a plain 'windo diffthis', but i want to exclude some window types
    local wins = vim.api.nvim_list_wins()
    for i, win in pairs(wins) do
      local buf = vim.api.nvim_win_get_buf(win)
      local buf_ft = vim.api.nvim_buf_get_option(buf, "ft")
      if not vim.tbl_contains(DiffExcludeFTs, buf_ft) then
        vim.api.nvim_win_call(win, function() vim.cmd("diffthis") end)
      end
    end
  end
  -- restore the original current window
  vim.api.nvim_set_current_win(cur_win)
end

-- using https://github.com/josephburnett/jd
function _G.window_diff_json()
  local wins = {}
  for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
    local buf = vim.api.nvim_win_get_buf(win)
    local buf_ft = vim.api.nvim_buf_get_option(buf, "ft")
    if not vim.tbl_contains(DiffExcludeFTs, buf_ft) then
      table.insert(wins, win)
    end
  end
  if #wins ~= 2 then
    vim.cmd[[echohl ErrorMsg | echo "JSON diff only possible with two windows" | echohl None]]
    return
  end
  local on_disk = nil
  local other = nil
  for _, w in pairs(wins) do
    local buf = vim.api.nvim_win_get_buf(w)
    local buf_name = vim.api.nvim_buf_get_name(buf) 
    local is_saved = buf_name ~= nil and vim.fn.filereadable(buf_name) == 1 and not vim.api.nvim_buf_get_option(buf, 'modified')
    if is_saved and on_disk == nil then
      on_disk = buf_name
    else
      other = buf
    end
  end
  if on_disk == nil then
    vim.cmd[[echohl ErrorMsg | echo "JSON diff only possible with at least one file on disk and unmodified" | echohl None]]
    return
  end
  local output_buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_option(output_buf, "ft", "diff")

  local width = vim.api.nvim_get_option("columns")
  local height = vim.api.nvim_get_option("lines") - vim.o.cmdheight - 1

  local jobid = vim.fn.jobstart("jd " .. on_disk, {
    on_stdout = vim.schedule_wrap(function(j, output)
      vim.api.nvim_buf_set_lines(output_buf, -1, -1, true, output)
    end),
    on_exit = vim.schedule_wrap(function(j, output)
      vim.api.nvim_buf_set_option(output_buf, 'modifiable', false)
      vim.api.nvim_buf_set_option(output_buf, "readonly", true)
      vim.api.nvim_open_win(output_buf, true, {
        row = (height - 50) / 2,
        col = (width - 120) / 2,
        width = 120,
        height = 50,
        relative = "editor",
        style = "minimal",
        border = "rounded",
        title = "JSON diff",
        title_pos = "center"
      })
    end)
  })
  vim.fn.chansend(jobid, vim.api.nvim_buf_get_lines(other, 0, -1, false))
  vim.fn.chanclose(jobid, 'stdin')
end

function _G.string_to_buffer(str)
  local lines = {}
  for line in str:gmatch("([^\n]*)\n?") do
    table.insert(lines, line)
  end
  local fbuf = vim.api.nvim_create_buf(true, false)
  vim.api.nvim_buf_set_lines(fbuf, -1, -1, false, lines)
  return fbuf
end

vim.cmd[[ highlight MyHighlightGroup ctermbg=blue guibg=blue ]]

function _G.window_highlight_set()
  vim.ui.input({prompt="Enter pattern", kind="center_win", default="^\\s*test.*"}, function(pattern)
    vim.w.my_highlight = vim.fn.matchadd("MyHighlightGroup", pattern)
  end)
end

function _G.window_highlight_clear()
  vim.fn.matchdelete(vim.w.my_highlight)
end

-- compared to upstream, i commented three of the previewers
-- as the third one seems the best to me
function _G.telescope_commits(opts)
  local make_entry = require "telescope.make_entry"
  local pickers = require "telescope.pickers"
  local finders = require "telescope.finders"
  local previewers = require("telescope.previewers")
  local conf = require("telescope.config").values
  local actions = require("telescope.actions")
  opts.entry_maker=custom_make_entry_gen_from_git_commits()
  local git_command = vim.F.if_nil(opts.git_command, { "git", "log", "--pretty=oneline", "--abbrev-commit", "--", "." })

  local prompt_title = "Git Commits"
  if opts.branch then
    prompt_title = "Git Commits (" .. opts.branch .. ")"
  end
  pickers
    .new(opts, {
      prompt_title = prompt_title,
      finder = finders.new_oneshot_job(git_command, opts),
      previewer = {
        -- previewers.git_commit_diff_to_parent.new(opts),
        -- previewers.git_commit_diff_to_head.new(opts),
        previewers.git_commit_diff_as_was.new(opts),
        -- previewers.git_commit_message.new(opts),
      },
      sorter = conf.file_sorter(opts),
      attach_mappings = function(_, map)
        actions.select_default:replace(actions.git_checkout)
        map({ "i", "n" }, "<c-r>m", actions.git_reset_mixed)
        map({ "i", "n" }, "<c-r>s", actions.git_reset_soft)
        map({ "i", "n" }, "<c-r>h", actions.git_reset_hard)
        return true
      end,
    })
    :find()
end

vim.api.nvim_create_augroup("QuickfixAtCurpos", {})
function _G.quickfix_at_curpos()
  if vim.b.popup_win ~= nil and vim.api.nvim_win_is_valid(vim.b.popup_win) then
    -- focus the existing popup
    vim.api.nvim_clear_autocmds({group = "QuickfixAtCurpos"})
    vim.api.nvim_set_current_win(vim.b.popup_win)
  else
    -- open a new popup
    local qf = vim.fn.getqflist()
    local cur_bufnr = vim.api.nvim_win_get_buf(0)
    local errors = {}
    local msg_width = 0
    for _, cur_qf in ipairs(qf) do
      if cur_qf.bufnr == cur_bufnr and cur_qf.lnum == vim.fn.line('.') then
        table.insert(errors, cur_qf.text)
        if #cur_qf.text > msg_width then
          msg_width = #cur_qf.text
        end
      end
    end
    if #errors > 0 then
      local popup_buf = vim.api.nvim_create_buf(false, true)
      vim.api.nvim_buf_set_option(popup_buf, 'buftype', 'nofile')
      vim.api.nvim_buf_set_option(popup_buf, "bufhidden", "hide")
      vim.api.nvim_buf_set_option(popup_buf, "swapfile", false)
      vim.api.nvim_buf_set_option(popup_buf, 'modifiable', true)

      local win_opts = {
        style = "minimal",
        border = "rounded",
        relative = "cursor",
        width = msg_width,
        height = #errors,
        anchor = "SE",
        row = 0,
        col = vim.fn.col('.'),
      }

      vim.api.nvim_buf_set_lines(popup_buf, 0, -1, false, errors)
      vim.api.nvim_buf_set_option(popup_buf, 'modifiable', false)
      vim.api.nvim_buf_set_option(popup_buf, "readonly", true)
      vim.keymap.set('n', 'q', '<cmd>quit!<cr>', { silent = true, buffer = popup_buf })

      local cur_buf = vim.api.nvim_win_get_buf(0)
      popup_win = vim.api.nvim_open_win(popup_buf, false, win_opts)
      vim.b.popup_win = popup_win

      vim.api.nvim_create_autocmd({ "WinEnter", "WinLeave", "TabClosed", "CursorMoved" }, {
        group = "QuickfixAtCurpos",
        callback = function()
          local ok, popup_win = pcall(vim.api.nvim_buf_get_var, cur_buf, 'popup_win')
          if ok then
            local ok, isvalid = pcall(vim.api.nvim_win_is_valid, popup_win)
            if ok and isvalid then
              pcall(vim.api.nvim_win_close, popup_win, true)
              vim.b.popup_win = nil
            end
          end
        end,
        once = true,
      })
    else
      -- no quickfix, but maybe there are diagnostics to display
      vim.diagnostic.open_float(0, {scope="line"})
    end
  end
end

function _G.open_in_centered_popup(buf, pref_height)
    local cur_bufnr = buf or vim.api.nvim_win_get_buf(0)
    local width = vim.api.nvim_get_option("columns")
    local height = vim.api.nvim_get_option("lines") - vim.o.cmdheight - 1
    local win_height = pref_height or 50
    if win_height > height then
      win_height = height
    end

    local opts = {
        style = "minimal",
        border = "rounded",
        relative = "editor",
        row = (height - win_height) / 2,
        col = (width - 100) / 2,
        width = 100,
        height = win_height,
    }
    local w = vim.api.nvim_open_win(cur_bufnr, true, opts)
    vim.api.nvim_win_call(w, function()
      -- noscrollbind useful to explore CSVs (open another window, don't affect the scroll in the main window)
      vim.cmd("setlocal noscrollbind")
    end)
    return w
end

function _G.open_in_cursor_popup(buf, pref_height)
    local cur_bufnr = buf or vim.api.nvim_win_get_buf(0)
    local height = vim.api.nvim_get_option("lines") - vim.o.cmdheight - 1
    local win_height = pref_height or 50
    if win_height > height then
      win_height = height
    end

    local opts = {
        style = "minimal",
        border = "rounded",
        relative = "cursor",
        row = 1,
        col = 5,
        width = 40,
        height = win_height,
    }
    return vim.api.nvim_open_win(cur_bufnr, true, opts)
end

local function open_text_in_cursor_popup(text, pref_height)
  local buf = string_to_buffer(text)
  vim.api.nvim_buf_set_option(buf, 'modifiable', false)
  vim.api.nvim_buf_set_option(buf, "readonly", true)
  vim.api.nvim_set_option_value("filetype", "markdown", {buf = buf})
  vim.api.nvim_set_option_value("modified", false, {buf = buf})
  vim.api.nvim_set_option_value("bufhidden", 'wipe', {buf = buf})
  open_in_cursor_popup(buf, pref_height)
end

function _G.under_cursor_unix_timestamp_to_date()
  local under_cursor = vim.fn.expand('<cword>')
  if #under_cursor == 13 then
    -- the timestamp includes milliseconds
    under_cursor = under_cursor:sub(1, 10) .. "." .. under_cursor:sub(11, 13)
  end
  vim.system({'date', '-d', '@' .. under_cursor, '-u', '+"%Y-%m-%d %H:%M:%S.%3N"'}, {text=true}, vim.schedule_wrap(function(obj)
  if vim.bo[vim.api.nvim_win_get_buf(0)].readonly or not vim.bo[vim.api.nvim_win_get_buf(0)].modifiable then
      open_text_in_cursor_popup(obj.stdout, 2)
    else
      vim.cmd("norm ciw" .. obj.stdout)
    end
  end))
  -- make dot-repeatable https://gist.github.com/kylechui/a5c1258cd2d86755f97b10fc921315c3
  vim.go.operatorfunc = "v:lua.noop"
  vim.cmd("normal! g@l")
  vim.go.operatorfunc = "v:lua.under_cursor_unix_timestamp_to_date"
end

function _G.under_cursor_minutes_to_hhmm()
  local under_cursor = vim.fn.expand('<cword>')
  local n = tonumber(under_cursor)
  local remainder = n % 60
  local res = ((n - remainder) / 60) .. ":" .. string.format("%02d", remainder)
  if vim.bo[vim.api.nvim_win_get_buf(0)].readonly or not vim.bo[vim.api.nvim_win_get_buf(0)].modifiable then
    open_text_in_cursor_popup(res, 2)
  else
    vim.cmd("norm ciw" .. res)
  end
  -- make dot-repeatable https://gist.github.com/kylechui/a5c1258cd2d86755f97b10fc921315c3
  vim.go.operatorfunc = "v:lua.noop"
  vim.cmd("normal! g@l")
  vim.go.operatorfunc = "v:lua.under_cursor_minutes_to_hhmm"
end

function _G.noop() end

function _G.under_cursor_seconds_to_hhmm()
  local under_cursor = vim.fn.expand('<cword>')
  local n = tonumber(under_cursor) / 60
  local remainder = n % 60
  local res = ((n - remainder) / 60) .. ":" .. string.format("%02d", remainder)
  if vim.bo[vim.api.nvim_win_get_buf(0)].readonly or not vim.bo[vim.api.nvim_win_get_buf(0)].modifiable then
    open_text_in_cursor_popup(res, 2)
  else
    vim.cmd("norm ciw" .. res)
  end
  -- make dot-repeatable https://gist.github.com/kylechui/a5c1258cd2d86755f97b10fc921315c3
  vim.go.operatorfunc = "v:lua.noop"
  vim.cmd("normal! g@l")
  vim.go.operatorfunc = "v:lua.under_cursor_seconds_to_hhmm"
end


function _G.open_command_in_popup(cmd, req_width, req_col, req_height, req_row)
  local popup_buf = vim.api.nvim_create_buf(false, true)
  local width = req_width or vim.o.columns-6
  local height = req_height or vim.o.lines-6
  local win_opts = {
    focusable = false,
    style = "minimal",
    border = "rounded",
    relative = "editor",
    width = width,
    height = height,
    anchor = "NW",
    row = req_row or 3,
    col = req_col or 3,
    noautocmd = true,
  }
  local popup_win = vim.api.nvim_open_win(popup_buf, true, win_opts)

  local git_root = vim.fs.root(vim.fn.getcwd(), ".git")
  vim.fn.jobstart(cmd, {term = true, cwd=git_root})
end

function _G.glow_for_buffer(bufnr)
  local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
  local path = require("plenary.path")
  local fname = "/tmp/emm-diff.md"
  local f = path:new(fname)
  f:write(table.concat(lines, "\n"), "w")
  open_command_in_popup("glow -s " .. vim.fn.stdpath("config") .. "/glow-tokyo-night-plus.json -w 115 " .. fname, 120, (vim.o.columns-120)/2)
  vim.defer_fn(function()
    f:rm()
  end, 1000)
end

function _G.lualine_refresh_all()
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    vim.api.nvim_win_call(win, function() require('lualine').refresh() end)
  end
end

function _G.load_into_qf_from_contents()
  local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
  local list = {}
  for _, line in ipairs(lines) do
    if line:match(":") then
      local m = vim.split(line, ':')
      table.insert(list, {
        filename = m[1],
        lnum = tonumber(m[2]),
      })
    else
      table.insert(list, {
        filename = line,
        lnum = 1,
      })
    end
  end
  print(vim.inspect(list))
  vim.fn.setqflist(list, 'r')
end

local function update_adb_status()
  vim.system({"adb", "devices"}, {text=true}, function(out)
    if out.stdout ~= nil then
      local out_lines = vim.split(out.stdout, "\n")
      if #out_lines >= 2 then
        if string.match(out_lines[2], "unauthorized") then
          local lr = vim.g.adb_last_restart
          if lr == nil or vim.uv.gettimeofday() - lr > 3 then
            vim.schedule(function()
              notif({"ADB: unauthorized device, restarting the adb server"})
            end)
            vim.system({"adb", "kill-server"})
            vim.g.adb_last_restart = vim.uv.gettimeofday()
          end
        end
        vim.g.adb_status = " " .. out_lines[2]:gsub("\t", " ")
        return
      end
    end
    vim.g.adb_status = " - no devices"
  end)
end

function _G.start_adb_monitor()
  vim.g.stop_adb_monitor = false
  local adb_timer = vim.uv.new_timer()
  adb_timer:start(0, 60000, function ()
    vim.system({"lsof", "-tiTCP:5037", "-sTCP:LISTEN"}, {text=true}, function(out)
      -- print(vim.inspect(out))
      local pid = tonumber(out.stdout)
      if pid then
        -- print("found adb pid " .. pid)
        adb_timer:stop()
        adb_timer:close()
        local watcher = vim.loop.new_fs_event()
        watcher:start("/proc/" .. pid .. "/fd/1", {}, vim.schedule_wrap(function(err, fname, evts)
          -- print(vim.inspect(evts))
          if evts.change then
            update_adb_status()
            -- print("adb state changed!")
            if watcher then
              watcher:close()
            end
            watcher = nil
            start_adb_monitor()
          end
        end))
        update_adb_status()
        -- print("started watcher")
      else
        print("didn't find adb, starting it..")
        vim.system({"adb", "devices"})
        adb_timer:stop()
        adb_timer:close()
        vim.defer_fn(start_adb_monitor, 50)
      end
      if vim.g.stop_adb_monitor then
        adb_timer:stop()
        adb_timer:close()
      end
    end)
  end)
end

function _G.stop_adb_monitor()
  vim.g.stop_adb_monitor = true
  vim.g.adb_status = ""
end
