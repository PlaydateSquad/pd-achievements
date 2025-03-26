# 🏆 Playdate Achievements

_An open achievement standard for the Playdate console._

Playdate Achievements is a community project establishing an open standard for achievements in [Playdate](https://play.date)™ games. Playdate is fun! Games on Playdate are fun! Achievements in games on Playdate are fun! Having a standard ensures a consistent experience for players, and makes it possible to view achievements earned across games in one place.

1. Play Playdate games!
2. Earn achievements!
3. View them in your Trophy Case!

## Everything On Display

[Trophy Case](https://github.com/gurtt/trophy-case) is a dedicated viewer which displays the achievements you’ve earned across _all_ Playdate games in one place. Trophy Case was designed in parallel with the Playdate Achievements standard, providing first-class support for its features and showcasing any games which choose to integrate with it.

<div align="center">
	<img src="./images/viewers/trophy-case-pd.png" width="400"/>
</div>

Of course, games may also present their earned achievements themselves. Additionally, the open standard makes it possible for others to create dedicated achievement viewer apps in the future.

## Show Me the Games!

It’s all about the games. Here’s a (non-comprehensive) list of games that award Playdate Achievements. Made your own? [Add it to the list!](https://github.com/PlaydateSquad/pd-achievements#contributing)

<a href="https://play.date/games/bona-fido/" alt="Bona Fido">
	<img src="https://media-cdn.play.date/media/games/374881/IMG_3666.gif" width="400"/>
</a>
<a href="https://play.date/games/cranky-cove/" alt="Cranky Cove">
	<img src="https://media-cdn.play.date/media/games/377192/cranky_cove_banner_small_noalpha_6YTos8R.png" width="400"/>
</a>
<a href="https://play.date/games/first-in-line/" alt="First in… Line?">
	<img src="https://media-cdn.play.date/media/games/318634/web_small.gif" width="400"/>
</a>
<a href="https://play.date/games/hexa/" alt="Hexa">
	<img src="https://media-cdn.play.date/media/games/345269/web_small.gif" width="400"/>
</a>
<a href="https://play.date/games/rowbot-rally/" alt="Rowbot Rally">
	<img src="https://media-cdn.play.date/media/games/243372/Web_Small.gif" width="400"/>
</a>
<a href="https://play.date/games/xtris/" alt="Xtris">
	<img src="https://media-cdn.play.date/media/games/375945/web-cover-small.png" width="400"/>
</a>

## Made a Game for Playdate?

Add some achievements! The Playdate Achievements framework makes it quick and easy to add achievements to your own games. [Check out the Getting Started Guide](https://github.com/PlaydateSquad/pd-achievements/blob/main/README.md) in the [`pd-achievements` repo](https://github.com/PlaydateSquad/pd-achievements), which provides simple instructions along with everything you need to:

1. Grant achievements that integrate with Trophy Case and other viewer apps.
2. Present toast notifications to players when they earn achievements. (optional)
3. Display an in-game viewer so players can see the achievements they’ve earned in your game. (optional)

Don’t forget to [add it to this page](https://github.com/PlaydateSquad/pd-achievements#contributing) when you’re finished!

## FAQ

<details><summary><b>What games support it?</b></summary><br>

You scrolled too fast! [Check out the growing list of games](#show-me-the-games) that offer Playdate Achievements above.

</details>

<details><summary><b>How does it work?</b></summary><br>

Playdate Achievements takes advantage of the `Shared/` folder that Playdate makes available to all games. By establishing an open standard for achievements, games can record available and earned achievements in dedicated subfolders which any other game or viewer app can read. This enables apps like [Trophy Case](https://github.com/gurtt/trophy-case) to present an aggregated list of all achievements earned across games.

</details>

<details><summary><b>Does it support non-Catalog games?</b></summary><br>

Yes! Playdate Achievements is an open standard available to _all_ games regardless of whether they’ve been accepted to Catalog or their distribution method. Games hosted on [itch.io]() or your own site are absolutely welcome and fully supported.

</details>

<details><summary><b>Does it work with games made in Pulp?</b></summary><br>

[Pulp](https://play.date/pulp/) games don't have access to the `Shared/` folder or Lua code libraries, and therefore aren’t compatible with Playdate Achievements. However, you may be able to integrate the library after using [Pulp Mill](https://github.com/nstbayless/pulp-to-lua), a Pulp-to-Lua transpiler.

</details>

<details><summary><b>How can I add Playdate Achievements to my game?</b></summary><br>

Check out our [getting started guide](https://github.com/PlaydateSquad/pd-achievements/blob/main/README.md) in the [`pd-achievements`](https://github.com/PlaydateSquad/pd-achievements) repo on GitHub.

</details>

<details><summary><b>Can I add my game to this page?</b></summary><br>

All games that integrate Playdate Achievements are welcome! [Open a pull request](https://github.com/PlaydateSquad/pd-achievements/compare) to add your game to the list and a member of the community will review and merge the changes.

</details>

<details><summary><b>How do I report a bug?</b></summary><br>

All framework development occurs in the [`pd-achievements`](https://github.com/PlaydateSquad/pd-achievements) repo on GitHub. Please open an issue to report any bugs you find. If you find bugs in the Trophy Case viewer app, report them in the separate [`trophy-case`](https://github.com/gurtt/trophy-case) repo.

</details>

<details><summary><b>I already implemented my own achievements system—what should I do?</b></summary><br>

That’s awesome! It’s up to you whether to add support for Playdate Achievements (but we urge you to consider it). The more games that support it, the better it is for the community and the more fun it is for players, who can view all the achievements they've earned together in one place. We've designed the open standard with the goal of supporting most types of achievements, and you can integrate support for Playdate Achievements in parallel with your own implementation, so the cost of migration is low.

</details>

<details><summary><b>Cool, but can it do…? (What if it doesn’t support the features I want?)</b></summary><br>

We believe strongly in creating a shared open standard suitable for _all_ Playdate games. The more games that support it, the better the experience for players and the better for the Playdate community as a whole. We need to strike a balance between simplicity (so it’s easy for anyone to integrate) and capability (so that it serves the needs of most games/devs).

If you have ideas for achievements which can’t be…ahem, _achieved_… using the current standard, [join the discussion on Discord](https://discord.com/channels/675983554655551509/1213250459851292713) or [open an issue](https://github.com/PlaydateSquad/pd-achievements/issues/new) (or [a pull request](https://github.com/PlaydateSquad/pd-achievements/compare)) in GitHub. Be sure to include a summary of the idea and a clear explanation of the use case it serves. Ideas are more likely to be accepted when they are backwards compatible with the current standard, making them opt-in for those already using Playdate Achievements.

We can’t guarantee all ideas will be accepted, but we absolutely want to hear from you so we can make the standard as effective as possible for everyone in the community, developers and players alike.

</details>

<details><summary><b>How can I contribute?</b></summary><br>

Fix a bug? Have feature ideas? Want to help make this page awesome? Regardless of your background and skill set, we welcome members of the community to help us make Playdate Achievements the best it can be. Peruse the [`pd-achievements`](https://github.com/PlaydateSquad/pd-achievements) repo on GitHub and [join the discussion in the Playdate Squad Discord](https://discord.com/channels/675983554655551509/1213250459851292713) to get involved.

</details>

_Playdate is a registered trademark of [Panic](https://panic.com/). Playdate Achievements is a community project, and is not affiliated with, endorsed by, or sponsored by Panic (but we’re confident they think it’s cool)._
