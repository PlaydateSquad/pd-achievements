# pd-achievements
Experimental cross-game achievement standard for the Playdate console.

This is essentially a reference implementation in the form of a functional library. It is not necessarily guaranteed to be robust against edge cases, but by the time of a 1.0 release it should be development ready for standard uses.

WARNING: This standard is still in development. Forward-compatibility is not yet guaranteed.

[The specification draft can be seen here.](https://docs.google.com/document/d/15iYMDmXdnDbOhoskyvfJsypu7Ls538R0kJNVYKDFx44/edit#heading=h.387me39epg7l)

# Usage
TODO: Better formalize this section once everything's been settled.

## Primary Module

To import the main library, include `achievements.lua` in your project and import it. This will create a global variable named `achievements` containing the module.

### achievements.initialize(table: config_data, bool: silent)
This function is responsible for configuring your game's metadata and valid achievements, loading local saved data, and exporting the necessary files to /Shared for other games to read your game's achievements.

This function logs relevant initialization information to the console unless the `silent` flag is set to True.

To configure your game, define a table containing the following format and pass it to this function:

```lua
local achievementData = {
    -- These fields are equivalent to the matching fields in your game's pdxinfo metadata.
    -- All are reconfigurable in case a game has multiple release editions which wish to share achievement data.
    -- They will be automatically filled in from the metadata if not defined here.
    gameID = "com.example.yourgame",
    name = "My Awesome Game",
    author = "You, Inc",
    description = "The next (r)evolution in cranking technology.",
    version = "1.0.0",
    -- Optionally, these two fields define default icons for achievements.
    defaultIcon = "icon_default",
    defaultIconLocked = "icon_locked_default",
    -- The filepath to an icon image for locked achievements which are marked as secret. Optional.
    secretIcon = "my_icon_hidden",
    achievements = {
        -- This table should be an array of achievement tables.
        -- Each of these tables stores the data for a single achievement.
        {
            -- A unique string ID for your achievement.
            id = "my_achievement",
            -- Display information for achievement viewers.
            name = "Achievement Name",
            description = "Achievement Description",
            -- Should this achievement appear in viewers if not yet earned?
            is_secret = false,
            -- The filepath to an icon image for the achievement once granted. Optional.
            icon = "my_icon",
            -- The filepath to an icon image for the achievement before it's granted. Optional.
            icon_locked = "my_icon_locked",
            -- These options, if present, handle achievements which require multiple steps to unlock.
            progress_max = 10,
            progress_is_percentage = false,
            -- This option determines how much this achievement matters towards 100%. Set to 0 for achievement to be entirely optional. Default 1.
            score_value = 3,
        },
        -- Continue configuring additional achievements as needed.
    }
}

achievements.initialize(achievementData)
```
This table makes up the top-level data structure being saved to the shared
json file. The gameID field determines the name of the folder it will
be written to, rather than bundleID, to keep things consistent.


### achievements.grant(string: achievement_id)

Grants the achievement `achievement_id` to the player. Attempting to grant a previously earned achievement does nothing.

Returns `true` if the achievement was successfully granted, otherwise `false`.

### achievements.revoke(string: achievement_id)

Revokes the achievement `achievement_id` from the player. Attempting to revoke an unearned achievement does nothing.

Returns `true` if the achievement was successfully revoked, otherwise `false`.

### achievements.advance(string: achievement_id, int: advance_by)

Increases or decreases the advancement `advancement_id`'s completion score by `advance_by`. Attempting this on an advancement without a `progress_max` set causes an error.

If the advancement's score reaches the max, calls `advancements.grant`. If it falls below the max, calls `advancements.revoke`.

Returns `true` on success, otherwise errors.

### achievements.advanceTo(string: achievement_id, int: advance_to)

Sets the advancement `advancementa_id`'s completion score to `advance_to` Attempting this on an advancement without a `progress_max` set causes an error.

If the advancement's score reaches the max, calls `advancements.grant`. If it falls below the max, calls `advancements.revoke`.

Returns `true` on success, otherwise errors. 

### achievements.save()

Saves the player's earned achievements as "Achievements.json" in your game's data, and exports the updated achievement information to /Shared.

### achievements.isGranted(string: achievement_id)

Returns `true` if the achievement has been earned by the player, returns `false` otherwise.

### `bool: achievements.forceSaveOnGrantOrRevoke`

If this flag is set to `true` then `achievements.save()` will be run every time an achievement is newly granted or revoked. Defaults to `false`.

## Crossgame Module

Adds helper functions for dealing with data written by other games.

Needs to be filled out through the development of a full reader.

### `achievements.crossgame.gamePlayed(game_id)`

Returns `true` if there is an achievement folder for the given gameID, returns `false` otherwise.

### `achievements.crossgame.listGames()`

Returns an array table containing the gameID's of all existing achievement folders.

### `achievements.crossgame.getData(game_id)`

Returns the exported achievementData of the requested game. See the type declarations in `achievements.lua` for more information.

TODO: Better document exactly what's in the standard and what parts need to be filled in by the user versus being automatically added on export.

## Toasts Module

To use toasts when achievements are granted, add `toast_graphics.lua` to your project and import it. This will create a global variable named `toast_graphics` containing the module.

There are several values which can be configured (this may break some things):

### `int: toast_graphics.displayGrantedMilliseconds`
How long should a toast animation last? Default: 2000

### `int: toast_graphics.displayGrantedDefaultX`
What X coordinate should a toast animation draw at? Default: 20

### `int: toast_graphics.displayGrantedDefaultY`
What Y coordinate should a toast animation draw at? Default: 0

### `int: toast_graphics.displayGrantedDelayNext`
How many milliseconds should pass after a toast begins before another one can begin playing? Default: 400

### `int: iconWidth`
How wide are the achievement icons? Default: 32

### `int: iconHeight`
How tall are the achievement icons? Default: 32

**[TODO]: The size of icons should really be set in the standard rather than configured here.**

### Wrappers:

`toast_graphics` provides wrappers around the following basic functions:
- `achievements.initialize` -> `toast_graphics.initialize`
- `achievements.grant`      -> `toast_graphics.grant`
- `achievements.revoke`     -> `toast_graphics.revoke`
- `achievments.isGranted`   -> `toast_graphics.isGranted`
- `achievements.save`       -> `toast_graphics.save`

When using this module, these wrappers should be used instead of the originals.


### toast_graphics.grant(string: achievement_id, function: draw_card_func)

Like `achievements.grant`, this function grants the achievement `achievement_id` to the player. It also queues up a toast for drawing. 

The new argument `draw_card_func` optionally takes a function which will be called each frame in order to draw the achievement toast to the screen. The function must take the following arguments:

- **`ach`**:  The achievement's internal data as configured during initialization.
- **`x`**: The base x coordinate the card should be drawn at.
- **`y`**: The base y coordinate the toast should be drawn at.
- **`elapsed_miliseconds`**: The amount of time which has passed since the toast began.

The function should return `true` while the animation is ongoing and `false` once it has ended.

### toast_graphics.drawCard(achievement_or_id, x, y, elapsed_msec)

Draws a card using the default toast animation at `x` and `y`, at `elapsed_msec` into the animation. `achievement_or_id` can be either a string achievement ID or an achievement's internal data. `x` and `y` default to the module's configured x/y locations. `elapsed_msec` defaults to 0.

### toast_graphics.updateVisuals()
Updates currently drawing toasts. Should be called once per frame as part of the global update loop.