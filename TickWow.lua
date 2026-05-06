local addonName = ...

local DEFAULTS = {
  visible = true,
  locked = false,
  useServerTime = false,
  useTwentyFourHour = true,
  point = "CENTER",
  relativePoint = "CENTER",
  x = 0,
  y = 180,
}

local Tick = {}
local frame = CreateFrame("Frame", "TickWowClockFrame", UIParent, BackdropTemplateMixin and "BackdropTemplate" or nil)
local text = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")

local function CopyDefaults(target, defaults)
  for key, value in pairs(defaults) do
    if target[key] == nil then
      target[key] = value
    end
  end
end

local function Print(message)
  DEFAULT_CHAT_FRAME:AddMessage("|cff66ccffTick|r: " .. message)
end

local function FormatClockTime()
  local hour
  local minute
  local second

  if TickWowDB.useServerTime then
    hour, minute = GetGameTime()
  else
    hour = tonumber(date("%H")) or 0
    minute = tonumber(date("%M")) or 0
    second = tonumber(date("%S")) or 0
  end

  if TickWowDB.useTwentyFourHour then
    if TickWowDB.useServerTime then
      return string.format("%02d:%02d", hour, minute)
    end

    return string.format("%02d:%02d:%02d", hour, minute, second)
  end

  local suffix = hour >= 12 and "PM" or "AM"
  local displayHour = hour % 12
  if displayHour == 0 then
    displayHour = 12
  end

  if TickWowDB.useServerTime then
    return string.format("%d:%02d %s", displayHour, minute, suffix)
  end

  return string.format("%d:%02d:%02d %s", displayHour, minute, second, suffix)
end

local function SavePosition()
  local point, _, relativePoint, x, y = frame:GetPoint(1)
  TickWowDB.point = point or DEFAULTS.point
  TickWowDB.relativePoint = relativePoint or DEFAULTS.relativePoint
  TickWowDB.x = x or DEFAULTS.x
  TickWowDB.y = y or DEFAULTS.y
end

local function ApplyPosition()
  frame:ClearAllPoints()
  frame:SetPoint(
    TickWowDB.point or DEFAULTS.point,
    UIParent,
    TickWowDB.relativePoint or DEFAULTS.relativePoint,
    TickWowDB.x or DEFAULTS.x,
    TickWowDB.y or DEFAULTS.y
  )
end

local function ApplyVisibility()
  if TickWowDB.visible then
    frame:Show()
  else
    frame:Hide()
  end
end

local function ApplyLockState()
  frame:EnableMouse(not TickWowDB.locked)
end

local function UpdateClock()
  text:SetText(FormatClockTime())
end

local function ShowHelp()
  Print("/tick - show or hide the clock")
  Print("/tick show - show the clock")
  Print("/tick hide - hide the clock")
  Print("/tick lock - lock the clock in place")
  Print("/tick unlock - allow dragging the clock")
  Print("/tick 12 - use 12-hour time")
  Print("/tick 24 - use 24-hour time")
  Print("/tick local - use your computer's local time")
  Print("/tick server - use realm server time")
  Print("/tick reset - reset position and settings")
end

local function HandleSlashCommand(input)
  local command = string.lower((input or ""):match("^%s*(.-)%s*$"))

  if command == "" or command == "toggle" then
    TickWowDB.visible = not TickWowDB.visible
    ApplyVisibility()
    Print(TickWowDB.visible and "Clock shown." or "Clock hidden.")
  elseif command == "show" then
    TickWowDB.visible = true
    ApplyVisibility()
    Print("Clock shown.")
  elseif command == "hide" then
    TickWowDB.visible = false
    ApplyVisibility()
    Print("Clock hidden.")
  elseif command == "lock" then
    TickWowDB.locked = true
    ApplyLockState()
    Print("Clock locked.")
  elseif command == "unlock" then
    TickWowDB.locked = false
    ApplyLockState()
    Print("Clock unlocked. Drag it to move.")
  elseif command == "12" then
    TickWowDB.useTwentyFourHour = false
    UpdateClock()
    Print("Using 12-hour time.")
  elseif command == "24" then
    TickWowDB.useTwentyFourHour = true
    UpdateClock()
    Print("Using 24-hour time.")
  elseif command == "local" then
    TickWowDB.useServerTime = false
    UpdateClock()
    Print("Using local time.")
  elseif command == "server" then
    TickWowDB.useServerTime = true
    UpdateClock()
    Print("Using server time.")
  elseif command == "reset" then
    TickWowDB.visible = DEFAULTS.visible
    TickWowDB.locked = DEFAULTS.locked
    TickWowDB.useServerTime = DEFAULTS.useServerTime
    TickWowDB.useTwentyFourHour = DEFAULTS.useTwentyFourHour
    TickWowDB.point = DEFAULTS.point
    TickWowDB.relativePoint = DEFAULTS.relativePoint
    TickWowDB.x = DEFAULTS.x
    TickWowDB.y = DEFAULTS.y
    ApplyPosition()
    ApplyVisibility()
    ApplyLockState()
    UpdateClock()
    Print("Clock reset.")
  elseif command == "help" then
    ShowHelp()
  else
    ShowHelp()
  end
end

function Tick:Initialize()
  TickWowDB = TickWowDB or {}
  CopyDefaults(TickWowDB, DEFAULTS)

  frame:SetSize(96, 28)
  frame:SetMovable(true)
  frame:RegisterForDrag("LeftButton")
  frame:SetClampedToScreen(true)
  if frame.SetBackdrop then
    frame:SetBackdrop({
      bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
      edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
      tile = true,
      tileSize = 16,
      edgeSize = 12,
      insets = { left = 3, right = 3, top = 3, bottom = 3 },
    })
    frame:SetBackdropColor(0, 0, 0, 0.65)
    frame:SetBackdropBorderColor(0.35, 0.45, 0.55, 0.9)
  end

  text:SetPoint("CENTER", frame, "CENTER", 0, 0)
  text:SetTextColor(1, 0.85, 0.35)

  frame:SetScript("OnDragStart", function(self)
    if not TickWowDB.locked then
      self:StartMoving()
    end
  end)

  frame:SetScript("OnDragStop", function(self)
    self:StopMovingOrSizing()
    SavePosition()
  end)

  frame:SetScript("OnUpdate", function(self, elapsed)
    self.elapsed = (self.elapsed or 0) + elapsed
    if self.elapsed >= 0.25 then
      self.elapsed = 0
      UpdateClock()
    end
  end)

  ApplyPosition()
  ApplyVisibility()
  ApplyLockState()
  UpdateClock()

  SLASH_TICKWOW1 = "/tick"
  SlashCmdList.TICKWOW = HandleSlashCommand
end

local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:SetScript("OnEvent", function(self, _, loadedAddonName)
  if loadedAddonName == addonName then
    self:UnregisterEvent("ADDON_LOADED")
    Tick:Initialize()
  end
end)
