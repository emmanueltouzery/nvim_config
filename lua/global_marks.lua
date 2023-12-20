function _G.add_global_mark()
  -- find a free mark name
  used_marks = {}
  for i, mark in ipairs(vim.fn.getmarklist()) do
    if mark.mark:match("[A-Z]") then
      used_marks[strings.strcharpart(mark.mark, 1, 1)] = true
    end
  end
  for i, mark in ipairs({'A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M', 
                        'N', 'O', 'P', 'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z'}) do
    if used_marks[mark] == nil then
      vim.fn.feedkeys("m" .. mark)
      vim.cmd("redraw!")
      -- not sure why defer_fn is needed, but without it,
      -- the state doesn't seem synced -- other nvim instances
      -- don't see the change despite calling rshada
      vim.defer_fn(function()
        vim.cmd("wshada!")
      end, 1000)
      return
    end
  end
  print("All marks are used up!")
end


