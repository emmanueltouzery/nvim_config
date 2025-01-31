local pickers = require "telescope.pickers"
local utils = require "telescope.utils"
local finders = require "telescope.finders"
local entry_display = require "telescope.pickers.entry_display"
local conf = require("telescope.config").values
local Str = require'plenary.strings'

_G.my_gen_from_quickfix = function(opts)
  if vim.g.telescope_entry_fullpath_display then
    local make_entry = require "telescope.make_entry"
    return make_entry.gen_from_quickfix({})
  end
  local quicker_hl = require'quicker.highlight'
  opts = opts or {}

  local displayer = entry_display.create {
    separator = "▏",
    items = {
      { width = 5 },
      { width = 25 },
      { remaining = true },
    },
  }

  local make_display = function(entry)
    local filename, path_hl = utils.transform_path(opts, entry.filename)

    local line_info = { entry.lnum, "TelescopeResultsLineNr" }

    if opts.trim_text then
      entry.text = entry.text:gsub("^%s*(.-)%s*$", "%1")
    end

    -- truncate myself so i can calculate offsets to move highlights
    local display_fname = Str.truncate(filename:match("[^/]+$"), 25)
    local d = displayer {
      line_info,
      display_fname,
      entry.text:gsub(".* | ", ""),
    }

    local hl2 = {}

    local filetype_icon = display_fname:match("^[^%s]+")
    local icon_strwidth = vim.api.nvim_strwidth(filetype_icon)
    table.insert(hl2, {{5+3, 5+3+icon_strwidth}, path_hl})
    table.insert(hl2, {{5+3+icon_strwidth+1,10+25}, "TelescopeResultsConstant"})
    if entry.bufnr and (vim.g.telescope_force_load_hl or vim.api.nvim_buf_is_loaded(entry.bufnr)) and entry.lnum ~= nil then
      local hl = quicker_hl.buf_get_ts_highlights(entry.bufnr, entry.lnum)
      local offset = 5 + 25 + display_fname:len() - vim.api.nvim_strwidth(display_fname) + 6
      for _, seh in ipairs(hl) do
        table.insert(hl2, {{seh[1]+offset, seh[2]+offset}, seh[3]})
      end
    end
    return d, hl2
  end

  return function(entry)
    local filename = entry.filename or vim.api.nvim_buf_get_name(entry.bufnr)

    return {
      valid = true,

      value = entry,
      ordinal = (not opts.ignore_filename and filename or "") .. " " .. entry.text,
      display = make_display,

      bufnr = entry.bufnr,
      filename = filename,
      lnum = entry.lnum,
      col = entry.col,
      text = entry.text,
      start = entry.start,
      finish = entry.finish,
    }
  end
end

_G.telescope_quickfix_locations = function(opts)
  local locations = _G.get_qf_locations({})

  if vim.tbl_isempty(locations) then
    return
  end

  local actions = require("telescope.actions")
  pickers.new(opts, {
    prompt_title = "Quickfix",
    finder = finders.new_table {
      results = locations,
      entry_maker = opts.entry_maker or my_gen_from_quickfix({
          path_display=function(opts, transformed_path)
            -- compared to the basic strategy, also display icons
            p = require'telescope.utils'.path_tail(transformed_path)
            return require'telescope.utils'.transform_devicons(transformed_path ,p)
          end
      }),
    },
    previewer = conf.qflist_previewer(opts),
    sorter = conf.generic_sorter(opts),
    attach_mappings = function(_, map)
      map('i', '<Cr>',  actions.select_default + actions.center)
      return true
    end,
  }):find()
end
