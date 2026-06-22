local function search_in_folder()
  local cwd = vim.fn.getcwd()
  if not vim.endswith(cwd, "/") then
    cwd = cwd .. "/"
  end
  local path = require'nvim-tree.api'.tree.get_node_under_cursor().absolute_path
  require('telescope').extensions.live_grep_args.live_grep_args({
    cwd=path,
    prompt_title="Search text in directory " .. path:gsub(escape_pattern(cwd), "")
  })
end

vim.keymap.set('n', '<localleader>s', search_in_folder, {desc="search in folder", buffer = true})
