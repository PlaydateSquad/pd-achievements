# toasts.lua

TODO: refine documentation

## Toasts Module

To use toasts when achievements are granted, add `toast_graphics.lua` to your project and import it after `achievements.lua`

> ## NOTICE:
> This module will automatically import `Corelibs/graphics` when loaded.

There are several values which can be configured (this may break some things):

### `int: achievements.toast_graphics.displayGrantedMilliseconds`
How long should a toast animation last? Default: 2000

### `int: achievements.toast_graphics.displayGrantedDefaultX`
What X coordinate should a toast animation draw at? Default: 20

### `int: achievements.toast_graphics.displayGrantedDefaultY`
What Y coordinate should a toast animation draw at? Default: 0

### `int: achievements.toast_graphics.displayGrantedDelayNext`
How many milliseconds should pass after a toast begins before another one can begin playing? Default: 400

### `int: achievements.toast_graphics.iconWidth`
How wide are the achievement icons? Default: 32

### `int: achievements.toast_graphics.iconHeight`
How tall are the achievement icons? Default: 32

**[TODO]: The size of icons should really be set in the standard rather than configured here.**

> ## **NOTICE:**
> `toast_graphics.lua` Adds additional functionality to the basic `achievements.grant` function. While using it, refer to the below documentation instead of the original.

### achievements.grant(string: achievement_id, function: draw_card_func)

Grants the achievement `achievement_id` to the player. Attempting to grant a previously earned achievement does nothing.

This also queues up a toast notification to be drawn to the screen.

The optional argument `draw_card_func` takes a function which will be called each frame in order to draw the achievement toast to the screen. The function must take the following arguments:

- **`ach`**:  The achievement's internal data as configured during initialization.
- **`x`**: The base x coordinate the card should be drawn at.
- **`y`**: The base y coordinate the toast should be drawn at.
- **`elapsed_miliseconds`**: The amount of time which has passed since the toast began.

The function passed to `draw_card_func` should return `true` while the animation is ongoing and `false` once it has ended. If a function is not provided, the included default will be used.

Returns `true` if the achievement was successfully granted, otherwise `false`.


### achievements.toast_graphics.drawCard(achievement_or_id, x, y, elapsed_msec)

Draws a card using the default toast animation at `x` and `y`, at `elapsed_msec` into the animation. `achievement_or_id` can be either a string achievement ID or an achievement's internal data. `x` and `y` default to the module's configured x/y locations. `elapsed_msec` defaults to 0.

### achievements.toast_graphics.updateVisuals()
Updates currently drawing toasts. Should be called once per frame as part of the global update loop.