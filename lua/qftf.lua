local fn = vim.fn

-- https://github.com/kevinhwang91/nvim-bqf#customize-quickfix-window-easter-egg
function _G.qftf(info)
  local type_mapping = {
    E = "",
    W = "",
    I = "",
    H = "",
  };
  local items
  local ret = {}
  if info.quickfix == 1 then
    items = fn.getqflist({id = info.id, items = 0}).items
  else
    items = fn.getloclist(info.winid, {id = info.id, items = 0}).items
  end
  for i = info.start_idx, info.end_idx do
    local e = items[i]
    local fname = ''
    local str
    if e.valid == 1 then
      if e.bufnr > 0 then
        fname = fn.bufname(e.bufnr)
        if fname == '' then
          fname = '[No Name]'
        else
          fname = fname:gsub('^' .. vim.env.HOME, '~')
        end
      end
      local lnum = e.lnum > 99999 and -1 or e.lnum
      -- local col = e.col > 999 and -1 or e.col
      local qtype = e.type == '' and '' or ' ' .. type_mapping[e.type:sub(1, 1):upper()]
      if lnum > 0 then
        str = string.format('%s  %s:%d %s', qtype, fname, lnum, e.text:gsub('^%s+', ''))
      elseif #fname > 0 then
        str = string.format('%s  %s %s', qtype, fname, e.text:gsub('^%s+', ''))
      else
        str = string.format('%s %s', qtype, e.text:gsub('^%s+', ''))
      end
    else
      str = e.text
    end
    if str == '' then
      str = ' ' -- avoid the ugly default of '||'
    elseif str:find('\n') then
      str = str:gsub('\n%s*', ' ')
    end
    table.insert(ret, str)
  end
  return ret
end
-- see http://ftp.vim.org/pub/vim/runtime/syntax/qf.vim
-- reset it to clear the quickfix display after our changes
-- syn match qfFileName "\<[a-zA-Z\._/]\+:\d\+\>"
-- vim.cmd[[hi def link qfFileName NONE]]

vim.o.qftf = '{info -> v:lua._G.qftf(info)}'
