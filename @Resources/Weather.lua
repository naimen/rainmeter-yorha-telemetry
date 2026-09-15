-- ==============================================================================
-- YoRHa Tactical Weather Telemetry Controller (Open-Meteo API)
-- Feeds real-time meteorology, 9-bar noon-anchored chrono array & air quality
-- ==============================================================================

local isWeatherMode = false
local isHazard = false
local hasInitialWeather = false
local hasInitialAQI = false

-- ------------------------------------------------------------------------------
-- Lightweight Pure-Lua JSON Parser (Zero external dependencies)
-- ------------------------------------------------------------------------------
local function parse_json(str)
    if not str or str == "" then return nil end
    local idx = 1
    local len = #str

    local function skip_ws()
        while idx <= len do
            local b = str:byte(idx)
            if b == 32 or b == 9 or b == 10 or b == 13 then
                idx = idx + 1
            else
                break
            end
        end
    end

    local parse_val

    local function parse_obj()
        local obj = {}
        idx = idx + 1
        skip_ws()
        if idx <= len and str:byte(idx) == 125 then
            idx = idx + 1
            return obj
        end
        while idx <= len do
            skip_ws()
            if str:byte(idx) ~= 34 then break end
            local key = parse_val()
            skip_ws()
            if idx > len or str:byte(idx) ~= 58 then break end
            idx = idx + 1
            local val = parse_val()
            obj[key] = val
            skip_ws()
            if idx <= len and str:byte(idx) == 44 then
                idx = idx + 1
            elseif idx <= len and str:byte(idx) == 125 then
                idx = idx + 1
                return obj
            else
                break
            end
        end
        return obj
    end

    local function parse_arr()
        local arr = {}
        idx = idx + 1
        skip_ws()
        if idx <= len and str:byte(idx) == 93 then
            idx = idx + 1
            return arr
        end
        while idx <= len do
            local val = parse_val()
            table.insert(arr, val)
            skip_ws()
            if idx <= len and str:byte(idx) == 44 then
                idx = idx + 1
            elseif idx <= len and str:byte(idx) == 93 then
                idx = idx + 1
                return arr
            else
                break
            end
        end
        return arr
    end

    local function parse_str()
        idx = idx + 1
        local s_start = idx
        local parts = {}
        while idx <= len do
            local b = str:byte(idx)
            if b == 92 then
                if idx > s_start then
                    table.insert(parts, str:sub(s_start, idx - 1))
                end
                local esc = str:sub(idx + 1, idx + 1)
                if esc == 'n' then table.insert(parts, '\n')
                elseif esc == 'r' then table.insert(parts, '\r')
                elseif esc == 't' then table.insert(parts, '\t')
                elseif esc == '"' then table.insert(parts, '"')
                elseif esc == '\\' then table.insert(parts, '\\')
                elseif esc == '/' then table.insert(parts, '/')
                else table.insert(parts, esc) end
                idx = idx + 2
                s_start = idx
            elseif b == 34 then
                if idx > s_start then
                    table.insert(parts, str:sub(s_start, idx - 1))
                end
                idx = idx + 1
                return table.concat(parts)
            else
                idx = idx + 1
            end
        end
        return table.concat(parts)
    end

    parse_val = function()
        skip_ws()
        if idx > len then return nil end
        local b = str:byte(idx)
        if b == 123 then
            return parse_obj()
        elseif b == 91 then
            return parse_arr()
        elseif b == 34 then
            return parse_str()
        elseif b == 116 and str:sub(idx, idx + 3) == "true" then
            idx = idx + 4
            return true
        elseif b == 102 and str:sub(idx, idx + 4) == "false" then
            idx = idx + 5
            return false
        elseif b == 110 and str:sub(idx, idx + 3) == "null" then
            idx = idx + 4
            return nil
        else
            local num_str = str:match('^[%-%d%.eE%+]+', idx)
            if num_str then
                idx = idx + #num_str
                return tonumber(num_str)
            else
                idx = idx + 1
                return nil
            end
        end
    end

    return parse_val()
end

-- ------------------------------------------------------------------------------
-- Main Controller Functions
-- ------------------------------------------------------------------------------
function Initialize()
    isWeatherMode = false
    isHazard = false
    hasInitialWeather = false
    hasInitialAQI = false
end

function SetMode(mode)
    if type(mode) == "string" then
        mode = (mode == "true" or mode == "1")
    end
    isWeatherMode = mode
    if isWeatherMode then
        SKIN:Bang('!HideMeterGroup', 'GroupClock')
        SKIN:Bang('!ShowMeterGroup', 'GroupWeather')
        SKIN:Bang('!SetOption', 'MeterTapeText', 'Text', 'METEO_HUD // WX')
        SyncBiohazard()
    else
        SKIN:Bang('!HideMeterGroup', 'GroupWeather')
        SKIN:Bang('!HideMeterGroup', 'GroupBiohazard')
        SKIN:Bang('!ShowMeterGroup', 'GroupClock')
        SKIN:Bang('!SetOption', 'MeterTapeText', 'Text', 'YORHA_OS // CLK')
    end
    SKIN:Bang('!Redraw')
end

function ToggleMode()
    SetMode(not isWeatherMode)
end

function Update()
    if not hasInitialWeather then
        local mWeather = SKIN:GetMeasure('MeasureWeatherString')
        if mWeather then
            local str = mWeather:GetStringValue()
            if str and str ~= "" then
                UpdateWeather()
            end
        end
    end
    if not hasInitialAQI then
        local mAQI = SKIN:GetMeasure('MeasureAirQualityString')
        if mAQI then
            local str = mAQI:GetStringValue()
            if str and str ~= "" then
                UpdateAirQuality()
            end
        end
    end
    return 0
end

function SyncBiohazard()
    if isWeatherMode and isHazard then
        SKIN:Bang('!ShowMeterGroup', 'GroupBiohazard')
    else
        SKIN:Bang('!HideMeterGroup', 'GroupBiohazard')
    end
    SKIN:Bang('!Redraw')
end

