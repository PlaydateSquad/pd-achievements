# Showing an In-game Achievements Viewer

## The `viewer.lua` Module

The viewer module lets you present all the achievements in your game to the player. When launched, the viewer appears as a modal overlay and temporarily blocks updates and input to your game. Players can scroll through a list of all available achievements, see which they've earned or made progress towards, and exit when finished to return to your game.

> NOTE: This is a reference implementation, and its use is entirely optional. You’re welcome to present achievements to players in whatever manner is most appropriate for your game.

## Sample Usage

Add `viewer.lua` to your project and import it _after_ `achievements.lua`. All its methods will be available under the global `achievements.viewer` namespace.

```lua
-- setup
import "/path/to/achievements"
import "/path/to/viewer"
```

When you're ready to present the viewer, such as in response to a menu selection:

```lua
achievements.viewer.launch()
```

> NOTE:
> To use the viewer, ensure all of the [required assets]("./assets") are included in the "achievements/assets" directory of your game. Many of these assets are also used by `toasts.lua`.

## Configuration

You can override the default configuration with custom values to adjust the appearance and behavior of the in-game viewer. See the schema below for a full list of properties you can change.

### Example

In this example, we’ll override the defaults to tweak the appearance of the viewer.

```lua
-- initialize, optionally providing a table with config values you wish to override
achievements.viewer.initialize({
   numDescriptionLines = 1, -- for shorter descriptions
   summaryMode = "percent", -- summarize progress as completion percentage
   -- ...
})

-- in response to some user action, such as selecting a menu option
achievements.viewer.launch()
```

### Schema

| key                    | type                           | description                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                               |
| ---------------------- | ------------------------------ | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `assetPath`            | `string`                       | The path to the image/sound/font [assets]("./assets") required by the module. Be sure to include the trailing slash.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      |
| `numDescriptionLines`  | `int`                          | The number of lines of the achievement description to display. Defaults to `2`. Reduce to `1` if all your descriptions are short; or increase to `3` if some of your descriptions are long. Set to `0` to hide descriptions entirely.                                                                                                                                                                                                                                                                                                                                                                                                                                     |
| `fadeColor`            | `playdata.graphics.color`      | The color to fade the background when the viewer launches. You can set this to `kColorWhite` if your game is mostly dark, or `kColorClear` to prevent a background fade.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  |
| `enableAboutScreen`    | `bool`                         | When `true` the player will have the option to display an about screen with a QR code to learn more about Playdate Achievements.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                          |
| `invertCards`          | `bool`                         | When `true` the viewer appearance is inverted to display white headers and black cards. (Achievement icons will display normally and won’t be inverted.)                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  |
| `soundVolume`          | `float`                        | The default audio volume for the viewer’s sound effects, in the range [0-1]. You can call `achievements.viewer.setSoundVolume()` later to change this (for example, if the player changes an in-game volume setting.) Defaults to `1`.                                                                                                                                                                                                                                                                                                                                                                                                                                    |
| `sortOrder`            | `default/recent/progress/name` | The default sort order for the achievements, which may be changed by the player via the d-pad. Must be one of:<br><br>**`default`**: Display in the order the achievements are defined in the game’s `achievementData`.<br><br>**`recent`**:" Show the most recently earned achievements first, followed by locked achievements in the order they are defined.<br><br>**`progress`**: Show locked in-progress achievements first beginning with the closest to completion; then other locked achievements in definition order; then granted achievements in definition order.<br><br>**`name`**: Sort alphabetically by achievement name.<br><br>Defaults to `"default"`. |
| `summaryMode`          | `count/percent/score/none`     | Determines how achievements are summarized in the header. Must be one of:<br><br>**`count`**: Display a the number of unlocked achievements out of the total number (including optional ones).<br><br>**`percent`**: Display a percentage completion, weighted by the `scoreValue` for each achievement.<br><br>**`score`**: Display the raw `scoreValue` earned out of the possible total.<br><br>**`none`**: Omit the summary<br><br>Defaults to `"count"`.                                                                                                                                                                                                             |
| `disableBackground`    | `bool`                         | Set this to `true` to prevent static captured background image from your game from appearing behind the viewer. You are responsible for setting an `updateFunction` and drawing something behind the viewer yourself.                                                                                                                                                                                                                                                                                                                                                                                                                                                     |
| `gameData`             | `bool`                         | The achievement data to display. Normally you’ll set this to `nil` (or omit it) so the module will retrieve your current game's data directly from the achievements library. If you want to display toasts for _another_ game’s achievements, obtain their `gameData` using the `crossgame` module and provide it here. Defaults to `nil`                                                                                                                                                                                                                                                                                                                                 |
| `updateFunction`       | `function(fade)`               | If provided, this function will be called every frame in which the viewer is visible and before the viewer itself draws. The `fade` parameter is an `int` in the range [0-1] that begins at 0, increases to 1 as the viewer fades in, remains 1 while displayed, and decreases to 0 again as it fades out.                                                                                                                                                                                                                                                                                                                                                                |
| `returnToGameFunction` | `function()`                   | If provided, this function will be called when the viewewr transfers control back to your game.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                           |

## API Reference

### achievements.viewer.initialize(`table`: _config_)

…

### achievements.viewer.launch(`table?`: _config_)

…

### achievements.viewer.forceExit()

…

### achievements.viewer.hasLaunched()

…

### achievements.viewer.setVolume(`float`: _level_)

…

### achievements.viewer.getCache()

…
