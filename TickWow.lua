local addonName = ...

local DEFAULTS = {
  visible = true,
  locked = false,
  useServerTime = false,
  useTwentyFourHour = true,
  timerDurationSeconds = 300,
  timerPlaySound = true,
  timerShowAlert = true,
  timerCompleteMessage = "Timer complete.",
  point = "CENTER",
  relativePoint = "CENTER",
  x = 0,
  y = 180,
}

local Tick = {}
local frame = CreateFrame("Frame", "TickWowClockFrame", UIParent, BackdropTemplateMixin and "BackdropTemplate" or nil)
local updateFrame = CreateFrame("Frame")
local text = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
local settingsFrame
local settingsControls = {}
local stopwatchFrame
local stopwatchDisplay
local stopwatchStartButton
local timerFrame
local timerDisplay
local timerDisplayPanel
local timerInput
local timerInputChanged = false
local timerStartButton
local timerOptionsFrame
local timerOptionControls = {}
local timerMessageInput

local CLOCK_MIN_WIDTH = 96
local CLOCK_HEIGHT = 28
local CLOCK_HORIZONTAL_PADDING = 28

local stopwatch = {
  elapsed = 0,
  running = false,
  startedAt = 0,
}

local countdown = {
  remaining = DEFAULTS.timerDurationSeconds,
  running = false,
  endTime = 0,
}

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

local function FormatDuration(totalSeconds, includeTenths)
  return TickWowCore.FormatDuration(totalSeconds, includeTenths)
end

local function ParseTimerDuration(input)
  return TickWowCore.ParseTimerDuration(input)
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

local function ResizeClockFrame()
  local textWidth = text:GetStringWidth() or 0
  local frameWidth = math.max(CLOCK_MIN_WIDTH, math.ceil(textWidth) + CLOCK_HORIZONTAL_PADDING)

  frame:SetSize(frameWidth, CLOCK_HEIGHT)
end

local function UpdateClock()
  text:SetText(FormatClockTime())
  ResizeClockFrame()
end

local function UpdateSettingsControls()
  if not settingsFrame then
    return
  end

  settingsControls.visible:SetChecked(TickWowDB.visible)
  settingsControls.locked:SetChecked(TickWowDB.locked)
  settingsControls.useServerTime:SetChecked(TickWowDB.useServerTime)
  settingsControls.useTwentyFourHour:SetChecked(TickWowDB.useTwentyFourHour)
end

local function ApplyClockSettings()
  ApplyVisibility()
  ApplyLockState()
  UpdateClock()
  UpdateSettingsControls()
end

local UpdateTimerDisplay
local UpdateTimerOptionControls

local function ResetSettings()
  TickWowDB.visible = DEFAULTS.visible
  TickWowDB.locked = DEFAULTS.locked
  TickWowDB.useServerTime = DEFAULTS.useServerTime
  TickWowDB.useTwentyFourHour = DEFAULTS.useTwentyFourHour
  TickWowDB.timerDurationSeconds = DEFAULTS.timerDurationSeconds
  TickWowDB.timerPlaySound = DEFAULTS.timerPlaySound
  TickWowDB.timerShowAlert = DEFAULTS.timerShowAlert
  TickWowDB.timerCompleteMessage = DEFAULTS.timerCompleteMessage
  TickWowDB.point = DEFAULTS.point
  TickWowDB.relativePoint = DEFAULTS.relativePoint
  TickWowDB.x = DEFAULTS.x
  TickWowDB.y = DEFAULTS.y

  countdown.remaining = TickWowDB.timerDurationSeconds
  countdown.running = false
  timerInputChanged = false

  ApplyPosition()
  ApplyClockSettings()
  UpdateTimerDisplay()
  UpdateTimerOptionControls()
end

local function AddToSpecialFrames(frameName)
  if UISpecialFrames then
    tinsert(UISpecialFrames, frameName)
  end
end

local function ApplyDialogBackdrop(dialogFrame)
  if dialogFrame.SetBackdrop then
    dialogFrame:SetBackdrop({
      bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
      edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
      tile = true,
      tileSize = 32,
      edgeSize = 32,
      insets = { left = 11, right = 12, top = 12, bottom = 11 },
    })
  end
end

