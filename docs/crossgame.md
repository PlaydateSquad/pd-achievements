# Reading Achievements From Other Games

## The `crossgame.lua` Module

This module enables games to inspect the achievements that _other_ games have written to `/Shared` on the same Playdate. This makes it possible to create cross-game experiences and achievements. For example, you might unlock a custom character skin in your game if the player has played another game to which that character belongs.

> NOTE: This is a reference implementation provided for convenience. You may use it as-is, or read achievement data matching the [schema](../achievements.schema.json) directly from `/Shared/Achievements/`.

## Sample Usage

Add `crossgame.lua` to your project and import it after `achievements.lua`:

```lua
-- setup
import "/path/to/achievements"
import "/path/to/crossgame"
```

Perform an action based on whether the player has played a particular game:

```lua
-- during gameplay
if achievements.crossgame.gamePlayed("wtf.rae.rowbotrally") then
	print("Hello, fellow Fish Bowl friend!")
end
```

## API Reference

### Functions

#### achievements.crossgame.gamePlayed(`string`: _game_id_)

Reports whether the specified game has been played on this Playdate, as indicated by the presence of a Playdate Achievements directory for the game in `/Shared`.

Returns `true` if there is an achievement folder for the given `game_id`, otherwise `false`.

#### achievements.crossgame.listGames()

Returns a list of all games for which Playdate Achievement data exists in `/Shared` on this Playdate, as an array table containing their game IDs.

#### achievements.crossgame.getData(`string`: _game_id_)

Returns the exported `achievementData` for the specified `game_id`. See the [achievement type declarations](achievements.md) for more details on the format of the returned data.

#### achievements.crossgame.loadImage(`string`: _game_id_, `string`: _filepath_)

Loads an image from the specified `filepath` relative to the shared image directory of the specified `game_id`. Can be used to load images specified in the game's `achievementData` blob, such as its game card or achievement icons.

Returns a `playdate.graphics.image`, or `nil` if none is found.
