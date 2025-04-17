# pd-achievements
Cross-game achievement standard for the Playdate console.

Useful for configuring, granting, and revoking in-game achievements. Comes with some limited achievement viewing support out-of-the-box, but developers are encouraged to create their own 3rd party clients for viewing achievements on-device.

WARNING: This standard is still in development. Forward-compatibility is not yet guaranteed.

[The specification draft can be seen here.](https://docs.google.com/document/d/15iYMDmXdnDbOhoskyvfJsypu7Ls538R0kJNVYKDFx44/edit#heading=h.387me39epg7l)

## Documentation
- [Using pd-achievements to manage your game's achievements](/docs/achievements.md)
- [Reading and using other games' achievements in your game](/docs/crossgame.md)
- [Display popups when the player earns an achievement](/docs/toasts.md)
- [Show an interactive in-game achievement browser](/docs/viewer.md)
- [JSON Schema document for the output specification](achievements.schema.json)

## Achievement Viewers
`pd-achievements` aims to create a standard data format to manage game achievements. While it provides some limited in-game achievement browsing functions, developers are encouraged to create their own achievement clients that read the data saved to `/Shared`.

Achievement clients:
- [Trophy Case](https://github.com/gurtt/trophy-case/)

## Support
Join the [Playdate Squad Discord](https://discord.com/invite/zFKagQ2) and then navigate to the [Achievement Framework discussion post](https://discord.com/channels/675983554655551509/1213250459851292713). Feel free to ask questions if you get stuck during implementation!

## Contributing
Add a new GitHub issue for feature requests or bug reports. Provide as much detail as possible. To contribute code to the repository, please fork this repository, make your changes, and create a new pull request back to the main repository for review.
