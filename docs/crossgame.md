# crossgame.lua

TODO: refine documentation

## Crossgame Module

Adds helper functions for dealing with data written by other games. To use it, add `crossgame.lua` to your project and import it after `achievements.lua`.

Needs to be filled out through the development of a full reader.

### `achievements.crossgame.gamePlayed(game_id)`

Returns `true` if there is an achievement folder for the given gameID, returns `false` otherwise.

### `achievements.crossgame.listGames()`

Returns an array table containing the gameID's of all existing achievement folders.

### `achievements.crossgame.getData(game_id)`

Returns the exported achievementData of the requested game. See the type declarations in `achievements.lua` for more information.

TODO: Better document exactly what's in the standard and what parts need to be filled in by the user versus being automatically added on export.