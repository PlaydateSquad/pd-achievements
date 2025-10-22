#include "achievements.h"

PlaydateAPI* pdapi = NULL;
struct achievements_t* ac_root = NULL;
const char* image_root = NULL;
json_encoder* e = NULL;
bool achievements_dirty = false;

struct achievement_private_t {
	uint64_t id;
	int granted_at;
	int progress;
};

static void writefile(void* userdata, const char* str, int len) {
	pdapi->file->write((SDFile*)userdata, str, len);
}

static void add_string_property(const char* name, const char* value) {
	int val_len = (int)strlen(value);
	if (val_len > 0) {
		e->addTableMember(e, name, (int)strlen(name));
		e->writeString(e, value, val_len);
	}
}

static void add_int_property(const char* name, int value) {
	e->addTableMember(e, name, (int)strlen(name));
	e->writeInt(e, value);
}

static void add_bool_property(const char* name, bool value) {
	e->addTableMember(e, name, (int)strlen(name));
	if (value)
		e->writeTrue(e);
	else
		e->writeFalse(e);
}

static bool file_exists(const char* path) {
	FileStat stat;
	int exists = pdapi->file->stat(path, &stat);
	return exists == 0 && stat.isdir == 0 && stat.size > 0;
}

static int file_size(const char* path) {
	FileStat stat;
	int exists = pdapi->file->stat(path, &stat);
	if (exists == 0) return stat.size;
	return 0;
}

static void copy_image(const char* game_id, const char* image, const char* subdir) {
	char* from;
	char* to;

	pdapi->system->formatString(&from, "%s/%s.pdi", image_root, image);
	if (subdir == NULL)
		pdapi->system->formatString(&to, "%s/Achievements/%s/%s.pdi", SHARED_ROOT_PATH, game_id, image);
	else
		pdapi->system->formatString(&to, "%s/Achievements/%s/AchievementImages/%s.pdi", SHARED_ROOT_PATH, game_id, image);

	if (file_exists(from) && !file_exists(to)) {
		pdapi->system->logToConsole("Copying %s to %s", from, to);

		SDFile* inFile = pdapi->file->open(from, kFileRead);
		SDFile* outFile = pdapi->file->open(to, kFileWrite);

		int numBytes = file_size(from);

		if (numBytes == 0) {
			pdapi->file->close(outFile);
			pdapi->file->close(inFile);
			return;
		}

		uint8_t* buffer = NULL;
		buffer = pdapi->system->realloc(buffer, numBytes);

		int read = pdapi->file->read(inFile, buffer, numBytes);

		if (read == -1) {
			pdapi->system->logToConsole(pdapi->file->geterr());
			pdapi->system->realloc(buffer, 0);

			pdapi->file->close(outFile);
			pdapi->file->close(inFile);
			return;
		}

		int wrote = pdapi->file->write(outFile, buffer, numBytes);

		if (wrote == -1) {
			pdapi->system->logToConsole(pdapi->file->geterr());
			pdapi->system->realloc(buffer, 0);

			pdapi->file->close(outFile);
			pdapi->file->close(inFile);
			return;
		}

		pdapi->system->logToConsole(pdapi->file->geterr());

		pdapi->system->realloc(buffer, 0);

		pdapi->file->close(outFile);
		pdapi->file->close(inFile);


	}

	pdapi->system->realloc(from, 0);
	pdapi->system->realloc(to, 0);
}

void achievements_init(PlaydateAPI* playdate_api, struct achievements_t* root, const char* app_image_root) {
	pdapi = playdate_api;
	ac_root = root;
	image_root = app_image_root;
	achievements_dirty = true;

	struct achievement_private_t store[MAX_ACHIEVEMENTS];
	memset(&store, 0, sizeof(store));
	SDFile* saveFile = pdapi->file->open("achievements.bin", kFileReadData);
	if (saveFile != NULL) {
		if (pdapi->file->read(saveFile, &store, sizeof(store)) != sizeof(store)) {
			memset(&store, 0, sizeof(store));
		}
		pdapi->file->close(saveFile);
	}

	for (int i = 0; i < MAX_ACHIEVEMENTS; i++) {
		struct achievement_private_t* s = &store[i];

		if (s->id == 0) break;

		for (int j = 0; j < MAX_ACHIEVEMENTS; j++) {

			struct achievement_t* a = &ac_root->achievements[i];

			if (a->id == NULL || a->id->val == 0) break;

			if (s->id == a->id->val) {
				a->granted_at = s->granted_at;
				a->progress = s->progress;
			}
		}		
	}
}

static void achievements_store_internal() {
	struct achievement_private_t store[MAX_ACHIEVEMENTS];
	memset(&store, 0, sizeof(store));

	for (int i = 0; i < MAX_ACHIEVEMENTS; i++) {
		struct achievement_private_t* s = &store[i];
		struct achievement_t* a = &ac_root->achievements[i];
		if (a->id == NULL || a->id->val == 0) break;
		s->id = a->id->val;
		s->granted_at = a->granted_at;
		s->progress = a->progress;
	}

	SDFile* saveFile = pdapi->file->open("achievements.bin", kFileWrite);
	if (saveFile != NULL) {
		pdapi->file->write(saveFile, store, sizeof(store));
		pdapi->file->close(saveFile);
	}
}

