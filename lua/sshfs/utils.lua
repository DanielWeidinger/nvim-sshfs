local function parse_config(config_lines)
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

			-- print,host)
			-- print(hostname)
			-- print(user)
			result[res_idx] = { host = host, hostname = hostname, user = user }
			res_idx = res_idx + 1
		end

	until not line

	return result
end

local function formatted_lines(entries)
	-- TODO: baseline hostnames for windows
	-- TODO: check if field exists
	local str_entries = vim.fn.map(entries, function(i, e)
		return "[" .. i .. "] " .. e["host"] .. " --> " .. e["user"] .. "@" .. e["hostname"]
	end)
	return str_entries
end

local function construct_sshfs_cmd(host, mnt_dir, dflt_path, exploration_only)
	dflt_path = dflt_path or "/" --optinal arg
	exploration_only = exploration_only or false
	local allow_other = (not exploration_only and " -o allow_other " or "")
    local password_stdin = " -o password_stdin "
    local ssh_cmd = " -o ssh_command='ssh -o StrictHostKeyChecking=accept-new' "
	-- local cmd = "sudo -S sshfs -o password_stdin "..allow_other..user.."@"..hostname..":"..dflt_path.." "..base_dir
	local cmd = "sshfs " .. host .. ":" .. dflt_path .. " " .. mnt_dir .. allow_other..password_stdin..ssh_cmd
	return cmd
end

return {
	parse_config = parse_config,
	formatted_lines = formatted_lines,
	construct_sshfs_cmd = construct_sshfs_cmd,
}
