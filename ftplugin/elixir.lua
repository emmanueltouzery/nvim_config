
require 'key-menu'.set('n', '<localleader>i', {desc='Inspect...', buffer = true})
vim.keymap.set('n', '<localleader>iv', ":lua elixir_insert_inspect_value()<cr>", {desc="elixir add inspect value", buffer = true})
vim.keymap.set('n', '<localleader>ip', ":lua elixir_insert_inspect_param()<cr>", {desc="elixir add inspect parameter", buffer = true})
vim.keymap.set('n', '<localleader>il', ":lua elixir_insert_inspect_label()<cr>", {desc="elixir add inspect label", buffer = true})
vim.keymap.set('n', '<localleader>if', ":lua elixir_insert_inspect_field()<cr>", {desc="elixir add inspect field", buffer = true})
require 'key-menu'.set('n', '<localleader>a', {desc='API', buffer = true})
vim.keymap.set('n', '<localleader>ac', ":lua require'elixir-extras'.elixir_view_docs({})<cr>", {desc="elixir apidocs (core only)", buffer = true})
vim.keymap.set('n', '<localleader>aa', ":lua require'elixir-extras'.elixir_view_docs({include_mix_libs=true})<cr>", {desc="elixir apidocs (all)", buffer = true})
require 'key-menu'.set('n', '<localleader>o', {desc='Open...', buffer = true})
vim.keymap.set('n', '<localleader>os', ":lua telescope_elixir_stacktrace({})<cr>", {desc="elixir open stacktrace", buffer = true})
require 'key-menu'.set('n', '<localleader>m', {desc='module...', buffer = true})
vim.keymap.set('n', '<localleader>mc', ":lua require'elixir-extras'.module_complete()<cr>", {desc="elixir module complete", buffer = true})

require 'key-menu'.set('n', '<localleader>n', {desc='iNdent', buffer = true})
vim.keymap.set('n', '<localleader>nm', ":lua elixir_match_error_details_indent({})<cr>", {desc="elixir indent match error details", buffer = true})
vim.keymap.set('n', '<localleader>nv', ":lua elixir_indent_output_val()<cr>", {desc="elixir indent output value", buffer = true})

local function elixir_add_stack_to_qf()
  local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
  vim.fn.setqflist({}, 'r')
  for _, line in ipairs(lines) do
    local match = vim.fn.matchlist(line, [[\v<((\w|_|/)+\.ex):(\d+)]])
    if #match > 0 then
      vim.fn.setqflist({}, 'a', {
        items = {
          {
            filename = match[2],
            lnum = match[4],
            col = 1,
            text = match[2] .. ":" .. match[4],
          },
        },
      })
    end
  end
  telescope_quickfix_locations{}
end

vim.keymap.set('n', '<localleader>cqa', elixir_add_stack_to_qf, {desc = "add stacktrace to quickfix", buffer = true})
