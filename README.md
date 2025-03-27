# 🏆 Playdate Achievements

_An open achievement standard for the Playdate console._

Playdate Achievements is a community project establishing an open standard for achievements in [Playdate](https://play.date)™ games. Playdate is fun! Games on Playdate are fun! Achievements in games on Playdate are fun! Having a standard ensures a consistent experience for players, and makes it possible to view achievements earned across games in one place.

1. Play Playdate games!
2. Earn achievements!
3. View them in your Trophy Case!

## Everything On Display

[Trophy Case](https://github.com/gurtt/trophy-case) is a dedicated viewer which displays the achievements you’ve earned across _all_ Playdate games in one place. Trophy Case was designed in parallel with the Playdate Achievements standard, providing first-class support for its features and showcasing any games which choose to integrate with it.

<div align="center">
	<img src="./assets/images/viewers/trophy-case-pd.png" width="600"/>
</div>

Of course, games may also present their earned achievements themselves. Additionally, the open standard makes it possible for others to create dedicated achievement viewer apps in the future.

## Show Me the Games!

It’s all about the games. Here’s a (non-comprehensive) list of games that award Playdate Achievements. Made your own? [Add it to the list!](https://github.com/PlaydateSquad/pd-achievements#contributing)

<div class="game-grid">

{% for game in site.data.games %}

<div class="game">
	<a href="{{ game.url }}">
		<img src="{{ game.image }}" alt="{{ game.name }}" title="{{ game.name }}" width="400"/>
	</a>
</div>

{% endfor %}

</div>

## Made a Game for Playdate?

Add some achievements! The Playdate Achievements framework makes it quick and easy to add achievements to your own games. [Check out the Getting Started Guide](https://github.com/PlaydateSquad/pd-achievements/blob/main/README.md) in the [`pd-achievements` repo](https://github.com/PlaydateSquad/pd-achievements), which provides simple instructions along with everything you need to:

1. Grant achievements that integrate with Trophy Case and other viewer apps.
2. Present toast notifications to players when they earn achievements. (optional)
3. Display an in-game viewer so players can see the achievements they’ve earned in your game. (optional)

Don’t forget to [add it to this page](https://github.com/PlaydateSquad/pd-achievements#contributing) when you’re finished!

## FAQ

{% for faq in site.data.faq %}

<details><summary>{{ faq.question }}</summary>{{ faq.answer | markdownify }}</details>

{% endfor %}

_Playdate is a registered trademark of [Panic](https://panic.com/). Playdate Achievements is a community project, and is not affiliated with, endorsed by, or sponsored by Panic (but we’re confident they think it’s cool)._
