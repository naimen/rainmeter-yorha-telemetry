-- ==============================================================================
-- YoRHa Tactical Calendar Controller
-- Dispatches between:
--   1. CalendarGregorian.lua (Standard YoRHa Gregorian HUD)
--   2. CalendarLunar.lua     (Chinese Lunar Calendar & 24 Solar Terms)
-- ==============================================================================

local isLunar = false
local Gregorian = nil
local Lunar = nil

function Initialize()
    local resPath = SKIN:GetVariable('@')
    if not resPath or resPath == "" then
        resPath = SKIN:MakePathAbsolute('@Resources/')
    end

    Gregorian = dofile(resPath .. 'CalendarGregorian.lua')
    Lunar = dofile(resPath .. 'CalendarLunar.lua')

    Update()
end

function ToggleCalendar()
    isLunar = not isLunar
    Update()
end

function Update()
    if not Gregorian or not Lunar then
        local resPath = SKIN:GetVariable('@')
        if not resPath or resPath == "" then
            resPath = SKIN:MakePathAbsolute('@Resources/')
        end
        Gregorian = dofile(resPath .. 'CalendarGregorian.lua')
        Lunar = dofile(resPath .. 'CalendarLunar.lua')
    end

    local now = os.date("*t")
    local year = now.year
    local month = now.month
    local day = now.day

    local weekNum = os.date("%V")
    if not weekNum or weekNum == "" or weekNum == "%V" then
        weekNum = os.date("%W")
    end

    local monthName = string.upper(os.date("%B"))

    local firstDayObj = os.date("*t", os.time{ year = year, month = month, day = 1 })
    local startOffset = (firstDayObj.wday + 5) % 7

    local daysInMonth = os.date("*t", os.time{ year = year, month = month + 1, day = 0 }).day
    local prevDaysInMonth = os.date("*t", os.time{ year = year, month = month, day = 0 }).day

    local slots = {}
    for i = startOffset - 1, 0, -1 do
        table.insert(slots, { day = prevDaysInMonth - i, current = false, isToday = false, monthOffset = -1 })
    end
    for d = 1, daysInMonth do
        table.insert(slots, { day = d, current = true, isToday = (d == day), monthOffset = 0 })
    end
    local nextD = 1
    while #slots < 35 do
        table.insert(slots, { day = nextD, current = false, isToday = false, monthOffset = 1 })
        nextD = nextD + 1
    end

    local context = {
        year = year,
        month = month,
        day = day,
        weekNum = weekNum,
        monthName = monthName,
        slots = slots,
        isLunar = isLunar
    }

    if not isLunar then
        Gregorian.Render(context)
    else
        Lunar.Render(context)
    end

    SKIN:Bang('!UpdateMeter', '*')
    SKIN:Bang('!Redraw')

    return tostring(weekNum)
end