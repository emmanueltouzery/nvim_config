-- forked from https://github.com/nvim-telescope/telescope.nvim/blob/master/lua/telescope/builtin/__git.lua#L197 as of 9f50168
local utils = require "telescope.utils"
local pickers = require "telescope.pickers"
local finders = require "telescope.finders"
local make_entry = require "telescope.make_entry"
local previewers = require("telescope.previewers")
local conf = require("telescope.config").values
local actions = require("telescope.actions")
local entry_display = require("telescope.pickers.entry_display")
local strings = require'plenary.strings'

_G.git_branches = function(opts)
  -- the base will be develop if a develop branch exists, otherwise master.
  local lines = 0
  vim.fn.jobstart(
    { "git", "branch", "--list", "develop"},
    {
      stdout_buffered = true,
      on_stdout = vim.schedule_wrap(function(j, output)
        for _, line in ipairs(output) do
          if #line > 0 then
            lines = lines + 1
          end
        end
      end),
      on_exit = vim.schedule_wrap(function(j, output)
        if lines > 0 then
          -- develop exists
          git_branches_with_base('develop', opts)
        else
          -- develop doesn't exist
          git_branches_with_base('master', opts)
        end
      end),
    })
end

_G.git_branches_with_base = function(base, opts)
  local format = "%(HEAD)"
  .. "%(refname)"
  .. "%(ahead-behind:origin/" .. base .. ")"
  .. "%(authorname)"
  .. "%(upstream:lstrip=2)"
  .. "%(committerdate:format-local:%Y/%m/%d %H:%M:%S)"
  local output = utils.get_os_command_output(
  { "git", "for-each-ref", "--perl", "--format", format, "--sort", "-authordate", opts.pattern },
  opts.cwd
  )
  local show_remote_tracking_branches = vim.F.if_nil(opts.show_remote_tracking_branches, true)

  local results = {}
  local widths = {
    name = 0,
    authorname = 0,
    upstream = 0,
    committerdate = 0,
    ahead = 0,
    behind = 0,
  }
  local unescape_single_quote = function(v)
    return string.gsub(v, "\\([\\'])", "%1")
  end
  local parse_line = function(line)
    local fields = vim.split(string.sub(line, 2, -2), "''", true)
    local entry = {
      head = fields[1],
      refname = unescape_single_quote(fields[2]),
      ahead = unescape_single_quote(fields[3]):gsub(" .*$", ""),
      behind = unescape_single_quote(fields[3]):gsub("^.* ", ""),
      authorname = unescape_single_quote(fields[4]),
      upstream = unescape_single_quote(fields[5]),
      committerdate = fields[6],
    }
    local prefix
    if vim.startswith(entry.refname, "refs/remotes/") then
      if show_remote_tracking_branches then
        prefix = "refs/remotes/"
      else
        return
      end
    elseif vim.startswith(entry.refname, "refs/heads/") then
      prefix = "refs/heads/"
    else
      return
    end
    local index = 1
    if entry.head ~= "*" then
      index = #results + 1
    end

    entry.name = string.sub(entry.refname, string.len(prefix) + 1)
    for key, value in pairs(widths) do
      widths[key] = math.max(value, strings.strdisplaywidth(entry[key] or ""))
    end
    if string.len(entry.upstream) > 0 then
      widths.upstream_indicator = 2
    end
    table.insert(results, index, entry)
  end
  for _, line in ipairs(output) do
    parse_line(line)
  end
  if #results == 0 then
    return
  end

  local name_width = widths.name
  if name_width > 35 then
    name_width = 35
  end
  local displayer = entry_display.create {
    separator = " ",
    items = {
      { width = 1 },
      { width = name_width },
      { width = 3+widths.ahead+widths.behind },
      { width = widths.authorname },
      { width = widths.upstream_indicator },
      { width = widths.upstream },
      { width = widths.committerdate },
    },
  }

  local make_display = function(entry)
    return displayer {
      { entry.head },
      { entry.name, "TelescopeResultsIdentifier" },
      { "" .. entry.behind .. " " .. entry.ahead },
      { entry.authorname },
      { string.len(entry.upstream) > 0 and "=>" or "" },
      { entry.upstream, "TelescopeResultsIdentifier" },
      { entry.committerdate },
    }
  end

  pickers
    .new(opts, {
      prompt_title = "Git Branches",
      finder = finders.new_table {
        results = results,
        entry_maker = function(entry)
          entry.value = entry.name
          entry.ordinal = entry.name
          entry.display = make_display
          return make_entry.set_default_entry_mt(entry, opts)
        end,
      },
      -- previewer = previewers.git_branch_log.new(opts),
      previewer = git_foresta_branch_log.new(opts),
      sorter = conf.file_sorter(opts),
      attach_mappings = function(_, map)
        actions.select_default:replace(actions.git_checkout)
        map({ "i", "n" }, "<c-t>", actions.git_track_branch)
        map({ "i", "n" }, "<c-r>", actions.git_rebase_branch)
        map({ "i", "n" }, "<c-a>", actions.git_create_branch)
        map({ "i", "n" }, "<c-s>", actions.git_switch_branch)
        map({ "i", "n" }, "<c-d>", actions.git_delete_branch)
        map({ "i", "n" }, "<c-y>", actions.git_merge_branch)
        return true
      end,
    })
    :find()
