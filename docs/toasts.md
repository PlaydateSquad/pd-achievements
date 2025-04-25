# Displaying Pop-ups for Earned Achievements

## The `toasts.lua` Module

The toasts module lets you notify players when they earn an achievement. An unobtrusive pop-up notification—or toast—will appear displaying the name and icon of the achievement, and can be configured to display at one of two sizes. If players earn multiple achievements in rapid succession, the module will queue them to ensure only one is shown at a time.

> NOTE: This is a reference implementation, and its use is entirely optional. You’re welcome to present notifications for earned achievements in whatever manner is most appropriate for your game. However, there is value in maintaining consistency for players so they know they've earned a Playdate Achievement, and therefore we encourage using this implementation and adjusting its configuration to suit your game.

## Sample Usage

Add `toasts.lua` to your project and import it _after_ `achievements.lua`. All its methods will be available under the global `achievements.toasts` namespace.

```lua
-- setup
import "/path/to/achievements"
import "/path/to/toasts"

-- optionally configure toasts to be displayed automatically anytime an achievement is granted
achievements.toasts.toastOnGranted = true
```

When a player earns an achievement, display a notification to let them know:

```lua
if myAchievementCondition == true then
	achievements.grant("my-achievement") -- grant the achievement
	achievements.toasts.toast("my-achievement") -- display a pop-up for the earned achievement (skip this if toastOnGranted is true)
end
```

> NOTE:
> To use toasts, ensure all of the [required assets](../achievements/assets) are included in the "achievements/assets" directory of your game. Many of these assets are also used by `viewer.lua`.

## Configuration

You can override the default configuration with custom values to adjust the appearance and behavior of toast notifications in your game. See the schema below for a full list of properties you can change.

### Example

In this example, we’ll override the defaults to tweak the appearance of toasts, and to ensure they always appear automatically any time an achievement is granted.

```lua
-- declare your config, providing just the values you wish to override
local config = {
   toastOnGrant = true, -- automatically show toasts for granted achievements
   miniMode = true, -- use tiny toasts to avoid blocking gameplay
   invert = true, -- show black cards with white text, for added contrast
   -- ...
}

-- initialize the toasts module with your custom config
achievements.toasts.initialize(config)

-- from here on out, every time you grant an achievement a toast will appear
achievements.grant("my_achievement") -- shows a toast!
```

### Schema

