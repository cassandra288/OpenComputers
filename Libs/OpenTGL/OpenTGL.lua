local gpu = require("component").gpu


-- function caches
local GpuGetResolution, GpuSetBackground, GpuSetForeground, GpuFill = gpu.getResolution, gpu.setBackground, gpu.setForeground, gpu.fill
local MathAbs, MathCeil, MathFloor = math.abs, math.ceil, math.floor

-- graphics buffers
local graphicCache, graphicBuffer


--========== Internal Stuff ==========--
local SemiChar = "▀"

------------ Helpful Math Functions ------------
local function ColorBlend(c1, c2, alpha)
    local invertedAlpha = 1 - alpha
    return
		((c2 >> 16) * invertedAlpha + (c1 >> 16) * alpha) // 1 << 16 |
		((c2 >> 8 & 0xFF) * invertedAlpha + (c1 >> 8 & 0xFF) * alpha) // 1 << 8 |
		((c2 & 0xFF) * invertedAlpha + (c1 & 0xFF) * alpha) // 1
end

------------ Rasterization Functions ------------
local function RasterizeLine(x1, y1, x2, y2, method)
    local dx, sx = MathAbs(x2 - x1), x1 < x2 and 1 or -1
    local dy, sy = MathAbs(y2 - y1), y1 < y2 and 1 or -1
    local err, e2 = (dx > dy and dx or -dy)/2, 0
    while true do
        method(x1, y1)
        if x1 == x2 and y1 == y2 then break end
        e2 = err
        if e2 > -dx then
            err = err - dy
            x1 = x1 + sx
        end
        if e2 < dy then
            err = err + dx
            y1 = y1 + sy
        end
    end
end

local function RasterizeRectangle(x1, y1, x2, y2, method)
    if x1 > x2 then
        x1, x2 = x2, x1
    end
    if y1 > y2 then
        y1, y2 = y2, y1
    end

    for x = x1, x2, 1 do
        for y = y1, y2, 1 do
            method(x, y)
        end
    end
end

local function RasterizeBox(x1, y1, x2, y2, method)
    if x1 > x2 then
        x1, x2 = x2, x1
    end
    if y1 > y2 then
        y1, y2 = y2, y1
    end

    --top and bottom
    for x = x1, x2, 1 do
        method(x, y1)
        method(x, y2)
    end
    --left and right
    for y = y1, y2, 1 do
        method(x1, y)
        method(x2, y)
    end
end

local function RasterizeEllipse(xc, yc, xr, yr, method)
    local x, y, changeX, changeY, err, twoXSquare, twoYSquare = xr, 0, yr * yr * (1 - 2 * xr), xr * xr, 0, 2 * xr * xr, 2 * yr * yr
    local stopX, stopY = twoYSquare * xr, 0

    while stopX >= stopY do
        method(xc + x, yc + y)
        method(xc - x, yc + y)
        method(xc - x, yc - y)
        method(xc + x, yc - y)

        y, stopY, err = y + 1, stopY + twoXSquare, err + changeY
        changeY = changeY + twoXSquare

        if (2 * err + changeX) > 0 then
            x, stopX, err = x - 1, stopX - twoYSquare, err + changeX
            changeX = changeX + twoYSquare
        end
    end

    x, y, changeX, changeY, err, stopX, stopY = 0, yr, yr * yr, xr * xr * (1 - 2 * yr), 0, 0, twoXSquare * yr

    while stopX <= stopY do
        method(xc + x, yc + y)
        method(xc - x, yc + y)
        method(xc - x, yc - y)
        method(xc + x, yc - y)

        x, stopX, err = x + 1, stopX + twoYSquare, err + changeX
        changeX = changeX + twoYSquare

        if (2 * err + changeY) > 0 then
            y, stopY, err = y - 1, stopY - twoXSquare, err + changeY
            changeY = changeY + twoXSquare
        end
    end
end


--========== Library Functions ==========--
------------ Resolution ------------
local sw, sh

local function UpdateResolution()
    local oldW, oldH = sw, sh
    sw, sh = GpuGetResolution()

    local oldCache, oldBuffer = graphicCache, graphicBuffer
    graphicCache, graphicBuffer = {}, {}
    for i = 1, sw * sh * 3, 3 do
       graphicCache[i], graphicBuffer[i], graphicCache[i + 1], graphicBuffer[i + 1], graphicCache[i + 2], graphicBuffer[i + 2] = "0x000000", "0x000000", "0x000000", "0x000000", " ", " " 
    end

    if oldW ~= nil then
        local oldIndex = 1
        for y = 1, oldH, 1 do
            local index = sw * 3
            for x = 1, oldW, 1 do
                graphicCache[index], graphicCache[index + 1], graphicCache[index + 2] = oldCache[oldIndex], oldCache[oldIndex + 1], oldCache[oldIndex + 2]
                graphicBuffer[index], graphicBuffer[index + 1], graphicBuffer[index + 2] = oldBuffer[oldIndex], oldBuffer[oldIndex + 1], oldBuffer[oldIndex + 2]

                index = index + 3
                oldIndex = oldIndex + 3
            end
        end
    end
