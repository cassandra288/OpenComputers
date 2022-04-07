local libs = {}

libs.core = require("ProgramCore")
libs.gl = require("OpenTGL")
libs.keyboard = require("keyboard")


libs.gl.Setup()
local screenW, screenH = require("component").gpu.getResolution()

libs.core.targetTPS = 10


local data = {}
data.dragging = false
data.squares = {}
data.undo_buffer = {}
data.colorFG = 0x000000
data.colorBG = 0xFFFFFF

io.open("UiPlan.txt", "w"):close()


local function redraw()
    libs.gl.Clear(0x000000)
    
    for _, v in ipairs(data.squares) do
        libs.gl.DrawRectangle(v.x, v.y, v.w, v.h, " ", v.color, v.color_fg)
    end

    if data.tmp_square then
        libs.gl.DrawRectangle(data.tmp_square.x, data.tmp_square.y, data.tmp_square.w, data.tmp_square.h, " ", data.colorBG, data.colorFG)
    end

    if data.region_stats then
        stat_str = data.region_stats.x..", "..data.region_stats.y..", "..data.region_stats.w..", "..data.region_stats.h
        libs.gl.DrawTextCentred(screenW/2, screenH, stat_str, 0x000000, 0xFFFFFF)
    end

    libs.gl.Render()
end

local function addSquare()
    square = {
        ["x"] = data.tmp_square.x,
        ["y"] = data.tmp_square.y,
        ["w"] = data.tmp_square.w,
        ["h"] = data.tmp_square.h,
        ["color"] = data.colorBG,
        ["color_fg"] = data.colorFG
    }
    data.tmp_square = nil
    table.insert(data.squares, square)
    redraw()
end

local function undoSquare()
    square = table.remove(data.squares)
    table.insert(data.undo_buffer, square)
    redraw()
end

local function redoSquare()
    square = table.remove(data.undo_buffer)
    table.insert(data.squares, square)
    redraw()
end

local function clearSquares()
    data.squares = {}
    data.undo_buffer = {}
end


local key_functions = {}

key_functions[libs.keyboard.keys.enter] = function()
    file = io.open("UiPlan.txt", "a")
    for i=1,#data.squares do
        file:write(data.squares[i].x..", "..data.squares[i].y..", "..data.squares[i].w..", "..data.squares[i].h.."\n")
    end
    file:close()
    libs.core.running = false
end

key_functions[libs.keyboard.keys.space] = clearSquares

key_functions[libs.keyboard.keys.z] = undoSquare

key_functions[libs.keyboard.keys.x] = redoSquare

key_functions[libs.keyboard.keys["1"]] = function()
    if libs.keyboard.isAltDown() then
        data.colorFG = 0x000000
        data.colorBG = 0xDDDDDD
    else
        data.colorFG = 0x000000
        data.colorBG = 0xFFFFFF
    end
    redraw()
end
key_functions[libs.keyboard.keys["2"]] = function()
    if libs.keyboard.isAltDown() then
        data.colorFG = 0xFFFFFF
        data.colorBG = 0x777777
    else
        data.colorFG = 0x000000
        data.colorBG = 0xAAAAAA
    end
    redraw()
end
key_functions[libs.keyboard.keys["3"]] = function()
    if libs.keyboard.isAltDown() then
        data.colorFG = 0x000000
        data.colorBG = 0xDD0000
    else
        data.colorFG = 0x000000
        data.colorBG = 0xFF0000
    end
    redraw()
end
key_functions[libs.keyboard.keys["4"]] = function()
    if libs.keyboard.isAltDown() then
        data.colorFG = 0xFFFFFF
        data.colorBG = 0x770000
    else
        data.colorFG = 0x000000
        data.colorBG = 0xAA0000
    end
    redraw()
end
key_functions[libs.keyboard.keys["5"]] = function()
    if libs.keyboard.isAltDown() then
        data.colorFG = 0x000000
        data.colorBG = 0x00DD00
    else
        data.colorFG = 0x000000
        data.colorBG = 0x00FF00
    end
    redraw()
end
key_functions[libs.keyboard.keys["6"]] = function()
    if libs.keyboard.isAltDown() then
        data.colorFG = 0xFFFFFF
        data.colorBG = 0x007700
    else
        data.colorFG = 0x000000
        data.colorBG = 0x00AA00
    end
    redraw()
end
key_functions[libs.keyboard.keys["7"]] = function()
    if libs.keyboard.isAltDown() then
        data.colorFG = 0x000000
        data.colorBG = 0x0000DD
    else
        data.colorFG = 0x000000
        data.colorBG = 0x0000FF
    end
    redraw()
end
key_functions[libs.keyboard.keys["8"]] = function()
    if libs.keyboard.isAltDown() then
        data.colorFG = 0xFFFFFF
        data.colorBG = 0x000077
    else
        data.colorFG = 0x000000
        data.colorBG = 0x0000AA
    end
    redraw()
end
key_functions[libs.keyboard.keys["9"]] = function()
    data.colorFG = 0xFFFFFF
    data.colorBG = 0x000000
    redraw()
end


local function key_up(_, _, _, code, _)
    if key_functions[code] then
       key_functions[code]() 
    end
end
table.insert(libs.core.callbacks.key_up, key_up)

local function touch(_, _, x, y, button, _)
    data.undo_buffer = {}
    data.tmp_square = {
        ["x"] = x,
        ["y"] = y,
        ["w"] = x,
        ["h"] = y
    }
    data.touch_start = {
        ["x"] = x,
        ["y"] = y
    }
    data.region_stats = data.tmp_square
    redraw()
end
table.insert(libs.core.callbacks.touch, touch)

local function drag(_, _, x, y, button, _)
    sx = math.min(data.touch_start.x, x)
    sy = math.min(data.touch_start.y, y)
    sw = math.max(data.touch_start.x, x)
    sh = math.max(data.touch_start.y, y)

    data.tmp_square = {
        ["x"] = sx,
        ["y"] = sy,
        ["w"] = sw,
        ["h"] = sh
    }
    
    data.region_stats = data.tmp_square
    redraw()
end
table.insert(libs.core.callbacks.drag, drag)

local function drop(_, _, x, y, button, _)
    addSquare()
end
table.insert(libs.core.callbacks.drop, drop)


local function main()
    
end
libs.core.Run(main)
