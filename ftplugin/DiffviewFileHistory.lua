local function difftastic_diff()
  local file_path = require'diffview.lib'.get_current_view().cur_layout.b.file.path
  local left_commit = require'diffview.lib'.get_current_view().cur_layout.a.file.rev.commit
  local right_commit = require'diffview.lib'.get_current_view().cur_layout.b.file.rev.commit
  open_difftastic(file_path, left_commit, right_commit)
end

vim.keymap.set('n', '<localleader>f', difftastic_diff, { buffer = true, desc = "Diff with difftastic" })
