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
    local global_marks = {
      items = vim.fn.getmarklist(),
      name_func = function(mark, _)
        -- get buffer name if it is opened, otherwise get file name
        return vim.api.nvim_get_mark(mark, {})[4]
      end,
    }
    local marks_table = {}
    local bufname = vim.api.nvim_buf_get_name(opts.bufnr or 0)
    for _, cnf in ipairs { global_marks } do
      for _, v in ipairs(cnf.items) do
        -- strip the first single quote character
        local mark = string.sub(v.mark, 2, 3)
        local _, lnum, col, _ = unpack(v.pos)
        -- need to use plenary to expand the path, else when the buffer is
        -- opened, I get ~ for the start of the path and I can't find the project.
        local name = Path.new(cnf.name_func(mark, lnum)):expand()
        local path_project = to_file_path_in_project(name)
        local row = {
          mark = mark,
          project = path_project and path_project[1]:match("[^/]+$") or "-",
          relative_fname = path_project and path_project[2] or name,
          lnum = lnum,
          col = col,
          filename = name or bufname,
        }
        -- only keep global marks (u="uppercase")
        if mark:match "%u" then
          table.insert(marks_table, row)
        end
      end
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
    vim.cmd("delmarks " .. entry.mark)
    -- https://github.com/neovim/neovim/issues/7198#issuecomment-323649157
    -- without wshada! the marks would return after a nvim restart...
    -- also slightly related: https://stackoverflow.com/a/32138657/516188
    vim.cmd("wshada!")
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
      map("i", "<c-d>", actions.delete_mark)
      map("n", "<c-d>", actions.delete_mark)
      return true
    end,
  }):find()
end

function global_marks_entry_maker()
  local width1 = 1
  local width2 = 9
  local total_width = width1 + width2 + 2 -- two separator spaces
  local displayer = entry_display.create {
    separator = " ",
    items = {
      { width = width1 },
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
      {entry.mark, "TelescopeResultsNumber"},
      {entry.project, "TelescopeResultsTitle"},
      relative_fname,
    }
  end

  return function(entry)
    return {
      valid = true,

      value = entry.mark .. " " .. entry.filename,
      ordinal = entry.mark,
      display = make_display,

      mark = entry.mark,
      project = entry.project,
      relative_fname = entry.relative_fname,

      filename = entry.filename,
      lnum = entry.lnum,
      col = entry.col,
    }
  end
end
