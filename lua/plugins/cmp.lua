local kind_icons = {
  Text = "   ",
  Method = " 󰆧 ",
  Function = " 󰊕 ",
  Constructor = "  ",
  Field = " 󰙅 ",
  Variable = "  ",
  Class = " 󰌗 ",
  Interface = " 󰜰 ",
  Module = " 󰅩 ",
  Property = " 󰜢 ",
  Unit = "  ",
  Value = " 󰎠 ",
  Enum = " 󰕘",
  Keyword = " 󰌋 ",
  Snippet = "  ",
  Color = " 󰏘 ",
  File = " 󰈔 ",
  Reference = " 󰈝 ",
  Folder = " 󰉋 ",
  EnumMember = "  ",
  Constant = " 󰞂 ",
  Struct = " 󰟦 ",
  Event = "  ",
  Operator = " 󰆕 ",
  TypeParameter = " 󰊄 ",
}
--- Given an LSP item kind, returns a nerdfont icon
--- @param kind_type string LSP item kind
--- @return string Nerdfont Icon
local function get_kind_icon(kind_type)
  return kind_icons[kind_type]
end

-- luasnip setup
local luasnip = require 'luasnip'

-- nvim-cmp setup
local cmp = require 'cmp'
cmp.setup {
  snippet = {
    expand = function(args)
      luasnip.lsp_expand(args.body)
    end,
  },
  mapping = cmp.mapping.preset.insert({
    ['<C-d>'] = cmp.mapping.scroll_docs(-4),
    ['<C-f>'] = cmp.mapping.scroll_docs(4),
    ['<C-Space>'] = cmp.mapping.complete(),
    ['<C-e>'] = cmp.mapping.abort(),
    -- ['<CR>'] = cmp.mapping.confirm {
    --   behavior = cmp.ConfirmBehavior.Replace,
    --   select = true,
    -- },
    ['<CR>'] = cmp.mapping(function(fallback) 
      -- workaround for https://github.com/hrsh7th/cmp-nvim-lsp-signature-help/issues/13
      if cmp.get_selected_entry() ~= nil and cmp.get_selected_entry().source.name == 'nvim_lsp_signature_help' then
        fallback()
      else
        cmp.mapping.confirm {
          behavior = cmp.ConfirmBehavior.Replace,
          select = true,
        }(fallback)
      end
    end),
    -- alt-enter is different from enter by inserting instead of replacing
    -- https://www.reddit.com/r/neovim/comments/r8qcxl/nvimcmp_deletes_the_first_word_after_autocomplete/
    ['<M-CR>'] = cmp.mapping(function(fallback) 
      -- workaround for https://github.com/hrsh7th/cmp-nvim-lsp-signature-help/issues/13
      if cmp.get_selected_entry() ~= nil and cmp.get_selected_entry().source.name == 'nvim_lsp_signature_help' then
        fallback()
      else
        cmp.mapping.confirm {
          behavior = cmp.ConfirmBehavior.Insert,
          select = true,
        }(fallback)
      end
    end),
    ['<Tab>'] = cmp.mapping(function(fallback)
      if cmp.visible() then
        cmp.select_next_item()
      elseif luasnip.expand_or_jumpable() then
        luasnip.expand_or_jump()
      else
        fallback()
      end
    end, { 'i', 's' }),
    ['<S-Tab>'] = cmp.mapping(function(fallback)
      if cmp.visible() then
        cmp.select_prev_item()
      elseif luasnip.jumpable(-1) then
        luasnip.jump(-1)
      else
        fallback()
      end
    end, { 'i', 's' }),
    ['<PageDown>'] = cmp.mapping(function(fallback)
      if cmp.visible() then
        cmp.select_next_item({count=20})
      else
        fallback()
      end
    end, { 'i', 's' }),
    ['<PageUp>'] = cmp.mapping(function(fallback)
      if cmp.visible() then
        cmp.select_prev_item({count=20})
      else
        fallback()
      end
    end, { 'i', 's' }),
  }),
  sources = {
    { name = "nvim_lua" },
    { name = 'nvim_lsp' },
    { name = 'luasnip' },
    { name = "path" },
    {
      name = 'buffer',
      option = {
        -- fetch from all visible windows (not sure about multi-tab)
        -- https://github.com/hrsh7th/cmp-buffer?tab=readme-ov-file#get_bufnrs-type-fun-number
        get_bufnrs = function()
          local bufs = {}
          for _, win in ipairs(vim.api.nvim_list_wins()) do
            bufs[vim.api.nvim_win_get_buf(win)] = true
          end
          return vim.tbl_keys(bufs)
        end,
        -- i think it's needed for non-ascii https://github.com/hrsh7th/cmp-buffer/issues/11
        keyword_pattern = [[\k\+]],
      }
    },
    { name = 'nvim_lsp_signature_help' },
    { name = 'emoji', max_item_count = 3 },
  },
  formatting = {
    format = function(entry, item)
      item.kind = string.format("%s %s", get_kind_icon(item.kind), item.kind)
      item.menu = ({
        nvim_lsp = "󰘦 ",
        luasnip = "",
        buffer = "󰈙",
        nvim_lua = "󰢱",
        path = "",
        ['vim-dadbod-completion'] = "󰆼",
      })[entry.source.name]
      item.dup = ({
        buffer = 1,
        path = 1,
        nvim_lsp = 0,
      })[entry.source.name] or 0
      return item
      end,
    },
    window = {
      documentation = cmp.config.window.bordered(),
    }
}

