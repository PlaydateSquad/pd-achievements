- refactor external game data loading
    - split into a sub-module. achievements.external or achievements.crossgame or something
    - function to list IDs of all played games with an Achievements.json
        - detect via folders with an Achievements.json?
        - cache game data files to ensure reduced disk re-access?
        - this is part of the argument for having a base-level Achievements/ subfolder :P

- figure out what to do about images
    - steal icons from the pdxinfo standard?
        - path to the directory containing the necessary images
        - images named after the achievement ID
        - folders of images for animation named after the achievement ID
    - perhaps...
        - a path to the dedicated directory containing the images
        - image filepaths begin from the indicated directory
        - achievements have an 'icon' field containing...
            - 'intro' and 'loop', arrays of image filepaths
                - include generic "do this again" value for repeating frames
            -  'loopcount', how many times to perform the loop before pausing on the last frame
        - this can be reused for both images and cards using an agnostic drawing module

- export relevant images from input to output
    - automatic, based on images listed in the filepaths?
    - based on user-list of files to export? seems redundant
    - based on provided directory, as detailed above

- consider splitting cross-game into a different file corelibs style
    - users can grab only the files they need, drop them in their project, and import them individually
    - it'd be nice to share core utilities in a separate file, but...
        - maybe core utils can just be dropped into a .utils submodule by whatever defines them...