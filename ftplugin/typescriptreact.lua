-- https://www.reddit.com/r/neovim/comments/ykpnob/comment/iuy3lea/
vim.cmd.runtime({"ftplugin/typescript.lua",  bang = true })

-- Set specific surrounding in 'mini.surround'
local ts_input = require('mini.surround').gen_spec.input.treesitter
vim.b.minisurround_config = {
  custom_surroundings = {
    t = {
      input = ts_input({ outer = '@tag.outer', inner = '@tag.inner' }),
    },
    T = {
      input = ts_input({ outer = '@tag_name.outer', inner = '@tag_name.inner' }),
      output = function()
        local tag_name = MiniSurround.user_input('Tag name')
        return { left = tag_name, right = tag_name }
      end,
    },
  },
}
