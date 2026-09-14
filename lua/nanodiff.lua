local async = vim.async

local async_sys = async.wrap(3, vim.system)

local function add_section(lines, line_to_path, header, items)
  if #items == 0 then return end

  table.insert(lines, "== " .. header .. " ==")
  for _, item in ipairs(items) do
    local display_str, target_path
    if item.orig_path then
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

local function open_status_tab(sections)
  vim.cmd("tabnew")

  -- 2. Create an unlisted, scratch buffer for the left side
  local left_buf = vim.api.nvim_create_buf(false, true)

  vim.bo[left_buf].buftype = "nofile"
  vim.bo[left_buf].bufhidden = "wipe"
  vim.bo[left_buf].swapfile = false

  local lines = {}
  vim.b[left_buf].line_to_path = {}
  for _, section in ipairs(sections) do
    add_section(lines, vim.b[left_buf].line_to_path, section.title, section.contents)
  end

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

local function get_diff_status(git_root)
  local output = async_sys({"git", "status", "--porcelain=v2"}, {cwd = git_root})

  local staged = {}
  local unstaged = {}
  local untracked = {}

  for line in output.stdout:gmatch("[^\r\n]+") do
    local prefix = line:sub(1, 1)

    if prefix == "1" then
      -- Ordinary changes: "1 <XY> sub mH mI mW hH hI <path>"
      local xy, path = line:match("^1%s+(%S+)%s+%S+%s+%S+%s+%S+%s+%S+%s+%S+%s+%S+%s+(.+)$")
      if xy then
        local x = xy:sub(1, 1) -- Staged
        local y = xy:sub(2, 2) -- Unstaged

        if x ~= "." then
          table.insert(staged, { path = path, status = x })
        end
        if y ~= "." then
          table.insert(unstaged, { path = path, status = y })
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
          table.insert(staged, {
            path = path,
            orig_path = orig_path,
            status = x,
          })
        elseif x ~= "." then
          table.insert(staged, { path = path, status = x })
        end

        if y ~= "." then
          table.insert(unstaged, { path = path, status = y })
        end
      end

    elseif prefix == "?" then
      -- Untracked files: "? <path>"
      local path = line:match("^%?%s+(.+)$")
      if path then
        table.insert(untracked, { path = path, status = "?" })
      end
    end
  end

  return {
    {title = "Staged", contents = staged},
    {title = "Unstaged", contents = unstaged},
    {title = "Untracked", contents = untracked},
  }
end

function _G.nanodiff_status()
  async.run(function()
    local git_root = vim.trim(async_sys({"git", "rev-parse", "--show-toplevel"}, {text = true}).stdout)
    local status = get_diff_status(git_root)
    vim.schedule(function() open_status_tab(status) end)
  end):raise_on_error()
end

local function get_diff_revspec(git_root, revspec)
  local output = vim.trim(async_sys({"git", "diff", "--name-status", "-M", revspec}, {text = true, cwd = git_root}).stdout)

  local results = {}

  for line in output:gmatch("[^\r\n]+") do
    -- Split line by tab characters
    local parts = {}
    for part in line:gmatch("[^\t]+") do
      table.insert(parts, part)
    end

    if #parts >= 2 then
      local raw_code = parts[1]
      local code_char = raw_code:sub(1, 1)
      local path = parts[2]
      local orig_path = nil
      local status

      if code_char == "A" then
        status = "added"
      elseif code_char == "D" then
        status = "deleted"
      elseif code_char == "M" then
        status = "modified"
      elseif code_char == "R" then
        status = "renamed"
        orig_path = parts[2]
        path = parts[3]
      elseif code_char == "C" then
        status = "copied"
        orig_path = parts[2]
        path = parts[3]
      else
        status = "unknown"
      end

      table.insert(results, {
        path = path,
        orig_path = orig_path,
        status = status,
      })
    end
  end

  return results
end

function _G.nanodiff_revspec(revspec)
  async.run(function()
    local git_root = vim.trim(async_sys({"git", "rev-parse", "--show-toplevel"}, {text = true}).stdout)
    local status = get_diff_revspec(git_root, revspec)
    print("status: " .. vim.inspect(status))
    vim.schedule(function() open_status_tab({{title = "Changes", contents = status}}) end)
  end):raise_on_error()
end

