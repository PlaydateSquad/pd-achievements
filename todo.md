- [x] split crossgame into a new submodule
    - [x] function to list IDs of all played games with an Achievements.json
    - [~] load data from ID'd game into useful format
    - [x] helper for image loading/drawing from external games

- finalize image standards
    - data fields for game art. banner/card, game icon, etc
    - animated images?
    - ensure all images are optional, just in case
    - [x] allow game to configure default locked/unlocked achievement icons
    - [x] allow game to configure "secret achievement" icon

- [x] optional data fields for achievements
    - [x] achievement progress fields
        - [x] max_progress
        - [x] current_progress
        - [x] progress_is_percentage
    - [x] achievement weight field
        - [x] determines how much an achievement counts towards 100%

- review toast animations
    - default animation more in line with "use the crank!"
    - make sure it's as simple as possible to define new animations