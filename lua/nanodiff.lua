local async = vim.async

local async_sys = async.wrap(3, vim.system)

local function add_section(lines, line_to_path, header, items, is_renamed)
  if #items == 0 then return end

  table.insert(lines, "== " .. header .. " ==")
  for _, item in ipairs(items) do
    local display_str, target_path
    if is_renamed then
      display_str = string.format("  [%s] %s -> %s", item.status, item.orig_path, item.path)
      target_path = item.path
    else
      display_str = string.format("  [%s] %s", item.status, item.path)
      target_path = item.path
    end

    table.insert(lines, display_str)
    line_to_path[#lines] = target_path
  end
  table.insert(lines, "") -- Empty line separator
end

local function open_status_tab(status)
  vim.cmd("tabnew")

  -- 2. Create an unlisted, scratch buffer for the left side
  local left_buf = vim.api.nvim_create_buf(false, true)

  vim.bo[left_buf].buftype = "nofile"
  vim.bo[left_buf].bufhidden = "wipe"
  vim.bo[left_buf].swapfile = false

  local lines = {}
  vim.b[left_buf].line_to_path = {}
  add_section(lines, vim.b[left_buf].line_to_path, "Staged Changes", status.staged, false)
  add_section(lines, vim.b[left_buf].line_to_path, "Staged Renames", status.staged_renamed, true)
  add_section(lines, vim.b[left_buf].line_to_path, "Unstaged Changes", status.unstaged, false)

  if #status.untracked > 0 then
    table.insert(lines, "== Untracked Files ==")
    for _, path in ipairs(git_data.untracked) do
      table.insert(lines, "  [?] " .. path)
      vim.b[left_buf].line_to_path[#lines] = path
    end
  end

  -- 3. Populate buffer content
  if lines and #lines > 0 then
    vim.api.nvim_buf_set_lines(left_buf, 0, -1, false, lines)
  end

  -- Lock buffer against accidental modifications
  vim.bo[left_buf].modifiable = false
  vim.bo[left_buf].readonly = true

  -- 4. Assign scratch buffer to the current window
  local left_win = vim.api.nvim_get_current_win()
  vim.api.nvim_win_set_buf(left_win, left_buf)

  -- 5. Split to create the right window
  vim.cmd("rightbelow vsplit")
  local right_win = vim.api.nvim_get_current_win()

  -- 6. Set left window width to 40 characters
  vim.api.nvim_win_set_width(left_win, 40)

  -- 7. Configure left window options (including winfixbuf)
  vim.wo[left_win].winfixbuf = true -- Lock window to this buffer
  vim.wo[left_win].number = false
  vim.wo[left_win].relativenumber = false
  vim.wo[left_win].signcolumn = "no"
  vim.wo[left_win].wrap = false

  return {
    left_buf = left_buf,
    left_win = left_win,
    right_win = right_win,
  }
end

local function get_git_status(output)
  local result = {
    staged = {},          -- Standard staged modifications/additions/deletions
    staged_renamed = {},  -- Specifically staged renames: { new_path, old_path }
    unstaged = {},        -- Worktree modifications/deletions
    untracked = {},       -- New untracked files
  }

  for line in output:gmatch("[^\r\n]+") do
    local prefix = line:sub(1, 1)

    if prefix == "1" then
      -- Ordinary changes: "1 <XY> sub mH mI mW hH hI <path>"
      local xy, path = line:match("^1%s+(%S+)%s+%S+%s+%S+%s+%S+%s+%S+%s+%S+%s+%S+%s+(.+)$")
      if xy then
        local x = xy:sub(1, 1) -- Staged
        local y = xy:sub(2, 2) -- Unstaged

        if x ~= "." then
          table.insert(result.staged, { path = path, status = x })
        end
        if y ~= "." then
          table.insert(result.unstaged, { path = path, status = y })
        end
      else
        print("couldn't match line: " .. line)
      end

    elseif prefix == "2" then
      -- Renamed/Copied changes: "2 <XY> sub mH mI mW hH hI X score <path>\t<origPath>"
      local xy, paths = line:match("^2%s+(%S+)%s+%S+%s+%S+%s+%S+%s+%S+%s+%S+%s+%S+%s+%S+%s+(.+)$")
      if xy and paths then
        local x = xy:sub(1, 1)
        local y = xy:sub(2, 2)

        -- Paths are tab-separated: "new_path\told_path"
        local path, orig_path = paths:match("^([^\t]+)\t(.+)$")

        if x == "R" or x == "C" then
          table.insert(result.staged_renamed, {
            path = path,
            orig_path = orig_path,
            status = x,
          })
        elseif x ~= "." then
          table.insert(result.staged, { path = path, status = x })
        end

        if y ~= "." then
          table.insert(result.unstaged, { path = path, status = y })
        end
      end

    elseif prefix == "?" then
      -- Untracked files: "? <path>"
      local path = line:match("^%?%s+(.+)$")
      if path then
        table.insert(result.untracked, path)
      end
    end
  end

  return result
end

function _G.nanodiff()
  async.run(function()
    local git_root = vim.trim(async_sys({"git", "rev-parse", "--show-toplevel"}, {text = true}).stdout)
    local res = async_sys({"git", "status", "--porcelain=v2"}, {cwd = git_root})
    local status = get_git_status(res.stdout)
    print("output parsed: " .. vim.inspect(status))
    vim.schedule(function() open_status_tab(status) end)
  end):raise_on_error()
end

