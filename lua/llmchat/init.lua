local Popup = require("nui.popup")
local Input = require("nui.input")
local Layout = require("nui.layout")
local event = require("nui.utils.autocmd").event

-- Store chat history
local chat_history = {}

-- Function to make API call to OpenRouter
local function call_openrouter_api(prompt, callback)
    local api_key = vim.env.OPENROUTER_API_KEY
    -- You need to replace YOUR_API_KEY with your actual OpenRouter API key
    local curl_command = string.format([[
        curl -X POST https://openrouter.ai/api/v1/chat/completions \
        -H "Content-Type: application/json" \
        -H "Authorization: Bearer %s" \
        -d '{
            "model": "openai/gpt-3.5-turbo",
            "messages": [{"role": "user", "content": "%s"}]
        }'
    ]], api_key, prompt)

    vim.fn.jobstart(curl_command, {
        on_stdout = function(_, data)
            if data[1] ~= "" then
                local success, result = pcall(vim.fn.json_decode, table.concat(data, "\n"))
                if success and result.choices and result.choices[1] then
                    callback(result.choices[1].message.content)
                end
            end
        end,
        on_stderr = function(_, data)
            print("Error:", vim.inspect(data))
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
        position = "90%",  -- Position at bottom
        size = {
            width = "70%",
            height = "15%",
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
    })

    -- Create history popup
    local history_popup = Popup({
        enter = false,
        border = {
            style = "rounded",
            text = {
                top = " History ",
                top_align = "left",
            },
        },
        position = "50%",
        size = {
            width = "30%",
            height = "90%",
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
            Layout.Box({
                Layout.Box(response_popup, { size = "80%" }),
                Layout.Box(input_popup, { size = "20%" }),
            }, { dir = "col", size = "70%" }),
            Layout.Box(history_popup, { size = "30%" }),  -- Make history sidebar 30% wide
        }, { dir = "row" })
    )

    -- Mount all popups
    layout:mount()

    -- Setup input handling
    local current_input = ""
    local current_line = 0

    -- Function to update history window
    local function update_history()
        local history_text = table.concat(
            vim.tbl_map(function(item)
                return string.format("User: %s\nAI: %s\n---", item.input, item.response)
            end, chat_history),
            "\n"
        )
        vim.api.nvim_buf_set_lines(history_popup.bufnr, 0, -1, false, vim.split(history_text, "\n"))
    end

    -- Handle input buffer changes
    input_popup:on(event.BufEnter, function()
        vim.cmd("startinsert!")
    end)

    -- Setup keymaps for input window
    input_popup:map("n", "<CR>", function()
        local input_text = vim.api.nvim_buf_get_lines(input_popup.bufnr, 0, -1, false)[1]
        if input_text and input_text ~= "" then
            -- Clear input buffer
            vim.api.nvim_buf_set_lines(input_popup.bufnr, 0, -1, false, {""})
            
            -- Call API
            call_openrouter_api(input_text, function(response)
                -- Update response window
                vim.api.nvim_buf_set_lines(response_popup.bufnr, 0, -1, false, vim.split(response, "\n"))
                
                -- Add to history
                table.insert(chat_history, {
                    input = input_text,
                    response = response
                })
                
                -- Update history window
                update_history()
            end)
        end
    end, { noremap = true })

    -- Setup keymaps for closing
    local function close_all()
        input_popup:unmount()
        response_popup:unmount()
        history_popup:unmount()
    end

    input_popup:map("n", "q", close_all, { noremap = true })
    response_popup:map("n", "q", close_all, { noremap = true })
    history_popup:map("n", "q", close_all, { noremap = true })
end

return M
