-- ==============================================================================
-- YoRHa Tactical Calendar Controller
-- Dispatches between:
--   1. CalendarGregorian.lua (Standard YoRHa Gregorian HUD)
--   2. CalendarLunar.lua     (Chinese Lunar Calendar & 24 Solar Terms)
-- ==============================================================================

local isLunar = false
local Gregorian = nil
local Lunar = nil

local function toRoman(num)
    num = tonumber(num)
    if not num or num <= 0 then return "" end
    local vals = { 1000, 900, 500, 400, 100, 90, 50, 40, 10, 9, 5, 4, 1 }
    local syms = { "M", "CM", "D", "CD", "C", "XC", "L", "XL", "X", "IX", "V", "IV", "I" }
    local res = ""
    for i = 1, #vals do
        while num >= vals[i] do
            res = res .. syms[i]
            num = num - vals[i]
        end
    end
    return res
end

local function toAstronomicalJulianRoman(jdn)
    jdn = tonumber(jdn)
    if not jdn or jdn <= 0 then return "" end
    local thousands = math.floor(jdn / 1000)
    local remainder = jdn % 1000
    local rThousands = toRoman(thousands)
    local rRemainder = toRoman(remainder)
    if rThousands ~= "" and rRemainder ~= "" then
        return rThousands .. "·" .. rRemainder
    elseif rThousands ~= "" then
        return rThousands
    else
        return rRemainder
    end
end

local function toJDN(y, m, d)
    local a = math.floor((14 - m) / 12)
    local y2 = y + 4800 - a
    local m2 = m + 12 * a - 3
    return d + math.floor((153 * m2 + 2) / 5) + 365 * y2 + math.floor(y2 / 4) - math.floor(y2 / 100) + math.floor(y2 / 400) - 32045
end

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
    local dayOfYear = now.yday or tonumber(os.date("%j")) or 1
    local jdn = toJDN(year, month, day)
    local julianRoman = toAstronomicalJulianRoman(jdn)

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
        dayOfYear = dayOfYear,
        jdn = jdn,
        julianRoman = julianRoman,
        weekNum = weekNum,
        monthName = monthName,
        slots = slots,
        isLunar = isLunar
    }

    SKIN:Bang('!SetVariable', 'CalDayOfYear', tostring(dayOfYear))
    SKIN:Bang('!SetVariable', 'CalJulianDate', tostring(jdn))
    SKIN:Bang('!SetVariable', 'CalJulianRoman', julianRoman)

    if not isLunar then
        Gregorian.Render(context)
    else
        Lunar.Render(context)
    end

    SKIN:Bang('!UpdateMeter', '*')
    SKIN:Bang('!Redraw')

    return tostring(weekNum)
end