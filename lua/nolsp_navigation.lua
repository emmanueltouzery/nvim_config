require("nolsp_navigation_locals")

local function find_buf_for_fname(fname)
  for i, bufnr in pairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_get_name(bufnr) == fname then
      return bufnr
    end
  end
  return nil
end

function _G.global_picker(flags, title)
  local word = vim.fn.expand('<cword>')
  local cwd = vim.fn.expand('%:h')
  local matches = {}
  vim.fn.jobstart("global " .. flags .. " " .. word, {
    cwd = cwd,
    on_stdout = vim.schedule_wrap(function(j, output)
        for _, line in ipairs(output) do
          if #line > 0 then
            local _, lnum_str, fname, line = line:gmatch("([%S]+)%s+([%S]+)%s+([%S]+)%s+(.*)")()
            table.insert(matches, {lnum = tonumber(lnum_str), col=-1, path = cwd .. '/' .. fname, fname = fname, line = line})
          end
        end
    end),
    on_exit = vim.schedule_wrap(function(j, output)
      if #matches == 0 then
        matches = find_local_declarations()
      end
      if #matches == 0 then
        vim.notify("No matches found", vim.log.levels.ERROR)
      elseif #matches == 1 then
        local fbuf = find_buf_for_fname(matches[1].path)
        if fbuf ~= nil then
          vim.cmd(":b" .. fbuf)
        else
          vim.cmd(":e " .. matches[1].path)
        end
        vim.fn.setpos('.', {0, matches[1].lnum, matches[1].col+1, 0})
        vim.cmd[[ norm! zz]]
      else
        local pickers = require "telescope.pickers"
        local finders = require "telescope.finders"
        local conf = require("telescope.config").values
        local entry_display = require("telescope.pickers.entry_display")
        local Str = require'plenary.strings'
        local opts = {}

        local displayer = entry_display.create {
          separator = " ",
          items = {
            { width = 35, },
            { remaining = true },
          },
        }
        local make_display = function(entry)
          return displayer {
            { Str.truncate(entry.path, 35, "…", -1), "TelescopeResultsIdentifier" },
            { entry.line, "Special" },
          }
        end

        pickers.new(opts, {
          prompt_title = title,
          finder = finders.new_table {
            results = matches,
            entry_maker = function(entry)
              -- print(vim.inspect(entry))
              entry.name = entry.fname
              entry.ordinal = entry.fname
              entry.display = make_display
              return entry
            end,
          },
          previewer = conf.grep_previewer(opts),
          sorter = conf.generic_sorter(opts),
        }):find()
      end
    end)
  })
end

function _G.global_find_definition()
  global_picker("-x", "Definitions")
end

function _G.global_find_references()
  global_picker("-rx", "References")
end

function _G.global_generate_tags(folder)
  vim.fn.jobstart("gtags", {cwd=folder})
end
