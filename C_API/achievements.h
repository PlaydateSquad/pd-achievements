#ifndef _ACHIEVEMENTS_H
#define _ACHIEVEMENTS_H

#include "pd_api.h"

// Increase if your game needs more
#define MAX_ACHIEVEMENTS 10

#ifdef _WINDLL
#define SHARED_ROOT_PATH "../../Shared"
#else
#define SHARED_ROOT_PATH "/Shared"
#endif

union achievement_id {
	const char str7[8];
	const uint64_t val;
};

enum achievement_status {
	
	achievement_not_granted = 0,
	achievement_in_progress = 1,
	achievement_already_granted = 2,
	achievement_granted = 3,

	achievement_error = 255,
};

struct achievement_t {
	// Uniquely identifies the achievement.  Max 7 chars in C api for efficiency
	const union achievement_id* id;

	// Nicely formatted name for the achievement. Shown to the player.
	const char* name;

	// Nicely formatted description for the achievement. Shown to the player.
	const char* description;

	// Nicely formatted description for the ungranted version of the achievement. Shown to the player.
	const char* description_locked;

	// Path to a 32x32 .pdi image to use as this achievement's icon when unlocked (in 'app_image_root' folder passed to achievements_init.)  No extension!
	const char* icon;

	// Path to a 32x32 .pdi image to use as this achievement's icon when locked (in 'app_image_root' folder passed to achievements_init.) No extension!
	const char* icon_locked;
	
	// time the achievement was granted, or zero if not granted (don't manually set this!)
	int granted_at;
	
	// How much weight this achievement carries towards 100% game completion.
	const int score_value;

	// Determines if the achievement should be hidden until granted.
	bool is_secret;

	// If this achievement is progression based, this is the limit at which the achievement will be automatically granted.
	const int progress_max;

	// How much progress has been made towards 'progressMax'.
	int progress;

	// Indicates if this achievement's progress should be shown to the player as a percentage.
	bool progress_is_percentage;
};

struct achievements_t {
	// Bundle identifier for your game.
	const char* game_id;

	// Nicely formatted name for your game.
	const char* name;

	// Nicely formatted author for your game.
	const char* author;

	// Short description about your game.
	const char* description;

	// Nicely formatted version string for your game
	const char* version;

	// Path to a 32x32 .pdi image to use as your game's icon. Supports transparency.
	const char* icon_path;

	//Path to a 380x90.pdi image to use as your game's card art. Doesn't support transparency.
	const char* card_path;

	struct achievement_t achievements[MAX_ACHIEVEMENTS];
};

void achievements_init(PlaydateAPI* pd, struct achievements_t* root, const char* app_image_root);
enum achievement_status achievements_grant(union achievement_id id);
enum achievement_status achievements_set_progress(union achievement_id id, int value);
void achievements_write();

#endif 