# 🏆 pd-achievements

_An open achievement standard for the Playdate console_

Playdate Achievements is a community project establishing an open standard for achievements in Playdate™ games. Having a standard ensures a consistent experience for players, and makes it possible to view achievements earned across games in one place.

This repository provides two things:

1. **Achievements Schema:** A [schema](achievements.schema.json) describing the open Playdate Achievements data storage format which _any_ game may use to adopt the standard.
2. **Lua Achievements Library:** A Lua library that games may use to implement the schema, along with UI niceties for displaying toast notifications and an in-game achievements viewer.

The included Lua reference library provides three components:
- An achievements management system for creating, unlocking, and saving achievements.
- An in-game viewer to show achievements in your game.
- A notification system for showing toasts when players unlock achievements in your game.

All of these components are optional—you can implement or omit any of these in the way that works best for your game.

> [!NOTE]
> If your game is not written in Lua you can still support Playdate Achievements. However, you'll need to reference the [schema](achievements.schema.json) and write your achievement data directly to the `/Shared` folder at the path `/Shared/Achievements/[gameID]/Achievements.json`, where `gameID` is the same as the gameID you specify in achievements.json.

## Documentation

- [Adding achievements to your game](/docs/achievements.md)
- [Reading other games’ achievements](/docs/crossgame.md)
- [Displaying popups for earned achievements](/docs/toasts.md)
- [Showing an in-game achievements viewer](/docs/viewer.md)
- [JSON Schema document for the output specification](achievements.schema.json)
- [Best practices for adding achievements to your game](https://gurtt.dev/trophy-case/dev)

## Games

Check out the [official website](https://playdatesquad.github.io/pd-achievements/) for a list of known games which award Playdate Achievements and integrate with viewers that support the schema.

## Achievement Viewers

`pd-achievements` aims to create a standard data format for Playdate game achievements. While it provides limited in-game achievement browsing capabilities, developers are encouraged to create their own achievement clients that read the data saved to `/Shared/Achievements/`.

**Available achievement clients:**

- [Trophy Case](https://github.com/gurtt/trophy-case/)

## Support

Join the [Playdate Squad Discord](https://discord.com/invite/zFKagQ2) and then navigate to the [Achievement Framework discussion post](https://discord.com/channels/675983554655551509/1213250459851292713). Feel free to ask questions if you get stuck during implementation!

## Contributing

Add a new GitHub issue for feature requests or bug reports. Provide as much detail as possible. To contribute code to the repository, please fork this repository, make your changes, and create a new pull request back to the main repository for review.

## SDK Fonts

The included [Playdate SDK](https://play.date/dev/) fonts ("Nontendo Bold", "Nontendo Light", and "Bitmore") by [Panic](https://panic.com) are licensed under [CC BY 4.0](http://creativecommons.org/licenses/by/4.0/).
