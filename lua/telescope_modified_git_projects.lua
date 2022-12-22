local pickers = require "telescope.pickers"
local action_state = require "telescope.actions.state"
local previewers = require("telescope.previewers")
local conf = require("telescope.config").values
local Job = require'plenary.job'
local finders = require "telescope.finders"
local entry_display = require "telescope.pickers.entry_display"

_G.telescope_modified_git_projects = function(opts)
  opts = opts or {}

  local function entry_maker(entry)
    return {
      value = entry.folder,
      ordinal = entry.folder,
      display = entry.folder,
      contents = entry.status
    }
  end

  -- ideally should be async but...
  local get_git_status = function(folder)
    local r = nil
    Job:new({
      command = 'git',
      args = { '-C', folder, 'status', '-s' },
      on_exit = function(j, return_val)
        r = j:result()
      end,
    }):sync()
    local res = {}
    if #r > 0 then
      res.folder = folder
      res.status = r
    end
    return res
  end

  local get_modified_git_repos = function ()
    local root_path = vim.fn.expand('~/projects/')
    local dir_contents = vim.fn.readdir(root_path)
    local dir_contents_path = vim.tbl_map(function(p) 
      return root_path .. p
    end, dir_contents)
    local subfolders = vim.tbl_filter(function(p) 
      return vim.fn.isdirectory(p) 
    end, dir_contents_path)
    return vim.tbl_filter(function(p) return p.status ~= nil end, vim.tbl_map(get_git_status, subfolders))
  end

  modified_git_repos = get_modified_git_repos()

  pickers.new(opts, {
    prompt_title = "Modified git projects",
    finder = finders.new_table {
      results = modified_git_repos,
      entry_maker = entry_maker,
    },
    previewer = previewers.new_buffer_previewer({
      define_preview = function(self, entry, status)
        vim.api.nvim_buf_set_lines(self.state.bufnr, 0, -1, true, entry.contents)
        -- require("telescope.previewers.utils").highlighter(
        --   self.state.bufnr,
        --   "diff",
        --   { preview = { treesitter = { enable = {} } } }
        -- )
      end,
    }),
    sorter = conf.generic_sorter(opts),
    attach_mappings = function(p, map)
      map("i", "<cr>", function(prompt_nr)
        local current_picker = action_state.get_current_picker(prompt_bufnr) -- picker state
        local entry = action_state.get_selected_entry()
        require'telescope.builtin'.find_files{cwd=entry.ordinal}
      end)
      tel_proj_attach_mappings(p, map)
      return true
    end,
  }):find()

end
