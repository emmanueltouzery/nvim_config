local pickers = require "telescope.pickers"
local action_state = require "telescope.actions.state"
local utils = require "telescope.utils"
local finders = require "telescope.finders"
local conf = require("telescope.config").values
local make_entry = require "telescope.make_entry"
local entry_display = require "telescope.pickers.entry_display"
local get_status = require("telescope.state").get_status
local Str = require'plenary.strings'
local Path = require'plenary.path'

-- https://stackoverflow.com/a/34953646/516188
local function escape_pattern(text)
  return text:gsub("([^%w])", "%%%1")
end

_G.telescope_global_marks = function(opts)
  local get_marks_table = function()
    local global_marks = load_my_marks()
    local marks_table = {}
    for _, mark in ipairs(global_marks) do
      local project_root = string.gsub(mark[2], "/" .. escape_pattern(mark[1]), "")
      local project = project_root:match("[^/]+$")
      local row = {
        project = project,
        relative_fname = mark[1],
        lnum = mark[3],
        col = 1,
        filename = mark[2],
        desc = mark[4],
      }
      table.insert(marks_table, row)
    end
    return marks_table
  end

  local gen_new_finder = function()
    return finders.new_table {
      results = get_marks_table(),
      entry_maker = global_marks_entry_maker(),
    }
  end

  local actions = {}
  actions.delete_mark = function(prompt_bufnr)
    local current_picker = action_state.get_current_picker(prompt_bufnr) -- picker state
    local entry = action_state.get_selected_entry()
    remove_global_mark(entry.filename, entry.lnum)
    current_picker:refresh(gen_new_finder(), { reset_prompt = true })
  end
  actions.edit_mark_desc = function(prompt_bufnr)
    vim.ui.input({prompt="Enter mark description", kind="center_win"}, function(desc)
      if desc then
        local current_picker = action_state.get_current_picker(prompt_bufnr) -- picker state
        local entry = action_state.get_selected_entry()
        edit_global_mark_desc(entry.filename, entry.lnum, desc)
        current_picker:refresh(gen_new_finder(), { reset_prompt = true })
      end
    end)
  end

  pickers.new(opts, {
    prompt_title = "Global Marks",
    layout_strategy = "vertical",
    layout_config = {
      preview_height = 0.7,
      preview_cutoff = 0,
    },
    finder = gen_new_finder(),
    previewer = conf.grep_previewer(opts),
    sorter = conf.generic_sorter(opts),
    push_cursor_on_edit = true,
    push_tagstack_on_edit = true,
    attach_mappings = function(_, map)
      map("i", "<c-Del>", actions.delete_mark)
      map("n", "<c-Del>", actions.delete_mark)
      map("i", "<c-e>", actions.edit_mark_desc)
      return true
    end,
  }):find()
end

function global_marks_entry_maker()
  local displayer = entry_display.create {
    separator = " ",
    items = {
      { width = 18 },
      { width = 30 },
      { remaining = true },
    },
  }

  local make_display = function(entry)
    -- code stolen from telescope's utils.calc_result_length()
    local status = get_status(vim.api.nvim_get_current_buf())
    local len = vim.api.nvim_win_get_width(status.results_win) - status.picker.selection_caret:len() - 2
    local relative_fname = utils.transform_path({__length = 30}, entry.relative_fname)
    return displayer {
      -- {entry.mark, "TelescopeResultsNumber"},
      {entry.project, "TelescopeResultsTitle"},
      relative_fname,
      entry.desc
    }
  end

  return function(entry)
    return {
      valid = true,

      value = entry.filename,
      ordinal = entry.project .. " " .. entry.filename .. " " .. entry.desc, -- used for filtering
      display = make_display,

      project = entry.project,
      relative_fname = entry.relative_fname,

      filename = entry.filename,
      lnum = entry.lnum,
      col = entry.col,
      desc = entry.desc,
    }
  end
end
