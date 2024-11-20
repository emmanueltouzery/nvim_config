local function hunk_popup_show(lines, width)
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
  local popup_win = vim.api.nvim_open_win(popup_buf, true, win_opts)
end

local function hunk_popup_show_change(minidiff_data, hunk)
  local lines = {}
  local width = 0

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

  hunk_popup_show(lines, width)
end

local function hunk_popup_show_add(minidiff_data, hunk)
  local lines = {}
  local width = 0

  for _, line in ipairs(vim.api.nvim_buf_get_lines(0, hunk.buf_start-1, hunk.buf_start-1+hunk.buf_count, false)) do
    table.insert(lines, "+" .. line)
    if #line+1 > width then
      width = #line+1
    end
  end

  hunk_popup_show(lines, width)
end

local function hunk_popup_show_delete(minidiff_data, hunk)
  local lines = {}
  local width = 0

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
  hunk_popup_show(lines, width)
end

function _G.hunk_popup()
  local cur_line = vim.fn.line('.')
  local minidiff_data = MiniDiff.get_buf_data(0)
  for _, hunk in ipairs(minidiff_data.hunks) do
    if hunk.type == "change" and hunk.buf_start <= cur_line and hunk.buf_start + hunk.buf_count > cur_line then
      hunk_popup_show_change(minidiff_data, hunk)
    elseif hunk.type == "add" and hunk.buf_start <= cur_line and hunk.buf_start + hunk.buf_count >= cur_line then
      hunk_popup_show_add(minidiff_data, hunk)
    elseif hunk.type == "delete" and hunk.buf_start == cur_line then
        hunk_popup_show_delete(minidiff_data, hunk)
    end
  end
end
