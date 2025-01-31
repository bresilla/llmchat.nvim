if vim.g.loaded_llmchat then
  return
end

require("llmchat").setup()

vim.g.loaded_llmchat = 1
