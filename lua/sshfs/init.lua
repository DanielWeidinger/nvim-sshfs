local windows = require('sshfs.window')
local win, host_count, hosts_map
local top_offset = 4

local function formatted_lines(entries)
    -- TODO: baseline hostnames
    local str_entries = vim.fn.map(entries, function (i, e)
        return "["..i.."] "..e["hostname"].." --> "..e["text"]
    end)
    return str_entries
end

local function set_mappings(buf)
  local mappings = {
    ['<cr>'] = 'open_host()',
    j = 'move_cursor(-1)',
    h = 'move_cursor(-1)',
    k = 'move_cursor(1)',
    l = 'move_cursor(1)',
    q = 'close_window()',
  }

  for k,v in pairs(mappings) do
    vim.api.nvim_buf_set_keymap(buf, 'n', k, ':lua require"sshfs".'..v..'<cr>', {
        nowait = true, noremap = true, silent = true
      })
  end
end

local function move_cursor(direction)
    local new_pos = math.max(top_offset + host_count, vim.api.nvim_win_get_cursor(win)[1] - direction)
    vim.api.nvim_win_set_cursor(win, {new_pos, 1})
end

local function close_window()
  vim.api.nvim_win_close(win, true)
end

local function open_host()
    local row = vim.api.nvim_win_get_cursor(win)[2]-1
    print(row)
    local idx = row - top_offset
    print(vim.fn.join(hosts_map, "\n"))
    local host = hosts_map[idx]
    print(host)
end

local function set_hosts(buf, hosts)
    vim.api.nvim_buf_set_option(buf, 'modifiable', true)

    vim.api.nvim_buf_set_lines(buf, 0, -1, false, {
        windows.center("Hosts"),
        windows.center("-----"),
        windows.center("")
    })
    vim.api.nvim_buf_set_lines(buf, top_offset, -1, false, formatted_lines(hosts))

    vim.api.nvim_buf_set_option(buf, 'modifiable', false)
end

local function open_hosts()
    local getAllHostCmd = "sed '/^$/d;s/Host //' $HOME/.ssh/config | sed -z 's/\\n\\s* /;/g'"
    local hosts = vim.fn.systemlist(getAllHostCmd)
    hosts_map = vim.fn.map(hosts, function (_, host)
        local entries = vim.fn.split(host, ';')

        local hostname = vim.fn.remove(entries, 0)
        local desc = vim.fn.join(entries, " ")

        return {hostname=hostname, text=desc}
    end)
    host_count = vim.fn.count(hosts_map, '.*')

    local buf, _win = windows.open_window()
    win = _win
    vim.api.nvim_buf_set_option(buf, "modifiable", false)
    set_hosts(buf, hosts_map)
    vim.api.nvim_win_set_cursor(win, {4, 1})
    set_mappings(buf)

    -- vim.fn.setqflist(hosts_map, "r")
    -- vim.fn.execute("copen")
end

return {
    open_hosts = open_hosts,
    close_window = close_window,
    move_cursor = move_cursor,
    open_host = open_host
}
