-- File: lua/my_telescope_plugin.lua
local M = {}

local pickers = require("telescope.pickers")
local finders = require("telescope.finders")
local conf = require("telescope.config").values

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


function M.cmd_string(prompt)
  local api_key = os.getenv("OPENROUTER_API_KEY")
  if not api_key then
    print("Error: OPENROUTER_API_KEY environment variable not set!")
    return nil
  end
  local payload = vim.fn.json_encode({
    model = "openai/gpt-3.5-turbo",
    prompt = prompt,
    max_tokens = 150,
    temperature = 0.7,
  })
  local url = "https://openrouter.ai/api/v1/chat/completions"
  local escaped_payload = vim.fn.shellescape(payload)
  local cmd = string.format(
    'curl --silent "%s" -H "Content-Type: application/json" -H "Authorization: Bearer %s" -d %s | awk "NF {p=1} p"',
    url,
    api_key,
    escaped_payload
  )
  return cmd
end

function M.send_to_api(cmd)
  local result = vim.fn.system(cmd)
  vim.wait(1000)
  if vim.v.shell_error ~= 0 then
    print("API call error: " .. result)
    return nil
  end
  return result
end

function M.decode_json(result)
  local decoded = vim.fn.json_decode(result)
  if decoded and decoded.choices and decoded.choices[1] and decoded.choices[1].text then
    return decoded.choices[1].text
  else
    print("Unexpected API response")
    return nil
  end
end

Llmchat = function()
    local prompt = M.get_visual_selection()
    if prompt == nil then
        return
    end
    local cmd = M.cmd_string(prompt)
    local result = M.send_to_api(cmd)
    if result == nil then
        return
    end
    local table = M.decode_json(result)
    if table == nil then
        return
    end
    print(table)
end


return M
