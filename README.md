# 🏆 pd-achievements

_An open achievement standard for the Playdate console_

Playdate Achievements is a community project establishing an open standard for achievements in Playdate™ games. Having a standard ensures a consistent experience for players, and makes it possible to view achievements earned across games in one place.

## Introduction

This repository provides two things:

1. **Achievements Schema:** A [schema](achievements.schema.json) describing the open Playdate Achievements data storage format which _any_ game may use to adopt the standard.
2. **Lua Achievements Reference Library:** A Lua library that games may use to implement the schema, which includes the following (optional) components:
   - An achievements management system for creating, unlocking, and saving achievements
   - An in-game viewer to show achievements in your game
   - A notification system for showing toasts when players unlock achievements in your game

> [!NOTE]
> If your game is not written in Lua you can still support Playdate Achievements. However, you’ll need to reference the [schema](achievements.schema.json) and write your achievement data directly to the `/Shared` folder at the path `/Shared/Achievements/[gameID]/Achievements.json`, where `gameID` matches the one specified in `achievements.json`.

## Documentation

The documentation below is for the Lua reference library, which implements the open standard described in the [JSON schema](achievements.schema.json). When implementing Playdate Achievements, consider some [best practices](https://gurtt.dev/trophy-case/dev) for adding achievements to your game.

### Quickstart

To get started, import the modules you wish to use and initialize with [achievement data](docs/achievements.md#configuring-achievements) matching the schema.

```lua
-- setup
import "./path/to/achievements" --always import this first; don’t include ".lua"
import "./path/to/toasts" -- an optional notification implementation
achievements.initialize(myAchievementData) -- initialize your achievements with a table matching the schema
```

Grant achievements to players and optionally display toast notifications at any time. Easily save your achievement data to the `/Shared` folder so it can be seen in any Playdate Achievements viewer.

```lua
-- during gameplay
if myAchievementCondition == true then
	achievements.grant("my-achievement") -- grant an achievement
	achievements.toasts.toast("my-achievement") -- display a pop-up for the earned achievement
	achievements.save() -- write your achievements to the /Shared folder
end
```

Refer to the library API reference below for additional information and details on the configuration options available for each module.

### Lua Library API Reference

The Lua reference library includes 4 separate modules, all of which are optional—implement or omit any of these in the way that works best for your game. The `achievements` module is required to use any of the others, and _must be included first_; the others may be included in any order.

- `achievements.lua`: [Add achievements to your game](/docs/achievements.md)
- `toasts.lua`: [Display popups for earned achievements](/docs/toasts.md)
- `viewer.lua`: [Show an in-game achievements viewer](/docs/viewer.md)
- `crossgame.lua`: [Read achievements from other games](/docs/crossgame.md)

### Attribution

For Catalog developers, we encourage you to add this _optional_ link to the Credits section of your game's Catalog web page:
```
<blockquote>🏆 Supports <a href="https://playdatesquad.github.io/pd-achievements">Playdate Achievements</a>!</blockquote>
```
![This game supports Playdate Achievements!](docs/images/catalog_attribution_preview.png)

## Games

Check out the [official website](https://playdatesquad.github.io/pd-achievements/) for a list of known games which award Playdate Achievements and integrate with viewers that support the schema. If you add Playdate Achievements to your game, [follow our submission guidelines](https://github.com/PlaydateSquad/pd-achievements/blob/gh-pages/README.md) to add your game to the page.

## Achievement Viewers

Playdate Achievements aims to create a standard data format for Playdate game achievements. While it provides limited in-game achievement browsing capabilities, developers are encouraged to create their own achievement clients that read the data saved to `/Shared/Achievements/`.

**Available achievement clients:**

- [Trophy Case](https://github.com/gurtt/trophy-case/)

## Support

Join the [Playdate Squad Discord](https://discord.com/invite/zFKagQ2) and then navigate to the [Achievement Framework discussion post](https://discord.com/channels/675983554655551509/1213250459851292713). Feel free to ask questions if you get stuck during implementation!

## Contributing

Add a new GitHub issue for feature requests or bug reports. Provide as much detail as possible. To contribute code to the repository, please fork this repository, make your changes, and create a new pull request back to the main repository for review.

## SDK Fonts

The included [Playdate SDK](https://play.date/dev/) fonts ("Nontendo Bold", "Nontendo Light", and "Bitmore") by [Panic](https://panic.com) are licensed under [CC BY 4.0](http://creativecommons.org/licenses/by/4.0/).