local function CreateDialogFrame(frameName, titleText, width, height, xOffset)
  local dialogFrame = CreateFrame("Frame", frameName, UIParent, BackdropTemplateMixin and "BackdropTemplate" or nil)
  dialogFrame:SetSize(width, height)
  dialogFrame:SetPoint("CENTER", UIParent, "CENTER", xOffset or 0, 0)
  dialogFrame:SetFrameStrata("DIALOG")
  dialogFrame:SetMovable(true)
  dialogFrame:EnableMouse(true)
  dialogFrame:RegisterForDrag("LeftButton")
  dialogFrame:SetScript("OnDragStart", function(self)
    self:StartMoving()
  end)
  dialogFrame:SetScript("OnDragStop", function(self)
    self:StopMovingOrSizing()
  end)
  dialogFrame:Hide()

  ApplyDialogBackdrop(dialogFrame)

  local title = dialogFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
  title:SetPoint("TOPLEFT", dialogFrame, "TOPLEFT", 22, -20)
  title:SetText(titleText)

  local closeButton = CreateFrame("Button", nil, dialogFrame, "UIPanelCloseButton")
  closeButton:SetPoint("TOPRIGHT", dialogFrame, "TOPRIGHT", -5, -5)

  AddToSpecialFrames(frameName)

  return dialogFrame, title
end

local function CreateUtilityFrame(frameName, titleText, width, height, xOffset)
  local utilityFrame = CreateFrame("Frame", frameName, UIParent, BackdropTemplateMixin and "BackdropTemplate" or nil)
  utilityFrame:SetSize(width, height)
  utilityFrame:SetPoint("CENTER", UIParent, "CENTER", xOffset or 0, 0)
  utilityFrame:SetFrameStrata("DIALOG")
  utilityFrame:SetMovable(true)
  utilityFrame:EnableMouse(true)
  utilityFrame:RegisterForDrag("LeftButton")
  utilityFrame:SetScript("OnDragStart", function(self)
    self:StartMoving()
  end)
  utilityFrame:SetScript("OnDragStop", function(self)
    self:StopMovingOrSizing()
  end)
  utilityFrame:Hide()

  if utilityFrame.SetBackdrop then
    utilityFrame:SetBackdrop({
      bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
      edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
      tile = true,
      tileSize = 16,
      edgeSize = 12,
      insets = { left = 3, right = 3, top = 3, bottom = 3 },
    })
    utilityFrame:SetBackdropColor(0, 0, 0, 0.8)
    utilityFrame:SetBackdropBorderColor(0.45, 0.5, 0.55, 1)
  end

  local title = utilityFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  title:SetPoint("TOP", utilityFrame, "TOP", 0, -8)
  title:SetText(titleText)

  local closeButton = CreateFrame("Button", nil, utilityFrame, "UIPanelCloseButton")
  closeButton:SetSize(22, 22)
  closeButton:SetPoint("TOPRIGHT", utilityFrame, "TOPRIGHT", -4, -4)

  AddToSpecialFrames(frameName)

  return utilityFrame, title
end

local function CreatePanelButton(parent, textValue, width)
  local button = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
  button:SetSize(width or 78, 24)
  button:SetText(textValue)

  return button
end

local function CreateCompactButton(parent, textValue)
  local button = CreateFrame("Button", nil, parent)
  button:SetSize(24, 24)

  local highlight = button:CreateTexture(nil, "HIGHLIGHT")
  highlight:SetTexture("Interface\\Buttons\\UI-Common-MouseHilight")
  highlight:SetBlendMode("ADD")
  highlight:SetAllPoints(button)
  button:SetHighlightTexture(highlight)

  return button
end

local function CreateTextureButton(parent, texturePath, size)
  local button = CreateFrame("Button", nil, parent)
  button:SetSize(size, size)
  button:SetNormalTexture(texturePath)

  local highlight = button:CreateTexture(nil, "HIGHLIGHT")
  highlight:SetTexture("Interface\\Buttons\\UI-Common-MouseHilight")
  highlight:SetBlendMode("ADD")
  highlight:SetAllPoints(button)
  button:SetHighlightTexture(highlight)

  return button
end

