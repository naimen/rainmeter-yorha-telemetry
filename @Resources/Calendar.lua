-- ==============================================================================
-- YoRHa Tactical Calendar Script
-- Supports:
--   1. Standard Gregorian Calendar (English YoRHa HUD)
--   2. Chinese Lunar Calendar (农历) with 24 Solar Terms (二十四节气),
--      Heavenly Stems & Earthly Branches (天干地支), and Japanese Weekdays (曜日)
-- ==============================================================================

local isLunar = false

-- 1900-2100 Chinese Lunar Information Table
local LUNAR_INFO = {
    0x04bd8, 0x04ae0, 0x0a570, 0x054d5, 0x0d260, 0x0d950, 0x16554, 0x056a0, 0x09ad0, 0x055d2, 
    0x04ae0, 0x0a5b6, 0x0a4d0, 0x0d250, 0x1d255, 0x0b540, 0x0d6a0, 0x0ada2, 0x095b0, 0x14977, 
    0x04970, 0x0a4b0, 0x0b4b5, 0x06a50, 0x06d40, 0x1ab54, 0x02b60, 0x09570, 0x052f2, 0x04970, 
    0x06566, 0x0d4a0, 0x0ea50, 0x16a95, 0x05ad0, 0x02b60, 0x186e3, 0x092e0, 0x1c8d7, 0x0c950, 
    0x0d4a0, 0x1d8a6, 0x0b550, 0x056a0, 0x1a5b4, 0x025d0, 0x092d0, 0x0d2b2, 0x0a950, 0x0b557, 
    0x06ca0, 0x0b550, 0x15355, 0x04da0, 0x0a5d0, 0x14573, 0x052d0, 0x0a9a8, 0x0e950, 0x06aa0, 
    0x0aea6, 0x0ab50, 0x04b60, 0x0aae4, 0x0a570, 0x05260, 0x0f263, 0x0d950, 0x05b57, 0x056a0, 
    0x096d0, 0x04dd5, 0x04ad0, 0x0a4d0, 0x0d4d4, 0x0d250, 0x0d558, 0x0b540, 0x0b5a0, 0x195a6, 
    0x095b0, 0x049b0, 0x0a974, 0x0a4b0, 0x0b27a, 0x06a50, 0x06d40, 0x0af46, 0x0ab60, 0x09570, 
    0x04af5, 0x04970, 0x064b0, 0x074a3, 0x0ea50, 0x06b58, 0x055c0, 0x0ab60, 0x096d5, 0x092e0, 
    0x0c960, 0x0d954, 0x0d4a0, 0x0da50, 0x07552, 0x056a0, 0x0abb7, 0x025d0, 0x092d0, 0x0cab5, 
    0x0a950, 0x0b4a0, 0x0baa4, 0x0ad50, 0x055d9, 0x04ba0, 0x0a5b0, 0x15176, 0x052b0, 0x0a930, 
    0x07954, 0x06aa0, 0x0ad50, 0x05b52, 0x04b60, 0x0a6e6, 0x0a4e0, 0x0d260, 0x0ea65, 0x0d530, 
    0x05aa0, 0x076a3, 0x096d0, 0x04bd7, 0x04ad0, 0x0a4d0, 0x1d0b6, 0x0d250, 0x0d520, 0x0dd45, 
    0x0b5a0, 0x056d0, 0x055b2, 0x049b0, 0x0a577, 0x0a4b0, 0x0aa50, 0x1b255, 0x06d20, 0x0ada0, 
    0x14b63, 0x09370, 0x049f8, 0x04970, 0x064b0, 0x168a6, 0x0ea50, 0x06aa0, 0x1a6c4, 0x0aae0, 
    0x092e0, 0x0d2e3, 0x0c960, 0x0d557, 0x0d4a0, 0x0da50, 0x05d55, 0x056a0, 0x0a6d0, 0x055d4, 
    0x052d0, 0x0a9b8, 0x0a950, 0x0b4a0, 0x0b6a6, 0x0ad50, 0x055a0, 0x0aba4, 0x0a5b0, 0x052b0, 
    0x0b273, 0x06930, 0x07337, 0x06aa0, 0x0ad50, 0x14b55, 0x04b60, 0x0a570, 0x054e4, 0x0d160, 
    0x0e968, 0x0d520, 0x0daa0, 0x16aa6, 0x056d0, 0x04ae0, 0x0a9d4, 0x0a2d0, 0x0d150, 0x0f252, 
    0x0d520
}