end

------------ Char Drawing ------------
local function GetChar(x, y)
    local index = (sw * (y - 1) + x) * 3 - 2
    return graphicBuffer[index], graphicBuffer[index + 1], graphicBuffer[index + 2]
end

local function SetChar(x, y, char, bg, fg, alpha)
    local index = (sw * (y - 1) + x) * 3 - 2
    if alpha then
        bg = ColorBlend(graphicBuffer[index], bg, alpha)
        fg = ColorBlend(graphicBuffer[index + 1], fg, alpha)
    end
    graphicBuffer[index], graphicBuffer[index + 1], graphicBuffer[index + 2] = bg, fg, char
end

local function DrawLine(x1, y1, x2, y2, char, bg, fg, alpha)
    RasterizeLine(x1, y1, x2, y2, function(x, y)
        SetChar(x, y, char, bg, fg, alpha)
    end)
end

local function DrawRectangle(x1, y1, x2, y2, char, bg, fg, alpha)
    RasterizeRectangle(x1, y1, x2, y2, function(x, y)
        SetChar(x, y, char, bg, fg, alpha)
    end)
end

local function DrawBox(x1, y1, x2, y2, char, bg, fg, alpha)
    RasterizeBox(x1, y1, x2, y2, function(x, y)
        SetChar(x, y, char, bg, fg, alpha)
    end)
end

local function DrawEllipse(xc, yc, xr, yr, char, bg, fg, alpha)
    RasterizeEllipse(xc, yc, xr, yr, function(x, y)
        SetChar(x, y, char, bg, fg, alpha)
    end)
end

------------ SemiChar Drawing ------------
local function GetSemiChar(x, y)
    local charY = MathCeil(y / 2)
    local index = (sw * (charY - 1) + x) * 3 - 2
    return graphicBuffer[index + (y % 2)]
end

local function SetSemiChar(x, y, color, alpha)
    local charY = MathCeil(y / 2)
    local index = (sw * (charY - 1) + x) * 3 - 2

    if alpha and graphicBuffer[index + 2] == SemiChar then
        color = ColorBlend(graphicBuffer[index + (y % 2)], color, alpha)
    end
    graphicBuffer[index + 2] = SemiChar
    graphicBuffer[index + (y % 2)] = color
end

local function DrawSemiLine(x1, y1, x2, y2, color, alpha)
    RasterizeLine(x1, y1, x2, y2, function(x, y)
        SetSemiChar(x, y, color, alpha)
    end)
end

local function DrawSemiRectangle(x1, y1, x2, y2, color, alpha)
    RasterizeRectangle(x1, y1, x2, y2, function(x, y)
        SetSemiChar(x, y, color, alpha)
    end)
end

local function DrawSemiBox(x1, y1, x2, y2, color, alpha)
    RasterizeBox(x1, y1, x2, y2, function(x, y)
        SetSemiChar(x, y, color, alpha)
    end)
end

local function DrawSemiEllipse(xc, yc, xr, yr, color, alpha)
    RasterizeEllipse(xc, yc, xr, yr, function(x, y)
        SetSemiChar(x, y, color, alpha)
    end)
end

------------ Text Drawing ------------
local function DrawTextLeft(x, y, text, bg, fg, alpha)
    for str in string.gmatch(text, "([^\n]+)") do
        for i = 1, #str, 1 do
            SetChar(x + (i - 1), y, str:sub(i, i), bg, fg, alpha)
        end
        y = y + 1
    end
end

