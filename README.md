# 🏆 Add _Your Game_ to the Playdate Achievements Page!

> [!NOTE]
> This branch is reserved exclusively for the [Playdate Achievements website](https://playdatesquad.github.io/pd-achievements/), which is hosted with [GitHub Pages](https://pages.github.com). If you haven’t yet added Playdate Achievements to your game, [start here](https://github.com/PlaydateSquad/pd-achievements) to learn about the Playdate Achievements standard and Lua reference library.

## Introduction

The Playdate Achivements standard is only as good as the games that support it. We aim to show off all games that award Playdate Achievements so the community can easily find and enjoy them. If you’ve already integrated Playdate Achievements in your game, you’ve come to the right place. Review the submission criteria and follow the steps below to add your game to the page.

## Submission Guidelines

We want to feature as many games that include Playdate Achievements as possible. We also want to ensure a great experience for players and other developers. These guidelines help ensure that games promoted on the page can be properly enjoyed by the entire community.

### Inclusive by Default

Playdate Achievements is an open standard. As such, we take an open and inclusive approach by default, and there are _no restrictions_ with regard to any of the following:

- **Distribution Channel:** Games available from Catalog, [itch.io](itch.io), your own website, or anywhere else you choose to host them are welcome.
- **Language/Platform:** Games written in any language—Lua, C, Swift, or even converted from Pulp via [Pulp Mill](https://github.com/nstbayless/pulp-to-lua)—are welcome.
- **Implementation Approach:** Games are welcome regardless of whether they make use of the [Lua Reference Library](https://github.com/PlaydateSquad/pd-achievements/blob/main/README.md#documentation), or implement the open [schema](https://github.com/PlaydateSquad/pd-achievements/blob/main/achievements.schema.json) on their own.
- **Game Content:** We are not a ratings board. Games of all kinds, including those with mature themes, are welcome as long as the listing itself remains family friendly.
- **Author(s):** And, of course, your game is welcome regardless of your background, race, color, religion, sex, gender, age, origin, or disability. This is an open platform for _everyone_.

### Submission Requirements

We impose a few hard requirements which games must meet in order to be listed:

1. **Achievements:** If you’ll allow us to state the obvious, your game must implement the Playdate Achievements standard and include one or more achievements for the player to unlock.
2. **Release Window:** Your game must be released or have a scheduled release date within the next 30 days. Games get abandoned all the time. We want to give proper attention to the games players can play _now_, and avoid cluttering the page with games that may never release.
3. **Game URL:** Your game must have a dedicated URL to which your listing can link. This provides a place for players to go to learn more about your game, and serves as an additional signal that the project will release as planned. Any page dedicated exclusively to your game will do, whether it’s a Catalog listing, itch.io page, or personal website.
4. **Listing Content**. Regardless of the age appropriateness of your game, please keep the image, title, and description of your game listing family friendly.
5. **Respectful:** Games that discriminate or disrespect any individuals or groups based on race, color, religion, sex, gender, age, origin, or disability will not be tolerated.

_In the event that any of these items are in question, it is the sole discretion of the Playdate Achievements community to decide how to proceed._

We also kindly ask that you abide by [best practices](https://gurtt.dev/trophy-case/dev) for creating Playdate Achievements. While there is no review process, we hope you’ll help us create a collection of games that provide truly fun, interesting, and attainable achievements that keep players engaged rather than pad out playtimes. Let’s show the world that achievements, done right, amplify the fun!

## Submitting Your Game

Follow the instructions below to submit your game for display on the [Playdate Achievements page](https://playdatesquad.github.io/pd-achievements/).

> [!NOTE]
> You can open a pull request directly _in this repo_ by [editing `_data/games.yml` with the GitHub file editor](https://github.com/PlaydateSquad/pd-achievements/edit/gh-pages/_data/games.yml), allowing you to skip step 1. However, with this approach you won’t have the chance to preview the resulting page before creating your pull request.

1. [Fork this repository](https://github.com/PlaydateSquad/pd-achievements/fork) and _uncheck_ the **Copy the `main` branch only** checkbox—you’ll need the `gh-pages` branch to make your change. Optionally create a new branch from the `gh-pages` branch with the name of your game to work on.

2. Edit `_data/games.yml`, copying the commented template and supplying the requisite information for your game. You’ll need to supply the following (**fields are required unless otherwise indicated**):

   | Key                | Type        | Description                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                               |
   | ------------------ | ----------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
   | `title`            | `string`    | The title of your game                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    |
   | `author`           | `string`    | Your name, alias, or studio—however you’d like attribution is fine.                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       |
   | `url`              | `URL`       | A link to a download page for your game. This could be a link to your game page in [Catalog](https://play.date/games), on [itch.io](itch.io), or a personal site.                                                                                                                                                                                                                                                                                                                                                                                         |
   | `image`            | `URL`       | A 380x90 black and white PNG image featuring your game’s cover art to display on the page. Use the same image you provided for `cardPath` in your game’s achievement data. Place the image in the `assets/images/games/` directory and reference it by relative path.                                                                                                                                                                                                                                                                                     |
   | `color`            | `CSS color` | A highlight color used as a bold border on your game listing. This can be any valid CSS color string, such as a hex value, e.g. `#FFFF00`.                                                                                                                                                                                                                                                                                                                                                                                                                |
   | `achievementCount` | `int`       | The number of Playdate Achievements available in your game. Include any hidden achievements.                                                                                                                                                                                                                                                                                                                                                                                                                                                              |
   | `releaseDate`      | `date`      | The date your game released, in `YYYY-MM-DD` format. If your game hasn’t released yet, you may provide a release date up to 30 days in the future. <br><br> A "New" badge will appear on games that released within the past 30 days. A "Soon" badge will appear on games that have a future release date.                                                                                                                                                                                                                                                |
   | `lastAddedDate`    | `date?`     | (_optional_) The date new achievements were last added to your game, in `YYYY-MM-DD` format. If your game has already released but doesn’t yet support achievements, provide a date up to 30 days in the future on which you expect an update with achievements to release. Defaults to the release date if none is provided. <br><br> A "More" badge will appear on games that have added achievements within the past 30 days. A "Soon" badge will appear on games that have a last-added date in the future (even if the release date is in the past). |
   | `description`      | `string?`   | (_optional_) A brief, one sentence description of your game. _This is not currently displayed_, but providing it now gives us flexibility to expose more detail about games in the future. Defaults to `nil`.                                                                                                                                                                                                                                                                                                                                             |

3. Commit your changes and push them to your fork. Include the name of your game in your commit message.

4. Navigate to the **Settings** tab and select **Pages** in the left sidebar. Ensure your **Build and Deployment** settings are set to deploy from the root of the branch you just pushed your changes to, then click **Save**. The link in the callout at the top contains the URL of your live site where you can preview your changes. It will build automatically after saving the deployment branch setting—check the **Actions** tab to observe progress or view any errors.

5. When ready, [open a pull request](https://github.com/PlaydateSquad/pd-achievements/compare/gh-pages...gh-pages) from your fork to this repo and a member of the community will review and merge your change. Be sure to select the `gh-pages` branch as your target in the base repository. To expedite your request, feel free to drop into the [Playdate Achievements Discord channel](https://discord.com/channels/675983554655551509/1213250459851292713), introduce yourself, and share a link to your PR!

We look forward to featuring your game!
