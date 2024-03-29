-- compared to the original one, we display stashes with git diff instead of git stash show:
-- https://stackoverflow.com/questions/76662495

function telescope_stash_mappings(prompt_bufnr, map)
  local actions = require('telescope.actions')
  map('i', '<C-f>', function(nr)
    local utils = require "telescope.utils"
    stash_key = require("telescope.actions.state").get_selected_entry(prompt_bufnr).value
    actions.close(prompt_bufnr)
    -- are there untracked files?
    local stdout, ret, stderr = utils.get_os_command_output { "git", "ls-tree", "-r", stash_key.. "^3", "--name-only" }
    if #stdout > 0 then
      vim.ui.select({"Tracked files", "Untracked files"}, {prompt="Show..."}, function(choice)
        if choice == "Tracked files" then
          vim.cmd(":DiffviewOpen " .. stash_key .. "^.." .. stash_key)
        else
          -- https://stackoverflow.com/questions/40883798
          vim.cmd(":DiffviewOpen 4b825dc642cb6eb9a060e54bf8d69288fbee4904.." .. stash_key .. "^3" )
        end
      end)
    else
      vim.cmd(":DiffviewOpen " .. stash_key .. "^.." .. stash_key)
    end
  end)
  map('i', '<C-Del>', function(nr)
    stash_key = require("telescope.actions.state").get_selected_entry(prompt_bufnr).value
    local action_state = require "telescope.actions.state"
    local current_picker = action_state.get_current_picker(prompt_bufnr)
    current_picker:delete_selection(function()
      local Job = require'plenary.job'
      Job:new({
        command = 'git',
        args = { 'stash', 'drop', stash_key },
        -- on_exit = function(j, return_val)
        --   print(vim.inspect(j:result()))
        -- end,
      }):sync()
    end)
  end)
  actions.select_default:replace(function(prompt_bufnr)
    -- copy-pasted from telescope actions.git_apply_stash + added the reload_all() and changed apply to pop
    local action_state = require "telescope.actions.state"
    local actions = require("telescope.actions")
    local utils = require "telescope.utils"

    local selection = action_state.get_selected_entry()
    if selection == nil then
      utils.__warn_no_selection "actions.git_apply_stash"
      return
    end
    actions.close(prompt_bufnr)
    local _, ret, stderr = utils.get_os_command_output { "git", "stash", "pop", "--index", selection.value }
    if ret == 0 then
      reload_all()
      -- utils.notify("actions.git_apply_stash", {
      --   msg = string.format("applied: '%s' ", selection.value),
      --   level = "INFO",
      -- })
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
        -- show stash, ignoring gitignored files, and including untracked files
        -- https://stackoverflow.com/a/76662742/516188
        -- https://stackoverflow.com/a/12681856/516188
        return {"sh", "-c", "(git -c color.ui=always diff " .. entry.value .. "^.." .. entry.value
          .. "; git -c color.ui=always show " .. entry.value .. "^3) | less -RS +0 --tilde"}
      end
    }),
      sorter = conf.file_sorter(opts),
      attach_mappings = telescope_stash_mappings,
    })
    :find()
end
