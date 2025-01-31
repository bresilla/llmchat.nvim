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

--- Sends the given prompt to the OpenAI API and returns the result text.
function M.send_to_api(prompt)
  local api_key = os.getenv("OPENAI_API_KEY")
  if not api_key then
    print("Error: OPENAI_API_KEY environment variable not set!")
    return nil
  end

  local payload = vim.fn.json_encode({
    model = "text-davinci-003",
    prompt = prompt,
    max_tokens = 150,
    temperature = 0.7,
  })

  local url = "https://api.openai.com/v1/completions"
  local cmd = string.format(
    "curl -sS %s -H 'Content-Type: application/json' -H 'Authorization: Bearer %s' -d '%s'",
    url,
    api_key,
    payload
  )

  local result = vim.fn.system(cmd)
  if vim.v.shell_error ~= 0 then
    print("API call error: " .. result)
    return nil
  end

  local decoded = vim.fn.json_decode(result)
  if decoded and decoded.choices and decoded.choices[1] and decoded.choices[1].text then
    return decoded.choices[1].text
  else
    print("Unexpected API response")
    return nil
  end
end

--- Main function: grabs the visual selection, sends it to the API,
--- and displays the response in a Telescope picker.
function M.run_api_on_selection()
  local prompt = M.get_visual_selection()
  if not prompt or prompt == "" then
    print("No text selected!")
    return
  end

  local response = M.send_to_api(prompt)
  if not response then
    print("No response from API!")
    return
  end

  pickers.new({}, {
    prompt_title = "API Response",
    finder = finders.new_table {
      results = vim.split(response, "\n"),
    },
    sorter = conf.generic_sorter({}),
  }):find()
end

-- Dummy setup function to satisfy Lazy.nvim.
function M.setup(opts)
  -- You can merge configuration options from opts if needed.
end

return M
