# UTPlus

A collection of mutators for UT99 to add some quality of life features.

## [UTPlus](Docs/UTPlus.md)
The main mutator that implements things like ping compensation, smoother EyeHeight algorithm, or more accurate mouse input.

## [MutAutoDemo](#Docs/MutAutoDemo.md)
A mutator that starts recording demos automatically when a match starts. Skips warmup if possible. Server can also force clients to record demos. Can be used to automatically record server-side demos.

## [MutAutoPause](#Docs/MutAutoPause.md)
A mutator that automatically pauses a match whenever a player leaves, and resumes play when the game is full again. Also delays any unpausing by a configurable number of seconds.

## [MutHitFeedback](#Docs/MutHitFeedback.md)
A mutator that provides audible feedback to player whenever they deal damage. 

## [MutHUDClock](#Docs/MutHUDClock.md)
Adds a clock to the HUD for all players.

## [MutIGEnhanced](#Docs/MutIGEnhanced.md)
A replacement for the InstaGibDM mutator. Provides a weapon with more configurable effects.

## [MutWarmup](#Docs/MutWarmup.md)
A mutator to allow play before the match starts. Provides all weapons available on the current map to player upon spawn.

## [MutXHairFactory](#Docs/MutXHairFactory.md)
A mutator to replace the default crosshair with a custom crosshair drawn from one or more layers.

## Getting Started

1. Clone this repository using `git clone https://github.com/Deaod/UTPlus.git` at the root of your UT installation
2. To build, run build.bat
3. To edit, open UTPlus.sublime-project in Sublime Text, or use your favorite text editor.
