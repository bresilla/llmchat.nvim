local M = {}

--- Retrieves the text from the current visual selection.
function M.get_visual_selection()
  local start_pos = vim.fn.getpos("'<")
  local end_pos = vim.fn.getpos("'>")
  if not (start_pos and end_pos) then
    print("Visual selection not found!")
    return nil
  end

  local lines = vim.fn.getline(start_pos[2], end_pos[2])
  if type(lines) == "string" then
    lines = { lines }
  end

  if #lines == 0 then
    return ""
  end

  lines[1] = string.sub(lines[1], start_pos[3])
  lines[#lines] = string.sub(lines[#lines], 1, end_pos[3])
  return table.concat(lines, "\n")
end

return M
