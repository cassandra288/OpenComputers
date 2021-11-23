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
    ["type"] = "title",
    ["text"] = "Programs"
  },
  {
    ["type"] = "program",
    ["text"] = "AtomMan",
    ["base_url"] = "https://raw.githubusercontent.com/Thomas2889/OpenComputers/master/Programs/AtomMan/",
    ["files"] = {
      "AtomMan.lua",
      "Files/AtomMan/ReactorManager.lua",
      "Files/AtomMan/UIRender.lua"
    },
    ["deps"] ={
      "OpenTGL",
      "ButtonLib",
      "ProgramCore"
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
local draw_offset = 0
local cursor_index = nil
local width, height = gpu.getResolution()

gpu.fill(1, 1, width, height, " ")

for i = 1, #data do
  if data[i].type == "lib" then
    cursor_index = i
    break
  end
end


local function GetDrawHeight(i)
  return i - draw_offset
end


local function UnhandledType(entry)
  error("Unhandled type "..entry.type)
end
local EntryDrawers = setmetatable({}, { __index = function() return UnhandledType end })

function EntryDrawers.title(entry, i)
  local drawHeight = GetDrawHeight(i)
  gpu.set(1, drawHeight, entry.text)
end

function EntryDrawers.lib(entry, i, cursor)
  local drawHeight = GetDrawHeight(i)
  gpu.set(1, drawHeight, "[ ] "..entry.text)
  
  if cursor then gpu.setBackground(0xbbbb00) end
  if entry.selected then
    gpu.setForeground(0x00ff00)
    gpu.set(2, drawHeight, "X")
    gpu.setForeground(0xffffff)
  else
    gpu.set(2, drawHeight, " ")
  end
  gpu.setBackground(0x000000)
end

function EntryDrawers.program(entry, i, cursor)
  local drawHeight = GetDrawHeight(i)
  gpu.set(1, drawHeight, "[ ] "..entry.text)
  
  if cursor then gpu.setBackground(0xbbbb00) end
  if entry.selected then
    gpu.setForeground(0x00ff00)
    gpu.set(2, drawHeight, "X")
    gpu.setForeground(0xffffff)
  else
    gpu.set(2, drawHeight, " ")
  end
  gpu.setBackground(0x000000)
end

function EntryDrawers.finish(entry, i, cursor)
  local drawHeight = GetDrawHeight(i)
  gpu.set(1, drawHeight, "[-] Select to Continue")
  if cursor then
    gpu.setBackground(0xbbbb00)
    gpu.set(2, drawHeight, "-")
    gpu.setBackground(0x000000)
  end
end


local function MoveCursor(to)
  local lowest = draw_offset + 1
  local highest = height + draw_offset
  if to == 2 then to = 1 end -- make sure the top title can show up
  if to < lowest then
    draw_offset = to - 1
    gpu.fill(1, 1, width, height, " ")
    for i = draw_offset + 1, height + draw_offset do
      EntryDrawers[data[i].type](data[i], i)
    end
  elseif to > highest then
    draw_offset = to - height
    gpu.fill(1, 1, width, height, " ")
    for i = draw_offset + 1, height + draw_offset do
      EntryDrawers[data[i].type](data[i], i)
    end
  end
  if to == 1 then to = 2 end

  from_entry = data[cursor_index]
  to_entry = data[to]

  EntryDrawers[from_entry.type](from_entry, cursor_index)
  EntryDrawers[to_entry.type](to_entry, to, true)
  
  cursor_index = to
end

local function Select()
  data[cursor_index].selected = not data[cursor_index].selected

  EntryDrawers[data[cursor_index].type](data[cursor_index], cursor_index, true)

  if data[cursor_index].type == "finish" then
    running = false
  elseif data[cursor_index].type == "program" then
    for _, dep in ipairs(data[cursor_index].deps) do
      dep_index = nil
      for i, entry in ipairs(data) do
        if entry.text == dep then
          dep_index = i
          break
        end
      end

      data[dep_index].selected = data[cursor_index].selected
      EntryDrawers[data[dep_index].type](data[dep_index], dep_index, false)
    end
  end
end


for i = 1, math.min(height, #data) do
  local entry = data[i]
  EntryDrawers[entry.type](entry, i)
end
MoveCursor(cursor_index)


local function UnhandledEvent()
  -- do nothing
end
local EventHandlers = setmetatable({}, { __index = function() return UnhandledEvent end })

function EventHandlers.interrupted()
  os.exit()
end

function EventHandlers.key_down(_, _, key_code)
  if key_code == 28 then
    Select()
  elseif key_code == 200 then
    for i = cursor_index - 1, 1, -1 do
      local type = data[i].type
      if type == "lib" or type == "finish" or type == "program" then
        MoveCursor(i)
        break
      end
    end
  elseif key_code == 208 then
    for i = cursor_index + 1, #data, 1 do
      local type = data[i].type
      if type == "lib" or type == "finish" or type == "program" then
        MoveCursor(i)
        break
      end
    end
  end
end

function EventHandlers.touch(_, _, y, button)
  if button == 0 then
    local type = data[y].type
    if type == "lib" or type == "finish" or type == "program" then
      MoveCursor(y)
      Select()
    end
  end
end

function EventHandlers.scroll(_, _, _, dir)
  if dir < 0 then
    for i = cursor_index + 1, #data, 1 do
      local type = data[i].type
      if type == "lib" or type == "finish" or type == "program" then
        dir = dir + 1
        if dir == 0 then
          MoveCursor(i)
          break
        end
      end
    end
  elseif dir > 0 then
    for i = cursor_index - 1, 1, -1 do
      local type = data[i].type
      if type == "lib" or type == "finish" or type == "program" then
        dir = dir - 1
        if dir == 0 then
          MoveCursor(i)
          break
        end
      end
    end
  end
end

local function HandleEvent(event_id, ...)
  if (event_id) then
    EventHandlers[event_id](...)
  end
end


while running do
  HandleEvent(event.pull())

  os.sleep(0.05)
end

require("term").setCursor(1, 1)
gpu.fill(1, 1, width, height, " ")

local fs = require("filesystem")
for i = 1, #data do
  entry = data[i]
  if entry.base_url and entry.selected then
    gpu.setForeground(0xff0000)
    print("Installing "..entry.text)
    gpu.setForeground(0xffffff)
    for j = 1, #entry.files do
      if entry.type == "lib" then
        fs.remove("/lib/"..entry.files[j])
        os.execute("wget "..entry.base_url..entry.files[j].." /lib/"..entry.files[j])
      else
        fs.remove("/home/"..entry.files[j])
        fs.makeDirectory("/home/"..fs.path(entry.files[j]))
        os.execute("wget "..entry.base_url..entry.files[j].." /home/"..entry.files[j])
      end
    end
  end
end