local function SetButtonIcon(button, iconType)
  button:SetText("")

  if iconType == "pause" then
    button:SetNormalTexture("Interface\\TimeManager\\PauseButton")
  elseif iconType == "reset" then
    button:SetNormalTexture("Interface\\TimeManager\\ResetButton")
  else
    button:SetNormalTexture("Interface\\Buttons\\UI-SpellbookIcon-NextPage-Up")
  end
end

local function FormatStopwatchTime(totalSeconds)
  totalSeconds = math.max(0, totalSeconds or 0)

  local hours = math.floor(totalSeconds / 3600)
  local minutes = math.floor((totalSeconds % 3600) / 60)
  local seconds = math.floor(totalSeconds % 60)

  return string.format("%02d:%02d:%02d", hours, minutes, seconds)
end

local function GetStopwatchElapsed()
  if stopwatch.running then
    return stopwatch.elapsed + (GetTime() - stopwatch.startedAt)
  end

  return stopwatch.elapsed
end

local function UpdateStopwatchDisplay()
  if not stopwatchDisplay then
    return
  end

  stopwatchDisplay:SetText(FormatStopwatchTime(GetStopwatchElapsed()))
  SetButtonIcon(stopwatchStartButton, stopwatch.running and "pause" or "play")
end

local function StartStopwatch()
  if stopwatch.running then
    return
  end

  stopwatch.running = true
  stopwatch.startedAt = GetTime()
  UpdateStopwatchDisplay()
end

local function PauseStopwatch()
  if not stopwatch.running then
    return
  end

  stopwatch.elapsed = GetStopwatchElapsed()
  stopwatch.running = false
  UpdateStopwatchDisplay()
end

local function ResetStopwatch()
  stopwatch.elapsed = 0
  stopwatch.running = false
  stopwatch.startedAt = 0
  UpdateStopwatchDisplay()
end

local function ToggleStopwatch()
  if stopwatch.running then
    PauseStopwatch()
  else
    StartStopwatch()
  end
end

local function CreateStopwatchFrame()
  if stopwatchFrame then
    UpdateStopwatchDisplay()
    return
  end

  local title
  stopwatchFrame, title = CreateUtilityFrame("TickWowStopwatchFrame", "Stopwatch", 188, 64, -120)

  local displayPanel = CreateFrame("Frame", nil, stopwatchFrame, BackdropTemplateMixin and "BackdropTemplate" or nil)
  displayPanel:SetSize(108, 30)
  displayPanel:SetPoint("BOTTOMLEFT", stopwatchFrame, "BOTTOMLEFT", 9, 8)
  if displayPanel.SetBackdrop then
    displayPanel:SetBackdrop({
      bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
      edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
      tile = true,
      tileSize = 16,
      edgeSize = 10,
      insets = { left = 3, right = 3, top = 3, bottom = 3 },
    })
    displayPanel:SetBackdropColor(0, 0, 0, 0.9)
    displayPanel:SetBackdropBorderColor(0.35, 0.45, 0.55, 1)
  end

  stopwatchDisplay = displayPanel:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
  stopwatchDisplay:SetPoint("CENTER", displayPanel, "CENTER", 0, 0)
  stopwatchDisplay:SetTextColor(1, 1, 1)

  stopwatchStartButton = CreateCompactButton(stopwatchFrame, "")
  stopwatchStartButton:SetPoint("LEFT", displayPanel, "RIGHT", 6, 0)
  stopwatchStartButton:SetScript("OnClick", ToggleStopwatch)

  local resetButton = CreateCompactButton(stopwatchFrame, "")
  resetButton:SetPoint("LEFT", stopwatchStartButton, "RIGHT", 4, 0)
  resetButton:SetScript("OnClick", ResetStopwatch)
  SetButtonIcon(resetButton, "reset")

  UpdateStopwatchDisplay()
end

local function ToggleStopwatchFrame()
  CreateStopwatchFrame()

  if stopwatchFrame:IsShown() then
    stopwatchFrame:Hide()
  else
    stopwatchFrame:Show()
  end
end

local function GetTimerRemaining()
  if countdown.running then
    return math.max(0, countdown.endTime - GetTime())
  end

  return countdown.remaining
end

