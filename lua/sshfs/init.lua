local windows = require('sshfs.window')

local function open_hosts()
    -- local getAllHostCmd = "grep -P \"^Host ([^*]+)$\" $HOME/.ssh/config | sed 's/Host //'"
    local getAllHostCmd = "sed '/^$/d;s/Host //' $HOME/.ssh/config | sed -z 's/\\n\\s* /;/g'"
    local hosts = vim.fn.systemlist(getAllHostCmd)
    local hosts_map = vim.fn.map(hosts, function (i, host)
        local entries = vim.fn.split(host, ';')

        local hostname = vim.fn.remove(entries, 0)
        local desc = vim.fn.join(entries, " ")

        return {nr=i, filename=hostname, text=desc}
    end)

    print("hello")
    windows.open_window(hosts_map)

    -- vim.fn.setqflist(hosts_map, "r")
    -- vim.fn.execute("copen")
end

return {
    open_hosts = open_hosts
}
