print("dfsdsfasdf")
-- get dimensions
local width = vim.api.nvim_get_option("columns")
local height = vim.api.nvim_get_option("lines")

-- calculate our floating window size
local win_height = math.ceil(height * 0.8 - 4)
local win_width = math.ceil(width * 0.8)

-- and its starting position
local row = math.ceil((height - win_height) / 2 - 1)
local col = math.ceil((width - win_width) / 2)

local border_opts = {
  style = "minimal",
  relative = "editor",
  width = win_width + 2,
  height = win_height + 2,
  row = row - 1,
  col = col - 1
}


local border_lines = { '╔' .. string.rep('═', win_width) .. '╗' }
local middle_line = '║' .. string.rep(' ', win_width) .. '║'
for i=1, win_height do
  table.insert(border_lines, middle_line)
end

table.insert(border_lines, '╚' .. string.rep('═', win_width) .. '╝')


local buf, win
local function open_window(entires)
    buf = vim.api.nvim_create_buf(false, true) -- create new emtpy buffer

    vim.api.nvim_buf_set_option(buf, 'bufhidden', 'wipe')

    -- set some options
    local opts = {
    style = "minimal",
    relative = "editor",
    width = win_width,
    height = win_height,
    row = row,
    col = col
    }

    print("test")
    -- set bufer's (border_buf) lines from first line (0) to last (-1)
    -- ignoring out-of-bounds error (false) with lines (border_lines)
    local border_buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_lines(border_buf, 0, -1, false, border_lines)
    local border_win = vim.api.nvim_open_win(border_buf, true, border_opts)
    win = vim.api.nvim_open_win(buf, true, opts)
    vim.api.nvim_command('au BufWipeout <buffer> exe "silent bwipeout! "'..border_buf)
end

return {
    open_window = open_window
}
