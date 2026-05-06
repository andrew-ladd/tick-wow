# tick-wow

A clock addon for World of Warcraft Burning Crusade Classic Anniversary.

## Target Client

- Burning Crusade Classic / Classic Anniversary Edition
- Game version: 2.5.x
- AddOn interface: 20505

## Current Features

- Draggable clock frame
- Persistent position and settings
- Local or server time display
- 12-hour or 24-hour display
- Slash commands through `/tick`

## Commands

- `/tick` - show or hide the clock
- `/tick show` - show the clock
- `/tick hide` - hide the clock
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
