TickWowCore = TickWowCore or {}

local Core = TickWowCore

function Core.Trim(value)
  return (value or ""):match("^%s*(.-)%s*$")
end

function Core.FormatDuration(totalSeconds, includeTenths)
  totalSeconds = math.max(0, totalSeconds or 0)

  local hours = math.floor(totalSeconds / 3600)
  local minutes = math.floor((totalSeconds % 3600) / 60)

  if includeTenths then
    local seconds = totalSeconds % 60

    if hours > 0 then
      return string.format("%d:%02d:%04.1f", hours, minutes, seconds)
    end

    return string.format("%02d:%04.1f", minutes, seconds)
  end

  local seconds = math.floor(totalSeconds % 60)

  if hours > 0 then
    return string.format("%d:%02d:%02d", hours, minutes, seconds)
  end

  return string.format("%02d:%02d", minutes, seconds)
end

function Core.ParseTimerDuration(input)
  local value = Core.Trim(input):lower()

  if value == "" then
    return nil
  end

  local minutes, seconds = value:match("^(%d+):(%d%d?)$")
  if minutes and seconds then
    return (tonumber(minutes) * 60) + tonumber(seconds)
  end

  local hours, colonMinutes, colonSeconds = value:match("^(%d+):(%d%d):(%d%d?)$")
  if hours and colonMinutes and colonSeconds then
    return (tonumber(hours) * 3600) + (tonumber(colonMinutes) * 60) + tonumber(colonSeconds)
  end

  local secondValue = value:match("^(%d+)%s*s$")
  if secondValue then
    return tonumber(secondValue)
  end

  local minuteValue = value:match("^(%d+)%s*m?$")
  if minuteValue then
    return tonumber(minuteValue) * 60
  end

  return nil
end

function Core.ReadToggleArgument(argument, currentValue)
  local value = Core.Trim(argument):lower()

  if value == "on" or value == "enable" or value == "enabled" then
    return true
  elseif value == "off" or value == "disable" or value == "disabled" then
    return false
  end

  return not currentValue
end

function Core.NormalizeMessage(message, defaultMessage)
  local normalized = Core.Trim(message)

  if normalized == "" then
    return defaultMessage
  end

  return normalized
end
