command! -nargs=* SSHFSOpenHosts lua require("sshfs").open_hosts(<f-args>)
