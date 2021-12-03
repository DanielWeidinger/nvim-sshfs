local M = {}

M.parse_config = function(config_lines, connections)
	local hostPattern = "Host%s+([%w%.-_]+)"
	local hostNamePattern = "Host[Nn]ame%s+([%w%.-_]+)"
	local userPattern = "User%s+([%w%.-_]+)"

	local result = {}
	local res_idx = 1

	local i = 0
	local line
	repeat
		i = i + 1
		line = config_lines[i]

		if line:find(hostPattern) then
			local host = line:match(hostPattern)
			local hostname, user

			i = i + 1
			line = config_lines[i]
			while line do
				if line:find(hostPattern) then
					i = i - 1
					break
				elseif line:find(hostNamePattern) then
					hostname = line:match(hostNamePattern)
				elseif line:find(userPattern) then
					user = line:match(userPattern)
				end

				i = i + 1
				line = config_lines[i]
			end

			result[res_idx] = { host = host, hostname = hostname, user = user, connected = connections[host] or false }
			res_idx = res_idx + 1
		end

	until not line

	return result
end

M.parse_connections = function(connection_lines)
	local connection_pattern = "^([%w%.-_]+):/ on .*$"

	local results = {}
	local res_idx = 1

	for _, line in pairs(connection_lines) do
		local matches = line:match(connection_pattern)
		if matches then
			results[matches] = true
		end
	end

	return results
end

M.formatted_lines = function(entries, win)
	-- TODO: baseline hostnames for windows
	local width = vim.api.nvim_win_get_width(win)
	local str_entries = vim.fn.map(entries, function(i, e)
		local base = "[" .. i .. "] " .. e.host .. " --> " .. e.user .. "@" .. e.hostname
		local len = vim.fn.len(base)
		local connected_string = " [" .. (e.connected and "x" or " ") .. "]"
		local appendix = string.format("%-" .. (width - len - 4) .. "s", "")
		return base .. appendix .. connected_string
	end)

	return str_entries
end

M.construct_sshfs_cmd = function(host, mnt_dir, dflt_path, exploration_only)
	dflt_path = dflt_path or "/" --optinal arg
	exploration_only = exploration_only or false
	local allow_other = (not exploration_only and " -o allow_other " or "")
	local password_stdin = " -o password_stdin "
	local ssh_cmd = " -o ssh_command='ssh -o StrictHostKeyChecking=accept-new' "
	-- local cmd = "sudo -S sshfs -o password_stdin "..allow_other..user.."@"..hostname..":"..dflt_path.." "..base_dir
	local cmd = "sshfs " .. host .. ":" .. dflt_path .. " " .. mnt_dir .. allow_other .. password_stdin .. ssh_cmd
	return cmd
end

return M