-- Dynamic Weather Icon based on WMO Weather Code
function UpdateWeatherIcon(code)
    code = tonumber(code) or 0
    if code == 0 then
        -- 0: Pure Clear Sky (Solar Reticle)
        SKIN:Bang('!SetOption', 'MeterWeatherIcon', 'Shape', 'Ellipse 48,52,18,18 | Fill Color 0,0,0,0 | StrokeWidth 1.5 | Stroke Color #ColorPaper#')
        SKIN:Bang('!SetOption', 'MeterWeatherIcon', 'Shape2', 'Line 48,26,48,30 | StrokeWidth 1.2 | Stroke Color #ColorMuted#')
        SKIN:Bang('!SetOption', 'MeterWeatherIcon', 'Shape3', 'Line 48,74,48,78 | StrokeWidth 1.2 | Stroke Color #ColorMuted#')
        SKIN:Bang('!SetOption', 'MeterWeatherIcon', 'Shape4', 'Line 22,52,26,52 | StrokeWidth 1.2 | Stroke Color #ColorMuted#')
        SKIN:Bang('!SetOption', 'MeterWeatherIcon', 'Shape5', 'Line 70,52,74,52 | StrokeWidth 1.2 | Stroke Color #ColorMuted#')
        SKIN:Bang('!SetOption', 'MeterWeatherIcon', 'Shape6', 'Ellipse 48,52,2,2 | Fill Color #ColorPaper# | StrokeWidth 0')
        SKIN:Bang('!SetOption', 'MeterWeatherIcon', 'Shape7', 'Line 0,0,0,0 | StrokeWidth 0')
        SKIN:Bang('!SetOption', 'MeterWeatherIcon', 'Shape8', 'Line 0,0,0,0 | StrokeWidth 0')
        SKIN:Bang('!SetOption', 'MeterWeatherIcon', 'Shape9', 'Line 0,0,0,0 | StrokeWidth 0')
        SKIN:Bang('!SetOption', 'MeterWeatherIcon', 'Shape10', 'Line 0,0,0,0 | StrokeWidth 0')
    elseif code == 1 or code == 2 then
        -- 1, 2: Mainly Clear / Partly Cloudy (Sun + Cloud)
        SKIN:Bang('!SetOption', 'MeterWeatherIcon', 'Shape', 'Ellipse 42,44,14,14 | Fill Color 0,0,0,0 | StrokeWidth 1.2 | Stroke Color #ColorPaper#')
        SKIN:Bang('!SetOption', 'MeterWeatherIcon', 'Shape2', 'Line 42,24,42,27 | StrokeWidth 1 | Stroke Color #ColorMuted#')
        SKIN:Bang('!SetOption', 'MeterWeatherIcon', 'Shape3', 'Line 22,44,25,44 | StrokeWidth 1 | Stroke Color #ColorMuted#')
        SKIN:Bang('!SetOption', 'MeterWeatherIcon', 'Shape4', 'Line 28,30,30,32 | StrokeWidth 1 | Stroke Color #ColorMuted#')
        SKIN:Bang('!SetOption', 'MeterWeatherIcon', 'Shape5', 'Line 56,30,54,32 | StrokeWidth 1 | Stroke Color #ColorMuted#')
        SKIN:Bang('!SetOption', 'MeterWeatherIcon', 'Shape6', 'Line 0,0,0,0 | StrokeWidth 0')
        SKIN:Bang('!SetOption', 'MeterWeatherIcon', 'Shape7', 'Path CloudP | Fill Color #ColorBarBg# | StrokeWidth 1.2 | Stroke Color #ColorPaper#')
        SKIN:Bang('!SetOption', 'MeterWeatherIcon', 'CloudP', '32,64 | LineTo 42,64 | CurveTo 51,56,47,58 | CurveTo 64,56,57,50 | CurveTo 72,64,72,59 | LineTo 74,64 | CurveTo 74,71,78,67 | LineTo 32,71 | CurveTo 32,64,28,67 | ClosePath 1')
        SKIN:Bang('!SetOption', 'MeterWeatherIcon', 'Shape8', 'Line 0,0,0,0 | StrokeWidth 0')
        SKIN:Bang('!SetOption', 'MeterWeatherIcon', 'Shape9', 'Line 0,0,0,0 | StrokeWidth 0')
        SKIN:Bang('!SetOption', 'MeterWeatherIcon', 'Shape10', 'Line 0,0,0,0 | StrokeWidth 0')
    elseif code == 3 then
        -- 3: Overcast / Mostly Cloudy (Tactical Solar Ring peeking behind Cloud Bank)
        SKIN:Bang('!SetOption', 'MeterWeatherIcon', 'Shape', 'Ellipse 42,42,12,12 | Fill Color 0,0,0,0 | StrokeWidth 1.2 | Stroke Color #ColorPaper#')
        SKIN:Bang('!SetOption', 'MeterWeatherIcon', 'Shape2', 'Line 42,24,42,27 | StrokeWidth 1 | Stroke Color #ColorMuted#')
        SKIN:Bang('!SetOption', 'MeterWeatherIcon', 'Shape3', 'Line 24,42,27,42 | StrokeWidth 1 | Stroke Color #ColorMuted#')
        SKIN:Bang('!SetOption', 'MeterWeatherIcon', 'Shape4', 'Path CloudBack | Fill Color #ColorInnerBg# | StrokeWidth 1 | Stroke Color #ColorMutedTrans#')
        SKIN:Bang('!SetOption', 'MeterWeatherIcon', 'CloudBack', '26,52 | LineTo 36,52 | CurveTo 44,45,41,47 | CurveTo 56,45,50,40 | CurveTo 63,52,63,48 | LineTo 66,52 | CurveTo 66,58,69,55 | LineTo 26,58 | CurveTo 26,52,23,55 | ClosePath 1')
        SKIN:Bang('!SetOption', 'MeterWeatherIcon', 'Shape5', 'Line 0,0,0,0 | StrokeWidth 0')
        SKIN:Bang('!SetOption', 'MeterWeatherIcon', 'Shape6', 'Line 0,0,0,0 | StrokeWidth 0')
        SKIN:Bang('!SetOption', 'MeterWeatherIcon', 'Shape7', 'Path CloudFront | Fill Color #ColorBarBg# | StrokeWidth 1.5 | Stroke Color #ColorPaper#')
        SKIN:Bang('!SetOption', 'MeterWeatherIcon', 'CloudFront', '28,62 | LineTo 40,62 | CurveTo 50,52,45,54 | CurveTo 66,52,58,45 | CurveTo 74,62,74,56 | LineTo 76,62 | CurveTo 76,71,80,66 | LineTo 28,71 | CurveTo 28,62,24,66 | ClosePath 1')
        SKIN:Bang('!SetOption', 'MeterWeatherIcon', 'Shape8', 'Line 24,75,76,75 | StrokeWidth 1 | StrokeDashes 2,2 | Stroke Color #ColorMuted#')
        SKIN:Bang('!SetOption', 'MeterWeatherIcon', 'Shape9', 'Line 0,0,0,0 | StrokeWidth 0')
        SKIN:Bang('!SetOption', 'MeterWeatherIcon', 'Shape10', 'Line 0,0,0,0 | StrokeWidth 0')
    elseif (code >= 51 and code <= 67) or (code >= 80 and code <= 82) then
        -- Rain / Drizzle / Showers (Cloud + Technical Rain Streaks)
        SKIN:Bang('!SetOption', 'MeterWeatherIcon', 'Shape', 'Line 0,0,0,0 | StrokeWidth 0')
        SKIN:Bang('!SetOption', 'MeterWeatherIcon', 'Shape2', 'Line 0,0,0,0 | StrokeWidth 0')
        SKIN:Bang('!SetOption', 'MeterWeatherIcon', 'Shape3', 'Line 0,0,0,0 | StrokeWidth 0')
        SKIN:Bang('!SetOption', 'MeterWeatherIcon', 'Shape4', 'Line 0,0,0,0 | StrokeWidth 0')
        SKIN:Bang('!SetOption', 'MeterWeatherIcon', 'Shape5', 'Line 0,0,0,0 | StrokeWidth 0')
        SKIN:Bang('!SetOption', 'MeterWeatherIcon', 'Shape6', 'Line 0,0,0,0 | StrokeWidth 0')
        SKIN:Bang('!SetOption', 'MeterWeatherIcon', 'Shape7', 'Path RainC | Fill Color #ColorBarBg# | StrokeWidth 1.3 | Stroke Color #ColorPaper#')
        SKIN:Bang('!SetOption', 'MeterWeatherIcon', 'RainC', '28,54 | LineTo 40,54 | CurveTo 50,44,45,46 | CurveTo 66,44,58,37 | CurveTo 74,54,74,48 | LineTo 76,54 | CurveTo 76,63,80,58 | LineTo 28,63 | CurveTo 28,54,24,58 | ClosePath 1')
        SKIN:Bang('!SetOption', 'MeterWeatherIcon', 'Shape8', 'Line 36,68,33,74 | StrokeWidth 1.2 | Stroke Color #ColorPaper#')
        SKIN:Bang('!SetOption', 'MeterWeatherIcon', 'Shape9', 'Line 48,68,45,74 | StrokeWidth 1.2 | Stroke Color #ColorPaper#')
        SKIN:Bang('!SetOption', 'MeterWeatherIcon', 'Shape10', 'Line 60,68,57,74 | StrokeWidth 1.2 | Stroke Color #ColorPaper#')
    elseif (code >= 71 and code <= 77) or (code >= 85 and code <= 86) then
        -- Snow (Cloud + Tactical Crystals)
        SKIN:Bang('!SetOption', 'MeterWeatherIcon', 'Shape', 'Line 0,0,0,0 | StrokeWidth 0')
        SKIN:Bang('!SetOption', 'MeterWeatherIcon', 'Shape2', 'Line 0,0,0,0 | StrokeWidth 0')
        SKIN:Bang('!SetOption', 'MeterWeatherIcon', 'Shape3', 'Line 0,0,0,0 | StrokeWidth 0')
        SKIN:Bang('!SetOption', 'MeterWeatherIcon', 'Shape4', 'Line 0,0,0,0 | StrokeWidth 0')
        SKIN:Bang('!SetOption', 'MeterWeatherIcon', 'Shape5', 'Line 0,0,0,0 | StrokeWidth 0')
        SKIN:Bang('!SetOption', 'MeterWeatherIcon', 'Shape6', 'Line 0,0,0,0 | StrokeWidth 0')
        SKIN:Bang('!SetOption', 'MeterWeatherIcon', 'Shape7', 'Path SnowC | Fill Color #ColorBarBg# | StrokeWidth 1.3 | Stroke Color #ColorPaper#')
        SKIN:Bang('!SetOption', 'MeterWeatherIcon', 'SnowC', '28,54 | LineTo 40,54 | CurveTo 50,44,45,46 | CurveTo 66,44,58,37 | CurveTo 74,54,74,48 | LineTo 76,54 | CurveTo 76,63,80,58 | LineTo 28,63 | CurveTo 28,54,24,58 | ClosePath 1')
        SKIN:Bang('!SetOption', 'MeterWeatherIcon', 'Shape8', 'Ellipse 36,70,1.5,1.5 | Fill Color #ColorPaper# | StrokeWidth 0')
        SKIN:Bang('!SetOption', 'MeterWeatherIcon', 'Shape9', 'Ellipse 48,72,1.5,1.5 | Fill Color #ColorPaper# | StrokeWidth 0')
        SKIN:Bang('!SetOption', 'MeterWeatherIcon', 'Shape10', 'Ellipse 60,70,1.5,1.5 | Fill Color #ColorPaper# | StrokeWidth 0')
    elseif code >= 95 and code <= 99 then
        -- Thunderstorm (Cloud + Amber Lightning Bolt)
        SKIN:Bang('!SetOption', 'MeterWeatherIcon', 'Shape', 'Line 0,0,0,0 | StrokeWidth 0')
        SKIN:Bang('!SetOption', 'MeterWeatherIcon', 'Shape2', 'Line 0,0,0,0 | StrokeWidth 0')
        SKIN:Bang('!SetOption', 'MeterWeatherIcon', 'Shape3', 'Line 0,0,0,0 | StrokeWidth 0')
        SKIN:Bang('!SetOption', 'MeterWeatherIcon', 'Shape4', 'Line 0,0,0,0 | StrokeWidth 0')
        SKIN:Bang('!SetOption', 'MeterWeatherIcon', 'Shape5', 'Line 0,0,0,0 | StrokeWidth 0')
        SKIN:Bang('!SetOption', 'MeterWeatherIcon', 'Shape6', 'Line 0,0,0,0 | StrokeWidth 0')
        SKIN:Bang('!SetOption', 'MeterWeatherIcon', 'Shape7', 'Path StormC | Fill Color #ColorBarBg# | StrokeWidth 1.3 | Stroke Color #ColorPaper#')
        SKIN:Bang('!SetOption', 'MeterWeatherIcon', 'StormC', '28,54 | LineTo 40,54 | CurveTo 50,44,45,46 | CurveTo 66,44,58,37 | CurveTo 74,54,74,48 | LineTo 76,54 | CurveTo 76,63,80,58 | LineTo 28,63 | CurveTo 28,54,24,58 | ClosePath 1')
        SKIN:Bang('!SetOption', 'MeterWeatherIcon', 'Shape8', 'Path Bolt | Fill Color #ColorWarning# | StrokeWidth 0')
        SKIN:Bang('!SetOption', 'MeterWeatherIcon', 'Bolt', '52,65 | LineTo 46,72 | LineTo 50,72 | LineTo 44,79 | LineTo 54,70 | LineTo 50,70 | ClosePath 1')
        SKIN:Bang('!SetOption', 'MeterWeatherIcon', 'Shape9', 'Line 0,0,0,0 | StrokeWidth 0')
        SKIN:Bang('!SetOption', 'MeterWeatherIcon', 'Shape10', 'Line 0,0,0,0 | StrokeWidth 0')
    elseif code == 45 or code == 48 then
        -- Fog / Mist (Horizontal Technical Scan Lines)
        SKIN:Bang('!SetOption', 'MeterWeatherIcon', 'Shape', 'Line 24,42,72,42 | StrokeWidth 1.5 | Stroke Color #ColorMuted#')
        SKIN:Bang('!SetOption', 'MeterWeatherIcon', 'Shape2', 'Line 20,52,76,52 | StrokeWidth 1.5 | Stroke Color #ColorPaper#')
        SKIN:Bang('!SetOption', 'MeterWeatherIcon', 'Shape3', 'Line 26,62,70,62 | StrokeWidth 1.5 | Stroke Color #ColorMuted#')
        SKIN:Bang('!SetOption', 'MeterWeatherIcon', 'Shape4', 'Line 0,0,0,0 | StrokeWidth 0')
        SKIN:Bang('!SetOption', 'MeterWeatherIcon', 'Shape5', 'Line 0,0,0,0 | StrokeWidth 0')
        SKIN:Bang('!SetOption', 'MeterWeatherIcon', 'Shape6', 'Line 0,0,0,0 | StrokeWidth 0')
        SKIN:Bang('!SetOption', 'MeterWeatherIcon', 'Shape7', 'Line 0,0,0,0 | StrokeWidth 0')
        SKIN:Bang('!SetOption', 'MeterWeatherIcon', 'Shape8', 'Line 0,0,0,0 | StrokeWidth 0')
        SKIN:Bang('!SetOption', 'MeterWeatherIcon', 'Shape9', 'Line 0,0,0,0 | StrokeWidth 0')
        SKIN:Bang('!SetOption', 'MeterWeatherIcon', 'Shape10', 'Line 0,0,0,0 | StrokeWidth 0')
    end
    SKIN:Bang('!UpdateMeter', 'MeterWeatherIcon')
