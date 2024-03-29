require("nolsp_navigation_locals")

local function find_buf_for_fname(fname)
  for i, bufnr in pairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_get_name(bufnr) == fname then
      return bufnr
    end
  end
  return nil
end

local function picker_finish(matches)
  if #matches == 0 then
    matches = find_local_declarations()
  end
  if #matches == 0 then
    vim.notify("No matches found", vim.log.levels.ERROR)
  elseif #matches == 1 then
    local fbuf = matches[1].bufnr or find_buf_for_fname(matches[1].path)
    if fbuf ~= nil then
      vim.api.nvim_win_set_buf(0, fbuf)
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
end

function _G.global_picker(queries_left, title, matches)
  local cwd = vim.fn.getcwd()
  local line_in_result = 1
  local fname, lnum_str, col_str
  vim.fn.jobstart(table.remove(queries_left, 1), {
    cwd = cwd,
    on_stdout = vim.schedule_wrap(function(j, output)
      for _, line in ipairs(output) do
        print(line_in_result)
        print(line)
        if #line > 0 then
          if line_in_result == 1 then
            -- help[query], skip
            line_in_result = line_in_result + 1
          elseif line_in_result == 2 then
            fname, lnum_str, col_str = line:gmatch("%.([^:]+):([^:]+):([^:]+)")()
            print(fname)
            line_in_result = line_in_result + 1
          elseif line_in_result == 3 then
            -- blank, skip
            line_in_result = line_in_result + 1
          elseif line_in_result == 4 then
            -- line contents
            line_contents = line:sub(12)
            print(line_contents)
            line_in_result = line_in_result + 1
            table.insert(matches, {lnum = tonumber(lnum_str), col = tonumber(col_str), path = cwd .. '/' .. fname, fname = fname, line = line_contents})
          elseif line:match("help%[") then
            line_in_result = 2
          end
        end
      end
    end),
    on_exit = vim.schedule_wrap(function(j, output)
      if #queries_left == 0 then
        print(vim.inspect(matches))
        picker_finish(matches)
      else
        global_picker(queries_left, title, matches)
      end
    end)
  })
end

local function get_rule_word_under(word, parent)
  return [[ast-grep scan --inline-rules '
id: query
language: Java
rule:
  pattern: ]] .. word .. [[

  inside:
    kind: ]] .. parent .. [[']]
end

function _G.global_find_definition()
  local word = vim.fn.expand('<cword>')
  global_picker({
    get_rule_word_under(word, 'method_declaration'),
    get_rule_word_under(word, 'class_declaration'),
    get_rule_word_under(word, 'enum_declaration'),
    get_rule_word_under(word, 'variable_declarator'),
  }, "Definitions", {})
end

function _G.global_find_references()
  local word = vim.fn.expand('<cword>')
  global_picker({get_rule_word_under(word, 'method_invocation')}, "References", {})
end