local STEMS = { "甲", "乙", "丙", "丁", "戊", "己", "庚", "辛", "壬", "癸" }
local BRANCHES = { "子", "丑", "寅", "卯", "辰", "巳", "午", "未", "申", "酉", "戌", "亥" }
local LUNAR_MONTHS = { "正月", "二月", "三月", "四月", "五月", "六月", "七月", "八月", "九月", "十月", "冬月", "腊月" }
local LUNAR_DAYS = {
    "初一", "初二", "初三", "初四", "初五", "初六", "初七", "初八", "初九", "初十",
    "十一", "十二", "十三", "十四", "十五", "十六", "十七", "十八", "十九", "二十",
    "廿一", "廿二", "廿三", "廿四", "廿五", "廿六", "廿七", "廿八", "廿九", "三十"
}

-- 24 Solar Terms Definitions & 21st Century Constants
local SOLAR_TERMS_DEF = {
    { name = "小寒", m = 1, c = 5.4055 },
    { name = "大寒", m = 1, c = 20.12 },
    { name = "立春", m = 2, c = 3.87 },
    { name = "雨水", m = 2, c = 18.73 },
    { name = "惊蛰", m = 3, c = 5.63 },
    { name = "春分", m = 3, c = 20.646 },
    { name = "清明", m = 4, c = 4.81 },
    { name = "谷雨", m = 4, c = 20.1 },
    { name = "立夏", m = 5, c = 5.52 },
    { name = "小满", m = 5, c = 21.04 },
    { name = "芒种", m = 6, c = 5.678 },
    { name = "夏至", m = 6, c = 21.37 },
    { name = "小暑", m = 7, c = 7.108 },
    { name = "大暑", m = 7, c = 22.83 },
    { name = "立秋", m = 8, c = 7.5 },
    { name = "处暑", m = 8, c = 23.13 },
    { name = "白露", m = 9, c = 7.646 },
    { name = "秋分", m = 9, c = 23.042 },
    { name = "寒露", m = 10, c = 8.318 },
    { name = "霜降", m = 10, c = 23.438 },
    { name = "立冬", m = 11, c = 7.438 },
    { name = "小雪", m = 11, c = 22.36 },
    { name = "大雪", m = 12, c = 7.18 },
    { name = "冬至", m = 12, c = 21.94 }
}

-- Convert any UTF-8 string to Rainmeter Character Reference Variables [\xXXXX]
-- This ensures 100% identical Unicode rendering across all Windows code pages (ANSI/GBK/CP1252)
local function toUnicode(str)
    if not str then return "" end
    local result = {}
    local i = 1
    local len = string.len(str)
    while i <= len do
        local b = string.byte(str, i)
        if b < 0x80 then
            table.insert(result, string.char(b))
            i = i + 1
        elseif b >= 0xC0 and b < 0xE0 then
            local b2 = string.byte(str, i + 1) or 0
            local cp = (b - 0xC0) * 0x40 + (b2 - 0x80)
            table.insert(result, string.format("[\\x%04X]", cp))
            i = i + 2
        elseif b >= 0xE0 and b < 0xF0 then
            local b2 = string.byte(str, i + 1) or 0
            local b3 = string.byte(str, i + 2) or 0
            local cp = (b - 0xE0) * 0x1000 + (b2 - 0x80) * 0x40 + (b3 - 0x80)
            table.insert(result, string.format("[\\x%04X]", cp))
            i = i + 3
        elseif b >= 0xF0 and b < 0xF8 then
            local b2 = string.byte(str, i + 1) or 0
            local b3 = string.byte(str, i + 2) or 0
            local b4 = string.byte(str, i + 3) or 0
            local cp = (b - 0xF0) * 0x40000 + (b2 - 0x80) * 0x1000 + (b3 - 0x80) * 0x40 + (b4 - 0x80)
            table.insert(result, string.format("[\\x%04X]", cp))
            i = i + 4
        else
            i = i + 1
        end
    end
    return table.concat(result)
end

-- Gregorian Julian Day Number
local function toJDN(y, m, d)
    local a = math.floor((14 - m) / 12)
    local y2 = y + 4800 - a
    local m2 = m + 12 * a - 3
    return d + math.floor((153 * m2 + 2) / 5) + 365 * y2 + math.floor(y2 / 4) - math.floor(y2 / 100) + math.floor(y2 / 400) - 32045
end

