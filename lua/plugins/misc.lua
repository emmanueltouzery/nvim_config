vim.cmd("let g:choosewin_label = '1234567890'")
vim.cmd("let g:choosewin_tablabel = 'abcdefghijklmnop'")

local tree_cb = require("nvim-tree.config").nvim_tree_callback
require'nvim-tree'.setup {
    diagnostics = {
	enable = true,
    },
    update_cwd = true,
    update_focused_file = {
	-- enables the feature
	enable = true,
	-- update the root directory of the tree to the one of the folder containing the file if the file is not under the current root directory
	-- only relevant when `update_focused_file.enable` is true
	update_cwd = true,
	-- list of buffer names / filetypes that will not update the cwd if the file isn't found under the current root directory
	-- only relevant when `update_focused_file.update_cwd` is true and `update_focused_file.enable` is true
	ignore_list = {},
    },
    view = {
	mappings = {
	    -- custom only false will merge the list with the default mappings
	    -- if true, it will only use your list to set the mappings
	    custom_only = true, -- MY CHANGE
	    list = {
		-- default mappings
		{ key = {"<CR>", "o", "<2-LeftMouse>"}, action = "edit" },
		{ key = "<C-e>",                        action = "edit_in_place" },
		{ key = {"O"},                          action = "edit_no_picker" },
		{ key = {"<2-RightMouse>", "<C-]>"},    action = "cd" },
		{ key = "<C-v>",                        action = "vsplit" },
		{ key = "<C-x>",                        action = "split" },
		{ key = "<C-t>",                        action = "tabnew" },
		{ key = "<",                            action = "prev_sibling" },
		{ key = ">",                            action = "next_sibling" },
		{ key = "P",                            action = "parent_node" },
		{ key = "<BS>",                         action = "close_node" },
		{ key = "<Tab>",                        action = "preview" },
		{ key = "K",                            action = "first_sibling" },
		{ key = "J",                            action = "last_sibling" },
		{ key = "I",                            action = "toggle_git_ignored" },
		{ key = "H",                            action = "toggle_dotfiles" },
		{ key = "R",                            action = "refresh" },
		{ key = "a",                            action = "create" },
		{ key = "d",                            action = "remove" },
		{ key = "D",                            action = "trash" },
		{ key = "r",                            action = "rename" },
		{ key = "<C-r>",                        action = "full_rename" },
		{ key = "x",                            action = "cut" },
		{ key = "c",                            action = "copy" },
		{ key = "p",                            action = "paste" },
		{ key = "y",                            action = "copy_name" },
		{ key = "Y",                            action = "copy_path" },
		{ key = "gy",                           action = "copy_absolute_path" },
		{ key = "[c",                           action = "prev_git_item" },
		{ key = "]c",                           action = "next_git_item" },
		{ key = "U", cb = tree_cb("dir_up") }, -- my change
		-- { key = "-",                            action = "dir_up" },
		{ key = "s",                            action = "system_open" },
		{ key = "f",                            action = "live_filter" },
		{ key = "F",                            action = "clear_live_filter" },
		{ key = "q",                            action = "close" },
		{ key = "g?",                           action = "toggle_help" },
		{ key = "W",                            action = "collapse_all" },
		{ key = "S",                            action = "search_node" },
		{ key = "<C-k>",                        action = "toggle_file_info" },
		{ key = ".",                            action = "run_file_command" }
	    }
	}
    },
    actions = {
	open_file = {
	    window_picker = {
		chars = '234567890ABCDEFGHIJKLMNOPQRSTUVWXYZ',
	    }
	}
    },
}

vim.g.glow_width = 120
vim.g.glow_border = "rounded"

require("todo-comments").setup {
    highlight = {
        pattern = {[[\s*\/\/.*<(KEYWORDS)\s*]], [[\s*--.*<(KEYWORDS)\s*]], [[\s*#.*<(KEYWORDS)\s*]]},
    }
}

-- vim: ts=4 sts=4 sw=4 et
