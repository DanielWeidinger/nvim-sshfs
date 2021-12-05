command! -nargs=* SSHFSOpenHosts lua require("sshfs").open_hosts(<f-args>)
command! -nargs=* SSHFSOpenQuickConnect lua require("sshfs").open_quick_connect(<f-args>)
