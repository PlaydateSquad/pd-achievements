- split crossgame into a new submodule
    - function to list IDs of all played games with an Achievements.json
        - detect via folders with an Achievements.json
    - load data from ID'd game into useful format
    - helper for image loading/drawing from external games

- finalize image standards
    - data fields for game art. banner/card, game icon, etc
    - animated images?
    - ensure all images are optional, just in case
    - allow game to configure default locked/unlocked achievement icons
    - allow game to configure "hidden achievement" icon
        - should the standard have default icons built-in for readers, or should the reader implement this?

- optional data fields for achievements
    - achievement progress fields
        - max_progress
        - current_progress
        - progress_is_percentage
    - achievement weight field
        - determines how much an achievement counts towards 100%

- review toast animations
    - default animation more in line with "use the crank!"
    - make sure it's as simple as possible to define new animations