local config = require("sshfs.config")

local M = {}
-- credit goes out to: https://www.2n.pl/blog/how-to-write-neovim-plugins-in-lua

M.center = function(str, win)
	win = win or 0
	local width = vim.api.nvim_win_get_width(win)
	local shift = math.floor(width / 2) - math.floor(string.len(str) / 2)
	return string.rep(" ", shift) .. str
end

M.set_header = function(buf, header)
	vim.api.nvim_buf_set_option(buf, "modifiable", true)

	local underline = ""
	for _ = 1, vim.fn.len(header) do
		underline = "-" .. underline
	end
	vim.api.nvim_buf_set_lines(buf, 0, -1, false, {
		M.center(header),
		M.center(underline),
		M.center(""),
	})

	vim.api.nvim_buf_set_option(buf, "modifiable", false)
end

M.set_content = function(buf, top_offset, content)
	vim.api.nvim_buf_set_option(buf, "modifiable", true)
	vim.api.nvim_buf_set_lines(buf, top_offset, -1, false, content)
	vim.api.nvim_buf_set_option(buf, "modifiable", false)
end

local open_legend_window = function(legend_content, win_width, win_height, row, col)
	local legend_len = vim.fn.len(legend_content)
	local opts = {
		style = "minimal",
		relative = "editor",
		width = win_width,
		height = legend_len,
		row = row + (win_height - legend_len),
		col = col,
	}

	local border_lines = { string.rep("-", win_width) }
	local legend_buf = vim.api.nvim_create_buf(false, true)
	vim.api.nvim_buf_set_lines(legend_buf, 0, -1, false, border_lines)
	vim.api.nvim_buf_set_lines(legend_buf, 1, -1, false, legend_content)
	local legend_win = vim.api.nvim_open_win(legend_buf, true, opts)

	return legend_buf, legend_win
end

local open_border_window = function(win_width, win_height, row, col)
	local border_opts = {
		style = "minimal",
		relative = "editor",
		width = win_width + 2,
		height = win_height + 2,
		row = row - 1,
		col = col - 1,
	}

	local border_lines = { "╔" .. string.rep("═", win_width) .. "╗" }
	local middle_line = "║" .. string.rep(" ", win_width) .. "║"
	for i = 1, win_height do
		table.insert(border_lines, middle_line)
	end
	table.insert(border_lines, "╚" .. string.rep("═", win_width) .. "╝")

	-- set bufer's (border_buf) lines from first line (0) to last (-1)
	-- ignoring out-of-bounds error (false) with lines (border_lines)
	local border_buf = vim.api.nvim_create_buf(false, true)
	vim.api.nvim_buf_set_lines(border_buf, 0, -1, false, border_lines)
	local border_win = vim.api.nvim_open_win(border_buf, true, border_opts)
	return border_buf, border_win
end

M.get_dimensions = function()
	-- get dimensions
	local width = vim.api.nvim_get_option("columns")
	local height = vim.api.nvim_get_option("lines")

	-- calculate our floating window size
	local win_height = math.ceil(height * config.options.height - 4)
	local win_width = math.ceil(width * config.options.width)

	return { width = width, height = height, win_height = win_height, win_width = win_width }
end
-- TODO: add keybinding legend
-- TODO: Add colorscheme
M.open_window = function(legend_content, dims)
	-- and its starting position
	local row = math.ceil((dims.height - dims.win_height) / 2 - 1)
	local col = math.ceil((dims.width - dims.win_width) / 2)

	local buf = vim.api.nvim_create_buf(false, true) -- create new emtpy buffer
	vim.api.nvim_buf_set_option(buf, "bufhidden", "wipe")

	local opts = {
		style = "minimal",
		relative = "editor",
		width = dims.win_width,
		height = dims.win_height - vim.fn.len(legend_content),
		row = row,
		col = col,
	}
	local legend_buf, _ = open_legend_window(legend_content, dims.win_width, dims.win_height, row, col)
	local border_buf, _ = open_border_window(dims.win_width, dims.win_height, row, col)
	local win = vim.api.nvim_open_win(buf, true, opts)
	vim.api.nvim_command('au BufWipeout <buffer> exe "silent bwipeout! "' .. border_buf)
	vim.api.nvim_command('au BufWipeout <buffer> exe "silent bwipeout! "' .. legend_buf)

	return buf, win
end

M.mappings = {
	["<cr>"] = "open_host()",
	j = "move_cursor(-1)",
	h = "move_cursor(-1)",
	k = "move_cursor(1)",
	l = "move_cursor(1)",
	q = "close_window()",
	d = "disconnect()",
}
M.set_mappings = function(buf)
	for k, v in pairs(M.mappings) do
		vim.api.nvim_buf_set_keymap(buf, "n", k, ':lua require"sshfs".' .. v .. "<cr>", {
			nowait = true,
			noremap = true,
			silent = true,
		})
	end
end

return M
