vim.api.nvim_create_user_command("Chat", function()
    require("llmchat").setup()
end, {})
