local M = {}

local function cmd_string(prompt)
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

local function send_to_api(cmd)
  local result = vim.fn.system(cmd)
  vim.wait(1000)
  if vim.v.shell_error ~= 0 then
    print("API call error: " .. result)
    return nil
  end
  return result
end

local function decode_json(result)
  local decoded = vim.fn.json_decode(result)
  if decoded and decoded.choices and decoded.choices[1] and decoded.choices[1].text then
    return decoded.choices[1].text
  else
    print("Unexpected API response")
    return nil
  end
end

function M.send_to_llm(prompt)
  local cmd = cmd_string(prompt)
  local result = send_to_api(cmd)
  if result == nil then
    return
  end
  local table = decode_json(result)
  if table == nil then
    return
  end
  return table
end

return M
