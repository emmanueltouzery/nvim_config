function get_sorted_qf_locations()
  local locations = _G.get_qf_locations({})

  table.sort(locations, function(a,b)
    local a_filename = a.filename or vim.api.nvim_buf_get_name(a.bufnr)
    local b_filename = b.filename or vim.api.nvim_buf_get_name(b.bufnr)
    if a_filename < b_filename then
      return true
    end
    if a_filename > b_filename then
      return false
    end
    -- same file
    return a.lnum < b.lnum
  end)
  return locations
end

function _G.next_quickfix()
  next_quickfix()
end

function next_quickfix()
  local sorted_qf_locations = get_sorted_qf_locations()

  -- find the first record for my filename
  local fname = vim.fn.expand('%:p')
  local lnum = vim.fn.line('.')
  local pick_next_fname = false

  -- if the current file is not one of the quickfix files, pick the first match we find
  local cur_fname_in_list = false
  for i, entry in ipairs(sorted_qf_locations) do
    local cur_fname = entry.filename or vim.api.nvim_buf_get_name(entry.bufnr)
    if cur_fname == fname then
      cur_fname_in_list = true
    end
  end
  if not cur_fname_in_list then
    pick_next_fname = true
  end

  for i, entry in ipairs(sorted_qf_locations) do
    local cur_fname = entry.filename or vim.api.nvim_buf_get_name(entry.bufnr)
    if cur_fname == fname then
      pick_next_fname = true
      if entry.lnum > lnum then
        vim.cmd(':' .. entry.lnum)
        select_current_qf(false)
        return
      end
    elseif pick_next_fname then
      vim.cmd('e ' .. cur_fname)
      vim.cmd(':' .. entry.lnum)
      select_current_qf(false)
      return
    end
  end
  -- no match, wraparound
  if #sorted_qf_locations > 0 then
    local entry = sorted_qf_locations[1]
    local cur_fname = entry.filename or vim.api.nvim_buf_get_name(entry.bufnr)
    vim.cmd('e ' .. cur_fname)
    vim.cmd(':' .. entry.lnum)
    select_current_qf(false)
  end
end

function _G.previous_quickfix()
  previous_quickfix()
end

function previous_quickfix()
  local sorted_qf_locations = get_sorted_qf_locations()

  -- find the first record for my filename
  local fname = vim.fn.expand('%:p')
  local lnum = vim.fn.line('.')
  local pick_next_fname = false

  -- if the current file is not one of the quickfix files, pick the first match we find
  local cur_fname_in_list = false
  for i, entry in ipairs(sorted_qf_locations) do
    local cur_fname = entry.filename or vim.api.nvim_buf_get_name(entry.bufnr)
    if cur_fname == fname then
      cur_fname_in_list = true
    end
  end
  if not cur_fname_in_list then
    pick_next_fname = true
  end

  for i = #sorted_qf_locations, 1, -1 do
    entry = sorted_qf_locations[i]
    local cur_fname = entry.filename or vim.api.nvim_buf_get_name(entry.bufnr)
    if cur_fname == fname then
      pick_next_fname = true
      if entry.lnum < lnum then
        vim.cmd(':' .. entry.lnum)
        select_current_qf(false)
        return
      end
    elseif pick_next_fname then
      vim.cmd('e ' .. cur_fname)
      vim.cmd(':' .. entry.lnum)
        select_current_qf(false)
      return
    end
  end
  -- no match, wraparound
  if #sorted_qf_locations > 0 then
    local entry = sorted_qf_locations[#sorted_qf_locations]
    local cur_fname = entry.filename or vim.api.nvim_buf_get_name(entry.bufnr)
    vim.cmd('e ' .. cur_fname)
    vim.cmd(':' .. entry.lnum)
    select_current_qf(false)
  end
end

function _G.next_closed_fold()
  local cur_line = vim.fn.line('.')
  local line_count = vim.fn.line('$')
  -- first finish the current closed fold if we're in one
  while vim.fn.foldclosed(cur_line) > 0 do
    cur_line = cur_line + 1
    if cur_line >= line_count then
      break
    end
  end
  -- now search for the next closed fold
  for i = cur_line, line_count, 1 do
    if vim.fn.foldclosed(i) > 0 then
      vim.cmd(':' .. i)
      return
    end
  end
end

function _G.previous_closed_fold()
  local cur_line = vim.fn.line('.')
  -- first finish the current closed fold if we're in one
  while vim.fn.foldclosed(cur_line) > 0 do
    cur_line = cur_line - 1
    if cur_line < 1 then
      break
    end
  end
  -- now search for the next closed fold
  local in_closed_fold = false
  for i = cur_line, 1, -1 do
    if vim.fn.foldclosed(i) > 0 then
      in_closed_fold = true
    elseif in_closed_fold then
      -- not in a closed fold anymore, but was in one earlier
      -- => found the top of the closed fold
      vim.cmd(':' .. (i+1))
      return
    end
  end
end
