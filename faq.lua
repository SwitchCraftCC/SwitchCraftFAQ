local utils = require("utils")
local url = utils.formatURL
local command = utils.formatCommand
local text = utils.text

local function rurl(...)
  return { url(...) }
end

local function processNames(names, prefixes, suffixed)
  local gennedNames = {}
  if type(names) == "string" then names = { names } end
  if type(prefixes) == "string" then prefixes = { prefixes } end

  for _, prefix in pairs(prefixes) do
    for _, name in pairs(names) do
      table.insert(gennedNames, prefix .. ":" .. name)
      if suffixed then
        table.insert(gennedNames, name .. ":" .. prefix)
      end
    end
  end

  return gennedNames
end

local function github(url, names)
  return {
    names = processNames(names, { "github", "gh" }, true),
    response = rurl("https://github.com/" .. url, url .. " - GitHub")
  }
end

local function docBase(url, siteName, defaultPrefix, page, pageName, names, prefixes)
  return {
    names = processNames(names, prefixes or defaultPrefix),
    response = rurl(url .. page, pageName .. " - " .. siteName)
  }
end

local function wiki(page, pageName, names, prefixes)
  return docBase("https://wiki.computercraft.cc/", "CC:Tweaked Wiki", { "wiki", "w" }, page, pageName, names, prefixes)
end

local function plethora(page, pageName, names)
  return docBase("https://squiddev-cc.github.io/plethora/", "Plethora", { "plethora", "p" }, page .. ".html", pageName, names)
end

local function addHandler(item, handler)
  -- We use a __call metamethod here, as that allows us to serialise the entry, while
  -- still allowing a somewhat sane API.
  item.handler = setmetatable({}, { __call = function(_, ...) return handler(...) end })
  return item
end

local cct_methods = {}
do
  local response, err = http.get("https://tweaked.cc/index.json")
  if not response then
    printError("Cannot download CC:T documentation:" .. err)
  else
    local methods = json.decode(response.readAll())
    response.close()
    for k, v in pairs(methods) do cct_methods[k:lower()] = v end
  end
end

