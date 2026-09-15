-- ==============================================================================
-- YoRHa Tactical Calendar: Standard Gregorian Branch
-- ==============================================================================

local Gregorian = {}

function Gregorian.Render(context)
    local year = context.year
    local month = context.month
    local day = context.day
    local weekNum = context.weekNum
    local monthName = context.monthName
    local slots = context.slots

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

        local rowTime = os.time{ year = rYear, month = rMonth, day = midSlot.day }
        local rowWk = tonumber(os.date("%V", rowTime)) or tonumber(os.date("%W", rowTime)) or 0
        table.insert(colWk, string.format("%02d", rowWk))

        for c = 1, 7 do
            local sIdx = (r - 1) * 7 + c
            local slot = slots[sIdx]
            local colStr = ""
            if slot.isToday then
                colStr = string.format("{%d}", slot.day)
            elseif not slot.current then
                colStr = "."
            else
                colStr = tostring(slot.day)
            end
            table.insert(colDays[c], colStr)
        end
    end

    -- Update Rainmeter variables
    SKIN:Bang('!SetVariable', 'CalWeekNum', tostring(weekNum))
    SKIN:Bang('!SetVariable', 'CalDayNum', string.format("%02d", day))
    SKIN:Bang('!SetVariable', 'CalMonthYear', monthName .. ' ' .. tostring(year))

    -- Header Badge
    local defHdr = SKIN:GetVariable('CalHeaderLabel', 'SYS: CHRONO // CAL_00')
    if SKIN:GetMeter('MeterCalHeaderText') then
        SKIN:Bang('!SetOption', 'MeterCalHeaderText', 'Text', defHdr)
    end
    if SKIN:GetMeter('MeterCalHeader') then
        SKIN:Bang('!SetOption', 'MeterCalHeader', 'Text', defHdr)
    end
    if SKIN:GetMeter('MeterCalMicroLabel') then
        SKIN:Bang('!SetOption', 'MeterCalMicroLabel', 'Text', 'ORBIT // GREGORIAN')
    end

    -- Left Panel: Day & Status
    SKIN:Bang('!SetOption', 'MeterCalDayLabel', 'Text', 'CYCLE // DAY')
    SKIN:Bang('!SetOption', 'MeterCalDayVal', 'FontFace', '#FontClockNum#')
    SKIN:Bang('!SetOption', 'MeterCalDayVal', 'FontSize', '40')
    SKIN:Bang('!SetOption', 'MeterCalDayVal', 'Text', string.format("%02d", day))

    SKIN:Bang('!SetOption', 'MeterCalWeekCombined', 'FontFace', '#FontTactical#')
    SKIN:Bang('!SetOption', 'MeterCalWeekCombined', 'FontSize', '14')
    SKIN:Bang('!SetOption', 'MeterCalWeekCombined', 'Text', 'WEEK ' .. tostring(weekNum))

    if SKIN:GetMeter('MeterCalJulianVal') then
        local julianFmt = SKIN:GetVariable('CalJulianFormat', 'JD // %s')
        local julianText = string.format(julianFmt, context.julianRoman or "")
        SKIN:Bang('!SetOption', 'MeterCalJulianVal', 'FontFace', '#FontTactical#')
        SKIN:Bang('!SetOption', 'MeterCalJulianVal', 'FontSize', '9')
        SKIN:Bang('!SetOption', 'MeterCalJulianVal', 'FontWeight', '700')
        SKIN:Bang('!SetOption', 'MeterCalJulianVal', 'FontColor', '#ColorPaper#')
        SKIN:Bang('!SetOption', 'MeterCalJulianVal', 'Text', julianText)
        SKIN:Bang('!ShowMeter', 'MeterCalJulianVal')
    end

    SKIN:Bang('!SetOption', 'MeterCalMonthVal', 'FontFace', '#FontMain#')
    SKIN:Bang('!SetOption', 'MeterCalMonthVal', 'FontSize', '8.5')
    SKIN:Bang('!SetOption', 'MeterCalMonthVal', 'Text', monthName .. ' ' .. tostring(year))

    -- Hide Ecliptic ring and Moon Phase in Gregorian mode
    if SKIN:GetMeter('MeterCalEcliptic') then
        SKIN:Bang('!HideMeter', 'MeterCalEcliptic')
    end
    if SKIN:GetMeter('MeterCalMoonPhase') then
        SKIN:Bang('!HideMeter', 'MeterCalMoonPhase')
    end

    -- English Weekday Headers
    local enHeaders = { "WK", "MO", "TU", "WE", "TH", "FR", "SA", "SU" }
    for i = 0, 7 do
        SKIN:Bang('!SetOption', 'MeterCalHdr_' .. i, 'FontFace', '#FontSub#')
        SKIN:Bang('!SetOption', 'MeterCalHdr_' .. i, 'FontSize', '10')
        SKIN:Bang('!SetOption', 'MeterCalHdr_' .. i, 'FontWeight', '700')
        if i == 0 then
            SKIN:Bang('!SetOption', 'MeterCalHdr_' .. i, 'FontColor', '#ColorMuted#')
        elseif i == 6 then
            SKIN:Bang('!SetOption', 'MeterCalHdr_' .. i, 'FontColor', '#ColorCalHdrSat#')
        elseif i == 7 then
            SKIN:Bang('!SetOption', 'MeterCalHdr_' .. i, 'FontColor', '#ColorCalHdrSun#')
        else
            SKIN:Bang('!SetOption', 'MeterCalHdr_' .. i, 'FontColor', '#ColorAccent#')
        end
        SKIN:Bang('!SetOption', 'MeterCalHdr_' .. i, 'Text', enHeaders[i + 1])
    end

    -- Rigid 5x8 Matrix Grid
    for r = 1, 5 do
        local wkMeter = string.format('MeterCal_%d_0', r)
        SKIN:Bang('!SetOption', wkMeter, 'FontFace', '#FontAnime#')
        SKIN:Bang('!SetOption', wkMeter, 'FontSize', '15')
        SKIN:Bang('!SetOption', wkMeter, 'FontWeight', '400')
        SKIN:Bang('!SetOption', wkMeter, 'FontColor', '#ColorMuted#')
        SKIN:Bang('!SetOption', wkMeter, 'Text', colWk[r])

        for c = 1, 7 do
            local cellMeter = string.format('MeterCal_%d_%d', r, c)
            local sIdx = (r - 1) * 7 + c
            local slot = slots[sIdx]
            SKIN:Bang('!SetOption', cellMeter, 'FontFace', '#FontAnime#')
            SKIN:Bang('!SetOption', cellMeter, 'FontSize', '15')
            SKIN:Bang('!SetOption', cellMeter, 'FontWeight', '400')
            if slot.isToday then
                SKIN:Bang('!SetOption', cellMeter, 'FontColor', '#ColorPaper#')
            elseif not slot.current then
                SKIN:Bang('!SetOption', cellMeter, 'FontColor', '#ColorMutedTrans#')
            elseif c == 7 then
                SKIN:Bang('!SetOption', cellMeter, 'FontColor', '#ColorCalWeekendSun#')
            elseif c == 6 then
                SKIN:Bang('!SetOption', cellMeter, 'FontColor', '#ColorCalWeekendSat#')
            else
                SKIN:Bang('!SetOption', cellMeter, 'FontColor', '#ColorPaper#')
            end
            SKIN:Bang('!SetOption', cellMeter, 'Text', colDays[c][r])
        end
    end
end

return Gregorian
