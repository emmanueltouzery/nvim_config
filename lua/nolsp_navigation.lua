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

function _G.global_picker(query, title, matches)
  local cwd = vim.fn.getcwd()
  local line_in_result = 1
  local fname, lnum_str, col_str
  vim.fn.jobstart(query, {
    cwd = cwd,
    on_stdout = vim.schedule_wrap(function(j, output)
      for _, line in ipairs(output) do
        if #line > 0 then
          if line_in_result == 1 then
            -- help[query], skip
            line_in_result = line_in_result + 1
          elseif line_in_result == 2 then
            fname, lnum_str, col_str = line:gmatch("%.([^:]+):([^:]+):([^:]+)")()
            line_in_result = line_in_result + 1
          elseif line_in_result == 3 then
            -- blank, skip
            line_in_result = line_in_result + 1
          elseif line_in_result == 4 then
            -- line contents? bunch of ^^^ under the proper line
            if line:match("%^%^%^") then
              line_in_result = line_in_result + 1
              table.insert(matches, {lnum = tonumber(lnum_str), col = tonumber(col_str), path = cwd .. '/' .. fname, fname = fname, line = line_contents})
            else
              line_contents = line:sub(12)
            end
          elseif line:match("help%[") then
            line_in_result = 2
          end
        end
      end
    end),
    on_exit = vim.schedule_wrap(function(j, output)
      picker_finish(matches)
    end)
  })
end

function _G.global_find_definition()
  local ts_utils = require("nvim-treesitter.ts_utils")
  local ts_node = ts_utils.get_node_at_cursor()
  local parent1 = ts_node:parent()
  if parent1:type() == "method_reference" then
    -- this is a method reference Class::method, and the cursor is on the method
    local methodName = vim.fn.expand('<cword>')
    local row1, col1, row2, col2 = ts_node:prev_sibling():prev_sibling():range()
    local bufnr = vim.api.nvim_win_get_buf(0)
    local className = vim.api.nvim_buf_get_text(bufnr, row1, col1, row2, col2, {})[1]
    local find_method_reference_def_pattern = [[
      id: query
      language: Java

      utils:
        is-method-identifier:
          inside:
            kind: method_declaration

      rule:
        pattern: #methodName#
        matches: is-method-identifier
        inside:
          stopBy:
            kind: class_declaration
          has:
            pattern: #className#
    ]]
    -- pre-filter the files to process with rg for speed
    global_picker({'sh', '-c', [[ast-grep scan --inline-rules ']]
      .. find_method_reference_def_pattern:gsub('#methodName#', methodName):gsub('#className#', className)
      .. [[' $(rg -l ]] .. methodName .. [[ . | tr '\n' ' ')]]}, "Definitions", {})
  else
    local word = vim.fn.expand('<cword>')
    local find_def_pattern = [[
    id: query
    language: Java
    rule:
      any:
        - pattern: #word#

          inside:
            kind: method_declaration
        - pattern: #word#

          inside:
            kind: class_declaration
        - pattern: #word#

          inside:
            kind: interface_declaration
        - pattern: #word#

          inside:
            kind: annotation_type_declaration
        - pattern: #word#

          inside:
            kind: enum_declaration
    ]]
    -- pre-filter the files to process with rg for speed
    global_picker({'sh', '-c', [[ast-grep scan --inline-rules ']] .. find_def_pattern:gsub('#word#', word)
      .. [[' $(rg -l ]] .. word .. [[ . | tr '\n' ' ')]]}, "Definitions", {})
  end
end

function _G.global_find_references()
  local word = vim.fn.expand('<cword>')
  local references_pattern = [[
id: query
language: Java
rule:
  any:
    - pattern: #word#

      inside:
        kind: method_invocation
    - pattern: #word#

      inside:
        kind: method_reference

    - pattern:
        context: new #word#($$PARAMS)
        selector: type_identifier

      inside:
        kind: object_creation_expression
  ]]
  -- pre-filter the files to process with rg for speed
  global_picker([[ast-grep scan --inline-rules ']] .. references_pattern:gsub('#word#', word)
    ..  [[' $(rg -l ]] .. word .. [[ . | tr '\n' ' ')]], "Definitions", {})
end
