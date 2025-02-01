local M = {}

local previewers = require("telescope.previewers")

-- Define a custom previewer that displays provided text in a buffer.
local text_previewer = previewers.new_buffer_previewer {
  title = "Standalone Text Previewer",
  -- This function is invoked to populate the preview window.
  define_preview = function(self, entry, status)
    -- Clear any existing content in the preview buffer.
    vim.api.nvim_buf_set_lines(self.state.bufnr, 0, -1, false, {})

    -- Determine what lines to display.
    local lines = {}
    if type(entry.text) == "string" then
      lines = vim.split(entry.text, "\n")
    elseif type(entry.text) == "table" then
      lines = entry.text
    else
      lines = { "No valid text provided" }
    end

    -- Write the text into the preview buffer.
    vim.api.nvim_buf_set_lines(self.state.bufnr, 0, -1, false, lines)
  end,
}

-- Open a floating window and display the provided text using our previewer.
function M.view(text)
  -- Create a scratch buffer.
  local bufnr = vim.api.nvim_create_buf(false, true)

  -- Open a floating window for the buffer.
  vim.api.nvim_open_win(bufnr, true, {
    relative = "editor",
    width = math.floor(vim.o.columns * 0.5),
    height = math.floor(vim.o.lines * 0.5),
    row = math.floor(vim.o.lines * 0.25),
    col = math.floor(vim.o.columns * 0.25),
    style = "minimal",
    border = "rounded",
  })

  -- Set the previewer's state buffer to our newly created buffer.
  text_previewer.state = { bufnr = bufnr }

  -- Create an entry that contains the text.
  local entry = { text = text }

  -- Render the text in the preview window.
  text_previewer:preview(entry, {})
end

-- M.view("Hello, world!")

return M

