# achievements.lua
This module is responsible for tracking and saving achievement progress for your game. Can be used as a standalone library, or in congruence with [toasts.lua](toasts.md) or [viewer.lua](viewer.md)

## Getting Started
To import the main library, include `achievements.lua` in your project and import it. This will create a global variable named `achievements` containing the module.

```lua
-- while the game is setting up
import "./path/to/achievements" -- don't include ".lua" in your import statement
achievements.initialize(data) -- initialize your data blob prior during your game setup

...

-- while the game is running
achievements.grant("my_cool_achievement") -- grant or revoke achievements as you wish
achievements.advance("my_progress_achievement", 4) -- add 4 to your achievement's progress, granting automagically if progress completes
achievements.save() -- write your achievements to disk
```

## Configuring Achievements
The most important part of configuring your achievements is properly constructing the achievement data blob and calling `achievements.initialize()` to properly set your game up. Calling `.initialize()` during your game's setup will ensure that the library is ready for use from within your game. It will not overwrite or reset previously saved achievement data.

### Example
```lua
local data = {
    -- This example infers most of the game metadata from your game's pdxinfo.
    iconPath = "assets/achievements/game_icon", -- Update these paths to match your game's file structure. See below for more details.
    cardPath = "assets/achievements/game_card", 
    achievements = {
        {
            -- these are the only required fields for a basic achievement.
            id = "my_achievement_1",
            name = "Achievement 1",
            description = "Achievement 1 Description",
        },
        {
            id = "my_achievement_2",
            name = "Achievement 2",
            description = "Achievement 2 Description",
            icon = "assets/achievements/icons/my_achievement_2_icon", -- Update this path to match your game's file structure. See below for more details.
            iconLocked = "assets/achievements/icons/my_locked_icon_2"
        },
        {
            id = "my_progress_achievement",
            name = "My Progress Achievement",
            description = "My Progress Achievement description",
            progressMax = 350,
            progressIsPercentage = false
        },
        {
            id = "my_secret_achievement",
            name = "My Secret Achievement",
            description = "My Secret Achievement description",
            isSecret = true,
            scoreValue = 0 -- don't count this achievement towards game completion
        },
        {
            -- continue defining achievements as much as you need
        }
    }
}

-- very important that you initialize the data blob before your game is set up.
achievements.initialize(data)
achievements.forceSaveOnGrantOrRevoke = true -- Defaults to false. Only set if you'd like the achievement data to be exported every time an achievement is granted or revoked.
```

### Schema

#### Achievements
| key                 | type                    | description                                                                                                                                         |
|---------------------|-------------------------|-----------------------------------------------------------------------------------------------------------------------------------------------------|
| `achievements`      | `list: AchievementData` | List of configured achievements for your game. **Required.**                                                                                        |
| `gameID`            | `string?`               | Bundle identifier for your game. Defaults to `bundleID` from your `pdxinfo`.                                                                        |
| `name`              | `string?`               | Nicely formatted name for your game. Defaults to `name` from your `pdxinfo`.                                                                        |
| `author`            | `string?`               | Nicely formatted author for your game. Defaults to `author` from your `pdxinfo`.                                                                    |
| `description`       | `string?`               | Short description about your game. Defaults to `description` from your `pdxinfo`.                                                                   |
| `version`           | `string?`               | Nicely formatted version string for your game. Defaults to `version` from your `pdxinfo`.                                                           |
| `iconPath`          | `string?`               | Path to the 32x32 `.png` icon to use as your game's icon. Recommended to use your `icon.png` from your game metadata. Defaults to `nil`.            |
| `cardPath`          | `string?`               | Path to the 380x90 `.png` art to use as your game's card art. Recommended to use your wide Catalog image asset (if you have it). Defaults to `nil`. |

#### AchievementData
| key                    | type       | description                                                                                                                                       |
|------------------------|------------|---------------------------------------------------------------------------------------------------------------------------------------------------|
| `id`                   | `string`   | Uniquely identifies the achievement. **Required.**                                                                                                |
| `name`                 | `string`   | Nicely formatted name for the achievement. Shown to the player. **Required.**                                                                     |
| `description`          | `string`   | Nicely formatted description for the achievement. Shown to the player. **Required.**                                                              |
| `descriptionLocked`    | `string?`  | Nicely formatted description for the ungranted version of the achievement. Shown the the player. Defaults to `nil`.                               |
| `isSecret`             | `bool?`    | Determines if the achievement should be hidden until granted. Defaults to `false`.                                                                |
| `icon`                 | `string?`  | Path to the achievement's 32x32 `.png` icon. The root folder is where "main.lua" is. Defaults to `nil`.                                           |
| `iconLocked`           | `string?`  | Path to the achievement's 32x32 `.png` locked icon (shown when achievement is not yet granted). Defaults to `nil`.                                |
| `progressMax`          | `number?`  | If this achievement is progression based, this is the limit at which the achievement will be automatically granted. Defaults to `nil`.            |
| `progress`             | `number?`  | How much progress has been made towards `progressMax`. Not necessary to set this by hand; instead, use `advance` or `advanceTo`. Defaults to `0`. |
| `progressIsPercentage` | `bool?`    | Indicates if this progress achievement represents a percentage. Defaults to `false`.                                                              |
| `scoreValue`           | `number?`  | How much weight this achievement carries towards 100% game completion. Defaults to `1`. Can be set to `0` to make the achievement optional.       |

## Properties

### achievements.forceSaveOnGrantOrRevoke (`bool`)
If this flag is set to `true` then achievements will be saved to disk every time an achievement is newly granted or revoked. Defaults to `false`.

## Functions

### achievements.initialize(table: config_data, bool: silent)
Initializes pdachievements with data about your game's achievements. This is required to run before calling other functions, such as `.grant()` or `.advance()`. See above for examples and full data schema. Set `silent` to `true` if you want to suppress the debug logs printed to the console.

### achievements.grant(string: achievement_id)
Grants the achievement `achievement_id` to the player. Attempting to grant a previously earned achievement does nothing. If your achievement has a `progressMax` field, use `achievements.advance()` or `achievements.advanceTo()` instead. 

Returns `true` if the achievement was successfully granted, otherwise `false`.

### achievements.revoke(string: achievement_id)
Revokes the achievement `achievement_id` from the player. Attempting to revoke an unearned achievement does nothing. If your achievement has a `progressMax` field, use `achievements.advance()` or `achievements.advanceTo()` instead. 

Returns `true` if the achievement was successfully revoked, otherwise `false`.

### achievements.advance(string: achievement_id, int: advance_by)
Increases or decreases the achievement `achievement_id`'s completion score by `advance_by`. Attempting this on an achievement without `progressMax` set throws an error. If the achievement's score reaches the max, the achievement will be granted. If it falls below the max, the achievement will be revoked.

Returns `true` on success, otherwise throws an error.

### achievements.advanceTo(string: achievement_id, int: advance_to)
Sets the achievement `achievement_id`'s completion score to `advance_to` Attempting this on an achievement without `progressMax` set throws an error. If the achievement's score reaches the max, the achievement will be granted. If it falls below the max, the achievement will be revoked.

Returns `true` on success, otherwise throws an error.

### achievements.save()
Saves the player's earned achievements as "Achievements.json" in your game's data, and exports the updated achievement information to `/Shared`.

### achievements.isGranted(string: achievement_id)
Returns `true` if the achievement has been earned by the player, returns `false` otherwise.

### achievements.getInfo(string: achievement_id)
Returns the metadata associated with the achievement. Returns an object with the schema `AchievementData` (see above).