function _G.my_open_tele()
    local w = vim.fn.expand('<cword>')
    -- require('telescope.builtin').live_grep()
    require("telescope").extensions.live_grep_raw.live_grep_raw()
    vim.fn.feedkeys(w)
end

function _G.copy_to_clipboard(to_copy)
    vim.cmd("let @+ = '" .. to_copy .. "'")
end

function _G.cur_file_path_in_project()
    local full_path = vim.fn.expand("%:p")
    for _, project in pairs(get_project_objects()) do
        if full_path:match("^" .. escape_pattern(project.path)) then
            return full_path:gsub("^" .. escape_pattern(project.path .. "/"), "")
        end
    end
    -- no project that matches, return the relative path
    return vim.fn.expand("%")
end

function _G.get_file_line()
    local file_path = cur_file_path_in_project()
    local line = vim.fn.line(".")
    return "`" .. file_path .. ":" .. line .. "`"
end

function _G.copy_file_line()
    local to_copy = get_file_line()
    vim.cmd("let @+ = '" .. to_copy .. "'")
    print(to_copy)
end

function _G.get_file_line_sel()
    local file_path = cur_file_path_in_project()
    local start_line = vim.fn.getpos("v")[2]
    local end_line = vim.fn.getcurpos()[2]
    -- local start_line = vim.fn.line("'<")
    -- local end_line = vim.fn.line("'>")
    return "`" .. file_path .. ":" .. start_line .. "-" .. end_line .. "`"
end

function _G.copy_file_line_sel()
    local to_copy = get_file_line_sel()
    vim.cmd("let @+ = '" .. to_copy .. "'")
    print(to_copy)
end

function _G.goto_fileline()
    local input = vim.fn.input("Enter file:line please: ")
    vim.cmd("redraw") -- https://stackoverflow.com/a/44892301/516188
    local fname = input:match("[^:]+")
    local line = input:gsub("[^:]+:", "")
    for _, project in pairs(get_project_objects()) do
        if vim.fn.filereadable(project.path .. "/" .. fname) == 1 then
            vim.cmd(":e " .. project.path .. "/" .. fname)
            vim.cmd(":" .. line)
            return
        end
    end
    vim.cmd("echoh WarningMsg | echo \"Can't find file in any project: " .. fname .. "\" | echoh None")
end

function _G.ShowCommitAtLine()
    local commit_sha = require"agitator".git_blame_commit_for_line()
    vim.cmd("DiffviewOpen " .. commit_sha .. "^.." .. commit_sha)
end
