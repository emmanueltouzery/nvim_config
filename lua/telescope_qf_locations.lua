local pickers = require "telescope.pickers"
local utils = require "telescope.utils"
local finders = require "telescope.finders"
local entry_display = require "telescope.pickers.entry_display"
local conf = require("telescope.config").values

_G.my_gen_from_quickfix = function(opts)
  local quicker_hl = require'quicker.highlight'
  opts = opts or {}

  local displayer = entry_display.create {
    separator = "▏",
    items = {
      { width = 5 },
      { width = 22 },
      { remaining = true },
    },
  }

  local make_display = function(entry)
    local filename = utils.transform_path(opts, entry.filename)

    local line_info = { entry.lnum, "TelescopeResultsLineNr" }

    if opts.trim_text then
      entry.text = entry.text:gsub("^%s*(.-)%s*$", "%1")
    end

    local d = displayer {
      line_info,
      -- filename,
      filename:match("[^/]+$"),
      entry.text:gsub(".* | ", ""),
    }

    local hl2 = {}
    -- filename column
    table.insert(hl2, {{6,32}, "TelescopeResultsConstant"})
    if entry.bufnr and vim.api.nvim_buf_is_loaded(entry.bufnr) and entry.lnum ~= nil then
      local hl = quicker_hl.buf_get_ts_highlights(entry.bufnr, entry.lnum)
      local offset = 5+22+8 -- col1+col2+?
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
