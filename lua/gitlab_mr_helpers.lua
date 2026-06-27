local function get_mr_number()
  return vim.trim(vim.system({"bash", "-c", "git ls-remote origin 'refs/merge-requests/*' | grep $(git rev-parse HEAD) | cut -d/ -f3"}):wait().stdout)
end

local function diff_new_to_old_line(diff, new_line)
  for _, h in ipairs(diff) do
    local old_start, old_count, new_start, new_count = unpack(h)
    if new_start + new_count >= new_line then
      old_move = old_count
      if old_move == 0 then
        old_move = 1
      end
      return old_start + old_move
    end
  end
end

local function gitlab_mr_open_at_line()
  local absolute_file_path = vim.api.nvim_buf_get_name(0)
  if vim.startswith(absolute_file_path, "diffview://") then
    absolute_file_path = require('diffview.lib').get_current_view().cur_entry.path
  end
  local git_path = vim.fs.root(absolute_file_path, '.git')
  local file_path = absolute_file_path:gsub(escape_pattern(git_path) .. "/", "")
  local path_sha1 = vim.trim(vim.system({ "bash", "-c", string.format("echo -n %s | sha1sum | cut -d' ' -f1", file_path) }):wait().stdout)

  local git_url = vim.system({"git", "config", "--get", "remote.origin.url"}):wait().stdout
  local gitlab_repo, gitlab_path = git_url:match("[/@]([^/@]-gitlab.-)[:/](.-)%.git")

  local mr_number = get_mr_number()

  local base_branch = vim.trim(vim.system({"bash", "-c", string.format([[git fetch origin refs/merge-requests/%d/merge -q && git log FETCH_HEAD --merges -n 1 --oneline | sed -E "s/.*into '(.*)'/\1/"]], mr_number)}):wait().stdout)

  -- open the file in the base branch
  local orig_file = vim.system({"git", "show", base_branch .. ':' .. file_path}):wait().stdout
  local cur_file = table.concat(vim.api.nvim_buf_get_lines(0, 0, -1, false), "\n")
  local diff = vim.diff(orig_file, cur_file, { result_type = "indices", ignore_whitespace = true })
  local old_lnum = diff_new_to_old_line(diff, vim.fn.line('.'))

  vim.system({"xdg-open", string.format("https://%s/%s/-/merge_requests/%d/diffs#%s_%d_%d", gitlab_repo, gitlab_path, mr_number, path_sha1, old_lnum, vim.fn.line("."))})
end

vim.keymap.set("n", "<leader>gu", gitlab_mr_open_at_line, {desc="gitlab url"})