end

local defaulter = utils.make_default_callable
local ns_previewer = vim.api.nvim_create_namespace "telescope.previewers"
local Job = require'plenary.job'

function get_ansi_escape_cols(line)
  local idx = 1
  res = {}
  cur_group = ""
  while idx <= #line do
    local c = string.byte(line, idx, idx)
    if c == 27 then
      table.insert(res, cur_group)
      cur_group = ""
      idx = get_ansi_escape_cols_handle_escape(line, idx, res)
    else
      cur_group = cur_group .. string.sub(line, idx, idx)
    end
    idx = idx + 1
  end
  if #cur_group > 0 then
    table.insert(res, cur_group)
  end
  return res
end

function get_ansi_escape_cols_handle_escape(line, idx, res)
  local second = string.sub(line, idx+2, idx+2)
  local third = string.sub(line, idx+3, idx+3)
  local fourth = string.sub(line, idx+4, idx+4)
  if second == 'm' then
    return idx+2
  end
  if second == '0' and third == 'm' then
    return idx+3
  end
  if second == '3' and fourth == 'm' then
    return idx+4
  end
  if third == ';' then
    return idx+6
  end
  print("UNHANDLED=>" .. second .. " " .. third)
end

git_foresta_branch_log = defaulter(function(opts)
  local highlight_buffer = function(bufnr, content, fields)
    for i = 1, #content do
      local line = content[i]
      local cols = fields[i]
      local date = cols[3]
      local name = cols[9]
      if date == nil or name == nil then
        goto continue
      end

      -- highlight git commit sha
      pcall(
      vim.api.nvim_buf_add_highlight,
      bufnr,
      ns_previewer,
      "TelescopeResultsIdentifier",
      i - 1,
      0,
      9
      )

      -- highlight tag info if present
      local _, cstart = line:find "%("
      if cstart then
        local cend = string.find(line, "%) ")
        if cend then
          pcall(
            vim.api.nvim_buf_add_highlight,
            bufnr,
            ns_previewer,
            "TelescopeResultsConstant",
            i - 1,
            cstart - 1,
            cend
          )
        end
      end

      -- highlight date
      local hstart, hend = string.find(line, escape_pattern(date))
      if hstart then
        if hend < #line then
          pcall(
            vim.api.nvim_buf_add_highlight,
            bufnr,
            ns_previewer,
            "TelescopeResultsSpecialComment",
            i - 1,
            hstart-1,
            hend
          )
        end
      end

      -- highlight username
      local hstart, hend = string.find(line, escape_pattern(name))
      if hstart then
        if hend < #line then
          pcall(
            vim.api.nvim_buf_add_highlight,
            bufnr,
            ns_previewer,
            "TelescopeResultsVariable",
            i - 1,
            hstart-1,
            hend
          )
        end
      end
      ::continue::
    end
  end

  return previewers.new_buffer_previewer {
    title = "Git Branch Preview",
    get_buffer_by_name = function(_, entry)
      return entry.value
    end,

    define_preview = function(self, entry, status)
      local args = {
        "-c",
        "git-foresta " .. entry.name .. " | head -n 500",
        entry.value,
      }

      Job:new({
        command = "sh",
        args = args,
        cwd = opts.cwd,
        on_exit = vim.schedule_wrap(function(j)
          if not vim.api.nvim_buf_is_valid(self.state.bufnr) then
            return
          end
          local output = j:result()
          local fields = vim.tbl_map(get_ansi_escape_cols, output)
          local clean_output = vim.tbl_map(function(cols) return table.concat(cols) end, fields)
          vim.api.nvim_buf_set_lines(self.state.bufnr, 0, -1, false, clean_output)
          highlight_buffer(self.state.bufnr, clean_output, fields)
        end),
      }):start()
    end,
  }
end, {})
