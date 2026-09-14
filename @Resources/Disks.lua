-- ==============================================================================
-- YoRHa Storage Disks Telemetry Processor
-- Translates real-time throughput strings (B/s, KB/s, MB/s, GB/s) into
-- normalized logarithmic pie chart arcs (0.0 to 1.0) calibrated to the
-- theoretical maximum IO capacity of each disk drive.
--
-- Response Curve:
--   - Idle (0 B/s)         -> 0% arc (clean dial)
--   - < 1 MB/s             -> 10% - 20% arc (visible responsive feedback)
--   - 1 MB/s to Max IO     -> 20% - 100% arc (smooth logarithmic growth to max speed)
-- ==============================================================================

local function log10(x)
    if math.log10 then
        return math.log10(x)
    else
        return math.log(x) / math.log(10)
    end
end

function Initialize()
    Update()
end

function ParseRate(str)
    if not str or str == "" then return 0 end
    local numStr, unit = string.match(str, "([%d%.,]+)%s*([%a/]+)")
    if not numStr then return 0 end
    numStr = string.gsub(numStr, ",", ".")
    local num = tonumber(numStr) or 0
    if num <= 0 then return 0 end
    if not unit then return num end

    unit = string.upper(unit)
    if string.find(unit, "T") then
        return num * 1024 * 1024
    elseif string.find(unit, "G") then
        return num * 1024
    elseif string.find(unit, "M") then
        return num
    elseif string.find(unit, "K") then
        return num / 1024
    elseif string.find(unit, "B") then
        return num / (1024 * 1024)
    end
    return num
end

function CalcArc(rateMBps, maxRateMBps)
    if rateMBps <= 0 then
        return 0
    end

    maxRateMBps = tonumber(maxRateMBps) or 500
    if maxRateMBps <= 1.0 then maxRateMBps = 500 end

    if rateMBps <= 1.0 then
        -- 0 to 1 MB/s: scale from 10% to 20% logarithmically
        local arc = 0.10 + 0.10 * log10(1 + 9 * rateMBps)
        return math.min(0.20, math.max(0.10, arc))
    else
        -- 1.0 MB/s to theoretical maximum: scale from 20% to 100% logarithmically
        local logRatio = log10(rateMBps) / log10(maxRateMBps)
        local arc = 0.20 + 0.80 * logRatio
        return math.min(1.0, math.max(0.20, arc))
    end
end

function Update()
    local d1MaxR = tonumber(SKIN:GetVariable('Disk1MaxRead', '560')) or 560
    local d1MaxW = tonumber(SKIN:GetVariable('Disk1MaxWrite', '530')) or 530
    local d2MaxR = tonumber(SKIN:GetVariable('Disk2MaxRead', '7300')) or 7300
    local d2MaxW = tonumber(SKIN:GetVariable('Disk2MaxWrite', '6600')) or 6600
    local d3MaxR = tonumber(SKIN:GetVariable('Disk3MaxRead', '220')) or 220
    local d3MaxW = tonumber(SKIN:GetVariable('Disk3MaxWrite', '220')) or 220

    local channels = {
        { measure = 'MeasureDisk1ReadStr',  target = 'MeasureDisk1ReadPie',  maxRate = d1MaxR },
        { measure = 'MeasureDisk1WriteStr', target = 'MeasureDisk1WritePie', maxRate = d1MaxW },
        { measure = 'MeasureDisk2ReadStr',  target = 'MeasureDisk2ReadPie',  maxRate = d2MaxR },
        { measure = 'MeasureDisk2WriteStr', target = 'MeasureDisk2WritePie', maxRate = d2MaxW },
        { measure = 'MeasureDisk3ReadStr',  target = 'MeasureDisk3ReadPie',  maxRate = d3MaxR },
        { measure = 'MeasureDisk3WriteStr', target = 'MeasureDisk3WritePie', maxRate = d3MaxW },
    }

    for _, ch in ipairs(channels) do
        local m = SKIN:GetMeasure(ch.measure)
        local str = m and m:GetStringValue() or ""
        local rate = ParseRate(str)
        local arc = CalcArc(rate, ch.maxRate)
        SKIN:Bang('!SetOption', ch.target, 'Formula', string.format("%.4f", arc))
        SKIN:Bang('!UpdateMeasure', ch.target)
    end
end
