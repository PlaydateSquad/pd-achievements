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

### Example

…

### Schema

…

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