UpdateTimerDisplay = function()
  if not timerDisplay then
    return
  end

  local remaining = GetTimerRemaining()
  if remaining > 0 then
    remaining = math.ceil(remaining)
  end

  timerDisplay:SetText(FormatDuration(remaining, false))
  SetButtonIcon(timerStartButton, countdown.running and "pause" or "play")

  if timerDisplayPanel then
    if countdown.running then
      timerDisplayPanel:Show()
    else
      timerDisplayPanel:Hide()
    end
  end

  if timerInput then
    if countdown.running then
      timerInput:Hide()
      timerInput:ClearFocus()
    else
      timerInput:Show()

      if not timerInput:HasFocus() then
        local inputSeconds = countdown.remaining > 0 and countdown.remaining or TickWowDB.timerDurationSeconds
        timerInput:SetText(FormatDuration(inputSeconds, false))
        timerInputChanged = false
      end
    end
  end
end

local function PauseTimer()
  if not countdown.running then
    return
  end

  countdown.remaining = GetTimerRemaining()
  countdown.running = false
  UpdateTimerDisplay()
end

local function StartTimer(durationSeconds)
  if durationSeconds then
    TickWowDB.timerDurationSeconds = math.max(1, math.floor(durationSeconds))
    countdown.remaining = TickWowDB.timerDurationSeconds
  end

  if countdown.remaining <= 0 then
    countdown.remaining = TickWowDB.timerDurationSeconds
  end

  countdown.running = true
  countdown.endTime = GetTime() + countdown.remaining
  timerInputChanged = false
  UpdateTimerDisplay()
end

local function ResetTimer()
  countdown.running = false
  countdown.remaining = TickWowDB.timerDurationSeconds
  timerInputChanged = false
  UpdateTimerDisplay()
end

local function ToggleTimer()
  if countdown.running then
    PauseTimer()
  else
    local duration = timerInputChanged and timerInput and ParseTimerDuration(timerInput:GetText()) or nil

    if timerInputChanged and duration then
      StartTimer(duration)
    elseif timerInputChanged then
      Print("Use a timer duration like 5, 5m, 90s, or 5:00.")
    else
      StartTimer()
    end
  end
end

local function PlayTimerCompleteSound()
  if not TickWowDB.timerPlaySound then
    return
  end

  if SOUNDKIT and SOUNDKIT.ALARM_CLOCK_WARNING_3 then
    PlaySound(SOUNDKIT.ALARM_CLOCK_WARNING_3)
  else
    pcall(PlaySound, "igMainMenuOptionCheckBoxOn")
  end
end

local function ShowTimerCompleteAlert()
  if not TickWowDB.timerShowAlert then
    return
  end

  local message = TickWowDB.timerCompleteMessage or DEFAULTS.timerCompleteMessage

  if RaidNotice_AddMessage and RaidWarningFrame and ChatTypeInfo and ChatTypeInfo.RAID_WARNING then
    RaidNotice_AddMessage(RaidWarningFrame, message, ChatTypeInfo.RAID_WARNING)
  elseif UIErrorsFrame then
    UIErrorsFrame:AddMessage(message, 1, 0.82, 0, 1)
  end
end

local function CompleteTimer()
  countdown.running = false
  countdown.remaining = 0
  UpdateTimerDisplay()
  PlayTimerCompleteSound()
  ShowTimerCompleteAlert()
  Print(TickWowDB.timerCompleteMessage or DEFAULTS.timerCompleteMessage)
end

UpdateTimerOptionControls = function()
  if not timerOptionsFrame then
    return
  end

  timerOptionControls.sound:SetChecked(TickWowDB.timerPlaySound)
  timerOptionControls.alert:SetChecked(TickWowDB.timerShowAlert)

  if timerMessageInput and not timerMessageInput:HasFocus() then
    timerMessageInput:SetText(TickWowDB.timerCompleteMessage or DEFAULTS.timerCompleteMessage)
    timerMessageInput:SetCursorPosition(0)
  end
end

local function CreateTimerOptionCheckButton(parent, key, label, anchorTo, offsetY)
  local checkButton = CreateFrame("CheckButton", nil, parent, "UICheckButtonTemplate")
  checkButton:SetPoint("TOPLEFT", anchorTo, "BOTTOMLEFT", 0, offsetY)
  checkButton:SetSize(24, 24)

  local labelText = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  labelText:SetPoint("LEFT", checkButton, "RIGHT", 6, 0)
  labelText:SetText(label)

  checkButton:SetScript("OnClick", function(self)
    TickWowDB[key] = self:GetChecked() and true or false
    UpdateTimerOptionControls()
  end)

  return checkButton
