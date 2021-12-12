local config = require("sshfs.config")

local M = {}

M.commands = {
	getAllHosts = "cat $HOME/.ssh/config",
	getAllConnections = "mount -t fuse.sshfs",
	unmountFolder = function(path)
		return "fusermount -u " .. path
	end,
	mountHost = function(host, mnt_dir, dflt_path, exploration_only)
		dflt_path = dflt_path or "/" --optinal arg
		exploration_only = exploration_only or false
		local allow_other = (not exploration_only and " -o allow_other " or "")
		local password_stdin = " -o password_stdin "
		local ssh_cmd = " -o ssh_command='ssh -o StrictHostKeyChecking=accept-new' "

		-- if type(host) ~= "string" then
		-- 	host = host.user .. "@" .. host.hostname
		-- end
		local cmd = "sshfs " .. host .. ":" .. dflt_path .. " " .. mnt_dir .. allow_other .. password_stdin .. ssh_cmd

		return cmd
	end,
}

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

			local mnt_path = connections[host] or (config.options.mnt_base_dir .. "/" .. host)
			result[res_idx] = {
				host = host,
				hostname = hostname,
				user = user,
				mnt_path = mnt_path,
				connected = (connections[host] and true or false),
			}
			res_idx = res_idx + 1
		end

	until not line

	return result
end

M.parse_connections = function(connection_lines)
	local connection_pattern = "^([%w%.-_]+):/ on .*$"
	local connection_path_pattern = "^[%w%.-_]+:/ on ([/%w%.-_%d]+) type .*$"

	local results = {}

	for _, line in pairs(connection_lines) do
		local matches = line:match(connection_pattern)
		if matches then
			local conn_path = line:match(connection_path_pattern)
			if not conn_path then
				error("Connection detected but no path. Regex is probably faulty")
			end
			results[matches] = conn_path
		end
	end

	return results
end

M.formatted_lines = function(entries, win)
	-- TODO: baseline hostnames for windows
	-- TODO: Add connection indication heading
	local width = vim.api.nvim_win_get_width(win)
	local str_entries = vim.fn.map(entries, function(i, e)
		local base = "[" .. i .. "] " .. e.host .. ": " .. e.user .. "@" .. e.hostname .. " --> " .. e.mnt_path
		local len = vim.fn.len(base)
		local connected_string = " [" .. (e.connected and config.options.connection_icon or " ") .. "]"
		local appendix = string.format("%-" .. (width - len - 4) .. "s", "")
		return base .. appendix .. connected_string
	end)

	return str_entries
end

M.generate_legend = function(mappings, width)
	local fn_name_pattern = "^([%w%.-_]+)%(.+"

	local fn_set = {}
	for key, value in pairs(mappings) do
		local fn_name = value:match(fn_name_pattern)

		if fn_name then
			fn_name = fn_name:gsub("_", " ")
			if fn_set[fn_name] ~= nil then
				fn_set[fn_name] = fn_set[fn_name] .. ", " .. key
			else
				fn_set[fn_name] = key
			end
		end
	end

	local result = {}
	local idx = 1
	local line = ""
	for key, value in pairs(fn_set) do
		local appenix = key .. " -> " .. value
		local new_line_len = string.len(appenix) + string.len(line)
		if new_line_len >= (width - 3) then
			result[idx] = line
			idx = idx + 1
			line = appenix
		else
			line = line .. ((line ~= "") and " | " or "") .. appenix
		end
	end
	result[idx] = line
	result[idx + 1] = ""

	return result
end

M.concat_lines = function(t1, t2)
	local result = {}
	local idx = 0
	local add_fn = function(t)
		for _, value in pairs(t) do
			table.insert(result, value)
			idx = idx + 1
		end
	end

	add_fn(t1)
	add_fn(t2)

	return result
end

return M
