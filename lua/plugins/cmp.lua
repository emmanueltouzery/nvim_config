local kind_icons = {
  Text = "   ",
  Method = "  ",
  Function = "  ",
  Constructor = "  ",
  Field = " פּ ",
  Variable = "  ",
  Class = "  ",
  Interface = " ﰮ ",
  Module = "  ",
  Property = " ﰠ ",
  Unit = "  ",
  Value = "  ",
  Enum = " 練",
  Keyword = "  ",
  Snippet = "  ",
  Color = "  ",
  File = "  ",
  Reference = "  ",
  Folder = "  ",
  EnumMember = "  ",
  Constant = " ﲀ ",
  Struct = " ﳤ ",
  Event = "  ",
  Operator = "  ",
  TypeParameter = "  ",
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
    ['<CR>'] = cmp.mapping.confirm {
      behavior = cmp.ConfirmBehavior.Replace,
      select = true,
    },
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
  }),
  sources = {
    { name = "nvim_lua" },
    { name = 'nvim_lsp' },
    { name = 'luasnip' },
    { name = "path" },
    { name = "buffer" },
  },
  formatting = {
    format = function(entry, item)
      item.kind = string.format("%s %s", get_kind_icon(item.kind), item.kind)
      item.menu = ({
        nvim_lsp = "[LSP]",
        luasnip = "[Snp]",
        buffer = "[Buf]",
        nvim_lua = "[Lua]",
        path = "[Path]",
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

-- vim: ts=2 sts=2 sw=2 et