end

local function CreateTimerOptionsFrame()
  if timerOptionsFrame then
    UpdateTimerOptionControls()
    return
  end

  local title
  timerOptionsFrame, title = CreateDialogFrame("TickWowTimerOptionsFrame", "Timer Options", 360, 240, 180)

  timerOptionControls.sound = CreateTimerOptionCheckButton(
    timerOptionsFrame,
    "timerPlaySound",
    "Play sound at zero",
    title,
    -28
  )
  timerOptionControls.alert = CreateTimerOptionCheckButton(
    timerOptionsFrame,
    "timerShowAlert",
    "Show screen alert at zero",
    timerOptionControls.sound,
    -10
  )

  local messageLabel = timerOptionsFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  messageLabel:SetPoint("TOPLEFT", timerOptionControls.alert, "BOTTOMLEFT", 0, -18)
  messageLabel:SetText("Screen alert message")

  timerMessageInput = CreateFrame("EditBox", nil, timerOptionsFrame, "InputBoxTemplate")
  timerMessageInput:SetSize(270, 24)
  timerMessageInput:SetPoint("TOPLEFT", messageLabel, "BOTTOMLEFT", 6, -8)
  timerMessageInput:SetAutoFocus(false)
  timerMessageInput:SetText(TickWowDB.timerCompleteMessage or DEFAULTS.timerCompleteMessage)
  timerMessageInput:SetCursorPosition(0)
  timerMessageInput:SetScript("OnEnterPressed", function(self)
    TickWowDB.timerCompleteMessage = TickWowCore.NormalizeMessage(self:GetText(), DEFAULTS.timerCompleteMessage)
    self:ClearFocus()
    UpdateTimerOptionControls()
    Print("Timer alert message updated.")
  end)
  timerMessageInput:SetScript("OnEscapePressed", function(self)
    self:ClearFocus()
    self:SetText(TickWowDB.timerCompleteMessage or DEFAULTS.timerCompleteMessage)
    self:SetCursorPosition(0)
  end)

  local doneButton = CreatePanelButton(timerOptionsFrame, "Close", 96)
  doneButton:SetPoint("BOTTOMRIGHT", timerOptionsFrame, "BOTTOMRIGHT", -24, 24)
  doneButton:SetScript("OnClick", function()
    if timerMessageInput then
      TickWowDB.timerCompleteMessage = TickWowCore.NormalizeMessage(
        timerMessageInput:GetText(),
        DEFAULTS.timerCompleteMessage
      )
      timerMessageInput:ClearFocus()
    end

    timerOptionsFrame:Hide()
  end)

  UpdateTimerOptionControls()
end

local function ToggleTimerOptionsFrame()
  CreateTimerOptionsFrame()

  if timerOptionsFrame:IsShown() then
    timerOptionsFrame:Hide()
  else
    timerOptionsFrame:Show()
  end
end

