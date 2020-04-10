local DISCORD_URL = settings.get("faq.discord_webhook")
if not DISCORD_URL then error("Missing Discord webhook!") end

local FAQ = require("faq")
local faq = {}
local utils = require("utils")

local function preprocessFAQ()
  for _, entry in pairs(FAQ) do
    -- first, generate the markdown if needed
    if not entry.markdownResponse then
      entry.markdownResponse = utils.toMarkdown(entry.response)
    end

    -- then index the names
    for _, name in pairs(entry.names) do
      faq[name] = entry
    end
  end
end
preprocessFAQ()

-- write FAQ to file for the website
local f = fs.open(".faq.json", "w")
f.write(json.encode(FAQ))
f.close()

local function sendDiscordMessage(player, entry, text)
  http.request(DISCORD_URL, json.encode({
    ["content"] = string.format(
      "%s**FAQ**/%s:\n%s",
      player and string.format("%s: ", player) or "",
      entry,
      text
    ),
    ["username"] = "SwitchCraft FAQ"
  }), {
    ["Content-Type"] = "application/json"
  })
end

local function sendIngameMessage(player, entry, message)
  local hover = utils.hoverText({
    utils.text("View this FAQ with: "),
    utils.text("!faq " .. entry, "aqua")
  })

  local messageData = {
    "",
    player and utils.playerHead(player) or "",
    utils.text("FAQ", "dark_green", true),
    utils.text("/", "gray"),
    utils.text(entry, entry == "error" and "dark_red" or "green"),
    utils.text(": ")
  }

  -- add the hover event to the message prefix
  for i, obj in pairs(messageData) do
    if type(obj) == "table" and not obj.hoverEvent then -- skip the blank text object and head
      obj.hoverEvent = hover
    end
  end

  -- concat the message to our object
  for _, obj in pairs(message) do
    table.insert(messageData, obj)
  end

  local tellraw = json.encode(messageData)
  local ok, error = commands.tellraw("@a", tellraw)
  if not ok then
    printError(textutils.serialise(error))
  end
end

local function list(player)
  sendIngameMessage(player, "faq:list", {
    utils.text("View the FAQ online: ", "yellow"),
    utils.formatURL("https://faq.switchcraft.pw")
  })
  sendDiscordMessage(player, "faq:list", "View the FAQ online: https://faq.switchcraft.pw")
end

local function displayEntry(player, entry, names)
  local name = (entry.names or names)[1]:lower()
  sendIngameMessage(player, name, entry.response)
  sendDiscordMessage(player, name, entry.markdownResponse)
end

local function entryNotFound(player, entryName)
  sendIngameMessage(player, "error", {
    utils.text("Entry `", "red"),
    utils.text(entryName, "dark_red"),
    utils.text("` not found.", "red")
  })
  sendDiscordMessage(player, "error", string.format("Entry `%s` not found.", entryName))
end

local function usage(player)
  sendIngameMessage(player, "faq:usage", {
    utils.text("Usage: ", "yellow"),
    utils.formatCommand("!faq [entry]", true)
  })
  sendDiscordMessage(player, "faq:usage", "**Usage**: `!faq [entry]`")
end

local function handleMessage(user, message)
  if message == "!faq" or message == "!faq list" or message == "!faq faq:list" then
    return list(user)
  else
    local parts = {}
    for part in message:gmatch("%S+") do
      table.insert(parts, part)
    end

    local original = faq[parts[2]]

    -- If this entry supplies a function, use that instead.
    local entry = original
    if #parts ~= 2 then
      if entry and entry.handler then
        entry = entry.handler(table.unpack(parts, 3))
      else
        return usage(user)
      end
    end

    if entry then
      displayEntry(user, entry, original.names)
    else
      entryNotFound(user, table.concat(parts, " ", 2))
    end
  end
end

local function main()
  print("Ready")
  while true do
    local event, user, message = os.pullEvent()
    if message and type(message) == "string" then
      message = message:lower()
    end

    if (event == "chat" or event == "chat_discord") and message:find("^!faq") then
      handleMessage(user, message)
    end
  end
end

print("Starting bot")
while true do
  local ok, err = pcall(main)
  if err == "Terminated" then error(err, 0) end
  if not ok then printError(err) end
  sleep(5)
end