| key                   | type                      | description                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      |
| --------------------- | ------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `assetPath`           | `string`                  | The path to the image/sound/font [assets](../achievements/assets) required by the module. Be sure to include the trailing slash.                                                                                                                                                                                                                                                                                                                                                                                                                                 |
| `toastOnGrant`        | `bool`                    | Indicates whether toasts should be shown automatically when an achievement is granted. Defaults to `false`.                                                                                                                                                                                                                                                                                                                                                                                                                                                      |
| `toastOnAdvance`      | `bool/int`                | When `true` a toast will be shown automatically when an achievement's progress is advanced via `advanceTo()` or `advanceBy()`. When set to a number between [0-1] a toast will be shown when any achievement's progress advances past that percentage of its maximum (but has not yet been granted). <br><br> For example, if you have an achievement with `progressMax = 20` and set `toastOnAdvance` to `0.25`, a progress toast will be displayed whenever the achievement is advanced from < 5 to >= 5 (25%), from < 10 to >= 10 (50%), etc.                 |
| `toastFromTop`        | `bool`                    | When `true`, toasts will slide down from the top of the screen instead of up from the bottom. Defaults to `false`.                                                                                                                                                                                                                                                                                                                                                                                                                                               |
| `numDescriptionLines` | `int`                     | The number of lines of the achievement description to display. Defaults to `2`. Reduce to `1` if all your descriptions are short; or increase to `3` if some of your descriptions are long. Set to `0` to hide descriptions entirely. Note that mini toasts never display a description.                                                                                                                                                                                                                                                                         |
| `miniMode`            | `bool`                    | When `true`, toasts are rendered in a miniature format using a smaller font and omitting the description. Mini toasts take up substantially less space on screen, keeping more of your game visible. Note that mini toasts are forced if the display scale is greater than 1. Defaults to `false`.                                                                                                                                                                                                                                                               |
| `invert`              | `bool`                    | Inverts the color of the toast. By default, toasts are shown as a white card with black text; when `true` they will appear as a black card with white text. Note that the shadow will appear in `shadowColor` regardless. Defaults to `false`.                                                                                                                                                                                                                                                                                                                   |
| `shadowColor`         | `playdate.graphics color` | Shadows are rendered in `gfx.kColorBlack` by default. Set this to `gfx.kColorWhite` for a glow effect, or `gfx.kColorClear` to omit the shadow. Note that the shadow is never shown if the display scale is greater than 1.                                                                                                                                                                                                                                                                                                                                      |
| `soundVolume`         | `float`                   | The default audio volume for the toast's sound effects, in the range [0-1]. You can call `achievements.toasts.setSoundVolume()` later to change this (for example, if the player changes an in-game volume setting.) Defaults to `1`.                                                                                                                                                                                                                                                                                                                            |
| `gameData`            | `bool`                    | The achievement data to use. Normally you’ll set this to `nil` (or omit it) so the module will retrieve your current game's data directly from the achievements library. If you want to display toasts for _another_ game’s achievements, obtain their `gameData` using the `crossgame` module and provide it here. Defaults to `nil`                                                                                                                                                                                                                            |
| `assumeGranted`       | `bool`                    | When `true`, all achievement toasts will display as "granted" (rather than "in progress") even if the achievement itself isn't yet unlocked. Defaults to `false`.                                                                                                                                                                                                                                                                                                                                                                                                |
| `animateUnlocking`    | `bool`                    | When `true` the checkbox icon shown for granted achievements will animate to its unlocked state. Defaults to `false`.                                                                                                                                                                                                                                                                                                                                                                                                                                            |
| `renderMode`          | `auto/sprite/manual`      | An advanced setting used to define how toasts get rendered. Must be one of: <br><br> **`auto`**: Overrides `platydate.update` while a toast is displayed in order to render the toast automatically after the game's update method has finished. <br><br> **`sprite`**: Draws the toast into a `playdate.graphics.sprite` with a very high priority. <br><br> **`manual`**: You are responsible for calling `achievements.toasts.manualUpdate()` at the end of your `playdate.update` function, after everything else has rendered. <br><br> Defaults to `auto`. |

## API Reference

### achievements.toasts.initialize(`table`: _config_)

Initializes the toasts module with the provided config options according to the [configuration schema](#schema) above. Only values you wish to override defaults for need be provided. This will also preload the image and sound assets used by the module.

### achievements.toasts.toast(`string`: _achievement_id_, `table?`: _config_)

Displays a popup notification to the player containing the name, icon, and any other details about the earned achievement specified by `achievement_id`. This may be a granted achievement, or an progress achievement which hasn't yet been granted but toward which progress has been made. Note that this does not grant or update the achievement itself, so call this immediately after granting/updating the achievement. Accepts an optional `config` table to override any configuration options previously set according to the [configuration schema](#schema) above.

Returns `true` if the toast is successfully displayed, an `int` indicating its position in the queue if queued, or `false` if no such achievement exists.

### achievements.toasts.isToasting()

Returns `true` if a toast is currently displayed to the user, or `false` otherwise.

### achievements.toasts.abortToasts()

Immediately hides any displayed toast and removes any pending toasts from the queue so they will not display.

### achievements.toasts.manualUpdate()

This is only necessary when the `renderMode` configuration value is set to `"manual"`. Call this function at the _end_ of your `playdate.update` to cause any displayed toasts to render atop your game content.

### achievements.toasts.setVolume(`float`: _level_)

Sets the volume of toast sound effects to the specified `level` in the range [0-1].

### achievements.toasts.getCache()

You shouldn’t need to call this function. It is provided to enable sharing of data between the `toasts` and `viewer` modules.
