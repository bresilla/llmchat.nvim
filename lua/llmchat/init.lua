-- File: lua/my_telescope_plugin.lua
local M = {}

local select = require("llmchat.select")
local router = require("llmchat.router")
local view = require("llmchat.view")


Llmchat = function()
    local prompt = select.get_visual_selection()
    if prompt == nil then
        return
    end
    local result = router.send_to_llm(prompt)
    if result == nil then
        return
    end
    -- print(result)
    view.view(result)
end


return M
