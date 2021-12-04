local M = {}

local defaults = {
	mnt_base_dir = vim.fn.expand("$HOME") .. "/Desktop",
	width = 0.6,
	height = 0.5,
}

M.options = {}

M.setup = function(options)
	if not options then
		M.options = defaults
	else
		for key, value in pairs(defaults) do
			M.options[key] = options[key] or value
		end
	end
end

return M