static SDFile* achievements_open_outfile() {
	char* buffer;
	pdapi->system->formatString(&buffer, "%s/Achievements", SHARED_ROOT_PATH);
	pdapi->file->mkdir(buffer);
	pdapi->system->realloc(buffer, 0);

	pdapi->system->formatString(&buffer, "%s/Achievements/%s", SHARED_ROOT_PATH, ac_root->game_id);
	pdapi->file->mkdir(buffer);
	pdapi->system->realloc(buffer, 0);

	pdapi->system->formatString(&buffer, "%s/Achievements/%s/AchievementImages", SHARED_ROOT_PATH, ac_root->game_id);
	pdapi->file->mkdir(buffer);
	pdapi->system->realloc(buffer, 0);

	pdapi->system->formatString(&buffer, "%s/Achievements/%s/Achievements.json", SHARED_ROOT_PATH, ac_root->game_id);
	pdapi->system->logToConsole("Writing achievements to %s", buffer);
	SDFile* file = pdapi->file->open(buffer, kFileWrite);
	pdapi->system->realloc(buffer, 0);

	return file;
}

static void achievements_copy_images() {
	copy_image(ac_root->game_id, ac_root->card_path, NULL);
	copy_image(ac_root->game_id, ac_root->icon_path, NULL);

	for (int i = 0; i < MAX_ACHIEVEMENTS; i++) {

		struct achievement_t* a = &ac_root->achievements[i];

		if (a->id == NULL || a->id->val == 0) break;

		copy_image(ac_root->game_id, a->icon, "AchievementImages");
		copy_image(ac_root->game_id, a->icon_locked, "AchievementImages");
	}
}

static void achievements_write_header() {
	add_string_property("gameID", ac_root->game_id);
	add_string_property("name", ac_root->name);
	add_string_property("author", ac_root->author);
	add_string_property("description", ac_root->description);
	add_string_property("version", ac_root->version);
	add_string_property("iconPath", ac_root->icon_path);
	add_string_property("cardPath", ac_root->card_path);
}

static void achievements_write_entry(struct achievement_t* a) {
	add_string_property("name", a->name);
	add_string_property("id", a->id->str7);
	add_string_property("description", a->description);
	add_string_property("descriptionLocked", a->description_locked);
	add_string_property("icon", a->icon);
	add_string_property("iconLocked", a->icon_locked);

	if (a->granted_at > 0) {
		add_int_property("grantedAt", a->granted_at);
	}

	if (a->score_value > 0) {
		add_int_property("scoreValue", a->score_value);
	}

	if (a->progress_max != 0) {
		add_int_property("progress", a->progress);
		add_int_property("progressMax", a->progress_max);
		if (a->progress_is_percentage) {
			add_bool_property("progressIsPercentage", a->progress_is_percentage);
		}
	}
}

void achievements_write() {

	if (!achievements_dirty) return;

	achievements_store_internal();

	json_encoder encoder;
	memset(&encoder, 0, sizeof(encoder));
	e = &encoder;

	SDFile* file = achievements_open_outfile();

	pdapi->json->initEncoder(&encoder, writefile, file, 1);

	encoder.startTable(&encoder);

	achievements_write_header();

	encoder.addTableMember(&encoder, "achievements", 12);
	encoder.startArray(&encoder);

	for (int i = 0; i < MAX_ACHIEVEMENTS; i++) {
		struct achievement_t* a = &ac_root->achievements[i];
		if (a->id == NULL || a->id->val == 0) break;

		encoder.addArrayMember(&encoder);
		encoder.startTable(&encoder);

		achievements_write_entry(a);

		encoder.endTable(&encoder);
	}

	encoder.endArray(&encoder);

	encoder.endTable(&encoder);

	pdapi->file->close(file);

	e = NULL;
	achievements_dirty = false;
}

static struct achievement_t* achievements_find(union achievement_id id) {
	for (int i = 0; i < MAX_ACHIEVEMENTS; ++i) {
		struct achievement_t* a = &ac_root->achievements[i];

		if (a->id == NULL || a->id->val == 0) break;

		if (a->id->val == id.val) {
			return a;
		}
	}
	return NULL;
}

static enum achievement_status achivements_grant_internal(struct achievement_t* a) {
	if (a->granted_at == 0) {
		a->granted_at = pdapi->system->getSecondsSinceEpoch(NULL);
		pdapi->system->logToConsole("Achievement granted: %s : %s", a->id->str7, a->name);
		achievements_dirty = true;
		return achievement_granted;
	}
	return achievement_already_granted;
}

enum achievement_status achievements_set_progress(union achievement_id id, int value) {
	struct achievement_t* a = achievements_find(id);
	if (a != NULL) {
		if (a->granted_at == 0) {
			if (value > a->progress && value <= a->progress_max) {
				a->progress = value;
				achievements_dirty = true;
			}
			else if (value > a->progress_max) {
				a->progress = a->progress_max;
			}
			if (a->progress >= a->progress_max ) {
				return achivements_grant_internal(a);
			}
			return achievement_in_progress;
		}
		else {
			return achievement_already_granted;
		}
	}
	return achievement_error;
}

enum achievement_status achievements_grant(union achievement_id id) {
	struct achievement_t* a = achievements_find(id);
	if (a != NULL) {
		return achivements_grant_internal(a);		
	}
	return achievement_error;
}