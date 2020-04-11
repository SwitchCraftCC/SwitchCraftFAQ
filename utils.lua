local utils = {}

function utils.text(str, colour, bold, italic, underlined, strikethrough)
  return {
    text = str,
    color = colour,
    bold = bold,
    italic = italic,
    underlined = underlined,
    strikethrough = strikethrough
  }
end

function utils.hoverText(texts)
  return {
    action = "show_text",
    value = {
      "",
      unpack(texts)
    }
  }
end

function utils.playerHead(name, uuid, text)
  if name:find("#") then return "" end
  local owner = uuid and { Id = uuid, Name = name } or name
  return {
    text = "   " .. (text or ""),
    hoverEvent = {
      action = "show_item",
      value = json.encode({
        id = "minecraft:skull",
        Damage = 3,
        Count = 1,
        tag = { SkullOwner = owner }
      })
    }
  }
end

function utils.formatURL(url, text)
  return {
    text = text or url,
    underlined = true,
    color = "blue",
    clickEvent = {
      action = "open_url",
      value = url
    },
    hoverEvent = utils.hoverText({
      utils.text("Click to visit: "),
      utils.text(url, "aqua")
    })
  }
end

function utils.formatCommand(command, suggest, text)
  return {
    text = text or command,
    underlined = true,
    color = "blue",
    clickEvent = {
      action = suggest and "suggest_command" or "run_command",
      value = command
    },
    hoverEvent = utils.hoverText({
      utils.text(suggest and "Click to suggest: " or "Click to run: "),
      utils.text(command, "aqua")
    })
  }
end

function utils.formatCopy(text)
  return {
    text = text,
    color = "gray",
    clickEvent = {
      action = "run_command",
      value = "/~computercraft_copy " .. text
    },
    hoverEvent = utils.hoverText({
      utils.text("Click to copy to clipboard."),
    })
  }
end

function utils.toMarkdown(textObjects)
  local out = ""

  for _, obj in pairs(textObjects) do
    if obj.clickEvent then
      if obj.clickEvent.action == "open_url" then
        if obj.text ~= obj.clickEvent.value then
          out = out .. string.format("[%s](%s)", obj.text, obj.clickEvent.value)
        else
          out = out .. obj.clickEvent.value
        end
      elseif obj.clickEvent.action == "run_command" or obj.clickEvent.action == "suggest_command" then
        out = out .. "`" .. obj.text .. "`"
      else
        out = out .. obj.text
      end
    elseif (obj.colour and obj.colour ~= "white") or obj.bold then
      out = out .. "**" .. obj.text .. "**"
    elseif obj.italic then
      out = out .. "*" .. obj.text .. "*"
    elseif obj.underlined then
      out = out .. "__" .. obj.text .. "__"
    elseif obj.strikethrough then
      out = out .. "~~" .. obj.text .. "~~"
    else
      out = out .. obj.text
    end
  end

  return out
end

return utils