end

-- Dynamic Weather Icon for Tomorrow's Forecast
function UpdateTmrwWeatherIcon(code)
    code = tonumber(code) or 0
    if code == 0 then
        -- Clear Sky
        SKIN:Bang('!SetOption', 'MeterWeatherTmrwIcon', 'Shape', 'Ellipse 38,128,7,7 | Fill Color 0,0,0,0 | StrokeWidth 1.2 | Stroke Color #ColorPaper#')
        SKIN:Bang('!SetOption', 'MeterWeatherTmrwIcon', 'Shape2', 'Line 38,117,38,119 | StrokeWidth 1 | Stroke Color #ColorMuted#')
        SKIN:Bang('!SetOption', 'MeterWeatherTmrwIcon', 'Shape3', 'Line 38,137,38,139 | StrokeWidth 1 | Stroke Color #ColorMuted#')
        SKIN:Bang('!SetOption', 'MeterWeatherTmrwIcon', 'Shape4', 'Line 27,128,29,128 | StrokeWidth 1 | Stroke Color #ColorMuted#')
        SKIN:Bang('!SetOption', 'MeterWeatherTmrwIcon', 'Shape5', 'Line 47,128,49,128 | StrokeWidth 1 | Stroke Color #ColorMuted#')
        SKIN:Bang('!SetOption', 'MeterWeatherTmrwIcon', 'Shape6', 'Ellipse 38,128,1.5,1.5 | Fill Color #ColorPaper# | StrokeWidth 0')
        SKIN:Bang('!SetOption', 'MeterWeatherTmrwIcon', 'Shape7', 'Line 0,0,0,0 | StrokeWidth 0')
        SKIN:Bang('!SetOption', 'MeterWeatherTmrwIcon', 'Shape8', 'Line 0,0,0,0 | StrokeWidth 0')
        SKIN:Bang('!SetOption', 'MeterWeatherTmrwIcon', 'Shape9', 'Line 0,0,0,0 | StrokeWidth 0')
        SKIN:Bang('!SetOption', 'MeterWeatherTmrwIcon', 'Shape10', 'Line 0,0,0,0 | StrokeWidth 0')
    elseif code == 1 or code == 2 then
        -- Partly Cloudy
        SKIN:Bang('!SetOption', 'MeterWeatherTmrwIcon', 'Shape', 'Ellipse 34,124,5,5 | Fill Color 0,0,0,0 | StrokeWidth 1 | Stroke Color #ColorPaper#')
        SKIN:Bang('!SetOption', 'MeterWeatherTmrwIcon', 'Shape2', 'Line 34,116,34,118 | StrokeWidth 1 | Stroke Color #ColorMuted#')
        SKIN:Bang('!SetOption', 'MeterWeatherTmrwIcon', 'Shape3', 'Line 26,124,28,124 | StrokeWidth 1 | Stroke Color #ColorMuted#')
        SKIN:Bang('!SetOption', 'MeterWeatherTmrwIcon', 'Shape4', 'Line 0,0,0,0 | StrokeWidth 0')
        SKIN:Bang('!SetOption', 'MeterWeatherTmrwIcon', 'Shape5', 'Line 0,0,0,0 | StrokeWidth 0')
        SKIN:Bang('!SetOption', 'MeterWeatherTmrwIcon', 'Shape6', 'Line 0,0,0,0 | StrokeWidth 0')
        SKIN:Bang('!SetOption', 'MeterWeatherTmrwIcon', 'Shape7', 'Path TmrwCloudP | Fill Color #ColorBarBg# | StrokeWidth 1.2 | Stroke Color #ColorPaper#')
        SKIN:Bang('!SetOption', 'MeterWeatherTmrwIcon', 'TmrwCloudP', '28,133 | LineTo 34,133 | CurveTo 39,128,37,129 | CurveTo 47,128,43,124 | CurveTo 51,133,51,130 | LineTo 53,133 | CurveTo 53,138,56,135 | LineTo 28,138 | CurveTo 28,133,25,135 | ClosePath 1')
        SKIN:Bang('!SetOption', 'MeterWeatherTmrwIcon', 'Shape8', 'Line 0,0,0,0 | StrokeWidth 0')
        SKIN:Bang('!SetOption', 'MeterWeatherTmrwIcon', 'Shape9', 'Line 0,0,0,0 | StrokeWidth 0')
        SKIN:Bang('!SetOption', 'MeterWeatherTmrwIcon', 'Shape10', 'Line 0,0,0,0 | StrokeWidth 0')
    elseif code == 3 then
        -- Overcast / Mostly Cloudy (Tactical Solar Ring peeking behind Cloud)
        SKIN:Bang('!SetOption', 'MeterWeatherTmrwIcon', 'Shape', 'Ellipse 34,124,5,5 | Fill Color 0,0,0,0 | StrokeWidth 1 | Stroke Color #ColorPaper#')
        SKIN:Bang('!SetOption', 'MeterWeatherTmrwIcon', 'Shape2', 'Line 34,116,34,118 | StrokeWidth 1 | Stroke Color #ColorMuted#')
        SKIN:Bang('!SetOption', 'MeterWeatherTmrwIcon', 'Shape3', 'Line 26,124,28,124 | StrokeWidth 1 | Stroke Color #ColorMuted#')
        SKIN:Bang('!SetOption', 'MeterWeatherTmrwIcon', 'Shape4', 'Line 0,0,0,0 | StrokeWidth 0')
        SKIN:Bang('!SetOption', 'MeterWeatherTmrwIcon', 'Shape5', 'Line 0,0,0,0 | StrokeWidth 0')
        SKIN:Bang('!SetOption', 'MeterWeatherTmrwIcon', 'Shape6', 'Line 0,0,0,0 | StrokeWidth 0')
        SKIN:Bang('!SetOption', 'MeterWeatherTmrwIcon', 'Shape7', 'Path TmrwCloudFront | Fill Color #ColorBarBg# | StrokeWidth 1.3 | Stroke Color #ColorPaper#')
        SKIN:Bang('!SetOption', 'MeterWeatherTmrwIcon', 'TmrwCloudFront', '28,132 | LineTo 35,132 | CurveTo 40,127,38,128 | CurveTo 48,127,44,123 | CurveTo 52,132,52,129 | LineTo 54,132 | CurveTo 54,137,57,134 | LineTo 28,137 | CurveTo 28,132,25,134 | ClosePath 1')
        SKIN:Bang('!SetOption', 'MeterWeatherTmrwIcon', 'Shape8', 'Line 25,139,53,139 | StrokeWidth 1 | StrokeDashes 2,2 | Stroke Color #ColorMuted#')
        SKIN:Bang('!SetOption', 'MeterWeatherTmrwIcon', 'Shape9', 'Line 0,0,0,0 | StrokeWidth 0')
        SKIN:Bang('!SetOption', 'MeterWeatherTmrwIcon', 'Shape10', 'Line 0,0,0,0 | StrokeWidth 0')
    elseif (code >= 51 and code <= 67) or (code >= 80 and code <= 82) then
        -- Rain
        SKIN:Bang('!SetOption', 'MeterWeatherTmrwIcon', 'Shape', 'Line 0,0,0,0 | StrokeWidth 0')
        SKIN:Bang('!SetOption', 'MeterWeatherTmrwIcon', 'Shape2', 'Line 0,0,0,0 | StrokeWidth 0')
        SKIN:Bang('!SetOption', 'MeterWeatherTmrwIcon', 'Shape3', 'Line 0,0,0,0 | StrokeWidth 0')
        SKIN:Bang('!SetOption', 'MeterWeatherTmrwIcon', 'Shape4', 'Line 0,0,0,0 | StrokeWidth 0')
        SKIN:Bang('!SetOption', 'MeterWeatherTmrwIcon', 'Shape5', 'Line 0,0,0,0 | StrokeWidth 0')
        SKIN:Bang('!SetOption', 'MeterWeatherTmrwIcon', 'Shape6', 'Line 0,0,0,0 | StrokeWidth 0')
        SKIN:Bang('!SetOption', 'MeterWeatherTmrwIcon', 'Shape7', 'Path TmrwRainC | Fill Color #ColorBarBg# | StrokeWidth 1.2 | Stroke Color #ColorPaper#')
        SKIN:Bang('!SetOption', 'MeterWeatherTmrwIcon', 'TmrwRainC', '28,128 | LineTo 35,128 | CurveTo 40,123,38,124 | CurveTo 48,123,44,119 | CurveTo 52,128,52,125 | LineTo 54,128 | CurveTo 54,133,57,130 | LineTo 28,133 | CurveTo 28,128,25,130 | ClosePath 1')
        SKIN:Bang('!SetOption', 'MeterWeatherTmrwIcon', 'Shape8', 'Line 33,136,31,140 | StrokeWidth 1.2 | Stroke Color #ColorPaper#')
        SKIN:Bang('!SetOption', 'MeterWeatherTmrwIcon', 'Shape9', 'Line 40,136,38,140 | StrokeWidth 1.2 | Stroke Color #ColorPaper#')
        SKIN:Bang('!SetOption', 'MeterWeatherTmrwIcon', 'Shape10', 'Line 47,136,45,140 | StrokeWidth 1.2 | Stroke Color #ColorPaper#')
    elseif (code >= 71 and code <= 77) or (code >= 85 and code <= 86) then
        -- Snow
        SKIN:Bang('!SetOption', 'MeterWeatherTmrwIcon', 'Shape', 'Line 0,0,0,0 | StrokeWidth 0')
        SKIN:Bang('!SetOption', 'MeterWeatherTmrwIcon', 'Shape2', 'Line 0,0,0,0 | StrokeWidth 0')
        SKIN:Bang('!SetOption', 'MeterWeatherTmrwIcon', 'Shape3', 'Line 0,0,0,0 | StrokeWidth 0')
        SKIN:Bang('!SetOption', 'MeterWeatherTmrwIcon', 'Shape4', 'Line 0,0,0,0 | StrokeWidth 0')
        SKIN:Bang('!SetOption', 'MeterWeatherTmrwIcon', 'Shape5', 'Line 0,0,0,0 | StrokeWidth 0')
        SKIN:Bang('!SetOption', 'MeterWeatherTmrwIcon', 'Shape6', 'Line 0,0,0,0 | StrokeWidth 0')
        SKIN:Bang('!SetOption', 'MeterWeatherTmrwIcon', 'Shape7', 'Path TmrwSnowC | Fill Color #ColorBarBg# | StrokeWidth 1.2 | Stroke Color #ColorPaper#')
        SKIN:Bang('!SetOption', 'MeterWeatherTmrwIcon', 'TmrwSnowC', '28,128 | LineTo 35,128 | CurveTo 40,123,38,124 | CurveTo 48,123,44,119 | CurveTo 52,128,52,125 | LineTo 54,128 | CurveTo 54,133,57,130 | LineTo 28,133 | CurveTo 28,128,25,130 | ClosePath 1')
        SKIN:Bang('!SetOption', 'MeterWeatherTmrwIcon', 'Shape8', 'Ellipse 33,137,1,1 | Fill Color #ColorPaper# | StrokeWidth 0')
        SKIN:Bang('!SetOption', 'MeterWeatherTmrwIcon', 'Shape9', 'Ellipse 40,139,1,1 | Fill Color #ColorPaper# | StrokeWidth 0')
        SKIN:Bang('!SetOption', 'MeterWeatherTmrwIcon', 'Shape10', 'Ellipse 47,137,1,1 | Fill Color #ColorPaper# | StrokeWidth 0')
    elseif code >= 95 and code <= 99 then
        -- Thunderstorm
        SKIN:Bang('!SetOption', 'MeterWeatherTmrwIcon', 'Shape', 'Line 0,0,0,0 | StrokeWidth 0')
        SKIN:Bang('!SetOption', 'MeterWeatherTmrwIcon', 'Shape2', 'Line 0,0,0,0 | StrokeWidth 0')
        SKIN:Bang('!SetOption', 'MeterWeatherTmrwIcon', 'Shape3', 'Line 0,0,0,0 | StrokeWidth 0')
        SKIN:Bang('!SetOption', 'MeterWeatherTmrwIcon', 'Shape4', 'Line 0,0,0,0 | StrokeWidth 0')
        SKIN:Bang('!SetOption', 'MeterWeatherTmrwIcon', 'Shape5', 'Line 0,0,0,0 | StrokeWidth 0')
        SKIN:Bang('!SetOption', 'MeterWeatherTmrwIcon', 'Shape6', 'Line 0,0,0,0 | StrokeWidth 0')
        SKIN:Bang('!SetOption', 'MeterWeatherTmrwIcon', 'Shape7', 'Path TmrwStormC | Fill Color #ColorBarBg# | StrokeWidth 1.2 | Stroke Color #ColorPaper#')
        SKIN:Bang('!SetOption', 'MeterWeatherTmrwIcon', 'TmrwStormC', '28,128 | LineTo 35,128 | CurveTo 40,123,38,124 | CurveTo 48,123,44,119 | CurveTo 52,128,52,125 | LineTo 54,128 | CurveTo 54,133,57,130 | LineTo 28,133 | CurveTo 28,128,25,130 | ClosePath 1')
        SKIN:Bang('!SetOption', 'MeterWeatherTmrwIcon', 'Shape8', 'Path TmrwBolt | Fill Color #ColorWarning# | StrokeWidth 0')
        SKIN:Bang('!SetOption', 'MeterWeatherTmrwIcon', 'TmrwBolt', '42,134 | LineTo 38,139 | LineTo 41,139 | LineTo 37,144 | LineTo 44,138 | LineTo 41,138 | ClosePath 1')
        SKIN:Bang('!SetOption', 'MeterWeatherTmrwIcon', 'Shape9', 'Line 0,0,0,0 | StrokeWidth 0')
        SKIN:Bang('!SetOption', 'MeterWeatherTmrwIcon', 'Shape10', 'Line 0,0,0,0 | StrokeWidth 0')
    elseif code == 45 or code == 48 then
        -- Fog
        SKIN:Bang('!SetOption', 'MeterWeatherTmrwIcon', 'Shape', 'Line 26,122,50,122 | StrokeWidth 1.2 | Stroke Color #ColorMuted#')
        SKIN:Bang('!SetOption', 'MeterWeatherTmrwIcon', 'Shape2', 'Line 24,128,52,128 | StrokeWidth 1.2 | Stroke Color #ColorPaper#')
        SKIN:Bang('!SetOption', 'MeterWeatherTmrwIcon', 'Shape3', 'Line 27,134,49,134 | StrokeWidth 1.2 | Stroke Color #ColorMuted#')
        SKIN:Bang('!SetOption', 'MeterWeatherTmrwIcon', 'Shape4', 'Line 0,0,0,0 | StrokeWidth 0')
        SKIN:Bang('!SetOption', 'MeterWeatherTmrwIcon', 'Shape5', 'Line 0,0,0,0 | StrokeWidth 0')
        SKIN:Bang('!SetOption', 'MeterWeatherTmrwIcon', 'Shape6', 'Line 0,0,0,0 | StrokeWidth 0')
        SKIN:Bang('!SetOption', 'MeterWeatherTmrwIcon', 'Shape7', 'Line 0,0,0,0 | StrokeWidth 0')
        SKIN:Bang('!SetOption', 'MeterWeatherTmrwIcon', 'Shape8', 'Line 0,0,0,0 | StrokeWidth 0')
        SKIN:Bang('!SetOption', 'MeterWeatherTmrwIcon', 'Shape9', 'Line 0,0,0,0 | StrokeWidth 0')
        SKIN:Bang('!SetOption', 'MeterWeatherTmrwIcon', 'Shape10', 'Line 0,0,0,0 | StrokeWidth 0')
    end
    SKIN:Bang('!UpdateMeter', 'MeterWeatherTmrwIcon')
