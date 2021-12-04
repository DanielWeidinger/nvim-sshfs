local utils = require("sshfs.utils")
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

	if not host.connected then
		if vim.fn.isdirectory(host.mnt_path) == 0 then
			print(host.mnt_path .. " does not exists.")
			local cwd_choice = vim.fn.input("Should " .. host.mnt_path .. " be created[Y/n]?\n")
			print("")
			if cwd_choice == "" or cwd_choice == "Y" or cwd_choice == "y" then
				vim.fn.mkdir(host.mnt_path, "p")
			else
				return
			end
		end
		local cmd = utils.construct_sshfs_cmd(host["host"], host.mnt_path)
		local passwd = vim.fn.input("Password for " .. host["host"] .. ": \n")
		print("")

		local res = vim.fn.system(cmd, passwd)
		if res ~= "" then
			print(res)
			return
		end
	end

	vim.api.nvim_win_close(vim.api.nvim_get_current_win(), false)
	print("Successfully " .. (host.connected and "re" or "") .. "connected!")
	local cwd_choice = vim.fn.input("Do you want to switch you cwd[Y/n]?\n")
	print("")
	if cwd_choice == "" or cwd_choice == "Y" or cwd_choice == "y" then
		vim.fn.chdir(host.mnt_path)
		if vim.fn.exists("NERDTree") == 1 then
			vim.cmd("NERDTreeCWD")
		end
	end
end

M.open_hosts = function()
	local getAllHostCmd = "cat $HOME/.ssh/config"
	local hosts = vim.fn.systemlist(getAllHostCmd)
	local getAllConnectionsCmd = "mount -t fuse.sshfs"
	local connections = vim.fn.systemlist(getAllConnectionsCmd)

	local connections_map = utils.parse_connections(connections)
	hosts_map = utils.parse_config(hosts, connections_map)
	host_count = vim.fn.len(hosts_map)

	local buf, _win = windows.open_window()
	win = _win
	vim.api.nvim_buf_set_option(buf, "modifiable", false)
	windows.set_header(buf, "Hosts")
	windows.set_content(buf, top_offset, utils.formatted_lines(hosts_map))
	vim.api.nvim_win_set_cursor(win, { 4, 1 })
	windows.set_mappings(buf)
end

M.setup({ mnt_base_dir = (vim.fn.expand("$HOME") .. "/mnt") })
return M
