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
            result[res_idx] = {host=host, hostname=hostname, user=user}
            res_idx  = res_idx + 1
        end

    until not line

    return result
end

local function formatted_lines(entries)
    -- TODO: baseline hostnames
    -- TODO: check if field exists
    print(vim.fn.join(entries, "\n"))
    local str_entries = vim.fn.map(entries, function (i, e)
        return "["..i.."] "..e["host"].." --> "..e["user"].."@"..e["hostname"]
    end)
    return str_entries
end


return {
    parse_config=parse_config,
    formatted_lines = formatted_lines
}
