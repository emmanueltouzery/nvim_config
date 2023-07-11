require("bufferline").setup({
  options = {
    numbers = function(opts)
      return string.format("%s", opts.id)
    end,
    max_name_length = 20,
    tab_size = 25,
    modified_icon = '',
    diagnostics = "nvim_lsp",
    diagnostics_indicator = function(_, _, diagnostics_dict, _)
      local s = " "
      for e, n in pairs(diagnostics_dict) do
        local sym = e == "error" and "  " or (e == "warning" and "  " or " 󰌶 ")
        s = s .. n .. sym
      end
      return s
    end,
    groups = {
      options = {
        toggle_hidden_on_enter = true, -- when you re-enter a hidden group this options re-opens that group so the buffer is visible
      },
      items = {
        {
          name = "Tests",
          auto_close = true,
          matcher = function(buf)
            return buf.filename:match("%_test") or buf.filename:match("%_spec")
          end,
        },
        {
          name = "Docs",
          auto_close = true,
          matcher = function(buf)
            return buf.filename:match("%.md") or buf.filename:match("%.txt")
          end,
        },
      },
    },
    offsets = {
      {
        filetype = "NvimTree",
        text = "File Explorer",
        text_align = "center",
      },
      {
        filetype = "Outline",
        text = "Symbols",
        text_align = "center",
      },
      {
        filetype = "packer",
        text = "Plugins manager",
        text_align = "center",
      },
    },
    show_buffer_icons = true,
    show_buffer_close_icons = true,
    show_close_icon = false,
    show_tab_indicators = true,
    persist_buffer_sort = true,
    separator_style = "thick",
    enforce_regular_tabs = true,
    always_show_bufferline = false,
    sort_by = "directory",
    custom_areas = {
      right = function()
        local result = {}
        local diagnostics = vim.diagnostic.get(0)
        local count = { 0, 0, 0, 0 }
        for _, diagnostic in ipairs(diagnostics) do
          if vim.startswith(vim.diagnostic.get_namespace(diagnostic.namespace).name, 'vim.lsp') then
            count[diagnostic.severity] = count[diagnostic.severity] + 1
          end
        end
        local error = count[vim.diagnostic.severity.ERROR]
        local warning = count[vim.diagnostic.severity.WARN]
        local info = count[vim.diagnostic.severity.INFO]
        local hint = count[vim.diagnostic.severity.HINT]

        if error ~= 0 then
          result[1] = {
            text = "  " .. error,
            guifg = "#ff6c6b",
          }
        end

        if warning ~= 0 then
          result[2] = {
            text = "  " .. warning,
            guifg = "#ECBE7B",
          }
        end

        if hint ~= 0 then
          result[3] = {
            text = "  " .. hint,
            guifg = "#98be65",
          }
        end

        if info ~= 0 then
          result[4] = {
            text = " 󰌶 " .. info,
            guifg = "#51afef",
          }
        end
        return result
      end,
    },
  },
})

-- vim: ts=2 sts=2 sw=2 et