local function DrawTextRight(x, y, text, bg, fg, alpha)
    for str in string.gmatch(text, "([^\n]+)") do
        for i = #str, 1, -1 do
            SetChar(x - #str + i, y, str:sub(i, i), bg, fg, alpha)
        end
        y = y + 1
    end
end

local function DrawTextCentered(x, y, text, bg, fg, alpha)
    for str in string.gmatch(text, "([^\n]+)") do
        local offset = MathFloor((#str - 1) / 2)
        for i = 1, #str, 1 do
            SetChar(x + (i - 1) - offset, y, str:sub(i, i), bg, fg, alpha)
        end
        y = y + 1
    end
end

------------ General ------------
local function Clear(clearColor)
    DrawRectangle(1, 1, sw, sh, " ", clearColor, clearColor)
end

------------ RENDERING ------------
local function Render()
    local backgroundGroup = {}

    local index = 1
    while index <  sw * sh * 3 do
        if graphicCache[index] ~= graphicBuffer[index] or graphicCache[index + 1] ~= graphicBuffer[index + 1] or graphicCache[index + 2] ~= graphicBuffer[index + 2] then
            local currBg, currFg, currChar = graphicBuffer[index], graphicBuffer[index + 1], graphicBuffer[index + 2]
            local currWidth, currHeight = 1, 1
            graphicCache[index], graphicCache[index + 1], graphicCache[index+ 2] = graphicBuffer[index], graphicBuffer[index + 1], graphicBuffer[index + 2]

            local seekIndex = index + 3
            while seekIndex < sw * 3 * MathCeil((index + 2) / 3 / sw) do
                local seekBg, seekFg, seekChar = graphicBuffer[seekIndex], graphicBuffer[seekIndex + 1], graphicBuffer[seekIndex + 2]
                local seekBgC, seekFgC, seekCharC = graphicCache[seekIndex], graphicCache[seekIndex + 1], graphicCache[seekIndex + 2]
                
                if seekBgC == seekBg and seekFgC == seekFg and seekCharC == seekChar then break end
                if seekBg ~= currBg or seekFg ~= currFg or seekChar ~= currChar then break end
                currWidth = currWidth + 1

                -- we update the cache on the go so that we don't process this index again later on
                graphicCache[seekIndex], graphicCache[seekIndex + 1], graphicCache[seekIndex+ 2] = graphicBuffer[seekIndex], graphicBuffer[seekIndex + 1], graphicBuffer[seekIndex + 2]

                seekIndex = seekIndex + 3
            end

            seekIndex = index + sw * 3
            while seekIndex < sw * sh * 3 do
                local fullMatch = true
                for matchingIndex = seekIndex, seekIndex + currWidth * 3 - 3, 3 do
                    local seekBg, seekFg, seekChar = graphicBuffer[matchingIndex], graphicBuffer[matchingIndex + 1], graphicBuffer[matchingIndex + 2]
                    local seekBgC, seekFgC, seekCharC = graphicCache[seekIndex], graphicCache[seekIndex + 1], graphicCache[seekIndex + 2]
                    if seekBg ~= currBg or seekFg ~= currFg or seekChar ~= currChar or (seekBgC == seekBg and seekFgC == seekFg and seekCharC == seekChar) then
                        fullMatch = false
                        break
                    end
                end

                if fullMatch then
                    for matchingIndex = seekIndex, seekIndex + currWidth * 3 - 3, 3 do
                        graphicCache[matchingIndex], graphicCache[matchingIndex + 1], graphicCache[matchingIndex+ 2] = graphicBuffer[matchingIndex], graphicBuffer[matchingIndex + 1], graphicBuffer[matchingIndex + 2]
                    end
                    currHeight = currHeight + 1
                else
                    break
                end

                seekIndex = seekIndex + sw * 3
            end

            -- group changes by nested colours so we make less calls to the GPU
            backgroundGroup[currBg] = backgroundGroup[currBg] or {}
            backgroundGroup[currBg][currFg] = backgroundGroup[currBg][currFg] or {}

            local indexCount = (index + 2) / 3
            local y = MathCeil(indexCount / sw)
            table.insert(backgroundGroup[currBg][currFg], {
                char = currChar,
                y = y,
                x = indexCount - (sw * (y - 1)),
                width = currWidth,
                height = currHeight
            })
        end
        index = index + 3
    end

    for bg, fgGrp in pairs(backgroundGroup) do
        GpuSetBackground(bg)
        for fg, fillGrp in pairs(fgGrp) do
            GpuSetForeground(fg)
            for _, fillData in pairs(fillGrp) do
                GpuFill(fillData.x, fillData.y, fillData.width, fillData.height, fillData.char)
            end
        end
    end
end


--========== Library Setup ==========--
local function Setup()
    graphicCache, graphicBuffer = {}, {}
    sw, sh = nil, nil

    UpdateResolution()
    Clear(0xffffff)
    for i, v in pairs(graphicBuffer) do graphicCache[i] = v end
    Clear(0x000000)
    Render()
end

return {
    UpdateResolution = UpdateResolution,
    Clear = Clear,
    Setup = Setup,

    GetChar = GetChar,
    SetChar = SetChar,
    DrawLine = DrawLine,
    DrawRectangle = DrawRectangle,
    DrawBox = DrawBox,
    DrawEllipse = DrawEllipse,

    GetSemiChar = GetSemiChar,
    SetSemiChar = SetSemiChar,
    DrawSemiLine = DrawSemiLine,
    DrawSemiRectangle = DrawSemiRectangle,
    DrawSemiBox = DrawSemiBox,
    DrawSemiEllipse = DrawSemiEllipse,

    DrawTextLeft = DrawTextLeft,
    DrawTextRight = DrawTextRight,
    DrawTextCentered = DrawTextCentered,

    Render = Render
};