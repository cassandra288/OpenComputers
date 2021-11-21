local gpu = require("component").gpu
local os = require("os")
local event = require("event")

data = {
  {
    ["type"] = "title",
    ["text"] = "Libs"
  },
  {
    ["type"] = "lib",
    ["text"] = "OpenTGL",
    ["base_url"] = "https://raw.githubusercontent.com/Thomas2889/OpenComputers/master/Libs/OpenTGL/",
    ["files"] = {
      "OpenTGL.lua"
    }
  },
  {
    ["type"] = "lib",
    ["text"] = "ButtonLib",
    ["base_url"] = "https://raw.githubusercontent.com/Thomas2889/OpenComputers/master/Libs/ButtonLib/",
    ["files"] = {
      "ButtonLib.lua"
    }
  },
  {
    ["type"] = "lib",
    ["text"] = "ProgramCore",
    ["base_url"] = "https://raw.githubusercontent.com/Thomas2889/OpenComputers/master/Libs/ProgramCore/",
    ["files"] = {
      "ProgramCore.lua"
    }
  },
  {
    ["type"] = "title",
    ["text"] = ""
  },
  {
    ["type"] = "finish"
  }
}


local running = true
local base_index = 1


local function DrawTitle(h, entry)
  gpu.set(1, h, entry.text)
end

local function DrawLib(h, entry)
  gpu.set(1, h, "[ ] "..entry.text)
  if entry.selected then
    gpu.setForeground(0x00ff00)
    gpu.set(2, h, "X")
    gpu.setForeground(0xffffff)
  end
end

local function DrawFinish(h, entry)
  gpu.set(1, h, "[-] Select to Continue")
end

local function UpdateLib(i)
  entry = data[i]
  if entry.selected then
    gpu.setForeground(0x00ff00)
    gpu.set(2, i, "X")
    gpu.setForeground(0xffffff)
  else
    gpu.set(2, i, " ")
  end
end

local function ClearCursor(i)
  entry = data[i]
  if entry.type == "lib" then
    UpdateLib(i)
  elseif entry.type == "finish" then
    gpu.set(2, i, "-")
  end
end

local function DrawCursor(i)
  entry = data[i]
  gpu.setBackground(0xbbbb00)
  if entry.type == "lib" then
    UpdateLib(i)
  elseif entry.type == "finish" then
    gpu.set(2, i, "-")
  end
  gpu.setBackground(0x000000)
end

local function Select(i)
  entry = data[i]
  if entry.type == "finish" then
    running = false
    DrawCursor(i)
  else
    entry.selected = not entry.selected
    DrawCursor(i)
  end
end


local cursor_index = 2
local width, height = gpu.getResolution()

gpu.fill(1, 1, width, height, " ")

for i=base_index, math.min(height, #data) do
  entry = data[i]
  if entry.type == "title" then
    DrawTitle(i, entry)
  elseif entry.type == "lib" then
    DrawLib(i, entry, i % 2 == 0)
  elseif entry.type == "finish" then
    DrawFinish(i, entry)
  end
end
DrawCursor(cursor_index)


local function OnKeyDown(_, _, _, key)
  if key == 28 then
    Select(cursor_index)
  elseif key == 200 then
    next_index = nil
    for i = cursor_index - 1, 1, -1 do
      local type = data[i].type
      if type == "lib" or type == "finish" then
        next_index = i
        break
      end
    end
    
    if next_index then
      ClearCursor(cursor_index)
      cursor_index = next_index
      DrawCursor(cursor_index)
    end
  elseif key == 208 then
    next_index = nil
    for i = cursor_index + 1, #data do
      local type = data[i].type
      if type == "lib" or type == "finish" then
        next_index = i
        break
      end
    end
    
    if next_index then
      ClearCursor(cursor_index)
      cursor_index = next_index
      DrawCursor(cursor_index)
    end
  end
end
event.listen("key_down", OnKeyDown)

local function OnTouch(_, _, x, y, button)
  if button == 0 then
    local type = data[y].type
    if type == "lib" or type == "finish" then
      ClearCursor(cursor_index)
      cursor_index = y
      Select(cursor_index)
    end
  end
end
event.listen("touch", OnTouch)


while running do
  os.sleep(0.05)
end


event.ignore("key_down", OnKeyDown)
event.ignore("touch", OnTouch)

require("term").setCursor(1, 1)
gpu.fill(1, 1, width, height, " ")

for i = 1, #data do
  entry = data[i]
  if entry.base_url then
    gpu.setForeground(0xff0000)
    print("Installing "..entry.text)
    gpu.setForeground(0xffffff)
    for j = 1, #entry.files do
      require("filesystem").remove("/lib/"..entry.files[j])
      os.execute("wget "..entry.base_url..entry.files[j].." /lib/"..entry.files[j])
    end
  end
end