local function CreateTimerFrame()
  if timerFrame then
    UpdateTimerDisplay()
    return
  end

  local title
  timerFrame, title = CreateUtilityFrame("TickWowTimerFrame", "Timer", 188, 64, 120)

  local optionsButton = CreateTextureButton(timerFrame, "Interface\\Buttons\\UI-OptionsButton", 18)
  optionsButton:SetPoint("TOPLEFT", timerFrame, "TOPLEFT", 5, -5)
  optionsButton:SetScript("OnClick", ToggleTimerOptionsFrame)

  timerDisplayPanel = CreateFrame("Frame", nil, timerFrame, BackdropTemplateMixin and "BackdropTemplate" or nil)
  timerDisplayPanel:SetSize(108, 30)
  timerDisplayPanel:SetPoint("BOTTOMLEFT", timerFrame, "BOTTOMLEFT", 9, 8)
  if timerDisplayPanel.SetBackdrop then
    timerDisplayPanel:SetBackdrop({
      bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
      edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
      tile = true,
      tileSize = 16,
      edgeSize = 10,
      insets = { left = 3, right = 3, top = 3, bottom = 3 },
    })
    timerDisplayPanel:SetBackdropColor(0, 0, 0, 0.9)
    timerDisplayPanel:SetBackdropBorderColor(0.35, 0.45, 0.55, 1)
  end

  timerDisplay = timerDisplayPanel:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
  timerDisplay:SetPoint("CENTER", timerDisplayPanel, "CENTER", 0, 0)
  timerDisplay:SetTextColor(1, 1, 1)

  timerInput = CreateFrame("EditBox", nil, timerFrame, "InputBoxTemplate")
  timerInput:SetSize(108, 30)
  timerInput:SetPoint("BOTTOMLEFT", timerFrame, "BOTTOMLEFT", 15, 8)
  timerInput:SetAutoFocus(false)
  timerInput:SetText(FormatDuration(TickWowDB.timerDurationSeconds, false))
  timerInput:SetCursorPosition(0)
  timerInput:SetScript("OnTextChanged", function(_, userInput)
    if userInput then
      timerInputChanged = true
    end
  end)
  timerInput:SetScript("OnEnterPressed", function(self)
    local duration = ParseTimerDuration(self:GetText())

    if duration then
      StartTimer(duration)
      self:ClearFocus()
    else
      Print("Use a timer duration like 5, 5m, 90s, or 5:00.")
    end
  end)
  timerInput:SetScript("OnEscapePressed", function(self)
    self:ClearFocus()
    self:SetText(FormatDuration(TickWowDB.timerDurationSeconds, false))
    timerInputChanged = false
  end)

  timerStartButton = CreateCompactButton(timerFrame, "")
  timerStartButton:SetPoint("LEFT", timerDisplayPanel, "RIGHT", 6, 0)
  timerStartButton:SetScript("OnClick", ToggleTimer)

  local resetButton = CreateCompactButton(timerFrame, "")
  resetButton:SetPoint("LEFT", timerStartButton, "RIGHT", 4, 0)
  resetButton:SetScript("OnClick", ResetTimer)
  SetButtonIcon(resetButton, "reset")

  UpdateTimerDisplay()
end

local function ToggleTimerFrame()
  CreateTimerFrame()

  if timerFrame:IsShown() then
    timerFrame:Hide()
  else
    timerFrame:Show()
  end
end

local function CreateCheckButton(parent, key, label, anchorTo, offsetY)
  local checkButton = CreateFrame("CheckButton", nil, parent, "UICheckButtonTemplate")
  checkButton:SetPoint("TOPLEFT", anchorTo, "BOTTOMLEFT", 0, offsetY)
  checkButton:SetSize(24, 24)

  local labelText = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  labelText:SetPoint("LEFT", checkButton, "RIGHT", 6, 0)
  labelText:SetText(label)

  checkButton:SetScript("OnClick", function(self)
    TickWowDB[key] = self:GetChecked() and true or false
    ApplyClockSettings()
  end)

  settingsControls[key] = checkButton

  return checkButton
end

