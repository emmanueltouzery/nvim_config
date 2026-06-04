local function commit_buffer(popup_buf, popup_win, also_push)
  local lines = vim.api.nvim_buf_get_lines(popup_buf, 0, -1, false)
  local stdin_text = table.concat(lines, "\n")
  vim.system({ "git", "commit", "--cleanup=strip", "-F", "-" }, {
    stdin = stdin_text,
  }, function(obj)
    vim.schedule(function()
      if obj.code == 0 then
        vim.notify("Git commit successful!", vim.log.levels.INFO)
        vim.api.nvim_win_close(popup_win, true)
        vim.api.nvim_buf_delete(popup_buf, { force = true })
        vim.api.nvim_exec_autocmds("User", {
          pattern = "GitCommitComplete",
        })
        if also_push then
          run_command({"git", "push"}, reload_all)
        end
      else
        -- If it fails (e.g., nothing to commit), show the stderr error
        local err = obj.stderr ~= "" and obj.stderr or "Unknown error"
        vim.notify("Git commit failed:\n" .. err, vim.log.levels.ERROR)
      end
    end)
  end)
end

function _G.open_git_commit_popup()
    vim.system({"bash", "-c", [[
      echo -n 'branch: '
      git branch --show-current
      echo 'Staged changes, will be committed:'
      git diff --staged --stat --exit-code
      staged_res=$?
      non_staged=$(git diff --stat --exit-code)
      if [ $? -gt 0 ]; then
        echo
        echo 'Non-staged changes, will NOT be committed:'
        echo "$non_staged"
      fi
      exit $staged_res ]]}, {text=true}, function(res)
      vim.schedule(function()
        if res.code == 0 then
          vim.notify("Nothing staged, can't commit", vim.log.levels.ERROR)
        else
          -- changes present, proceed to commit
          local popup_buf = vim.api.nvim_create_buf(true, false)
          vim.api.nvim_buf_set_option(popup_buf, 'ft', 'mygitcommit') -- syntax/mygitcommit.lua
          vim.api.nvim_buf_set_option(popup_buf, 'textwidth', 80)
          vim.api.nvim_buf_set_lines(popup_buf, 0, -1, false, vim.tbl_map(function(l) return "# " .. l end, vim.split(res.stdout, "\n")))

          local editor_width = vim.api.nvim_get_option("columns")
          local editor_height = vim.api.nvim_get_option("lines") - vim.o.cmdheight - 1

          local width = 150
          local height = 60
          local win_opts = {
            focusable = true,
            style = "minimal",
            border = "rounded",
            relative = "editor",
            width = width,
            height = height,
            anchor = "NW",
            row = (editor_height - height) / 2,
            col = (editor_width - width) / 2,
          }
          local popup_win = vim.api.nvim_open_win(popup_buf, true, win_opts)
          vim.wo[popup_win].winbar = "%=--- Git commit message ---%="
          vim.wo[popup_win].spell = true

          vim.keymap.set('n', 'q', function()
            vim.api.nvim_win_close(popup_win, true)
            vim.api.nvim_buf_delete(popup_buf, { force = true })
          end, { buffer = popup_buf})

          vim.keymap.set('n', '<localleader>c', function()
            commit_buffer(popup_buf, popup_win, false)
          end, { buffer = popup_buf, desc = "Perform git commit"})

          vim.keymap.set('n', '<localleader>p', function()
            commit_buffer(popup_buf, popup_win, true)
          end, { buffer = popup_buf, desc = "Perform git commit and push"})

          -- color characters after various limits for 1st line, 2nd line and all followup lines
          vim.cmd([[match ErrorMsg '\%1l\%>72v.\+\|\%2l.\+\|\%>2l\%>100v.\+']])

          vim.api.nvim_buf_set_lines(popup_buf, 0, 0, false, { "", "", "# Use <localleader>c and <localleader>p to commit and push to commit", "# " })
          vim.api.nvim_win_set_cursor(popup_win, { 1, 0 })
          vim.cmd("startinsert")
        end
      end)
    end)
end

vim.keymap.set("n", "<leader>gX", open_git_commit_popup, { desc = "Perform git commit" })
