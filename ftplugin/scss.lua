-- START add virtual text to expand some shorthand css property values into longhand
local bufnr = vim.api.nvim_get_current_buf()
local ns = vim.api.nvim_create_namespace("scss_virtual_text")

local query = vim.treesitter.query.parse("scss", [[
  (declaration
    (property_name) @prop
    (#any-of? @prop "flex" "padding" "box-shadow")) @decl
]])

-- Unitless numbers (e.g. "1") set flex-grow, defaulting flex-shrink to 1 and flex-basis to 0% per W3C spec.
-- Dimensions with units or keywords (e.g. "100px", "auto") set flex-basis instead, with grow and shrink defaulting to 1.
local function is_unitless_number(token)
  return token:match("^%d+%.?%d*$") ~= nil
end

local function expand_property(name, tokens)
  local count = #tokens
  if count == 0 then return "" end

  if name == "flex" then
    local raw_val = table.concat(tokens, " ")
    local grow, shrink, basis

    if raw_val == "initial" then
      grow, shrink, basis = "0", "1", "auto"
    elseif raw_val == "auto" then
      grow, shrink, basis = "1", "1", "auto"
    elseif raw_val == "none" then
      grow, shrink, basis = "0", "0", "auto"
    elseif count == 1 then
      if is_unitless_number(tokens[1]) then
        grow, shrink, basis = tokens[1], "1", "0%"
      else
        grow, shrink, basis = "1", "1", tokens[1]
      end
    elseif count == 2 then
      if is_unitless_number(tokens[2]) then
        grow, shrink, basis = tokens[1], tokens[2], "0%"
      else
        grow, shrink, basis = tokens[1], "1", tokens[2]
      end
    elseif count >= 3 then
      grow, shrink, basis = tokens[1], tokens[2], tokens[3]
    end

    return string.format("grow: %s | shrink: %s | basis: %s", grow or "0", shrink or "1", basis or "auto")

  elseif name == "padding" then
    if count == 1 then
      return string.format("all: %s", tokens[1])
    elseif count == 2 then
      return string.format("y: %s | x: %s", tokens[1], tokens[2])
    elseif count == 3 then
      return string.format("top: %s | x: %s | bot: %s", tokens[1], tokens[2], tokens[3])
    elseif count >= 4 then
      return string.format("top: %s | right: %s | bot: %s | left: %s", tokens[1], tokens[2], tokens[3], tokens[4])
    end

  elseif name == "box-shadow" then
    local val = table.concat(tokens, " ")
    if val == "none" or val == "initial" or val == "inherit" then
      return "shadow: " .. val
    end

    local inset = val:match("%binset%b") and "inset" or "outset"
    local color = val:match("(rgba?%b())") or val:match("(hsla?%b())") or val:match("(var%b())") or val:match("#%x+")

    local lengths = {}
    for _, t in ipairs(tokens) do
      if t ~= "inset" and not t:find("^rgba?") and not t:find("^hsla?") and not t:find("^var") and not t:find("^#") then
        if not t:match("^%a+$") or t == "0" then
          table.insert(lengths, t)
        elseif not color then
          color = t
        end
      end
    end

    return string.format("x: %s | y: %s | blur: %s | spread: %s | color: %s | %s",
      lengths[1] or "0", lengths[2] or "0", lengths[3] or "0", lengths[4] or "0",
      color or "currentcolor", inset
    )
  end

  return table.concat(tokens, " ")
end

local function update_scss_virt_text()
  if not vim.api.nvim_buf_is_valid(bufnr) then return end
  vim.api.nvim_buf_clear_namespace(bufnr, ns, 0, -1)

  local ok, parser = pcall(vim.treesitter.get_parser, bufnr)
  if not ok or not parser then return end

  local syntax_tree = parser:parse()[1]
  if not syntax_tree then return end

  for _, match, _ in query:iter_matches(syntax_tree:root(), bufnr, 0, -1) do
    local prop_node, decl_node

    for id, node in pairs(match) do
      local ts_node = type(node) == "table" and node[1] or node
      local capture_name = query.captures[id]

      if capture_name == "decl" then
        decl_node = ts_node
      elseif capture_name == "prop" then
        prop_node = ts_node
      end
    end

    if decl_node and prop_node then
      local val_tokens = {}

      for i = 0, decl_node:child_count() - 1 do
        local child = decl_node:child(i)
        local type_name = child:type()

        if child:id() ~= prop_node:id() and type_name ~= ":" and type_name ~= ";" and type_name ~= "comment" then
          table.insert(val_tokens, vim.treesitter.get_node_text(child, bufnr))
        end
      end

      if #val_tokens > 0 then
        local prop_name = vim.treesitter.get_node_text(prop_node, bufnr)
        local start_row = decl_node:range()
        local expanded = expand_property(prop_name, val_tokens)

        vim.api.nvim_buf_set_extmark(bufnr, ns, start_row, 0, {
          virt_text = { { "  -- " .. expanded, "Comment" } },
          virt_text_pos = "eol",
        })
      end
    end
  end
end

vim.api.nvim_create_autocmd("BufWritePost", {
  buffer = bufnr,
  callback = update_scss_virt_text,
})

vim.schedule(update_scss_virt_text)
-- END add virtual text to expand some shorthand css property values into longhand
