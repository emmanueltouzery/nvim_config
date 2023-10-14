-- started from telescope's oldfiles+improved
-- if there are no recent files, fallback to the normal files picker
_G.telescope_recent_or_all = function(opts)
  opts = opts or {cwd_only=true}
  local current_buffer = vim.api.nvim_get_current_buf()
  local current_file = vim.api.nvim_buf_get_name(current_buffer)
  local results = {}

  for _, file in ipairs(vim.v.oldfiles) do
    local file_stat = vim.loop.fs_stat(file)
    if file_stat and file_stat.type == "file" and not vim.tbl_contains(results, file) and file ~= current_file then
      table.insert(results, file)
    end
  end

  if opts.cwd_only or opts.cwd then
    local utils = require "telescope.utils"
    local cwd = opts.cwd or vim.loop.cwd()
    cwd = cwd .. utils.get_separator()
    cwd = cwd:gsub([[\]], [[\\]])
    results = vim.tbl_filter(function(file)
      return vim.fn.matchstrpos(file, cwd)[2] ~= -1
    end, results)
  end

  if #results == 0 then
    -- no recent results, fallback on the list of all files
    require'telescope.builtin'.find_files{hidden=true, cwd=opts.cwd, cwd_only=opts.cwd_only}
  else
    local pickers = require "telescope.pickers"
    local finders = require "telescope.finders"
    local make_entry = require "telescope.make_entry"
    local conf = require("telescope.config").values

    pickers
    .new(opts, {
      prompt_title = "Oldfiles",
      finder = finders.new_table {
        results = results,
        entry_maker = opts.entry_maker or make_entry.gen_from_file(opts),
      },
      sorter = conf.file_sorter(opts),
      previewer = conf.file_previewer(opts),
    })
    :find()
  end
end
