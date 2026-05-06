local repoRoot = arg and arg[0] and arg[0]:match("^(.*)/tests/run%.lua$")
if repoRoot and repoRoot ~= "" then
  package.path = repoRoot .. "/?.lua;" .. package.path
end

dofile((repoRoot and repoRoot ~= "" and repoRoot .. "/" or "") .. "TickWowCore.lua")

local Core = TickWowCore
local passed = 0

local function equal(actual, expected, label)
  if actual ~= expected then
    error(string.format("%s: expected %s, got %s", label, tostring(expected), tostring(actual)), 2)
  end

  passed = passed + 1
end

equal(Core.Trim("  Pull now  "), "Pull now", "Trim removes outer whitespace")
equal(Core.Trim(nil), "", "Trim handles nil")

equal(Core.FormatDuration(0, false), "00:00", "Format zero duration")
equal(Core.FormatDuration(65, false), "01:05", "Format minute duration")
equal(Core.FormatDuration(3661, false), "1:01:01", "Format hour duration")
equal(Core.FormatDuration(65.4, true), "01:05.4", "Format tenths")
equal(Core.FormatDuration(-10, false), "00:00", "Format clamps negative")

equal(Core.ParseTimerDuration("5"), 300, "Parse bare minutes")
equal(Core.ParseTimerDuration("5m"), 300, "Parse explicit minutes")
equal(Core.ParseTimerDuration("90s"), 90, "Parse seconds")
equal(Core.ParseTimerDuration("5:00"), 300, "Parse minute colon seconds")
equal(Core.ParseTimerDuration("1:05:09"), 3909, "Parse hour colon minutes colon seconds")
equal(Core.ParseTimerDuration(""), nil, "Parse empty duration")
equal(Core.ParseTimerDuration("abc"), nil, "Parse invalid duration")

equal(Core.ReadToggleArgument("on", false), true, "Read toggle on")
equal(Core.ReadToggleArgument("off", true), false, "Read toggle off")
equal(Core.ReadToggleArgument("", true), false, "Read toggle empty flips true")
equal(Core.ReadToggleArgument("", false), true, "Read toggle empty flips false")

equal(Core.NormalizeMessage("  Pull now  ", "Timer complete."), "Pull now", "Normalize custom message")
equal(Core.NormalizeMessage("   ", "Timer complete."), "Timer complete.", "Normalize empty message")

print(string.format("ok - %d tests passed", passed))
