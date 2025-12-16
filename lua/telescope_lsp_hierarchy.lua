local pickers = require "telescope.pickers"
local entry_display = require("telescope.pickers.entry_display")
local finders = require "telescope.finders"
local conf = require("telescope.config").values

local function tbl_reverse(tbl)
  local len = #tbl
  for i = 1, math.floor(len / 2) do
    local j = len - i + 1
    local swp = tbl[i]
    tbl[i] = tbl[j]
    tbl[j] = swp
  end
  return tbl
end

-- https://microsoft.github.io/language-server-protocol/specifications/lsp/3.17/specification/#textDocument_prepareCallHierarchy
function _G.telescope_display_call_hierarchy()

  local displayer = entry_display.create {
    separator = " ",
    hl_chars = { [":"] = "Comment" },
    items = {
      { width = 35, },
      { remaining = true },
    },
  }

  local make_display = function(entry)
    local p = entry.path:match("[^/]+/[^/]+$")
    return displayer {
      { entry.name, "TelescopeResultsIdentifier" },
      { string.format("%s:%d", p, entry.lnum), function() return { {{0, #p}, "Special"}, {{#p+1, #p+2+#tostring(entry.lnum)}, "Comment"}} end},
    }
  end

  local make_display_nested = function(entry)
    local p = entry.path:match("[^/]+/[^/]+$")
    return displayer {
      { entry.name, "TelescopeResultsFunction" },
      { string.format("%s:%d", p, entry.lnum), function() return { {{0, #p}, "Special"}, {{#p+1, #p+2+#tostring(entry.lnum)}, "Comment"}} end},
    }
  end

  local by_lsp = vim.lsp.buf_request_sync(0, 'textDocument/prepareCallHierarchy', vim.lsp.util.make_position_params())
  if by_lsp ~= nil and #by_lsp >= 1 then
    local result = by_lsp[vim.tbl_keys(by_lsp)[1]].result
    if #result >= 1 then
      local call_hierarchy_item = result[1]
      call_tree = get_call_hierarchy_for_item(call_hierarchy_item)

      data = {}
      for _, caller_info in pairs(call_tree) do
        print_hierarchy(caller_info, 0, data)
      end

      local conf = require("telescope.config").values
      -- Reverse the callers so they have the same top-to-bottom order as in the file
      local sorting_strategy = conf.sorting_strategy
      if sorting_strategy == "ascending" then
        tbl_reverse(data)
      end

      pickers.new({}, {
        prompt_title = "Incoming calls: " .. call_hierarchy_item.name,
        finder = finders.new_table {
          results = data,
          entry_maker = function(entry)
            -- print(vim.inspect(entry))
            entry.name = entry.desc
            entry.ordinal = entry.desc
            if entry.depth ~= nil and entry.depth > 0 then
              entry.display = make_display_nested
            else
              entry.display = make_display
            end
            entry.path = entry.item.item.from.uri:gsub("^file:..", "")
            entry.lnum = entry.item.item.fromRanges[1].start.line+1
            return entry
          end,
        },
        previewer = conf.grep_previewer({}),
      }):find()
    end
  end
end

function _G.get_call_hierarchy_for_item(call_hierarchy_item)
  local call_tree = {}
  -- https://microsoft.github.io/language-server-protocol/specifications/lsp/3.17/specification/#callHierarchy_incomingCalls
  local by_lsp = vim.lsp.buf_request_sync(0, 'callHierarchy/incomingCalls', { item = call_hierarchy_item })
  if by_lsp and #by_lsp >= 1 then
    local result = by_lsp[vim.tbl_keys(by_lsp)[1]].result
    if #result >= 1 then
      for _, item in ipairs(result) do
        -- "group by" URL, because two calling classes/functions could have the same name,
        -- but different URIs/being distinct. If we grouped by name, we'd merge them.
        call_tree[item.from.uri] = { item = item, nested_hierarchy = get_call_hierarchy_for_item(item.from)}
      end
    end
  end
  return call_tree
end

function _G.print_hierarchy(item, depth, res)
  local prefix = string.rep(" ", depth)
  if depth > 0 then
    prefix = prefix ..  "󰘍 "
  end
  for _, nested_h in pairs(item.nested_hierarchy) do
    print_hierarchy(nested_h, depth + 1, res)
  end
  table.insert(res, {item = item, desc = prefix .. item.item.from.name, depth = depth})
end
