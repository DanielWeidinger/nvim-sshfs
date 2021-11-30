-- force lua to import the modules again
package.loaded['dev'] = nil
package.loaded['sshfs'] = nil
package.loaded['sshfs.window'] = nil
package.loaded['sshfs.utils'] = nil


-- [ , + r ] keymap to reload the lua file
-- NOTE: someone need to source this file to apply these configurations. So, the
-- very first time you open the project, you have to source this file using
-- ":luafile dev/init.lua". From that point onward, you can hit the keybind to
-- reload
vim.api.nvim_set_keymap('n', ',r', '<cmd>luafile dev/init.lua<cr>', {})
-- vim.api.nvim_set_keymap('n', ',m', '<cmd>lua require("sshfs").open_hosts()<cr>', {})
vim.api.nvim_set_keymap('n', ',m', '<cmd>lua require("sshfs").open_hosts()<cr>', {})
