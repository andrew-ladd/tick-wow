# tick-wow

A clock addon for World of Warcraft Burning Crusade Classic Anniversary.

## Target Client

- Burning Crusade Classic / Classic Anniversary Edition
- Game version: 2.5.x
- AddOn interface: 20505

## Current Features

- Draggable clock frame
- Settings window
- Stopwatch window
- Countdown timer window
- Timer sound and screen alert options
- Persistent position and settings
- Local or server time display
- 12-hour or 24-hour display
- Slash commands through `/tick`

## Commands

- `/tick` - show or hide clock settings
- `/tick toggle` - show or hide the clock
- `/tick show` - show the clock
- `/tick hide` - hide the clock
- `/tick settings` - show or hide clock settings
- `/tick stopwatch` - show or hide the stopwatch
- `/tick stopwatch start` - start the stopwatch
- `/tick stopwatch pause` - pause the stopwatch
- `/tick stopwatch reset` - reset the stopwatch
- `/tick timer` - show or hide the countdown timer
- `/tick timer options` - show or hide timer options
- `/tick timer sound on` - enable timer completion sound
- `/tick timer sound off` - disable timer completion sound
- `/tick timer alert on` - enable timer completion screen alerts
- `/tick timer alert off` - disable timer completion screen alerts
- `/tick timer message Pull now` - set the timer screen alert message
- `/tick timer 5` - start a 5 minute countdown
- `/tick timer 5:00` - start a 5 minute countdown
- `/tick timer 90s` - start a 90 second countdown
- `/tick timer pause` - pause the countdown timer
- `/tick timer reset` - reset the countdown timer
- `/tick lock` - lock the clock in place
- `/tick unlock` - allow dragging the clock
- `/tick 12` - use 12-hour time
- `/tick 24` - use 24-hour time
- `/tick local` - use your computer's local time
- `/tick server` - use realm server time
- `/tick reset` - reset position and settings

## Development Notes

Install the addon folder as `tick-wow` so the client can load `tick-wow_TBC.toc`.
The base `tick-wow.toc` is included as a fallback for tooling or clients that do not select the TBC-specific TOC.

## Tests

Run the Lua unit tests with:

```sh
lua tests/run.lua
```

Run a syntax check with:

```sh
luac -p TickWowCore.lua TickWow.lua
```
