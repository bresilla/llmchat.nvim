local M = {}

M.view_state = {
  floating = {
    buf = -1,
    win = -1,
  }
}


-- Helper function that normalizes the content.
-- It accepts either a string or a table and returns a flat table of strings,
-- ensuring that no string contains a newline character.
local function normalize_content(content)
  local lines = {}
  if type(content) == "string" then
    -- Split a single string into individual lines.
    lines = vim.split(content, "\n", { plain = true })
  elseif type(content) == "table" then
    -- If content is already a table, iterate through each element.
    for _, item in ipairs(content) do
      if type(item) == "string" then
        -- Split each string if it contains newlines.
        local split_lines = vim.split(item, "\n", { plain = true })
        for _, l in ipairs(split_lines) do
          table.insert(lines, l)
        end
      end
    end
  end
  return lines
end

-- Function to create (or update) a floating window with optional content.
function M.floating_window(opts, content)
  opts = opts or {}
  local width  = opts.width  or math.floor(vim.o.columns * 0.8)
  local height = opts.height or math.floor(vim.o.lines * 0.8)
  local col    = math.floor((vim.o.columns - width) / 2)
  local row    = math.floor((vim.o.lines - height) / 2)
  local buf

  -- Use an existing valid buffer if available.
  if opts.buf and vim.api.nvim_buf_is_valid(opts.buf) then
    buf = opts.buf
  else
    buf = vim.api.nvim_create_buf(false, true)
    -- vim.api.nvim_set_option_value('wrap', true, { buf = buf })
  end

  if content then
    local current_lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
    local current_line_count = #current_lines

    -- If there is already content, add a separator line.
    if current_line_count > 0 then
      local separator = string.rep("-", width)
      vim.api.nvim_buf_set_lines(buf, current_line_count, current_line_count, false, { separator })
      current_line_count = current_line_count + 1
    end

    -- Normalize the content so that each string is a single line.
    local normalized = normalize_content(content)
    vim.api.nvim_buf_set_lines(buf, current_line_count, current_line_count, false, normalized)
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

  -- Key mappings: 'x' clears the buffer, <Esc> hides the window.
  vim.api.nvim_buf_set_keymap(buf, 'n', 'x',
    '<cmd>lua vim.api.nvim_buf_set_lines(0, 0, -1, false, {})<CR>',
    { noremap = true, silent = true }
  )
  vim.api.nvim_buf_set_keymap(buf, 'n', '<Esc>',
    '<cmd>lua vim.api.nvim_win_hide(0)<CR>',
    { noremap = true, silent = true }
  )

  return { buf = buf, win = win }
end

-- Function to toggle the floating view.
-- If content is provided and the window exists, it appends the new content.
-- If no content is provided, it hides the window.
function M.toggle_view(content)
  if content then
    if vim.api.nvim_win_is_valid(M.view_state.floating.win) then
      local buf = M.view_state.floating.buf
      local width = vim.api.nvim_win_get_width(M.view_state.floating.win)
      local current_lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
      local current_line_count = #current_lines

      if current_line_count > 0 then
        local separator = string.rep("-", width)
        vim.api.nvim_buf_set_lines(buf, current_line_count, current_line_count, false, { separator })
        current_line_count = current_line_count + 1
      end

      -- Normalize and insert the new content.
      local normalized = normalize_content(content)
      vim.api.nvim_buf_set_lines(buf, current_line_count, current_line_count, false, normalized)
    else
      M.view_state.floating = M.floating_window({ buf = M.view_state.floating.buf }, content)
    end
  else
    if vim.api.nvim_win_is_valid(M.view_state.floating.win) then
      vim.api.nvim_win_hide(M.view_state.floating.win)
    end
  end
end

vim.api.nvim_create_user_command("Llmchat", function()
    M.toggle_view({"hello wwwworld"})
end, {})
--
return M

