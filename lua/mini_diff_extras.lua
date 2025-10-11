
-- START lifted from git-signs

--- @param old_start integer
--- @param old_count integer
--- @param new_start integer
--- @param new_count integer
--- @return Gitsigns.Hunk.Hunk
local function create_hunk(old_start, old_count, new_start, new_count)
  return {
    removed = { start = old_start, count = old_count, lines = {} },
    added = { start = new_start, count = new_count, lines = {} },
    head = ('@@ -%d%s +%d%s @@'):format(
      old_start,
      old_count > 0 and ',' .. old_count or '',
      new_start,
      new_count > 0 and ',' .. new_count or ''
    ),

    vend = new_start + math.max(new_count - 1, 0),
    type = new_count == 0 and 'delete' or old_count == 0 and 'add' or 'change',
  }
end

--- @alias Gitsigns.RawHunk {[1]:integer, [2]:integer, [3]:integer, [4]:integer}
--- @alias Gitsigns.RawDifffn fun(a: string, b: string, linematch?: integer): Gitsigns.RawHunk[]

--- @type Gitsigns.RawDifffn
local run_diff_xdl = function(a, b, linematch)
  return vim.diff(a, b, {
    result_type = 'indices',
    -- algorithm = opts.algorithm,
    -- indent_heuristic = opts.indent_heuristic,
    -- ignore_whitespace = opts.ignore_whitespace,
    -- ignore_whitespace_change = opts.ignore_whitespace_change,
    -- ignore_whitespace_change_at_eol = opts.ignore_whitespace_change_at_eol,
    -- ignore_blank_lines = opts.ignore_blank_lines,
    linematch = linematch,
  }) --[[@as Gitsigns.RawHunk[] ]]
end

--- @param hunks Gitsigns.Hunk.Hunk[]
--- @return Gitsigns.Hunk.Hunk[]
local function denoise_hunks(hunks)
  local gaps_between_regions = 5
  -- Denoise the hunks
  local ret = { hunks[1] } --- @type Gitsigns.Hunk.Hunk[]
  for j = 2, #hunks do
    local h, n = ret[#ret], hunks[j]
    if not h or not n then
      break
    end
    if n.added.start - h.added.start - h.added.count < gaps_between_regions then
      h.added.count = n.added.start + n.added.count - h.added.start
      h.removed.count = n.removed.start + n.removed.count - h.removed.start

      if h.added.count > 0 or h.removed.count > 0 then
        h.type = 'change'
      end
    else
      ret[#ret + 1] = n
    end
  end
  return ret
end

--- @param removed string[]
--- @param added string[]
--- @return Gitsigns.Region[] removed
--- @return Gitsigns.Region[] added
local function run_word_diff(removed, added)
  local adds = {} --- @type Gitsigns.Region[]
  local rems = {} --- @type Gitsigns.Region[]

  if #removed ~= #added then
    return rems, adds
  end

  for i = 1, #removed do
    -- pair lines by position
    local a = table.concat(vim.split(removed[i], ''), '\n')
    local b = table.concat(vim.split(added[i], ''), '\n')

    local hunks = {} --- @type Gitsigns.Hunk.Hunk[]
    for _, r in ipairs(run_diff_xdl(a, b)) do
      local rs, rc, as, ac = r[1], r[2], r[3], r[4]

      -- Balance of the unknown offset done in hunk_func
      if rc == 0 then
        rs = rs + 1
      end
      if ac == 0 then
        as = as + 1
      end

      hunks[#hunks + 1] = create_hunk(rs, rc, as, ac)
    end

    hunks = denoise_hunks(hunks)

    for _, h in ipairs(hunks) do
      adds[#adds + 1] = { i, h.type, h.added.start, h.added.start + h.added.count }
      rems[#rems + 1] = { i, h.type, h.removed.start, h.removed.start + h.removed.count }
    end
  end
  return rems, adds
end

-- END of lifted from git-signs

local function do_inline_diff(popup_buf, lines)
  local remove = {}
  local add = {}
  for _, line in ipairs(lines) do
    if line:match("^-") then
      if #add > 0 then
        return
      end
      table.insert(remove, line)
    else
      table.insert(add, line)
    end
  end
  if #add ~= #remove then
    return
  end

  removed_regions, added_regions = run_word_diff(remove, add)

  local ns = vim.api.nvim_create_namespace('my_highlights')
  for _, region in ipairs(removed_regions) do
    local line = region[1]-1
    vim.api.nvim_buf_set_extmark(popup_buf, ns, line, region[3]-1, {
      end_line = line,
      end_col = region[4]-1,
      hl_group = 'GitSignsDeleteInline',
    })
  end

  for _, region in ipairs(added_regions) do
    local line = region[1]-1
    vim.api.nvim_buf_set_extmark(popup_buf, ns, #add + line, region[3]-1, {
      end_line = #add + line,
      end_col = region[4]-1,
      hl_group = 'GitSignsAddInline',
    })
  end
end

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
  local parent_buf = vim.api.nvim_get_current_buf()

  local function close_popup()
    local ok, popup_win = pcall(vim.api.nvim_buf_get_var, parent_buf, 'popup_win')
    if ok then
      local ok, isvalid = pcall(vim.api.nvim_win_is_valid, popup_win)
      if ok and isvalid then
        pcall(vim.api.nvim_win_close, popup_win, true)
        vim.api.nvim_buf_del_var(parent_buf, 'popup_win')
      end
    end
  end

  vim.api.nvim_buf_call(popup_buf, function()
    vim.keymap.set('n', 'q', close_popup, { buffer = true })
  end)

  do_inline_diff(popup_buf, lines)

  vim.api.nvim_create_autocmd({ "WinEnter", "WinLeave", "TabClosed", "CursorMoved" }, {
    group = "hunkAtCurpos",
    callback = close_popup,
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
  for _, line in ipairs(vim.api.nvim_buf_get_lines(0, hunk.buf_start-1, hunk.buf_start-1+hunk.buf_count, false)) do
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

    -- merge small contiguous hunks
    -- this is messy and mostly guesswork
    local merged_hunks = {}
    local cur_hunk = nil
    local previous_hunk = nil
    for _, hunk in ipairs(minidiff_data.hunks) do
      local previous_pos = cur_hunk and previous_hunk.buf_start + previous_hunk.buf_count
      if previous_hunk and previous_hunk.type == "delete" then
        previous_pos = previous_pos + 1
      end
      if previous_pos and previous_pos >= hunk.buf_start then
        -- merge hunks
        if hunk.type ~= cur_hunk.type then
          cur_hunk.type = "change"
        end
        if hunk.type == "delete" and hunk.buf_count == 0 then
          cur_hunk.buf_count = cur_hunk.buf_count + 1
        else
          cur_hunk.buf_count = cur_hunk.buf_count + hunk.buf_count
        end
        if cur_hunk.ref_count == 0 then
          cur_hunk.ref_start = hunk.ref_start
        end
        cur_hunk.ref_count = cur_hunk.ref_count + hunk.ref_count
      else
        if cur_hunk then
          table.insert(merged_hunks, cur_hunk)
        end
        cur_hunk = hunk
      end
      previous_hunk = hunk
    end
    table.insert(merged_hunks, cur_hunk)

    local lines = {}
    local width = 0

    for _, hunk in ipairs(merged_hunks) do
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
