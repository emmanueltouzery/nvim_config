-- compared to the original one, we display stashes with git diff instead of git stash show:
-- https://stackoverflow.com/questions/76662495

function telescope_stash_mappings(prompt_bufnr, map)
  local actions = require('telescope.actions')
  map('i', '<C-v>', function(nr)
    stash_key = require("telescope.actions.state").get_selected_entry(prompt_bufnr).value
    actions.close(prompt_bufnr)
    vim.cmd(":DiffviewOpen " .. stash_key .. "^.." .. stash_key)
  end)
  map('i', '<C-Del>', function(nr)
    stash_key = require("telescope.actions.state").get_selected_entry(prompt_bufnr).value
    actions.close(prompt_bufnr)
    local Job = require'plenary.job'
    Job:new({
      command = 'git',
      args = { 'stash', 'drop', stash_key },
      on_exit = function(j, return_val)
        print(vim.inspect(j:result()))
      end,
    }):sync()
  end)
  actions.select_default:replace(function(prompt_bufnr)
    -- copy-pasted from telescope actions.git_apply_stash + added the reload_all()
    local action_state = require "telescope.actions.state"
    local actions = require("telescope.actions")
    local utils = require "telescope.utils"

    local selection = action_state.get_selected_entry()
    if selection == nil then
      utils.__warn_no_selection "actions.git_apply_stash"
      return
    end
    actions.close(prompt_bufnr)
    local _, ret, stderr = utils.get_os_command_output { "git", "stash", "apply", "--index", selection.value }
    if ret == 0 then
      reload_all()
      utils.notify("actions.git_apply_stash", {
        msg = string.format("applied: '%s' ", selection.value),
        level = "INFO",
      })
    else
      utils.notify("actions.git_apply_stash", {
        msg = string.format("Error when applying: %s. Git returned: '%s'", selection.value, table.concat(stderr, " ")),
        level = "ERROR",
      })
    end
  end)
  return true
end


function _G.telescope_git_list_stashes(opts)
  local pickers = require "telescope.pickers"
  local make_entry = require "telescope.make_entry"
  local actions = require("telescope.actions")
  local finders = require "telescope.finders"
  local previewers = require("telescope.previewers")
  local conf = require("telescope.config").values

  opts.show_branch = vim.F.if_nil(opts.show_branch, true)
  opts.entry_maker = vim.F.if_nil(opts.entry_maker, make_entry.gen_from_git_stash(opts))

  pickers
    .new(opts, {
      prompt_title = "Git Stash",
      finder = finders.new_oneshot_job(
        vim.tbl_flatten {
          "git",
          "--no-pager",
          "stash",
          "list",
        },
        opts
      ),
      previewer = previewers.new_termopen_previewer({
      get_command = function(entry, status)
        export = entry.contents
        return {"sh", "-c", "git -c color.ui=always diff " .. entry.value .. "^.." .. entry.value  .. " | less -RS +0 --tilde"}
      end
    }),
      sorter = conf.file_sorter(opts),
      attach_mappings = telescope_stash_mappings,
    })
    :find()
end
