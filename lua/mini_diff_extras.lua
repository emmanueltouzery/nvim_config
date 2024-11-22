local function hunk_popup_show(lines, width)
  if #lines == 0 or width == 0 then
    return
  end
  local popup_buf = vim.api.nvim_create_buf(false, true)
  local height = #lines
  local win_opts = {
    focusable = false,
    style = "minimal",
    border = "rounded",
    relative = "cursor",
    width = width,
    height = height,
    anchor = "NW",
    row = 1,
    col = 1,
    noautocmd = true,
  }
  vim.api.nvim_buf_set_lines(popup_buf, 0, -1, false, lines)
  vim.api.nvim_set_option_value("filetype", "diff", {buf = popup_buf})
  vim.b.popup_win = vim.api.nvim_open_win(popup_buf, false, win_opts)

  vim.api.nvim_create_autocmd({ "WinEnter", "TabClosed", "CursorMoved" }, {
    group = "hunkAtCurpos",
    callback = function()
      local ok, popup_win = pcall(vim.api.nvim_buf_get_var, 0, 'popup_win')
      if ok then
        local ok, isvalid = pcall(vim.api.nvim_win_is_valid, popup_win)
        if ok and isvalid then
          pcall(vim.api.nvim_win_close, popup_win, true)
          vim.b.popup_win = nil
        end
      end
    end,
    once = true,
  })
end

local function hunk_popup_add_change(minidiff_data, hunk, lines, width)
  -- first the deleted lines
  local cur_line = 1
  for line in vim.gsplit(minidiff_data.ref_text, "\n") do
    if cur_line >= hunk.ref_start then
      if cur_line >= hunk.ref_start + hunk.ref_count then
        goto change_ref_done
      end
      table.insert(lines, "-" .. line)
      if #line+1 > width then
        width = #line+1
      end
    end
    cur_line = cur_line + 1
  end

  ::change_ref_done::
  -- now the added lines
  for _, line in ipairs(vim.api.nvim_buf_get_lines(0, hunk.buf_start-1, hunk.buf_start-1+hunk.ref_count, false)) do
    table.insert(lines, "+" .. line)
    if #line+1 > width then
      width = #line+1
    end
  end

  return width
end

local function hunk_popup_add_add(minidiff_data, hunk, lines, width)
  for _, line in ipairs(vim.api.nvim_buf_get_lines(0, hunk.buf_start-1, hunk.buf_start-1+hunk.buf_count, false)) do
    table.insert(lines, "+" .. line)
    if #line+1 > width then
      width = #line+1
    end
  end

  return width
end

local function hunk_popup_add_delete(minidiff_data, hunk, lines, width)
  local cur_line = 1
  for line in vim.gsplit(minidiff_data.ref_text, "\n") do
    if cur_line >= hunk.ref_start then
      if cur_line >= hunk.ref_start + hunk.ref_count then
        goto change_ref_done
      end
      table.insert(lines, "-" .. line)
      if #line+1 > width then
        width = #line+1
      end
    end
    cur_line = cur_line + 1
  end

  ::change_ref_done::
  return width
end

vim.api.nvim_create_augroup("hunkAtCurpos", {})
function _G.hunk_popup()
  if vim.b.popup_win ~= nil and vim.api.nvim_win_is_valid(vim.b.popup_win) then
    -- focus the existing popup
    vim.api.nvim_clear_autocmds({group = "hunkAtCurpos"})
    vim.api.nvim_set_current_win(vim.b.popup_win)
  else
    -- open a new popup
    local cur_line = vim.fn.line('.')
    local minidiff_data = MiniDiff.get_buf_data(0)

    local lines = {}
    local width = 0

    for _, hunk in ipairs(minidiff_data.hunks) do
      if hunk.type == "change" and hunk.buf_start <= cur_line and hunk.buf_start + hunk.buf_count > cur_line then
        width = hunk_popup_add_change(minidiff_data, hunk, lines, width)
      elseif hunk.type == "add" and hunk.buf_start <= cur_line and hunk.buf_start + hunk.buf_count >= cur_line then
        width = hunk_popup_add_add(minidiff_data, hunk, lines, width)
      elseif hunk.type == "delete" and hunk.buf_start == cur_line then
        width = hunk_popup_add_delete(minidiff_data, hunk, lines, width)
      end
    end
    hunk_popup_show(lines, width)
  end
end
