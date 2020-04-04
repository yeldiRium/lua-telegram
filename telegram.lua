local json = require("json")
local internet = require("internet")

local function noop() end

local telegram = {}
local config = {timeout = 300}
local handlers = {text = noop}

local function base_url() return "https://api.telegram.org/bot" .. config.token end

local function make_context(update)
    local chat_id = update.message.chat.id

    local context = {
        update = update,
        reply = function(message)
            internet.request(base_url() .. "/sendMessage",
                             {chat_id = chat_id, text = message})
        end
    }

    return context
end

function telegram.configure(token, timeout)
    config.token = token

    if timeout ~= nil then config.timeout = timeout end
end

function telegram.on_text(handler) handlers.text = handler end

function telegram.handle_update(update)
    local context = make_context(update)

    if update.message ~= nil and update.message.text ~= nil then
        handlers.text(context)
    end
end

function telegram.start_polling()
    if config.token == nil then
        print("You need to configure the bot before starting it.")
        return
    end

    print("Starting to poll...")

    local current_offset = 1

    while true do
        local json_response = ""

        for chunk in internet.request(base_url() .. "/getUpdates", {
            offset = current_offset,
            timeout = config.timeout
        }) do json_response = json_response .. chunk end

        local response = json.decode(json_response)
        local updates = response.result

        for _, update in ipairs(updates) do
            print("Processing update " .. update.update_id .. " from " .. update.message.from.id)
            current_offset = update.update_id + 1
            telegram.handle_update(update)
        end
    end
end

return telegram
