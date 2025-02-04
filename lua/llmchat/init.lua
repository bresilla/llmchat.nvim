local Popup = require("nui.popup")
local Input = require("nui.input")
local Layout = require("nui.layout")
local event = require("nui.utils.autocmd").event

-- Store chat history
local chat_history = {}

-- Function to make API call to OpenRouter
local function call_openrouter_api(prompt, callback)
    local api_key = os.getenv("OPENROUTER_API_KEY")

    if not api_key then
        print("Error: OPENROUTER_API_KEY environment variable not set!")
        return nil
    end

    local payload = vim.fn.json_encode({
        model = "openai/gpt-3.5-turbo",
        messages = {
            {
                role = "user",
                content = prompt --.. " ---- output in markdown"
            }
        },
        max_tokens = 1000,
        temperature = 0.7,
    })
    local url = "https://openrouter.ai/api/v1/chat/completions"
    local escaped_payload = vim.fn.shellescape(payload)

    local curl_command = string.format(
        'curl --silent "%s" -H "Content-Type: application/json" -H "Authorization: Bearer %s" -d %s',
        url,
        api_key,
        escaped_payload
    )

    print(curl_command)

    vim.fn.jobstart(curl_command, {
        on_stdout = function(_, data)
            if data[1] ~= "" then
                local success, result = pcall(vim.fn.json_decode, table.concat(data, "\n"))
                if success and result.choices and result.choices[1] and result.choices[1].message then
                    local content = result.choices[1].message.content
                    if content then
                        local lines = vim.split(content, "\n", { plain = true })
                        print(lines)
                        callback(lines)
                    end
                end
            end
        end,
        on_stderr = function(_, data)
            if data and #data > 0 and data[1] ~= "" then
                print("Error:", vim.inspect(data))
            end
        end,
    })
end

local M = {}

function M.setup()
    -- Create input popup
    local input_popup = Popup({
        enter = true,
        border = {
            style = "rounded",
            text = {
                top = " Input ",
                top_align = "left",
            },
        },
        position = "91%",  -- Position at bottom
        size = {
            width = "70%",
            height = "15%",
        },
        highlight = "TelescopeBorder",
        win_options = {
            winhighlight = "Normal:Normal,FloatBorder:TelescopeBorder",
        },
    })

    -- Create response popup
    local response_popup = Popup({
        enter = false,
        border = {
            style = "rounded",
            text = {
                top = " Response ",
                top_align = "left",
            },
        },
        position = "50%",
        size = {
            width = "70%",
            height = "75%",
        },
        win_options = {
            winhighlight = "Normal:Normal,FloatBorder:TelescopeBorder",
        },
    })

    local layout = Layout(
        {
            position = "50%",
            size = {
                width = "80%",  -- Make the entire layout take only 80% of the screen width
                height = "90%",
            },
        },
        Layout.Box({
            Layout.Box(response_popup, { size = "80%" }),
            Layout.Box(input_popup, { size = "20%" }),
        }, { dir = "col", size = "70%" })
    )

    -- Mount all popups
    layout:mount()

    -- Handle input buffer changes
    input_popup:on(event.BufEnter, function()
        vim.cmd("startinsert!")
    end)

    -- Setup keymaps for input window
    input_popup:map("n", "<CR>", function()
        local lines = vim.api.nvim_buf_get_lines(input_popup.bufnr, 0, -1, false)
        local input_text = table.concat(lines, "\n")
        if input_text and input_text ~= "" then
            -- Clear input buffer
            vim.api.nvim_buf_set_lines(input_popup.bufnr, 0, -1, false, {""})
            -- Call API
            call_openrouter_api(input_text, function(response)
                -- Update response window
                vim.api.nvim_buf_set_lines(response_popup.bufnr, 0, -1, false, response)
                -- Add to history
                table.insert(chat_history, {
                    input = input_text,
                    response = table.concat(response, "\n")
                })
            end)
        end
    end, { noremap = true })

    -- Setup keymaps for closing
    local function close_all()
        input_popup:unmount()
        response_popup:unmount()
    end

    input_popup:map("n", "<leader>c", close_all, { noremap = true })
    response_popup:map("n", "<leader>c", close_all, { noremap = true })
end

vim.api.nvim_create_user_command("Chat", function() M.setup() end, {})

return M