return {
  -- Chatboxes
  {
    names = { "chatbox:docs", "chatbox", "chatbot", "cb" },
    response = rurl("https://chat.switchcraft.pw/docs", "Chatbox documentation")
  },
  {
    names = { "chatbox:nodejs", "chatbox:node", "chatbox:npm", "chatbox:js" },
    response = rurl("https://www.npmjs.com/package/switchchat", "SwitchChat Node.JS module")
  },

  -- GitHubs
  addHandler(github("SquidDev-CC/CC-Tweaked", { "cctweaked", "cct" }), function(name)
    if not cct_methods[name] then return nil end

    local method = cct_methods[name]
    local response = rurl(method.source, method.name)
    if method.summary then table.insert(response, text(" - " .. method.summary:gsub("%s+", " "))) end
    return { response = response, markdownResponse = utils.toMarkdown(response) }
  end),
  github("SquidDev-CC/Plethora", { "plethora", "p" }),
  github("SquidDev-CC/cloud-catcher", { "cloudcatcher", "cloud-catcher", "cloud" }),
  github("Vexatos/Computronics", "computronics"),
  github("kepler155c/opus", "opus"),
  github("kepler155c/opus-apps", { "opus-apps", "milo" }),
  github("SwitchCraftCC/SwitchCraftROM", { "rom" }),
  github("SwitchCraftCC/SwitchCraftFAQ", { "faq" }),
  github("SwitchCraftCC/SwitchMarket", { "switchmarket", "market" }),
  github("SwitchCraftCC/KristPay", { "kristpay", "kp" }),

  -- Forums
  {
    names = { "forums", "forum" },
    response = rurl("https://forums.computercraft.cc/", "ComputerCraft:Tweaked Forums")
  },

  -- Wiki
  {
    names = { "wiki" },
    response = rurl("https://wiki.computercraft.cc/", "ComputerCraft:Tweaked Wiki")
  },
  {
    names = { "wiki:old" },
    response = rurl("http://www.computercraft.info/wiki", "Old (outdated) ComputerCraft Wiki")
  },
  wiki("Special:RequestAccount", "Request account", "account"),
  wiki("Network_security", "Network security", { "network", "networksecurity", "netsec" }),

  -- Wiki: HTTP API
  {
    names = { "http" },
    response = rurl("https://wiki.computercraft.cc/HTTP_API", "HTTP API - CC:Tweaked Wiki")
  },
  wiki("Http.get", "http.get", "get", "http"),
  wiki("Http.post", "http.post", "post", "http"),
  wiki("Http.websocket", "http.websocket", "websocket", "http"),

  -- Discords
  {
    names = { "discord:switchcraft", "discord:sc", "discord" },
    response = rurl("https://discord.switchcraft.pw")
  },
  {
    names = { "discord:cc", "discord:cct", "discord:hydro", "ccdiscord", "cctdiscord" },
    response = rurl("https://discord.computercraft.cc")
  },

  -- Plethora
  plethora("getting-started", "Getting started", { "docs", "d" }),
  plethora("methods", "Method reference", { "methods", "method", "reference", "m" }),
  plethora("item-transfer", "Moving items", { "items", "item", "transfer", "i" }),
  plethora("items/module-introspection", "Introspection module", "introspection"),
  plethora("items/module-laser", "Frickin' laser beam", { "laser", "l" }),
  plethora("items/module-scanner", "Block scanner", { "blockscanner", "scanner", "scan" }),
  plethora("items/module-sensor", "Entity sensor", { "entitysensor", "entities", "entity", "sensor", "sense" }),
  plethora("items/module-kinetic", "Kinetic augment", { "kineticaugment", "kinetic", "k" }),
  plethora("items/module-chat", "Chat recorder", { "chatrecorder", "chat" }),
  plethora("items/module-glasses", "Overlay glasses", { "overlayglasses", "overlay", "glasses" }),
  plethora("items/redstone-integrator", "Redstone integrator", { "redstoneintegrator", "redstone", "integrator", "red" }),
  plethora("items/keyboard", "Keyboard", { "keyboard", "key" }),
  plethora("examples/laser-drill", "Laser drill", "drill"),
  plethora("examples/laser-sentry", "Laser sentry", "sentry"),
  plethora("examples/auto-feeder", "Auto feeder", "feeder"),

  -- Programs
  {
    names = { "ore3d", "xray" },
    response = rurl("https://forums.computercraft.cc/index.php?topic=5", "Ore3D - true 3D Augmented Reality XRAY Vision")
  },
  {
    names = { "milo" },
    response = rurl("https://forums.computercraft.cc/index.php?topic=87", "Milo - Crafting and Inventory System")
  },
  {
    names = { "opus" },
    response = rurl("http://www.computercraft.info/forums2/index.php?/topic/27810-opus-os/", "Opus OS")
  },
  {
    names = { "opus:pastebin", "opus:installer", "opus:p", "opus:i" },
    response = { utils.formatCopy("pastebin run UzGHLbNC") }
  },

  -- Shops
  {
    names = { "shop:kmarx", "kmarx" },
    response = rurl("https://energetic.pw/computercraft/kmarx/", "kMarx by HydroNitrogen")
  },
  {
    names = { "shop:xenon", "xenon" },
    response = rurl("https://github.com/incinirate/Xenon/wiki", "Xenon by Emma")
  },
  {
    names = { "shop:swshop", "swshop" },
    response = rurl("https://forums.computercraft.cc/index.php?topic=87", "Milo - Crafting and Inventory System")
  },
  {
    names = { "shopcomparison", "shops" },
    response = rurl("https://energetic.pw/switchcraft/shop-comparison", "Shop Program Comparison Table")
  },

  -- Misc
  {
    names = { "cloudcatcher", "cloud" },
    response = rurl("https://cloud-catcher.squiddev.cc/", "Cloud Catcher")
  },
  {
    names = { "rom" },
    response = rurl("https://rom.switchcraft.pw/", "SwitchCraft ROM")
  },
  {
    names = { "rules" },
    response = rurl("https://rules.switchcraft.pw/", "SwitchCraft Rules")
  },
  {
    names = { "dynmap", "map", "d" },
    response = rurl("https://dynmap.switchcraft.pw/", "SwitchCraft Dynmap")
  },
  {
    names = { "switchmarket", "market", "auctions", "auction" },
    response = rurl("https://market.switchcraft.pw/", "SwitchMarket")
  },
  --[[{
    names = { "analytics", "graphs", "charts", "tps" },
    response = rurl("https://analytics.switchcraft.pw/", "SwitchCraft Analytics")
  },]]
  {
    names = { "donate", "supporter", "support" },
    response = rurl("https://donate.switchcraft.pw/", "Donate to SwitchCraft")
  },
  {
    names = { "krist" },
    response = rurl("https://krist.ceriat.net/", "Krist Homepage")
  },
  {
    names = { "kristweb", "krist:web", "krist:wallet", "kristclub", "kristwallet" },
    response = rurl("https://krist.club/", "Krist Web Wallet")
  },
  {
    names = { "kristforge", "kristminer", "krist:miner", "krist:mine" },
    response = rurl("https://github.com/tmpim/kristforge", "Kristforge GPU miner")
  },
  {
    names = { "kristql", "krist:query", "krist:sql" },
    response = rurl("https://query.krist.ceriat.net/", "Krist SQL Query API")
  },
}
