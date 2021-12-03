local utils = require("sshfs.utils")
local windows = require("sshfs.window")

local win, host_count, hosts_map
local top_offset = 4
local dflt_mnt_basedir = vim.fn.expand("$HOME") .. "/Desktop"

local function move_cursor(direction)
	local new_pos = math.max(top_offset, vim.api.nvim_win_get_cursor(win)[1] - direction) -- lower bound
	new_pos = math.min(top_offset + host_count - 1, new_pos) -- upper bound
	vim.api.nvim_win_set_cursor(win, { new_pos, 1 })
end

local function close_window()
	vim.api.nvim_win_close(win, true)
end

local function open_host()
	local row = vim.api.nvim_win_get_cursor(win)[1] + 1
	local idx = row - top_offset
	local host = hosts_map[idx]
	local mnt_dir = dflt_mnt_basedir .. "/" .. host["host"]
	if vim.fn.isdirectory(mnt_dir) == 0 then
		print(mnt_dir .. " does not exists.")
		local cwd_choice = vim.fn.input("Should " .. mnt_dir .. " be created[Y/n]?\n")
		print("")
		if cwd_choice == "" or cwd_choice == "Y" or cwd_choice == "y" then
			vim.fn.mkdir(mnt_dir, "p")
		else
			return
		end
	end
	local cmd = utils.construct_sshfs_cmd(host["host"], mnt_dir)
	local passwd = vim.fn.input("Password for " .. host["host"] .. ": \n")
	print("")

	local res = vim.fn.system(cmd, passwd)
	if res == "" then
		print(vim.api.nvim_get_current_win())
		vim.api.nvim_win_close(vim.api.nvim_get_current_win(), false)
		print("Successfully connected!")
		local cwd_choice = vim.fn.input("Do you want to switch you cwd[Y/n]?\n")
		print("")
		if cwd_choice == "" or cwd_choice == "Y" or cwd_choice == "y" then
			vim.fn.chdir(mnt_dir)
			if vim.fn.exists("NERDTree") == 1 then
				vim.cmd("NERDTreeCWD")
			end
		end
	else
		print(res)
	end
end

local function open_hosts()
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

return {
	open_hosts = open_hosts,
	close_window = close_window,
	move_cursor = move_cursor,
	open_host = open_host,
}