local function CreateSettingsFrame()
  if settingsFrame then
    UpdateSettingsControls()
    return
  end

  settingsFrame = CreateFrame("Frame", "TickWowSettingsFrame", UIParent, BackdropTemplateMixin and "BackdropTemplate" or nil)
  settingsFrame:SetSize(320, 270)
  settingsFrame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
  settingsFrame:SetFrameStrata("DIALOG")
  settingsFrame:SetMovable(true)
  settingsFrame:EnableMouse(true)
  settingsFrame:RegisterForDrag("LeftButton")
  settingsFrame:SetScript("OnDragStart", function(self)
    self:StartMoving()
  end)
  settingsFrame:SetScript("OnDragStop", function(self)
    self:StopMovingOrSizing()
  end)
  settingsFrame:Hide()

  if settingsFrame.SetBackdrop then
    settingsFrame:SetBackdrop({
      bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
      edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
      tile = true,
      tileSize = 32,
      edgeSize = 32,
      insets = { left = 11, right = 12, top = 12, bottom = 11 },
    })
  end

  local title = settingsFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
  title:SetPoint("TOPLEFT", settingsFrame, "TOPLEFT", 22, -20)
  title:SetText("Tick Settings")

  local closeButton = CreateFrame("Button", nil, settingsFrame, "UIPanelCloseButton")
  closeButton:SetPoint("TOPRIGHT", settingsFrame, "TOPRIGHT", -5, -5)

  local visible = CreateCheckButton(settingsFrame, "visible", "Show clock", title, -24)
  local locked = CreateCheckButton(settingsFrame, "locked", "Lock clock position", visible, -8)
  local useServerTime = CreateCheckButton(settingsFrame, "useServerTime", "Use server time", locked, -8)
  local useTwentyFourHour = CreateCheckButton(settingsFrame, "useTwentyFourHour", "Use 24-hour time", useServerTime, -8)

  local buttonWidth = 112
  local buttonGap = 14
  local leftButtonX = 32
  local rightButtonX = leftButtonX + buttonWidth + buttonGap

  local stopwatchButton = CreatePanelButton(settingsFrame, "Stopwatch", buttonWidth)
  stopwatchButton:SetPoint("BOTTOMLEFT", settingsFrame, "BOTTOMLEFT", leftButtonX, 64)
  stopwatchButton:SetScript("OnClick", ToggleStopwatchFrame)

  local timerButton = CreatePanelButton(settingsFrame, "Timer", buttonWidth)
  timerButton:SetPoint("BOTTOMLEFT", settingsFrame, "BOTTOMLEFT", rightButtonX, 64)
  timerButton:SetScript("OnClick", ToggleTimerFrame)

  local resetButton = CreatePanelButton(settingsFrame, "Reset", buttonWidth)
  resetButton:SetPoint("BOTTOMLEFT", settingsFrame, "BOTTOMLEFT", leftButtonX, 28)
  resetButton:SetText("Reset")
  resetButton:SetScript("OnClick", function()
    ResetSettings()
    Print("Clock reset.")
  end)

  local doneButton = CreatePanelButton(settingsFrame, "Close", buttonWidth)
  doneButton:SetPoint("BOTTOMLEFT", settingsFrame, "BOTTOMLEFT", rightButtonX, 28)
  doneButton:SetText("Close")
  doneButton:SetScript("OnClick", function()
    settingsFrame:Hide()
  end)

  if UISpecialFrames then
    tinsert(UISpecialFrames, "TickWowSettingsFrame")
  end

  UpdateSettingsControls()
end

local function ToggleSettingsFrame()
  CreateSettingsFrame()

  if settingsFrame:IsShown() then
    settingsFrame:Hide()
  else
    settingsFrame:Show()
  end
end

local function ShowHelp()
  Print("/tick - show or hide clock settings")
  Print("/tick toggle - show or hide the clock")
  Print("/tick show - show the clock")
  Print("/tick hide - hide the clock")
  Print("/tick settings - show or hide clock settings")
  Print("/tick stopwatch - show or hide the stopwatch")
  Print("/tick timer - show or hide the countdown timer")
  Print("/tick timer options - show or hide timer options")
  Print("/tick timer sound on|off - enable or disable timer sound")
  Print("/tick timer alert on|off - enable or disable timer screen alerts")
  Print("/tick timer message <text> - set the timer screen alert message")
  Print("/tick timer 5:00 - start a 5 minute countdown")
  Print("/tick lock - lock the clock in place")
  Print("/tick unlock - allow dragging the clock")
  Print("/tick 12 - use 12-hour time")
  Print("/tick 24 - use 24-hour time")
  Print("/tick local - use your computer's local time")
  Print("/tick server - use realm server time")
  Print("/tick reset - reset position and settings")
end

local function ReadToggleArgument(argument, currentValue)
  return TickWowCore.ReadToggleArgument(argument, currentValue)
end

