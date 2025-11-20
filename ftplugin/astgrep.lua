local function ast_grep_buffer()
  vim.system({
    "ast-grep", "scan", "--json", "--inline-rules",
    table.concat(vim.api.nvim_buf_get_lines(0, 0, -1, false), "\n")
  }, {text=true}, vim.schedule_wrap(function(res)
    local ok, json_matches = pcall(vim.json.decode, res.stdout)
    if not ok then
      notif({res.stdout})
      if #res.stderr > 0 then
        notif({res.stderr})
        print(res.stderr)
      end
    else
      local all_items = {}
      for _, match in ipairs(json_matches) do
        table.insert(all_items, {
          filename = match.file,
          lnum = match.range.start.line+1,
          col = match.range.start.column,
        })
      end
      if #all_items == 0 then
        notif({"Ast-grep: no matches"})
      else
        vim.fn.setqflist({}, ' ', { title = title, items = all_items })
        telescope_quickfix_locations{prompt_title = 'Ast-grep matches'}
      end
    end
  end))
end
vim.keymap.set('n', '<localleader>g', ast_grep_buffer, {desc="run ast-grep query", buffer = true})

vim.treesitter.language.register('yaml', 'astgrep')
vim.treesitter.start()

vim.bo.commentstring =  "#%s"