end

-- Update Main Weather, Daily Forecast & 9-Column Noon-Anchored Chrono Array
function UpdateWeather()
    local measure = SKIN:GetMeasure('MeasureWeatherString')
    if not measure then return end
    local jsonStr = measure:GetStringValue()
    if not jsonStr or jsonStr == "" then return end

    local data = parse_json(jsonStr)
    if not data or not data.current then return end
    hasInitialWeather = true

    -- 1. Current Telemetry (Numeric only, formatted via UTF-16 INI text masks)
    local rawTemp = data.current.temperature_2m or 0.0
    local curTemp = rawTemp >= 0 and math.floor(rawTemp + 0.5) or math.ceil(rawTemp - 0.5)
    local curHumid = math.floor((data.current.relative_humidity_2m or 0) + 0.5)
    local curBaro = math.floor((data.current.surface_pressure or 0) + 0.5)
    local curCode = data.current.weather_code or 0

    SKIN:Bang('!SetVariable', 'CurTemp', tostring(curTemp))
    SKIN:Bang('!SetVariable', 'HumidVal', tostring(curHumid))
    SKIN:Bang('!SetVariable', 'BaroVal', tostring(curBaro))

    -- Dynamically update weather icon to reflect current sky condition (e.g. Overcast vs Sun)
    UpdateWeatherIcon(curCode)

    -- Today's High / Low
    if data.daily and data.daily.temperature_2m_max and data.daily.temperature_2m_min then
        local todayMax = math.floor(data.daily.temperature_2m_max[1] + 0.5)
        local todayMin = math.floor(data.daily.temperature_2m_min[1] + 0.5)
        SKIN:Bang('!SetVariable', 'TodayHi', tostring(todayMax))
        SKIN:Bang('!SetVariable', 'TodayLo', tostring(todayMin))

        -- Tomorrow's Forecast
        if #data.daily.temperature_2m_max >= 2 then
            local tmrwMax = math.floor(data.daily.temperature_2m_max[2] + 0.5)
            local tmrwMin = math.floor(data.daily.temperature_2m_min[2] + 0.5)
            local tmrwPrecip = 0
            if data.daily.precipitation_probability_max and data.daily.precipitation_probability_max[2] then
                tmrwPrecip = math.floor(data.daily.precipitation_probability_max[2] + 0.5)
            end

            local tmrwCode = (data.daily.weather_code and data.daily.weather_code[2]) or 0
            local tomorrowDate = (data.daily.time and data.daily.time[2]) or ""
            if data.hourly and data.hourly.time and data.hourly.weather_code and tomorrowDate ~= "" then
                local tmrwNoon = tomorrowDate .. "T12:00"
                local tmrwAft = tomorrowDate .. "T14:00"
                for idx, tStr in ipairs(data.hourly.time) do
                    if tStr == tmrwNoon or tStr == tmrwAft then
                        if data.hourly.weather_code[idx] then
                            tmrwCode = data.hourly.weather_code[idx]
                            break
                        end
                    end
                end
            end
            UpdateTmrwWeatherIcon(tmrwCode)

            SKIN:Bang('!SetVariable', 'TmrwHi', tostring(tmrwMax))
            SKIN:Bang('!SetVariable', 'TmrwLo', tostring(tmrwMin))
            SKIN:Bang('!SetVariable', 'TmrwRain', tostring(tmrwPrecip))
        end
    end

    -- 2. 9-Column Dynamic Chrono-Array
    -- Bar 2 is anchored to Current Hour (0h)
    -- Bar 1: -1h
    -- Bar 3..9: +1h, +2h, +3h, +6h, +9h, +12h, +18h
    if data.hourly and data.hourly.time and data.hourly.temperature_2m then
        local curTimeStr = (data.current and data.current.time) or os.date("%Y-%m-%dT%H:00")
        local curHourIso = string.sub(curTimeStr, 1, 13) .. ":00"

        local curIdx = nil
        for idx, t in ipairs(data.hourly.time) do
            if string.sub(t, 1, 13) .. ":00" == curHourIso then
                curIdx = idx
                break
            end
        end
        if not curIdx then
            local curH = tonumber(os.date("%H")) or 12
            curIdx = math.min(#data.hourly.time, curH + 1)
        end

        local hourOffsets = { -1, 0, 1, 2, 3, 6, 9, 12, 18 }
        local slotIndices = {}
        local hourLabels = {}

        for i = 1, 9 do
            local off = hourOffsets[i]
            local targetIdx = curIdx + off
            if targetIdx < 1 then targetIdx = 1 end
            if targetIdx > #data.hourly.time then targetIdx = #data.hourly.time end
            slotIndices[i] = targetIdx

            local tStr = data.hourly.time[targetIdx]
            if tStr and #tStr >= 16 then
                hourLabels[i] = string.sub(tStr, 12, 16)
            else
                local h = (tonumber(os.date("%H")) or 12) + off
                while h < 0 do h = h + 24 end
                hourLabels[i] = string.format("%02d:00", h % 24)
            end
        end

        local temps = {}
        local precips = {}
        local winds = {}
        local minT = 999
        local maxT = -999
        local peakTempIdx = 2
        local maxP = -1
        local peakPrecipIdx = 2

        for i = 1, 9 do
            local idx = slotIndices[i]
            local hourLabel = hourLabels[i]
            SKIN:Bang('!SetVariable', 'ChronoTime' .. i, hourLabel)

            local t = data.hourly.temperature_2m[idx] or 15
            local p = (data.hourly.precipitation_probability and data.hourly.precipitation_probability[idx]) or 0
            local w = (data.hourly.wind_speed_10m and data.hourly.wind_speed_10m[idx]) or 10

            temps[i] = math.floor(t + 0.5)
            precips[i] = math.floor(p + 0.5)
            winds[i] = w

            if temps[i] < minT then minT = temps[i] end
            if temps[i] > maxT then
                maxT = temps[i]
                peakTempIdx = i
            end
            if precips[i] > maxP then
                maxP = precips[i]
                peakPrecipIdx = i
            end

            SKIN:Bang('!SetVariable', 'ChronoTemp' .. i, tostring(temps[i]))
        end

        -- 9 Column Centers (Spacing = 34px across X=176..448, Middle Bar 5 = 312)
        local xCols = { 176, 210, 244, 278, 312, 346, 380, 414, 448 }

        -- Temperature Trend Line Dynamic Geometry (Range Y=52..66)
        local tempRange = maxT - minT
        if tempRange < 1 then tempRange = 1 end

        local yNodes = {}
        for i = 1, 9 do
            local norm = (temps[i] - minT) / tempRange
            yNodes[i] = math.floor(66 - (norm * 14) + 0.5)
        end

        -- 8 Dashed connector lines (Shape 1..8)
        SKIN:Bang('!SetOption', 'MeterChronoTelemetryShape', 'Shape',
            string.format("Line %d,%d,%d,%d | StrokeWidth 1 | StrokeDashes 2,2 | Stroke Color #ColorMuted#", xCols[1], yNodes[1], xCols[2], yNodes[2]))
        for i = 2, 8 do
            SKIN:Bang('!SetOption', 'MeterChronoTelemetryShape', 'Shape' .. i,
                string.format("Line %d,%d,%d,%d | StrokeWidth 1 | StrokeDashes 2,2 | Stroke Color #ColorMuted#", xCols[i], yNodes[i], xCols[i+1], yNodes[i+1]))
        end

        -- 9 Dynamic Node Dots (Shape 9..17) & FontColor on Temp/Time
        for i = 1, 9 do
            local dotIdx = 8 + i
            if i == peakTempIdx then
                SKIN:Bang('!SetOption', 'MeterChronoTelemetryShape', 'Shape' .. dotIdx,
                    string.format("Ellipse %d,%d,3,3 | Fill Color #ColorWarning# | StrokeWidth 0", xCols[i], yNodes[i]))
                SKIN:Bang('!SetOption', 'MeterChronoTemp' .. i, 'FontColor', '#ColorWarning#')
                SKIN:Bang('!SetOption', 'MeterChronoTime' .. i, 'FontColor', '#ColorWarning#')
            elseif i == 2 then -- Current hour anchor dot (Bar 2)
                SKIN:Bang('!SetOption', 'MeterChronoTelemetryShape', 'Shape' .. dotIdx,
                    string.format("Ellipse %d,%d,2.5,2.5 | Fill Color #ColorAccent# | StrokeWidth 0", xCols[i], yNodes[i]))
                SKIN:Bang('!SetOption', 'MeterChronoTemp' .. i, 'FontColor', '#ColorPaper#')
                SKIN:Bang('!SetOption', 'MeterChronoTime' .. i, 'FontColor', '#ColorAccent#')
            else
                SKIN:Bang('!SetOption', 'MeterChronoTelemetryShape', 'Shape' .. dotIdx,
                    string.format("Ellipse %d,%d,2.5,2.5 | Fill Color #ColorPaper# | StrokeWidth 0", xCols[i], yNodes[i]))
                SKIN:Bang('!SetOption', 'MeterChronoTemp' .. i, 'FontColor', '#ColorPaper#')
                SKIN:Bang('!SetOption', 'MeterChronoTime' .. i, 'FontColor', '#ColorMuted#')
            end
        end

        -- 9 Reaction Micro-Gauge Columns (Boxes Shape 18..26, Fills Shape 27..35, Ticks Shape 36..44, Cap Shape 45)
        -- Shifted down: Y=74..120 (H=46px)
        SKIN:Bang('!SetOption', 'MeterChronoTelemetryShape', 'Shape45', 'Rectangle 0,0,0,0 | Fill Color 0,0,0,0 | StrokeWidth 0')

        for i = 1, 9 do
            local boxShape = 17 + i
            local fillShape = 26 + i
            local tickShape = 35 + i

            local h = math.floor((precips[i] / 100) * 42 + 0.5)
            if precips[i] > 0 and h < 2 then h = 2 end
            local baseY = 119
            local fillY = baseY - h
            local tickH = math.max(0, math.floor(h * 0.75))
            local tickY = baseY - 1 - tickH

            -- Uniform clean border across all columns, with subtle accent on Bar 2 anchor
            local boxStroke = (i == 2) and "#ColorAccent#" or "#ColorMutedTrans#"
            SKIN:Bang('!SetOption', 'MeterChronoTelemetryShape', 'Shape' .. boxShape,
                string.format("Rectangle %d,74,14,46 | Fill Color #ColorInnerBg# | StrokeWidth 1 | Stroke Color %s", xCols[i] - 7, boxStroke))
            SKIN:Bang('!SetOption', 'MeterChronoTelemetryShape', 'Shape' .. tickShape,
                string.format("Line %d,%d,%d,%d | StrokeWidth 1.5 | Stroke Color #ColorPaper#", xCols[i], baseY - 1, xCols[i], tickY))

            -- Translucent reaction column body (fill height represents precipitation %)
            local fillCol = (i == 2) and "#ColorAccent#" or "#ColorMutedTrans#"
            if h == 0 then
                SKIN:Bang('!SetOption', 'MeterChronoTelemetryShape', 'Shape' .. fillShape,
                    string.format("Rectangle %d,%d,10,1 | Fill Color %s | StrokeWidth 0", xCols[i] - 5, baseY - 1, fillCol))
            else
                SKIN:Bang('!SetOption', 'MeterChronoTelemetryShape', 'Shape' .. fillShape,
                    string.format("Rectangle %d,%d,10,%d | Fill Color %s | StrokeWidth 0", xCols[i] - 5, fillY, h, fillCol))
            end
        end

        -- Dynamic ISO Wind Symbols (No Flagpole) (Shifted to Y=128..136, Shape 46..63)
        for i = 1, 9 do
            local shapeA = 44 + 2 * i
            local shapeB = 45 + 2 * i
            local w = winds[i]
            local cx = xCols[i]

            if w < 12 then
                -- Light breeze (< 12 km/h / < ~6 kt): 1 clean horizontal line
                SKIN:Bang('!SetOption', 'MeterChronoTelemetryShape', 'Shape' .. shapeA,
                    string.format("Line %d,131,%d,131 | StrokeWidth 1.5 | Stroke Color #ColorPaper#", cx - 7, cx + 7))
                SKIN:Bang('!SetOption', 'MeterChronoTelemetryShape', 'Shape' .. shapeB,
                    "Line 0,0,0,0 | StrokeWidth 0")
            elseif w < 24 then
                -- Moderate wind (12-24 km/h / ~7-13 kt): 1 long bar + 1 short bar
                SKIN:Bang('!SetOption', 'MeterChronoTelemetryShape', 'Shape' .. shapeA,
                    string.format("Line %d,129,%d,129 | StrokeWidth 1.5 | Stroke Color #ColorPaper#", cx - 7, cx + 7))
                SKIN:Bang('!SetOption', 'MeterChronoTelemetryShape', 'Shape' .. shapeB,
                    string.format("Line %d,133,%d,133 | StrokeWidth 1.5 | Stroke Color #ColorPaper#", cx - 4, cx + 4))
            elseif w < 38 then
                -- Strong breeze (24-38 km/h / ~14-20 kt): 2 full bars
                SKIN:Bang('!SetOption', 'MeterChronoTelemetryShape', 'Shape' .. shapeA,
                    string.format("Line %d,129,%d,129 | StrokeWidth 1.5 | Stroke Color #ColorPaper#", cx - 7, cx + 7))
                SKIN:Bang('!SetOption', 'MeterChronoTelemetryShape', 'Shape' .. shapeB,
                    string.format("Line %d,133,%d,133 | StrokeWidth 1.5 | Stroke Color #ColorPaper#", cx - 7, cx + 7))
            else
                -- High wind / Gale (>= 38 km/h / >= 21 kt): Amber Pennant Triangle + Base Line
                local pName = "IsoPennant" .. i
                SKIN:Bang('!SetOption', 'MeterChronoTelemetryShape', 'Shape' .. shapeA,
                    string.format("Path %s | Fill Color #ColorWarning# | StrokeWidth 0", pName))
                SKIN:Bang('!SetOption', 'MeterChronoTelemetryShape', pName,
                    string.format("%d,132 | LineTo %d,132 | LineTo %d,125 | ClosePath 1", cx - 7, cx + 7, cx))
                SKIN:Bang('!SetOption', 'MeterChronoTelemetryShape', 'Shape' .. shapeB,
                    string.format("Line %d,135,%d,135 | StrokeWidth 1.5 | Stroke Color #ColorWarning#", cx - 7, cx + 7))
            end
        end
    end

    SKIN:Bang('!Redraw')
end

-- Update Air Quality & Pollen (Biohazard Icon Overlay)
function UpdateAirQuality()
    local measure = SKIN:GetMeasure('MeasureAirQualityString')
    if not measure then return end
    local jsonStr = measure:GetStringValue()
    if not jsonStr or jsonStr == "" then return end

    local data = parse_json(jsonStr)
    if not data or not data.current then return end
    hasInitialAQI = true

    local aqi = data.current.european_aqi or 0
    local pm25 = data.current.pm2_5 or 0.0
    local alder = data.current.alder_pollen or 0
    local birch = data.current.birch_pollen or 0
    local grass = data.current.grass_pollen or 0
    local maxPollen = math.max(alder, birch, grass)

    -- CRITICAL REQUIREMENT: Biohazard overlay is ONLY displayed when pollen or aerosol is HIGH
    isHazard = (maxPollen >= 10) or (pm25 >= 25)

    if isHazard then
        local tag = "AEROSOL: HIGH"
        if maxPollen >= 10 and pm25 >= 25 then
            tag = "POLLEN+PM2.5"
        elseif maxPollen >= 10 then
            tag = "POLLEN: HIGH"
        else
            tag = string.format("PM2.5: %.1f", pm25)
        end

        local aqiDesc = "CAUTION"
        if aqi > 100 then aqiDesc = "WARNING"
        elseif aqi > 150 then aqiDesc = "HAZARD"
        end

        SKIN:Bang('!SetVariable', 'BiohazardAerosol', tag)
        SKIN:Bang('!SetVariable', 'BiohazardAQI', tostring(aqi))
        SKIN:Bang('!SetVariable', 'BiohazardStatus', aqiDesc)
        SKIN:Bang('!SetOption', 'MeterBiohazardAerosolText', 'Text', tag)
        SKIN:Bang('!SetOption', 'MeterBiohazardDetailText', 'Text', string.format("AQI: %d [%s]", aqi, aqiDesc))
        SKIN:Bang('!UpdateMeterGroup', 'GroupBiohazard')
    end

    SyncBiohazard()
end