-- Gregorian to Chinese Lunar calculation
local function getLunarDate(gYear, gMonth, gDay)
    if gYear < 1900 or gYear > 2100 then
        return { year = gYear, month = gMonth, day = gDay, isLeap = false }
    end

    -- 2415051 is JDN for 1900-01-31 (Chinese New Year 1900)
    local offset = toJDN(gYear, gMonth, gDay) - 2415051

    local lYear = 1900
    while lYear <= 2100 do
        local info = LUNAR_INFO[lYear - 1900 + 1]
        local sum = 0
        for m = 1, 12 do
            local bit = math.floor(info / math.pow(2, 16 - m)) % 2
            sum = sum + (bit == 1 and 30 or 29)
        end
        local leapM = info % 16
        if leapM > 0 then
            local leapDays = (math.floor(info / 65536) % 2 == 1) and 30 or 29
            sum = sum + leapDays
        end

        if offset < sum then break end
        offset = offset - sum
        lYear = lYear + 1
    end

    local info = LUNAR_INFO[lYear - 1900 + 1]
    local leapM = info % 16
    local isLeap = false
    local lMonth = 1

    for m = 1, 12 do
        local bit = math.floor(info / math.pow(2, 16 - m)) % 2
        local days = (bit == 1) and 30 or 29
        if offset < days then
            lMonth = m
            isLeap = false
            break
        end
        offset = offset - days

        if leapM > 0 and leapM == m then
            local leapDays = (math.floor(info / 65536) % 2 == 1) and 30 or 29
            if offset < leapDays then
                lMonth = m
                isLeap = true
                break
            end
            offset = offset - leapDays
        end
    end

    local lDay = offset + 1
    return { year = lYear, month = lMonth, day = lDay, isLeap = isLeap }
end

-- Solar Terms for a specific Gregorian year
local function getSolarTermsForYear(Y)
    local y = Y % 100
    local terms = {}
    for i, t in ipairs(SOLAR_TERMS_DEF) do
        local d = math.floor(y * 0.2422 + t.c) - math.floor((y - 1) / 4)
        if t.name == "小寒" and Y == 2019 then d = d - 1
        elseif t.name == "大寒" and Y == 2082 then d = d + 1
        elseif t.name == "立春" and Y == 2017 then d = d - 1
        elseif t.name == "春分" and Y == 2084 then d = d + 1
        elseif t.name == "立夏" and Y == 2011 then d = d + 1
        elseif t.name == "小满" and Y == 2008 then d = d + 1
        elseif t.name == "芒种" and Y == 2008 then d = d + 1
        elseif t.name == "夏至" and Y == 1928 then d = d + 1
        elseif t.name == "小暑" and Y == 2016 then d = d + 1
        elseif t.name == "大暑" and Y == 2022 then d = d + 1
        elseif t.name == "立秋" and Y == 2002 then d = d + 1
        elseif t.name == "白露" and Y == 1927 then d = d + 1
        elseif t.name == "秋分" and Y == 2042 then d = d + 1
        elseif t.name == "霜降" and Y == 2089 then d = d + 1
        elseif t.name == "立冬" and Y == 2089 then d = d + 1
        elseif t.name == "小雪" and Y == 2078 then d = d + 1
        elseif t.name == "大雪" and Y == 2054 then d = d + 1
        elseif t.name == "冬至" and Y == 2021 then d = d - 1
        end
        table.insert(terms, { name = t.name, month = t.m, day = d, year = Y })
    end
    return terms
end

-- Current active Solar Term for today
local function getCurrentSolarTerm(year, month, day)
    local terms = getSolarTermsForYear(year)
    local currentTerm = "冬至"
    for i, t in ipairs(terms) do
        if month > t.month or (month == t.month and day >= t.day) then
            currentTerm = t.name
        else
            break
        end
    end
    return currentTerm
end

-- Check if a specific date is a Solar Term day
local function getSolarTermOnDay(year, month, day)
    local terms = getSolarTermsForYear(year)
    for i, t in ipairs(terms) do
        if t.month == month and t.day == day then
            return t.name
        end
    end
    return nil
end

function Initialize()
    Update()
end

function ToggleCalendar()
    isLunar = not isLunar
    Update()
end

