local utils = require("sshfs.utils")
local conn = require("sshfs.connections")
local windows = require("sshfs.window")
local config = require("sshfs.config")

local M = {}

local win, host_count, hosts_map
local top_offset = 4

M.setup = config.setup

M.move_cursor = function(direction)
	local new_pos = math.max(top_offset, vim.api.nvim_win_get_cursor(win)[1] - direction) -- lower bound
	new_pos = math.min(top_offset + host_count - 1, new_pos) -- upper bound
	vim.api.nvim_win_set_cursor(win, { new_pos, 1 })
end

M.close_window = function()
	vim.api.nvim_win_close(win, true)
end

M.open_host = function()
	local row = vim.api.nvim_win_get_cursor(win)[1] + 1
	local idx = row - top_offset
	local host = hosts_map[idx]

	vim.api.nvim_win_close(vim.api.nvim_get_current_win(), false)

	conn.connect_to_host(host)
end

M.open_hosts = function()
	local dims = windows.get_dimensions()
	local legend_content = utils.generate_legend(windows.mappings, dims.win_width)

	local buf, _win = windows.open_window(legend_content, dims)
	win = _win

	local hosts = vim.fn.systemlist(utils.commands.getAllHosts)
	local connections = vim.fn.systemlist(utils.commands.getAllConnections)

	local connections_map = utils.parse_connections(connections)
	hosts_map = utils.parse_config(hosts, connections_map)
	host_count = vim.fn.len(hosts_map)

	local host_content = utils.formatted_lines(hosts_map)

	vim.api.nvim_buf_set_option(buf, "modifiable", false)
	windows.set_header(buf, "Hosts")
	windows.set_content(buf, top_offset, host_content)
	vim.api.nvim_win_set_cursor(win, { top_offset, 1 })
	windows.set_mappings(buf)
end

M.disconnect = function()
	local row = vim.api.nvim_win_get_cursor(win)[1] + 1
	local idx = row - top_offset
	local host = hosts_map[idx]

	if host.connected then
		conn.disconnect_from_host(host)
		M.close_window()
		M.open_hosts()
	else
		print("Host not connected!")
	end
end

M.open_quick_connect = function()
	local mnt_path = vim.fn.input("Mount path:\n")
	print("")
	local connection_str = vim.fn.input("Connection string[<user>@<host>]:\n")
	print("")
	local dflt_path = vim.fn.input("Path in remote host:\n")
	print("")
	local ftp_connection_str = connection_str .. ":" .. dflt_path

	local connections = vim.fn.systemlist(utils.commands.getAllConnections)
	local host = {
		mnt_path = mnt_path,
		host = ftp_connection_str,
		connected = (connections[connection_str] and true or false),
	} -- TODO: alias ssh/config hosts with connection_str

	conn.connect_to_host(host)
end

M.setup()
return M
