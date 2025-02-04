vim.api.nvim_create_user_command("Lau", function()
    require("lau").setup()
end, {})