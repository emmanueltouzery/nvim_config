local pickers = require "telescope.pickers"
local utils = require "telescope.utils"
local finders = require "telescope.finders"
local entry_display = require "telescope.pickers.entry_display"
local conf = require("telescope.config").values

function gen_from_quickfix(opts)
  opts = opts or {}

  local displayer = entry_display.create {
    separator = "▏",
    items = {
      { width = 5 },
      { width = 0.45 },
      { remaining = true },
    },
  }

  local make_display = function(entry)
    local filename = utils.transform_path(opts, entry.filename)

    local line_info = { entry.lnum, "TelescopeResultsLineNr" }

    if opts.trim_text then
      entry.text = entry.text:gsub("^%s*(.-)%s*$", "%1")
    end

    return displayer {
      line_info,
      entry.text:gsub(".* | ", ""),
      -- filename,
      filename:match("[^/]+$"),
    }
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

  pickers.new(opts, {
    prompt_title = "Quickfix",
    finder = finders.new_table {
      results = locations,
      entry_maker = opts.entry_maker or gen_from_quickfix(opts),
    },
    previewer = conf.qflist_previewer(opts),
    sorter = conf.generic_sorter(opts),
  }):find()
end
