local M = {}

-- Keep track of our two windows (and their buffers)
M.view_state = {
  floating = {
    buf = -1,
    win = -1,
  },
  user_input = {
    buf = -1,
    win = -1,
  }
}

local function normalize_content(content)
  local lines = {}
  if type(content) == "string" then
    lines = vim.split(content, "\n", { plain = true })
  elseif type(content) == "table" then
    for _, item in ipairs(content) do
      if type(item) == "string" then
        local split_lines = vim.split(item, "\n", { plain = true })
        for _, l in ipairs(split_lines) do
          table.insert(lines, l)
        end
      end
    end
  end
  return lines
end

function M.floating_window(opts, content)
  opts = opts or {}
  local width  = opts.width  or math.floor(vim.o.columns * 0.8)
  local height = opts.height or math.floor(vim.o.lines * 0.7)
  local col    = opts.col or math.floor((vim.o.columns - width) / 2)
  local row    = opts.row or math.floor((vim.o.lines - height) / 2)
  local buf

  if opts.buf and vim.api.nvim_buf_is_valid(opts.buf) then
    buf = opts.buf
  else
    buf = vim.api.nvim_create_buf(false, true)
  end

  if content then
    local normalized = normalize_content(content)
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, normalized)
  end

  local win_conf = {
    relative = "editor",
    width    = width,
    height   = height,
    col      = col,
    row      = row,
    style    = "minimal",
    border   = "rounded",
  }

  local win = vim.api.nvim_open_win(buf, true, win_conf)

  vim.api.nvim_buf_set_keymap(buf, 'n', 'x',
    '<cmd>lua vim.api.nvim_buf_set_lines(0, 0, -1, false, {})<CR>',
    { noremap = true, silent = true })
  vim.api.nvim_buf_set_keymap(buf, 'n', '<Esc>',
    ':Llmchat<CR>', { noremap = true, silent = true })

  return { buf = buf, win = win }
end

-- This function opens two floating windows at once:
-- - The "main" window (above) shows the given content.
-- - The "user input" window (below) has a fixed height of 2 lines.
-- A gap of 1 line is inserted between them.
function M.open_windows(content)
  -- Total group dimensions (you can adjust these percentages as desired)
  local total_width  = math.floor(vim.o.columns * 0.8)
  local total_height = math.floor(vim.o.lines * 0.7)

  local input_height = 2  -- user input window height (in lines)
  local gap          = 2  -- gap between the two windows
  local main_height  = total_height - (input_height + gap)

  -- Compute the starting (top-left) position so the whole group is centered.
  local group_row = math.floor((vim.o.lines - total_height) / 2)
  local group_col = math.floor((vim.o.columns - total_width) / 2)

  -- Create the main floating window (for content)
  local main_opts = {
    buf   = M.view_state.floating.buf,
    width = total_width,
    height = main_height,
    col   = group_col,
    row   = group_row,
  }
  M.view_state.floating = M.floating_window(main_opts, content)

  -- Create the user input floating window (for user input)
  local input_opts = {
    buf   = M.view_state.user_input.buf,
    width = total_width,
    height = input_height,
    col   = group_col,
    row   = group_row + main_height + gap,  -- place it below the main window plus gap
  }
  -- Initialize with an empty buffer; you can later attach mappings or autocommands to this buffer.
  M.view_state.user_input = M.floating_window(input_opts, "")
end

-- This toggle function checks if either of the two windows is visible.
-- If so, it closes both; otherwise, it opens them.
function M.toggle_view(content)
  local floating_win = M.view_state.floating.win
  local input_win    = M.view_state.user_input.win

  if (floating_win and vim.api.nvim_win_is_valid(floating_win))
      or (input_win and vim.api.nvim_win_is_valid(input_win)) then
    if floating_win and vim.api.nvim_win_is_valid(floating_win) then
      vim.api.nvim_win_close(floating_win, true)
    end
    if input_win and vim.api.nvim_win_is_valid(input_win) then
      vim.api.nvim_win_close(input_win, true)
    end
  else
    M.open_windows(content)
  end
end

-- Create a user command and keymap to toggle the chat view.
vim.api.nvim_create_user_command("Llmchat", function()
  M.toggle_view({"hello wwwworld"})
end, {})

vim.keymap.set("n", "<leader>x", ":Llmchat<CR>", { noremap = true, silent = true })

return M