function _G.dadbod_setup_cmp()
  require('cmp').setup.buffer({ sources = { { name = 'vim-dadbod-completion'}, { name = 'buffer',
  option = {
    -- for dadbod, offer dadbod completions, plus buffer completion for strings
    -- from the dbout buffer, so i can easily filter by string values printed in dbout.
    get_bufnrs = function()
      local bufs = {}
      for _, win in ipairs(vim.api.nvim_list_wins()) do
        local buf = vim.api.nvim_win_get_buf(win)
        local ft = vim.api.nvim_buf_get_option(buf, 'ft')
        if ft == 'dbout' then
          bufs[buf] = true
        end
      end
      return vim.tbl_keys(bufs)
    end,
    -- i think it's needed for non-ascii https://github.com/hrsh7th/cmp-buffer/issues/11
    keyword_pattern = [[\k\+]],
  }
}, } })
end

vim.cmd[[autocmd FileType sql,mysql,plsql lua dadbod_setup_cmp()]]

-- https://github.com/hrsh7th/nvim-cmp/wiki/Menu-Appearance#how-to-add-visual-studio-code-dark-theme-colors-to-the-menu
vim.api.nvim_set_hl(0, 'CmpItemKindInterface', { link='@lsp.type.class' })
vim.api.nvim_set_hl(0, 'CmpItemKindClass', { link='CmpItemKindInterface' })

vim.api.nvim_set_hl(0, 'CmpItemKindVariable', { link='@variable' })

vim.api.nvim_set_hl(0, 'CmpItemKindText', { link='@label' })

vim.api.nvim_set_hl(0, 'CmpItemKindFunction', { link='@lsp.type.function' })
vim.api.nvim_set_hl(0, 'CmpItemKindMethod', { link='CmpItemKindFunction' })

vim.api.nvim_set_hl(0, 'CmpItemKindKeyword', { link='@keyword' })

vim.api.nvim_set_hl(0, 'CmpItemKindProperty', { link='@symbol' })
vim.api.nvim_set_hl(0, 'CmpItemKindUnit', { link='CmpItemKindProperty' })
vim.api.nvim_set_hl(0, 'CmpItemKindField', { link='CmpItemKindProperty' })

-- vim: ts=2 sts=2 sw=2 et
