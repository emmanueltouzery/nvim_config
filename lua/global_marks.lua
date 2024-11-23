-- {relative_path, path, lnum}

function _G.my_marks_fname()
  return vim.fn.stdpath("data") .. "/my_marks"
end

function _G.load_my_marks()
  local Path = require("plenary.path")
  local path = Path.new(my_marks_fname())
  if not path:exists() then
    return {}
  else
    local contents = path:read()
    local marks = {}
    for line in contents:gmatch("([^\n]*)\n?") do
      if #line > 0 then
        local fields = vim.split(line, ":")
        local desc = ""
        if #fields >= 4 then
          desc = fields[4]
          i = 5
          while i <= #fields do
            desc = desc .. ":" .. fields[i]
            i = i + 1
          end
        end
        table.insert(marks, {fields[1], fields[2], tonumber(fields[3]), desc})
      end
    end

  table.sort(marks, function(a,b)
    -- project
    if a[1] < b[1] then
      return true
    end
    if a[1] > b[1] then
      return false
    end
    -- file
    if a[2] < b[2] then
      return true
    end
    if a[2] > b[2] then
      return false
    end
    -- line
    return a[3] < b[3]
  end)

    return marks
  end
end

function _G.my_mark_file_row(mark)
  return mark[1] .. ":" .. mark[2] .. ":" .. mark[3] .. ":" .. mark[4] .. "\n"
end

function _G.add_my_mark(mark)
  local Path = require("plenary.path")
  local path = Path.new(my_marks_fname())
  local cur_mark_str = my_mark_file_row(mark)
  if not path:exists() then
    path:write(cur_mark_str, 'w')
  else
    path:write("\n" .. cur_mark_str, 'a')
  end
end

function _G.add_global_mark()
  vim.ui.input({prompt="Enter mark description", kind="center_win"}, function(desc)
    if desc == nil then
      return
    end
    local rel_fname = vim.fn.expand('%')
    local fname = vim.fn.expand('%:p')
    local lnum = vim.fn.line('.')
    add_my_mark({rel_fname, fname, lnum, desc})
  end)
end

function _G.remove_global_mark(fname, lnum)
  local marks = load_my_marks()
  local mark_str = ""
  -- drop a single entry max. otherwise if i get duplicates, i end up
  -- deleting all the duplicates, not just one
  local dropped_one_already = false
  for _, mark in ipairs(marks) do
    if (not dropped_one_already) and mark[2] == fname and mark[3] == lnum then
      dropped_one_already = true
    else
      mark_str = mark_str .. my_mark_file_row(mark)
    end
  end
  local Path = require("plenary.path")
  local path = Path.new(my_marks_fname())
  path:write(mark_str, 'w')
end