function Update()
    local now = os.date("*t")
    local year = now.year
    local month = now.month
    local day = now.day

    local weekNum = os.date("%V")
    if not weekNum or weekNum == "" or weekNum == "%V" then
        weekNum = os.date("%W")
    end

    local monthName = string.upper(os.date("%B"))

    local firstDayObj = os.date("*t", os.time{year=year, month=month, day=1})
    local startOffset = (firstDayObj.wday + 5) % 7

    local daysInMonth = os.date("*t", os.time{year=year, month=month+1, day=0}).day
    local prevDaysInMonth = os.date("*t", os.time{year=year, month=month, day=0}).day

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

    local colWk = {}
    local colDays = { {}, {}, {}, {}, {}, {}, {} }

    for r = 1, 5 do
        local midSlot = slots[(r - 1) * 7 + 4]
        local rYear = year
        local rMonth = month + midSlot.monthOffset
        if rMonth < 1 then
            rMonth = 12
            rYear = rYear - 1
        elseif rMonth > 12 then
            rMonth = 1
            rYear = rYear + 1
        end

        local rowTime = os.time{year=rYear, month=rMonth, day=midSlot.day}
        local rowWk = tonumber(os.date("%V", rowTime)) or tonumber(os.date("%W", rowTime)) or 0
        table.insert(colWk, string.format("%02d", rowWk))

        for c = 1, 7 do
            local sIdx = (r - 1) * 7 + c
            local slot = slots[sIdx]
            local colStr = ""

            if not isLunar then
                -- Standard Gregorian numbers
                if slot.isToday then
                    colStr = string.format("{%d}", slot.day)
                elseif not slot.current then
                    colStr = "."
                else
                    colStr = tostring(slot.day)
                end
            else
                -- Chinese Lunar Calendar representation
                if not slot.current then
                    colStr = toUnicode("·")
                else
                    local sYear = year
                    local sMonth = month + slot.monthOffset
                    if sMonth < 1 then
                        sMonth = 12
                        sYear = sYear - 1
                    elseif sMonth > 12 then
                        sMonth = 1
                        sYear = sYear + 1
                    end

                    -- Check 24 Solar Term on this day
                    local termOnDay = getSolarTermOnDay(sYear, sMonth, slot.day)
                    if termOnDay then
                        colStr = toUnicode(termOnDay)
                    else
                        local sLunar = getLunarDate(sYear, sMonth, slot.day)
                        if sLunar.day == 1 then
                            colStr = toUnicode((sLunar.isLeap and "闰" or "") .. LUNAR_MONTHS[sLunar.month])
                        else
                            colStr = toUnicode(LUNAR_DAYS[sLunar.day] or tostring(sLunar.day))
                        end
                    end

                    if slot.isToday then
                        colStr = "{" .. colStr .. "}"
                    end
                end
            end
            table.insert(colDays[c], colStr)
        end
    end

    if not isLunar then
        -- ==============================================================================
        -- MODE 1: STANDARD GREGORIAN CALENDAR
        -- ==============================================================================
        SKIN:Bang('!SetVariable', 'CalWeekNum', tostring(weekNum))
        SKIN:Bang('!SetVariable', 'CalDayNum', string.format("%02d", day))
        SKIN:Bang('!SetVariable', 'CalMonthYear', monthName .. ' ' .. tostring(year))

        -- Header text
        local defHdr = SKIN:GetVariable('CalHeaderLabel', 'SYS: CHRONO // CAL_00')
        if SKIN:GetMeter('MeterCalHeaderText') then
            SKIN:Bang('!SetOption', 'MeterCalHeaderText', 'Text', defHdr)
        end
        if SKIN:GetMeter('MeterCalHeader') then
            SKIN:Bang('!SetOption', 'MeterCalHeader', 'Text', defHdr)
        end

        -- Left Panel
        SKIN:Bang('!SetOption', 'MeterCalDayLabel', 'Text', 'CYCLE // DAY')
        SKIN:Bang('!SetOption', 'MeterCalDayVal', 'FontFace', '#FontClockNum#')
        SKIN:Bang('!SetOption', 'MeterCalDayVal', 'FontSize', '40')
        SKIN:Bang('!SetOption', 'MeterCalDayVal', 'Text', string.format("%02d", day))

        SKIN:Bang('!SetOption', 'MeterCalWeekCombined', 'FontFace', '#FontTactical#')
        SKIN:Bang('!SetOption', 'MeterCalWeekCombined', 'FontSize', '14')
        SKIN:Bang('!SetOption', 'MeterCalWeekCombined', 'Text', 'WEEK ' .. tostring(weekNum))

        SKIN:Bang('!SetOption', 'MeterCalMonthVal', 'FontFace', '#FontMain#')
        SKIN:Bang('!SetOption', 'MeterCalMonthVal', 'FontSize', '8.5')
        SKIN:Bang('!SetOption', 'MeterCalMonthVal', 'Text', monthName .. ' ' .. tostring(year))

        -- English Weekday Headers
        local enHeaders = { "WK", "MO", "TU", "WE", "TH", "FR", "SA", "SU" }
        for i = 0, 7 do
            SKIN:Bang('!SetOption', 'MeterCalHdr_' .. i, 'FontFace', '#FontSub#')
            SKIN:Bang('!SetOption', 'MeterCalHdr_' .. i, 'Text', enHeaders[i + 1])
        end

        -- Column texts & standard font
        SKIN:Bang('!SetOption', 'MeterCalCol_0', 'Text', table.concat(colWk, "\n"))
        for c = 1, 7 do
            SKIN:Bang('!SetOption', 'MeterCalCol_' .. c, 'Text', table.concat(colDays[c], "\n"))
        end

    else
        -- ==============================================================================
        -- MODE 2: CHINESE LUNAR CALENDAR (农历) + 24 SOLAR TERMS + JAPANESE WEEKDAYS
        -- ==============================================================================
        local lunarToday = getLunarDate(year, month, day)

        -- Heavenly Stem & Earthly Branch (天干地支)
        local stem = STEMS[(lunarToday.year - 4) % 10 + 1]
        local branch = BRANCHES[(lunarToday.year - 4) % 12 + 1]
        local yearGanZhi = stem .. branch .. "年"
        local monthStr = (lunarToday.isLeap and "闰" or "") .. LUNAR_MONTHS[lunarToday.month]
        local lunarDayStr = LUNAR_DAYS[lunarToday.day] or string.format("%02d", lunarToday.day)
        local currentSolarTerm = getCurrentSolarTerm(year, month, day)

        SKIN:Bang('!SetVariable', 'CalDayNum', toUnicode(lunarDayStr))
        SKIN:Bang('!SetVariable', 'CalMonthYear', toUnicode(yearGanZhi .. " " .. monthStr))

        -- Header text
        local headerText = toUnicode("SYS: CHRONO // 农历")
        if SKIN:GetMeter('MeterCalHeaderText') then
            SKIN:Bang('!SetOption', 'MeterCalHeaderText', 'Text', headerText)
        end
        if SKIN:GetMeter('MeterCalHeader') then
            SKIN:Bang('!SetOption', 'MeterCalHeader', 'Text', headerText)
        end

        -- Left Panel: Lunar Day, Current Solar Term (节气), and 天干地支
        SKIN:Bang('!SetOption', 'MeterCalDayLabel', 'Text', toUnicode("CYCLE // 农历"))
        SKIN:Bang('!SetOption', 'MeterCalDayVal', 'FontFace', '#FontSub#')
        SKIN:Bang('!SetOption', 'MeterCalDayVal', 'FontSize', '28')
        SKIN:Bang('!SetOption', 'MeterCalDayVal', 'Text', toUnicode(lunarDayStr))

        -- Display Current 节气 instead of Week Number
        SKIN:Bang('!SetOption', 'MeterCalWeekCombined', 'FontFace', '#FontSub#')
        SKIN:Bang('!SetOption', 'MeterCalWeekCombined', 'FontSize', '15')
        SKIN:Bang('!SetOption', 'MeterCalWeekCombined', 'Text', toUnicode(currentSolarTerm))

        -- Display 天干地支 instead of Month/Year
        SKIN:Bang('!SetOption', 'MeterCalMonthVal', 'FontFace', '#FontSub#')
        SKIN:Bang('!SetOption', 'MeterCalMonthVal', 'FontSize', '9')
        SKIN:Bang('!SetOption', 'MeterCalMonthVal', 'Text', toUnicode(yearGanZhi .. " " .. monthStr))

        -- Japanese Weekday Terms for Weekday Headers (月, 火, 水, 木, 金, 土, 日)
        local jpHeaders = { "周", "月", "火", "水", "木", "金", "土", "日" }
        for i = 0, 7 do
            SKIN:Bang('!SetOption', 'MeterCalHdr_' .. i, 'FontFace', '#FontSub#')
            SKIN:Bang('!SetOption', 'MeterCalHdr_' .. i, 'Text', toUnicode(jpHeaders[i + 1]))
        end

        -- Column texts in Lunar format (YorHa Mincho font with 8.5pt for clean CJK alignment)
        SKIN:Bang('!SetOption', 'MeterCalCol_0', 'FontFace', '#FontSub#')
        SKIN:Bang('!SetOption', 'MeterCalCol_0', 'FontSize', '8.5')
        SKIN:Bang('!SetOption', 'MeterCalCol_0', 'Text', table.concat(colWk, "\n"))

        for c = 1, 7 do
            SKIN:Bang('!SetOption', 'MeterCalCol_' .. c, 'FontFace', '#FontSub#')
            SKIN:Bang('!SetOption', 'MeterCalCol_' .. c, 'FontSize', '8.5')
            SKIN:Bang('!SetOption', 'MeterCalCol_' .. c, 'Text', table.concat(colDays[c], "\n"))
        end
    end

    SKIN:Bang('!UpdateMeter', '*')
    SKIN:Bang('!Redraw')

    return tostring(weekNum)
end