-- File: lua/my_telescope_plugin.lua
local M = {}


local pickers = require("telescope.pickers")
local finders = require("telescope.finders")
local conf = require("telescope.config").values

local select = require("llmchat.select")
local router = require("llmchat.router")


Llmchat = function()
    local prompt = select.get_visual_selection()
    if prompt == nil then
        return
    end
    local result = router.send_to_llm(prompt)
    if result == nil then
        return
    end
    print(result)
end


return M
