function _G.telescope_lsp_completions()
  local params = vim.lsp.util.make_position_params()
  vim.lsp.buf_request(0, 'textDocument/completion', params, function(err, result, ctx, config)
    local pickers = require "telescope.pickers"
    local finders = require "telescope.finders"
    local previewers = require("telescope.previewers")
    local conf = require("telescope.config").values
    local actions = require("telescope.actions")

    local completion_item_kinds = {
      { "  Text", "CmpItemKindText"},
      { "󰆧 Method", "CmpItemKindFunction"},
      { "󰊕 Function", "CmpItemKindFunction"},
      { " Constructor", "CmpItemKindConstructor"},
      { "󰙅 Field", "CmpItemKindField"},
      { " Variable", "CmpItemKindVariable"},
      { "󰌗 Class", "CmpItemKindClass"},
      { "󰜰 Interface", "CmpItemKindInterface"},
      { "󰅩 Module", "CmpItemKindModule"},
      { "󰜢 Property", "CmpItemKindProperty"},
      { " Unit", "CmpItemKindUnit"},
      { "󰎠 Value", "CmpItemKindValue"},
      { "󰕘 Enum", "CmpItemKindEnum"},
      { "󰌋 Keyword", "CmpItemKindKeyword"},
      { " Snippet", "CmpItemKindSnippet"},
      { "󰏘 Color", "CmpItemKindColor"},
      { "󰈔 File", "CmpItemKindFile"},
      { "󰈝 Reference", "CmpItemKindReference"},
      { "󰉋 Folder", "CmpItemKindFolder"},
      { " EnumMember", "CmpItemKindEnumMember"},
      { "󰞂 Constant", "CmpItemKindConstant"},
      { "󰟦 Struct", "CmpItemKindStruct"},
      { " Event", "CmpItemKindEvent"},
      { "󰆕 Operator", "CmpItemKindOperator"},
      { "󰊄 TypeParameter", "CmpItemKindTypeParameter"},
    }

    local make_display = function(entry)
      local kind_hl = completion_item_kinds[entry.value.kind]
      local hl = { { { 0, #kind_hl[1] }, kind_hl[2]} }
      return kind_hl[1] .. " " .. entry.value.label, hl
    end

    local function entry_maker(entry)
      return {
        value = entry,
        ordinal = entry.label,
        display = make_display,
        contents = entry
      }
    end

    pickers.new(opts, {
      prompt_title = "LSP completions",
      finder = finders.new_table {
        results = result.items,
        entry_maker = entry_maker,
      },
      previewer = previewers.new_buffer_previewer({
        -- messy because of the conceal
        setup = function(self)
          vim.schedule(function()
            local winid = self.state.winid
            vim.wo[winid].conceallevel = 2
            vim.wo[winid].concealcursor = "n"
            local augroup = vim.api.nvim_create_augroup('TelescopeApiDocsResumeConceal', { clear = true })
            vim.api.nvim_create_autocmd({"User"}, {
              group = augroup,
              pattern = "TelescopeResumePost",
              callback = function()
                local action_state = require("telescope.actions.state")
                local current_picker = action_state.get_current_picker(vim.api.nvim_get_current_buf())
                if current_picker.prompt_title == "LSP completions" then
                  local winid = current_picker.all_previewers[1].state.winid
                  vim.wo[winid].conceallevel = 2
                  vim.wo[winid].concealcursor = "n"
                end
              end
            })
          end)
          return {}
        end,
        define_preview = function(self, entry, status)
          local lines = {
             (entry.contents.data and entry.contents.data.imports) and "# " .. vim.fn.join(vim.tbl_map(function(imp) return imp.full_import_path end, entry.contents.data.imports), ", ") or "",
             "",
             entry.contents.detail and "`" .. entry.contents.detail .. "`" or "",
           }
          if entry.contents.documentation ~= nil then
            table.insert(lines, "")
            for _, l in ipairs(vim.split(entry.contents.documentation.value, "\n")) do
              table.insert(lines, l)
            end
          end
          vim.api.nvim_buf_set_lines(self.state.bufnr, 0, -1, true, lines)
          vim.bo[self.state.bufnr].filetype = "markdown"
         end
        }),
        sorter = conf.generic_sorter(opts),
        attach_mappings = function(p, map)
          map("i", "<cr>", function(prompt_bufnr)
            local val = require("telescope.actions.state").get_selected_entry(prompt_bufnr).value
            actions.close(prompt_bufnr)
            vim.cmd("norm! a" .. val.textEdit.newText:gsub("%(.*", ""))
            vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes('<esc>A<C-space><Down>',true,false,true),'m',true)
          end)
          return true
        end,
      }):find()
  end)
end
