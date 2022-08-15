local neogit = require('neogit')
local nnoremap = require('keymap').nnoremap

neogit.setup {}

nnoremap(";gs", function()
    neogit.open({})
end);

nnoremap(";ga", "<cmd>!git fetch --all<CR>");
