local function telescope_projects_fname()
  return vim.fn.stdpath('data') .. '/telescope-projects.txt'
end

function _G.telescope_load_projects()
  local path = io.open(telescope_projects_fname())
  if path == nil then
    return {}
  end
    local contents = path:read("*a")
    path:close()
    local projects = {}
    for line in contents:gmatch("([^\n]*)\n?") do
      if #line > 0 then
        local fields = vim.split(line, "=")
        table.insert(projects, { name = fields[1], path = fields[2] })
      end
    end
    table.sort(projects, function(a, b) return a.name < b.name end)
    return projects
end

local function add_project(project)
  local fname = telescope_projects_fname()
  local exists = vim.uv.fs_stat(fname) ~= nil
  local cur_project_str = string.format("%s=%s", project.name, project.path)
  if not exists then
    local path = io.open(fname, "w")
    path:write(cur_project_str)
    path:close()
  else
    local path = io.open(fname, "a")
    path:write("\n" .. cur_project_str)
    path:close()
  end
end

local function remove_project(project)
  local projects = telescope_load_projects()
  -- drop a single entry max. otherwise if i get duplicates, i end up
  -- deleting all the duplicates, not just one
  local dropped_one_already = false
  local contents_str = ""
  for _, cur_project in ipairs(projects) do
    if (not dropped_one_already) and cur_project.name == project.name and cur_project.path == project.path then
      dropped_one_already = true
    else
      contents_str = contents_str .. string.format("%s=%s\n", cur_project.name, cur_project.path)
    end
  end
  local path = io.open(telescope_projects_fname(), "w")
  path:write(contents_str)
  path:close()
end

local function add_current_folder_as_project(cb)
  local project_name = vim.fn.getcwd(vim.fn.winnr()):match("[^/]+$")
  vim.ui.input({prompt="Enter project name", kind="center_win", default=project_name}, function(desc)
    if desc == nil then
      return
    end
    add_project({ name = desc, path = vim.fn.getcwd() })
    cb()
  end)
end

-- shared with telescope_modified_git_projects
function _G.tel_proj_attach_mappings(prompt_bufnr, map)
  map('i', '<C-s>', function(nr)
    require('telescope').extensions.live_grep_args.live_grep_args{
      cwd=require("telescope.actions.state").get_selected_entry(prompt_bufnr).value
    }
  end)
  map('i', '<C-g>', function(nr)
    require('telescope.builtin').git_status{
      cwd=require("telescope.actions.state").get_selected_entry(prompt_bufnr).value
    }
  end)
  map('i', '<C-r>', function(nr)
    telescope_recent_or_all{
      cwd_only=true,
      cwd=require("telescope.actions.state").get_selected_entry(prompt_bufnr).value
    }
  end)
end

function _G.telescope_projects()
  local pickers = require "telescope.pickers"
  local finders = require "telescope.finders"
  local entry_display = require "telescope.pickers.entry_display"
  local make_entry = require "telescope.make_entry"
  local conf = require("telescope.config").values

  local gen_new_finder = function()

    local displayer = entry_display.create {
      separator = " ",
      items = {
        { width = 30, },
        { remaining = true },
      },
    }

    local make_display = function(entry)
      return displayer {
        { entry.name, "TelescopeResultsIdentifier" },
        { entry.path },
      }
    end

    return finders.new_table {
      results = telescope_load_projects(),
      entry_maker = global_marks_entry_maker(),
      entry_maker = function(entry)
        entry.value = entry.path
        entry.ordinal = entry.name
        entry.display = make_display
        return make_entry.set_default_entry_mt(entry, opts)
      end,
    }
  end

  pickers.new(opts, {
    prompt_title = "Projects",
    finder = gen_new_finder(),
    sorter = conf.generic_sorter(opts),
    attach_mappings = function(prompt_bufnr, map)
      map("i", "<enter>", function(nr)
        path = require("telescope.actions.state").get_selected_entry(prompt_bufnr).value
        require'telescope.builtin'.find_files{cwd=path}
      end)
      tel_proj_attach_mappings(prompt_bufnr, map)
      map('i', '<C-a>', function(nr)
        local actions = require("telescope.actions")
        local action_state = require "telescope.actions.state"
        local current_picker = action_state.get_current_picker(prompt_bufnr)
        actions.close(prompt_bufnr)
        vim.defer_fn(function()
          add_current_folder_as_project(function()
            telescope_projects()
          end)
        end, 100)
      end)
      map('i', '<C-Del>', function(nr)
        local action_state = require "telescope.actions.state"
        local entry = action_state.get_selected_entry()
        remove_project(entry)
        local current_picker = action_state.get_current_picker(prompt_bufnr)
        current_picker:refresh(gen_new_finder(), { reset_prompt = true })
      end)
      return true
    end,
  }):find()
end

vim.keymap.set("n", "<leader>op", _G.telescope_projects, {desc="Open project"})