local function HandleSlashCommand(input)
  local command = string.lower((input or ""):match("^%s*(.-)%s*$"))
  local keyword, argument = command:match("^(%S+)%s*(.-)$")

  if command == "" then
    ToggleSettingsFrame()
  elseif command == "toggle" then
    TickWowDB.visible = not TickWowDB.visible
    ApplyClockSettings()
    Print(TickWowDB.visible and "Clock shown." or "Clock hidden.")
  elseif command == "show" then
    TickWowDB.visible = true
    ApplyClockSettings()
    Print("Clock shown.")
  elseif command == "hide" then
    TickWowDB.visible = false
    ApplyClockSettings()
    Print("Clock hidden.")
  elseif command == "settings" or command == "options" or command == "config" then
    ToggleSettingsFrame()
  elseif keyword == "stopwatch" or keyword == "sw" then
    if argument == "start" then
      CreateStopwatchFrame()
      stopwatchFrame:Show()
      StartStopwatch()
    elseif argument == "pause" or argument == "stop" then
      PauseStopwatch()
    elseif argument == "reset" then
      ResetStopwatch()
    else
      ToggleStopwatchFrame()
    end
  elseif keyword == "timer" then
    if argument == "" then
      ToggleTimerFrame()
    elseif argument == "options" or argument == "settings" or argument == "config" then
      ToggleTimerOptionsFrame()
    elseif argument == "sound" or argument:match("^sound%s+") then
      local toggleArgument = argument:match("^sound%s*(.-)$")
      TickWowDB.timerPlaySound = ReadToggleArgument(toggleArgument, TickWowDB.timerPlaySound)
      UpdateTimerOptionControls()
      Print(TickWowDB.timerPlaySound and "Timer sound enabled." or "Timer sound disabled.")
    elseif argument == "alert" or argument:match("^alert%s+") then
      local toggleArgument = argument:match("^alert%s*(.-)$")
      TickWowDB.timerShowAlert = ReadToggleArgument(toggleArgument, TickWowDB.timerShowAlert)
      UpdateTimerOptionControls()
      Print(TickWowDB.timerShowAlert and "Timer screen alert enabled." or "Timer screen alert disabled.")
    elseif argument == "message" or argument:match("^message%s+") then
      local message = argument:match("^message%s*(.-)$")
      TickWowDB.timerCompleteMessage = TickWowCore.NormalizeMessage(message, DEFAULTS.timerCompleteMessage)
      UpdateTimerOptionControls()
      Print("Timer alert message updated.")
    elseif argument == "pause" or argument == "stop" then
      PauseTimer()
    elseif argument == "reset" then
      ResetTimer()
    elseif argument == "start" then
      CreateTimerFrame()
      timerFrame:Show()
      StartTimer()
    else
      local duration = ParseTimerDuration(argument)

      if duration then
        CreateTimerFrame()
        timerFrame:Show()
        StartTimer(duration)
      else
        Print("Use a timer duration like 5, 5m, 90s, or 5:00.")
      end
    end
  elseif command == "lock" then
    TickWowDB.locked = true
    ApplyClockSettings()
    Print("Clock locked.")
  elseif command == "unlock" then
    TickWowDB.locked = false
    ApplyClockSettings()
    Print("Clock unlocked. Drag it to move.")
  elseif command == "12" then
    TickWowDB.useTwentyFourHour = false
    ApplyClockSettings()
    Print("Using 12-hour time.")
  elseif command == "24" then
    TickWowDB.useTwentyFourHour = true
    ApplyClockSettings()
    Print("Using 24-hour time.")
  elseif command == "local" then
    TickWowDB.useServerTime = false
    ApplyClockSettings()
    Print("Using local time.")
  elseif command == "server" then
    TickWowDB.useServerTime = true
    ApplyClockSettings()
    Print("Using server time.")
  elseif command == "reset" then
    ResetSettings()
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

  frame:SetSize(CLOCK_MIN_WIDTH, CLOCK_HEIGHT)
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

  countdown.remaining = TickWowDB.timerDurationSeconds
  ApplyPosition()
  ApplyClockSettings()
  CreateSettingsFrame()

  updateFrame:SetScript("OnUpdate", function(self, elapsed)
    self.elapsed = (self.elapsed or 0) + elapsed

    if self.elapsed < 0.1 then
      return
    end

    self.elapsed = 0
    UpdateClock()

    if stopwatch.running or (stopwatchFrame and stopwatchFrame:IsShown()) then
      UpdateStopwatchDisplay()
    end

    if countdown.running then
      if GetTimerRemaining() <= 0 then
        CompleteTimer()
      else
        UpdateTimerDisplay()
      end
    elseif timerFrame and timerFrame:IsShown() then
      UpdateTimerDisplay()
    end
  end)

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
