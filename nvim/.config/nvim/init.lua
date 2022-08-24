require("base")
require("keymap")
require("set")
require("highlights")
require("maps")
require("macos")
require("plugins")

local has = function(x)
	return vim.fn.has(x) == 1
end
local is_mac = has("macunix")
if is_mac then
	require("macos")
end

-- if has("nvim") and vim.fn.executable("nvr") then
--   -- vim.cmd("let $GIT_EDITOR = 'nvr -cc split --remote-wait +"set bufhidden=wipe''")
-- end
