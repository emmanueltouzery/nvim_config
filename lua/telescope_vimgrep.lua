local utils = require "telescope.utils"
local entry_display = require "telescope.pickers.entry_display"
local Str = require'plenary.strings'
local Path = require("plenary.path")

-- 99% copy-pasted from telescope, i only changed the display,
-- which is unfortunately not pluggable, to get a nicer multi-column view

local handle_entry_index = function(opts, t, k)
  local override = ((opts or {}).entry_index or {})[k]
  if not override then
    return
  end

  local val, save = override(t, opts)
  if save then
    rawset(t, k, val)
  end
  return val
end

-- Gets called only once to parse everything out for the vimgrep, after that looks up directly.
local parse_with_col = function(t)
  local _, _, filename, lnum, col, text = string.find(t.value, [[(..-):(%d+):(%d+):(.*)]])

  local ok
  ok, lnum = pcall(tonumber, lnum)
  if not ok then
    lnum = nil
  end

  ok, col = pcall(tonumber, col)
  if not ok then
    col = nil
  end

  t.filename = filename
  t.lnum = lnum
  t.col = col
  t.text = text

  return { filename, lnum, col, text }
end

local parse_without_col = function(t)
  local _, _, filename, lnum, text = string.find(t.value, [[(..-):(%d+):(.*)]])

  local ok
  ok, lnum = pcall(tonumber, lnum)
  if not ok then
    lnum = nil
  end

  t.filename = filename
  t.lnum = lnum
  t.col = nil
  t.text = text

  return { filename, lnum, nil, text }
end

local parse_only_filename = function(t)
  t.filename = t.value
  t.lnum = nil
  t.col = nil
  t.text = ""

  return { t.filename, nil, nil, "" }
end

local lookup_keys = {
  display = 1,
  ordinal = 1,
  value = 1,
}

_G.my_gen_from_vimgrep = function(opts)
  if vim.g.telescope_entry_fullpath_display then
    local make_entry = require "telescope.make_entry"
    return make_entry.gen_from_vimgrep({})
  end
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
    local res, hl = displayer {
      line_info,
      display_fname,
      -- this gsub causes considerable performance issues with
      -- text search, for which we can type very fast and results come in fast
      -- => comment it out
      entry.text -- :gsub(".* | ", ""),
    }
    local filetype_icon = display_fname:match("^[^%s]+")
    local icon_strwidth = vim.api.nvim_strwidth(filetype_icon)
    table.insert(hl, {{5+3, 5+3+icon_strwidth}, path_hl})
    table.insert(hl, {{5+3+icon_strwidth+1,10+25}, "TelescopeResultsConstant"})

    return res, hl

    -- highlighting the matches would require matching a filename to a buffer, or opening the file to a buffer...
    -- https://github.com/fdschmidt93/telescope-egrepify.nvim/blob/43a38fdc69c181fede29981f4b3a8441cb4be25e/lua/telescope/_extensions/egrepify/entry_maker.lua#L107
    -- maybe i optionally enable that sometime, but i'm not crazy of the performance consequences

    -- if entry.bufnr and (vim.g.telescope_force_load_hl or vim.api.nvim_buf_is_loaded(entry.bufnr)) and entry.lnum ~= nil then
    --   local hl = quicker_hl.buf_get_ts_highlights(entry.bufnr, entry.lnum)
    --   local offset = 5 + 22 + display_fname:len() - vim.api.nvim_strwidth(display_fname) + 6
    --   for _, seh in ipairs(hl) do
    --     table.insert(hl2, {{seh[1]+offset, seh[2]+offset}, seh[3]})
    --   end
    -- end
    -- return d, hl2
  end

  local mt_vimgrep_entry
  local parse = parse_with_col
  if opts.__matches == true then
    parse = parse_only_filename
  elseif opts.__inverted == true then
    parse = parse_without_col
  end

  local disable_devicons = opts.disable_devicons
  local disable_coordinates = opts.disable_coordinates
  local only_sort_text = opts.only_sort_text

  local execute_keys = {
    path = function(t)
      if Path:new(t.filename):is_absolute() then
        return t.filename, false
      else
        return Path:new({ t.cwd, t.filename }):absolute(), false
      end
    end,

    filename = function(t)
      return parse(t)[1], true
    end,

    lnum = function(t)
      return parse(t)[2], true
    end,

    col = function(t)
      return parse(t)[3], true
    end,

    text = function(t)
      return parse(t)[4], true
    end,
  }

  -- For text search only, the ordinal value is actually the text.
  if only_sort_text then
    execute_keys.ordinal = function(t)
      return t.text
    end
  end

  local display_string = "%s%s%s"

  mt_vimgrep_entry = {
    cwd = utils.path_expand(opts.cwd or vim.loop.cwd()),

    display = make_display,

    __index = function(t, k)
      local override = handle_entry_index(opts, t, k)
      if override then
        return override
      end

      local raw = rawget(mt_vimgrep_entry, k)
      if raw then
        return raw
      end

      local executor = rawget(execute_keys, k)
      if executor then
        local val, save = executor(t)
        if save then
          rawset(t, k, val)
        end
        return val
      end

      return rawget(t, rawget(lookup_keys, k))
    end,
  }

  return function(line)
    return setmetatable({ line }, mt_vimgrep_entry)
  end
end
