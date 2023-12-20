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

_G.telescope_global_marks = function(opts)
  local get_marks_table = function()
    local global_marks = load_my_marks()
    local marks_table = {}
    for _, mark in ipairs(global_marks) do
      local project_root = string.gsub(mark[2], "/" .. mark[1], "")
      local project = project_root:match("[^/]+$")
      local row = {
        project = project,
        relative_fname = mark[1],
        lnum = mark[3],
        col = 1,
        filename = mark[2],
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

  pickers.new(opts, {
    prompt_title = "Global Marks",
    finder = gen_new_finder(),
    previewer = conf.grep_previewer(opts),
    sorter = conf.generic_sorter(opts),
    push_cursor_on_edit = true,
    push_tagstack_on_edit = true,
    attach_mappings = function(_, map)
      map("i", "<c-Del>", actions.delete_mark)
      map("n", "<c-Del>", actions.delete_mark)
      return true
    end,
  }):find()
end

function global_marks_entry_maker()
  local width2 = 18
  local total_width = width2 + 2 -- two separator spaces
  local displayer = entry_display.create {
    separator = " ",
    items = {
      { width = width2 },
      { remaining = true },
    },
  }

  local make_display = function(entry)
    -- code stolen from telescope's utils.calc_result_length()
    local status = get_status(vim.api.nvim_get_current_buf())
    local len = vim.api.nvim_win_get_width(status.results_win) - status.picker.selection_caret:len() - 2
    local true_len = len - total_width
    local relative_fname = utils.transform_path({__length = true_len}, entry.relative_fname)
    return displayer {
      -- {entry.mark, "TelescopeResultsNumber"},
      {entry.project, "TelescopeResultsTitle"},
      relative_fname,
    }
  end

  return function(entry)
    return {
      valid = true,

      value = entry.filename,
      ordinal = entry.filename,
      display = make_display,

      project = entry.project,
      relative_fname = entry.relative_fname,

      filename = entry.filename,
      lnum = entry.lnum,
      col = entry.col,
    }
  end
end
