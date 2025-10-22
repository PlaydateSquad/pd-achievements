## Introduction

This directory contains a C implementation for use with the Playdate C API.

Note it only includes the file/data/logic parts - enough to create and manage the json achievements file in the correct location, and keep track of achievements granted, and progress of incomplete achievements.   

As with other parts of the Playdate C API, there are no UI/UX elements currently.

## Documentation

### QuickStart

*	Copy the source files achievements.c and achievements.h into your game project
*   Create a Source folder for your achievement images (or use the same folder as your launcher assets)

```c
#include "achievements.h"

// define IDs for your elements (this prevents extra string comparisons.
// Note ids are limited to 7 chars, because they're packed into a 64bit uint
const union achievement_id id_world_1 = { "world_1" };
const union achievement_id id_items_20 = { "20items" };
const union achievement_id id_monsters_100 = { "kill100" };

// define your achievement structure
struct achievements_t achievements = {
    .game_id = {"com.example.mygame"},
    .name =	{"My lovely game"},
    .author = {"MyGameco"},
    .description ={"Really is a lovely game"},
    .version = {"1.0"},
    .icon_path = {"icon"},  // a 32x32 pdi image - usually your launcher asset image
    .card_path = {"ac-card"}, // a 380x90 banner image

    .achievements = {
        {
            .id = &id_world_1,
            .name = {"First world complete"},
            .description = {"Did the thing"},
            .description_locked = {"Do the thing"},
            .icon = {"ac-icon-banana"}, // 32x32 icon for the unlocked achievement
            .icon_locked = {"ac-icon-locked"}, // 32x32 icon for the locked achievement
        },

        {
            .id = &id_items_20,
            .name = {"Twenty things"},
            .description = {"Collected 20 items"},
            .description_locked = {"Get collecting!"},
            .icon = {"ac-icon"},
            .icon_locked = {"ac-icon-locked"},
            .progress_max = 20,
        }	
    };
}

// At the start of play
void init(void) {
    // pd is your PlaydateAPI* pointer
    // "imagefolder" is where your achievement images are stored within your game bundle
    achievements_init(pd, &achievements, "imagefolder");
}

// Then when you need to unlock some achievements
void during_gameplay() {

    if (myAchievementCondition == true ) {
       achievements_grant(id_world_1);
    }

    // or to update progress
    achievements_set_progress(id_items_20, myGameData.numItems);

    // then when appropriate, write to disk
    achievements_write();
}
```
