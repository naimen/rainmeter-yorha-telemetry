-- ==============================================================================
-- YoRHa Tactical Calendar: Chinese Lunar & 24 Solar Terms Branch
-- ==============================================================================

local Lunar = {}

-- 2000-2100 Chinese Lunar Information Table
local LUNAR_INFO = {
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

-- 24 Solar Terms Names (ordered from Xiao Han to Dong Zhi)
local SOLAR_TERMS_NAMES = {
    "小寒", "大寒", "立春", "雨水", "惊蛰", "春分",
    "清明", "谷雨", "立夏", "小满", "芒种", "夏至",
    "小暑", "大暑", "立秋", "处暑", "白露", "秋分",
    "寒露", "霜降", "立冬", "小雪", "大雪", "冬至"
}

-- 2000-2100 Solar Terms Table (101 years, 24 terms per year)
-- Encoded as 24 hex characters: odd chars = 1st term day, even chars = 2nd term day - 15
local SOLAR_TERMS_INFO = {
    "664455455656777878887776", -- 2000
    "554355555656787878887777", -- 2001
    "554466556666788888887777", -- 2002
    "654466556667788888998877", -- 2003
    "664455455656777878887776", -- 2004
    "554355555656787878887777", -- 2005
    "554466555666787888887777", -- 2006
    "654466556667788888998877", -- 2007
    "664455455656777877887776", -- 2008
    "554355455656787878887777", -- 2009
    "554466555666787888887777", -- 2010
    "654466556667788888898877", -- 2011
    "664455455556777877887776", -- 2012
    "554355455656777878887777", -- 2013
    "554466555666787888887777", -- 2014
    "654466556667788888898777", -- 2015
    "654455445556777877887776", -- 2016
    "553355455656777878887777", -- 2017
    "554456555666787888887777", -- 2018
    "554466556666788888898777", -- 2019
    "654455445556677777887776", -- 2020
    "553355455656777878887776", -- 2021
    "554455555666787878887777", -- 2022
    "554466556666788888898777", -- 2023
    "654455445556677777887766", -- 2024
    "553355455656777878887776", -- 2025
    "554355555656787878887777", -- 2026
    "554466556666788888887777", -- 2027
    "654455445556677777887766", -- 2028
    "553355455656777878887776", -- 2029
    "554355555656787878887777", -- 2030
    "554466556666788888887777", -- 2031
    "654455445556677777887766", -- 2032
    "553355455656777878887776", -- 2033
    "554355555656787878887777", -- 2034
    "554466555666787888887777", -- 2035
    "654455445556677777887766", -- 2036
    "553355455656777878887776", -- 2037
    "554355555656787878887777", -- 2038
    "554466555666787888887777", -- 2039
    "654455445556677777887766", -- 2040
    "553355455556777877887776", -- 2041
    "554355455656787878887777", -- 2042
    "554466555666787888887777", -- 2043
    "654455445556677777787766", -- 2044
    "553355445556777877887776", -- 2045
    "554355455656777878887777", -- 2046
    "554466555666787888887777", -- 2047
    "654455445555677777787666", -- 2048
    "543355445556677777887776", -- 2049
    "553355455656777878887777", -- 2050
    "554455555666787878887777", -- 2051
    "554455445555677777787666", -- 2052
    "543355445556677777887776", -- 2053
    "553355455656777878887777", -- 2054
    "554455555656787878887777", -- 2055
    "554455445555677777787666", -- 2056
    "543355445556677777887766", -- 2057
    "553355455656777878887776", -- 2058
    "554455555656787878887777", -- 2059
    "554455445555677777776666", -- 2060
    "543355445556677777887766", -- 2061
    "553355455656777878887776", -- 2062
    "554355555656787878887777", -- 2063
    "554455445555677777776666", -- 2064
    "543355445556677777887766", -- 2065
    "553355455656777878887776", -- 2066
    "554355555656787878887777", -- 2067
    "554455444555676777776666", -- 2068
    "543355445556677777887766", -- 2069
    "553355455556777877887776", -- 2070
    "554355555656787878887777", -- 2071
    "554455444555676777776666", -- 2072
    "543355445556677777787766", -- 2073
    "553355455556777877887776", -- 2074
    "554355455656777878887777", -- 2075
    "554455444555676777776666", -- 2076
    "543355445556677777787766", -- 2077
    "553355445556677877887776", -- 2078
    "554355455656777878887777", -- 2079
    "554455444555676777776666", -- 2080
    "543355445555677777787666", -- 2081
    "553355445556677777887776", -- 2082
    "553355455656777878887777", -- 2083
    "554444444555676767776666", -- 2084
    "443355445555677777787666", -- 2085
    "543355445556677777887776", -- 2086
    "553355455656777878887777", -- 2087
    "554444444545676767776666", -- 2088
    "443355445555677777787666", -- 2089
    "543355445556677777887766", -- 2090
    "553355455656777878887776", -- 2091
    "554444444545676767776666", -- 2092
    "443355445555677777776666", -- 2093
    "543355445556677777887766", -- 2094
    "553355455656777878887776", -- 2095
    "554344444545676767776666", -- 2096
    "443355445555676777776666", -- 2097
    "543355445556677777887766", -- 2098
    "553355455656777878887776", -- 2099
    "554355555656787878887777", -- 2100
}

-- Convert any UTF-8 string to Rainmeter Character Reference Variables [\xXXXX]
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
    if gYear < 2000 or gYear > 2100 then
        return { year = gYear, month = gMonth, day = gDay, isLeap = false }
    end

    local offset = toJDN(gYear, gMonth, gDay) - 2451580
    if offset < 0 then
        return { year = gYear, month = gMonth, day = gDay, isLeap = false }
    end

    local lYear = 2000
    while lYear <= 2100 do
        local info = LUNAR_INFO[lYear - 2000 + 1]
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

    if lYear > 2100 then
        return { year = gYear, month = gMonth, day = gDay, isLeap = false }
    end

    local info = LUNAR_INFO[lYear - 2000 + 1]
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

-- Solar Terms lookup for a specific Gregorian year (2000-2100)
local termsCache = {}
local function getSolarTermsForYear(Y)
    if Y < 2000 or Y > 2100 then
        return {}
    end
    if termsCache[Y] then
        return termsCache[Y]
    end
    local hexStr = SOLAR_TERMS_INFO[Y - 2000 + 1]
    local terms = {}
    for i = 1, 24 do
        local nibble = tonumber(string.sub(hexStr, i, i), 16)
        local m = math.floor((i - 1) / 2) + 1
        local d = (i % 2 == 1) and nibble or (nibble + 15)
        table.insert(terms, { name = SOLAR_TERMS_NAMES[i], month = m, day = d, year = Y })
    end
    termsCache[Y] = terms
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

function Lunar.Render(context)
    local year = context.year
    local month = context.month
    local day = context.day
    local slots = context.slots

    local lunarToday = getLunarDate(year, month, day)

    -- Heavenly Stem & Earthly Branch (天干地支)
    local stem = STEMS[(lunarToday.year - 4) % 10 + 1]
    local branch = BRANCHES[(lunarToday.year - 4) % 12 + 1]
    local yearGanZhi = stem .. branch .. "年"
    local monthStr = (lunarToday.isLeap and "闰" or "") .. LUNAR_MONTHS[lunarToday.month]
    local lunarDayStr = LUNAR_DAYS[lunarToday.day] or string.format("%02d", lunarToday.day)
    local currentSolarTerm = getCurrentSolarTerm(year, month, day)

    -- Rainmeter variables
    SKIN:Bang('!SetVariable', 'CalDayNum', toUnicode(lunarDayStr))
    SKIN:Bang('!SetVariable', 'CalMonthYear', toUnicode(yearGanZhi .. " " .. monthStr))

    -- Header Badge
    local headerText = toUnicode("SYS: CHRONO // 农历·〇")
    if SKIN:GetMeter('MeterCalHeaderText') then
        SKIN:Bang('!SetOption', 'MeterCalHeaderText', 'Text', headerText)
    end
    if SKIN:GetMeter('MeterCalHeader') then
        SKIN:Bang('!SetOption', 'MeterCalHeader', 'Text', headerText)
    end
    if SKIN:GetMeter('MeterCalMicroLabel') then
        SKIN:Bang('!SetOption', 'MeterCalMicroLabel', 'Text', 'ORBIT // LUNAR')
    end

    -- Left Panel: Day & Status
    SKIN:Bang('!SetOption', 'MeterCalDayLabel', 'Text', toUnicode("CYCLE // 星耀"))
    SKIN:Bang('!SetOption', 'MeterCalDayVal', 'FontFace', '#FontClockNum#')
    SKIN:Bang('!SetOption', 'MeterCalDayVal', 'FontSize', '28')
    SKIN:Bang('!SetOption', 'MeterCalDayVal', 'Text', toUnicode(lunarDayStr))

    -- Current Solar Term (节气)
    SKIN:Bang('!SetOption', 'MeterCalWeekCombined', 'FontFace', '#FontSub#')
    SKIN:Bang('!SetOption', 'MeterCalWeekCombined', 'FontSize', '15')
    SKIN:Bang('!SetOption', 'MeterCalWeekCombined', 'Text', toUnicode(currentSolarTerm))

    -- 天干地支 Year & Lunar Month
    SKIN:Bang('!SetOption', 'MeterCalMonthVal', 'FontFace', '#FontSub#')
    SKIN:Bang('!SetOption', 'MeterCalMonthVal', 'FontSize', '9')
    SKIN:Bang('!SetOption', 'MeterCalMonthVal', 'Text', toUnicode(yearGanZhi .. " " .. monthStr))

    -- Headers: Column 0 is 气 (Solar Term column), Columns 1..7 are Japanese Weekdays (月..日)
    local jpHeaders = { "气", "月", "火", "水", "木", "金", "土", "日" }
    for i = 0, 7 do
        SKIN:Bang('!SetOption', 'MeterCalHdr_' .. i, 'FontFace', '#FontClockNum#')
        SKIN:Bang('!SetOption', 'MeterCalHdr_' .. i, 'Text', toUnicode(jpHeaders[i + 1]))
    end

    -- Generate Columns:
    -- Column 0: Solar term in that week row, or □ if none
    -- Columns 1..7: Pure lunar dates (初一..三十)
    local colWkLunar = {}
    local colDays = { {}, {}, {}, {}, {}, {}, {} }

    for r = 1, 5 do
        local rowSolarTerm = nil
        for c = 1, 7 do
            local sIdx = (r - 1) * 7 + c
            local slot = slots[sIdx]
            if slot.current then
                local sYear = year
                local sMonth = month + slot.monthOffset
                if sMonth < 1 then
                    sMonth = 12
                    sYear = sYear - 1
                elseif sMonth > 12 then
                    sMonth = 1
                    sYear = sYear + 1
                end

                local term = getSolarTermOnDay(sYear, sMonth, slot.day)
                if term then
                    rowSolarTerm = term
                    break
                end
            end
        end

        if rowSolarTerm then
            table.insert(colWkLunar, toUnicode(rowSolarTerm))
        else
            table.insert(colWkLunar, toUnicode("·"))
        end

        for c = 1, 7 do
            local sIdx = (r - 1) * 7 + c
            local slot = slots[sIdx]
            local colStr = ""

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

                local sLunar = getLunarDate(sYear, sMonth, slot.day)
                local dayName = LUNAR_DAYS[sLunar.day] or string.format("%02d", sLunar.day)
                colStr = toUnicode(dayName)

                if slot.isToday then
                    colStr = "｢" .. colStr .. "｣"
                end
            end
            table.insert(colDays[c], toUnicode(colStr))
        end
    end

    -- Apply Column Texts
    for c = 0, 7 do
        SKIN:Bang('!SetOption', 'MeterCalCol_' .. c, 'FontFace', '#FontSub#')
        SKIN:Bang('!SetOption', 'MeterCalCol_' .. c, 'FontSize', '10')
        SKIN:Bang('!SetOption', 'MeterCalCol_' .. c, 'LineSpacing', '6')
    end
    SKIN:Bang('!SetOption', 'MeterCalCol_0', 'Text', table.concat(colWkLunar, "\n"))

    for c = 1, 7 do
        SKIN:Bang('!SetOption', 'MeterCalCol_' .. c, 'Text', table.concat(colDays[c], "\n"))
    end
end

return Lunar
