local utils = require("sshfs.utils")

local M = {}

M.connect_to_host = function(host)
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

		local passwd = vim.fn.input("Password for " .. host["host"] .. "(<cr> for ssh-key auth): \n")
		local cmdParams = { host = (host["host"] or host), mnt_dir = host.mnt_path }
		if passwd == "" then
			cmdParams.key_auth = true
		end
		local cmd = utils.commands.mountHost(cmdParams)
		print("")

		local res = vim.fn.system(cmd, passwd)
		if res ~= "" then
			print(res)
			return
		end
	end

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

M.disconnect_from_host = function(host)
	local cmd = utils.commands.unmountFolder(host.mnt_path)
	local result = vim.fn.system(cmd)
	print(result)
end

return M
