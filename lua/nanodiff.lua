local async = vim.async

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

local async_sys = async.wrap(3, vim.system)

function _G.nanodiff()
  async.run(function()
    local git_root = vim.trim(async_sys({"git", "rev-parse", "--show-toplevel"}, {text = true}).stdout)
    local res = async_sys({"git", "status", "--porcelain=v2"}, {cwd = git_root})
    print("output parsed: " .. vim.inspect(get_git_status(res.stdout)))
  end):raise_on_error()
end

