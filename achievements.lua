
--[[
	==prototype achievements library==
	This is an initial prototype implementation in order to help effect a standard.
	This prototype will have no strong error checks and be small in scope. Any
	  wider-scope implementation of the standard will be separate.


	== API Style Guide ==
	Behavior is stacked similar to corelibs. Areas of functionality are held in individual files.
	Public API functions are added to a relevant global table as pascalCase.
	Private API functions/variables are added to a .internal sub-table as snake_case.

	 == Module Overview ==
	- achievements.lua      | A single-file library which establishes the basics of the achievement
		system and allows a single game to enable achievements.
	- crossgame.lua         | A single-file library which depends on achievements.lua and provides
		helpers for reading achievement data and related assets from other games.
	- notifications.lua     | A single-file library which lays the groundwork for highly customizable
		generic toast notifications. Does not hook into the achievement system directly.
	- achievementToasts.lua | Depends on achievements.lua and notifications.lua. Provides decorations
		for achievements.lua functions with preconfigured toast support.
--]]

--[[ 
	== Technical Specifications ==
--]]

---@class achievement_root
---@field author string The author of the game, as in pdxinfo.
---@field name string The name of the game, as in pdxinfo.
---@field description string The description of the game, as in pdxinfo.
---@field gameID string A unique ID to identify the game. Analogous to BundleID in pdxinfo.
---@field version string The version string of the game, as in pdxinfo.
---@field specversion string The version string of the specification used.
---@field libversion string The version string of the Achievement library used.
---@field imagePath string The root filepath for a directory of icons used by achievements. Default "achievementImages"
---@field defaultIcon string | nil The filepath for the game's default unlocked achievement icon, relative to the value of achievements.imagePath.
---@field defaultIconLocked string | nil The filepath for the game's default locked achievement icon, relative to the value of achievements.imagePath.
---@field achievements achievement[] An array of valid achievements for the game.

---@class achievement
---@field name string The name of the achievement.
---@field description string The description of the achievement.
---@field id string A unique ID by which to identify the achievement. Used in various API functions.
---@field granted_at boolean | number False if the achievement has not been earned, otherwise the Playdate epoch second the achievement was earned at as returned by playdate.getSecondsSinceEpoch().
---@field is_secret boolean | nil If true, this achievement should not appear in any player-facing lists while the .granted_at field is false. Defaut false.
---@field icon string | nil The filepath of the achievement's unlocked icon image, relative to the value of achievements.imagePath.
---@field icon_locked string | nil The filepath of the achievement's locked icon image, relative to the value of achievements.imagePath.
---@field progress number | nil Current progress towards unlocking the achievement, as x/.progress_max. Should not be set manually under most circumstances.
---@field progress_max number | nil Maxiumum progress possible towards the achievement before it is to be unlocked.
---@field progress_is_percentage boolean | false If false, an achievement list should display current progress as a tally "$(progress)/$(progress_max)". If true, it should be displayed as a percentage number (progress/progress_max)*100. Default false.
---@field score_value number | nil The weight of the achievement towards 100%-ing a game. Each achievement grants score_value/(total scores)% completion. Default 1.

-- [[ == Implementation == ]]

local metadata <const> = playdate.metadata

local shared_achievement_folder <const> = "/Shared/Data/"
local achievement_file_name <const> = "Achievements.json"
local shared_images_subfolder <const> = "AchievementImages/"
local shared_images_updated_file <const> = "_last_seen_version.txt"

---@diagnostic disable-next-line: lowercase-global
achievements = {
	specversion = "0.1+prototype",
	libversion = "0.2-alpha+prototype",

	forceSaveOnGrantOrRevoke = false,
}

function achievements.paths.get_achievement_folder_root_path(gameID)
	if type(gameID) ~= "string" then
		error("bad argument #1: expected string, got " .. type(gameID), 2)
	end
	local root = string.format(shared_achievement_folder .. "%s/", gameID)
	return root
end
function achievements.paths.get_achievement_data_file_path(gameID)
	if type(gameID) ~= "string" then
		error("bad argument #1: expected string, got " .. type(gameID), 2)
	end
	local root = achievements.paths.get_achievement_folder_root_path(gameID)
	return root .. achievement_file_name
end
function achievements.paths.get_shared_images_path(gameID)
	if type(gameID) ~= "string" then
		error("bad argument #1: expected string, got " .. type(gameID), 2)
	end
	local root = achievements.paths.get_achievement_folder_root_path(gameID)
	return root .. shared_images_subfolder
end
function achievements.paths.get_shared_images_updated_file_path(gameID)
	if type(gameID) ~= "string" then
		error("bad argument #1: expected string, got " .. type(gameID), 2)
	end
	local folder = achievements.paths.get_shared_images_path(gameID)
	return folder .. shared_images_updated_file
end

local function load_granted_data()
	local data = json.decodeFile(achievement_file_name)
	if not data then
		data = {}
	end
	achievements.granted = data
end

local function export_data()
	local data = achievements.gameData
	json.encodeToFile(achievements.paths.get_achievement_data_file_path(data.gameID), true, data)
end

local function dirname(str)
	local pos = str:reverse():find("/", 0, true)
	if pos == nil then
		return "/"
	end
	if pos == #str then
		pos = str:reverse():find("/", 2, true)
	end
	return str:sub(0, #str - (pos - 1))
end

local function force_extension(str, new_ext)
	local pos = str:reverse():find(".", 0, true)
	if pos == nil then
		return str .. "." .. new_ext
	end
	if pos == 1 then
		return str .. new_ext
	end
	return str:sub(0, (#str - 1) - (pos - 1)) .. "." .. new_ext
end

achievements.getPaths = function(gameID, variables)
	local shared_folder = achievements.paths.get_shared_images_path(gameID)
	local result = {}
	for _, variable in ipairs(variables) do
		for _, value in pairs(achievements.keyedAchievements) do
			if value[variable] ~= nil then
				local ref = value[variable]
				local filename = force_extension(value[variable], "pdi") -- Always compiled to .pdi, (so use like pd.image.new).
				result[ref] = { native = achievements.gameData.imagePath .. filename, shared = ( shared_folder .. filename ) }
			end
		end
	end
	return result
end

local function copy_file(src_path, dest_path)
	-- make sure the source-file exists
	if not (playdate.file.exists(src_path) or playdate.file.isdir(src_path)) then
		error("Can't find file '"..src_path.."'; either non-existant, non-accessible, or a directory.")
	end

	-- make sure the folder structure up to the destination path exists
	local subfolder = dirname(dest_path)
	if playdate.file.exists(subfolder) and not playdate.file.isdir(subfolder) then
		error("Directory-name for destination, '"..subfolder.."', is not a folder.")
	end
	if not playdate.file.exists(subfolder) then
		playdate.file.mkdir(subfolder)
	end

	-- open both the source and the destination paths (one for reading, the other for writing to)
	local in_file, err = playdate.file.open(src_path, playdate.file.kFileRead)
	if err then
		error("Can't open source file '"..src_path.."', because: '"..err.."'.")
	end
	local out_file, err = playdate.file.open(dest_path, playdate.file.kFileWrite)
	if err then
		error("Can't open destination file '"..dest_path.."', because: '"..err.."'.")
	end

	-- no 'SEEK_END' in lua, so we need to check the size this way
	local num_bytes = playdate.file.getSize(src_path)
	if num_bytes == 0 then
		out_file:close()
		in_file:close()
		return
	end

	-- finally, the acctual read/write process
	local buffer, err = in_file:read(num_bytes)
	if buffer == nil then
		error("Can't read source file '"..src_path.."', because: '"..err.."'.")
	end
	-- NOTE: the documentation says this should be a string, but it seems we can get away with just yeeting the buffer in there
	local res, err = out_file:write(buffer)
	if res == 0 then
		error("Can't write to destination file '"..dest_path.."' because: '"..err.."'.")
	end

	out_file:close()
	in_file:close()
end

local copy_folder
copy_folder = function(src_path, dest_path, overwrite)
	if not playdate.file.isdir(src_path) then
		error("Could not open directory at " .. src_path)
	end

	if not playdate.file.isdir(dest_path) then
		if playdate.file.exists(dest_path) then
			error("Destination '"..subfolder.."' is not a folder.")
		else
			playdate.file.mkdir(subfolder)
		end
	else
		if overwrite == true then
			playdate.file.delete(dest_path, true)
			playdate.file.mkdir(dest_path)
		end
	end

	for _, node in ipairs(playdate.file.listFiles(src_path)) do
		if string.sub(node, -1) == "/" then
			copy_folder(src_path .. node, dest_path .. node)
		else
			copy_file(src_path .. node, dest_path .. node)
		end
	end
end

local function export_images(gameID, current_build_nr)
	-- if >= the current version of the gamedata already exists, no need to re-copy the images
	local verfile_path = achievements.paths.get_shared_images_updated_file_path(gameID)
	if playdate.file.exists(verfile_path) and not playdate.file.isdir(verfile_path) then
		local ver_file, err = playdate.file.open(verfile_path, playdate.file.kFileRead)
		if not ver_file then
			error("Couldn't read version file at '" .. verfile_path .. "', because: " .. err, 2)
		end
		local ver_str = ver_file:readline()
		ver_file:close()
		local ver = tonumber(ver_str) or -1
		if ver >= current_build_nr then
			return
		end
	end

	-- otherwise, the structure should be copied
	copy_folder(achievements.gameData.imagePath, achievements.paths.get_shared_images_path(gameID))

	-- also write the version-file
	local ver_file, err = playdate.file.open(verfile_path, playdate.file.kFileWrite)
	if not ver_file then
		error("Couldn't write version file at '" .. verfile_path .. "', because: " .. err, 2)
	end
	ver_file:write(tostring(current_build_nr))
	ver_file:close()
end

local function donothing(...) end

---@param ach_root  achievement_root The game data being validated.
---@param prevent_debug boolean If false, does not print debug info to the console.
-- Takes in achievement game data, validates correct data, and sets defaults.
local function validate_gamedata(ach_root, prevent_debug)
	local print = (prevent_debug and donothing) or print

	for _, field in ipairs{ "name", "author", "description", } do
		if ach_root[field] == nil then
			if playdate.metadata[field] ~= nil then
				ach_root[field] = playdate.metadata[field]
				print(field .. ' not configured: defaulting to "' .. ach_root[field] .. '"')
			else
				print("WARNING: " .. field .. " not configured AND not present in pxinfo metadata")
			end
		elseif type(ach_root[field]) ~= "string" then
			error("expected '" .. field .. "' to be type string, got " .. type(ach_root[field]), 3)
		end
	end

	if ach_root.gameID == nil then
		ach_root.gameID = string.gsub(metadata.bundleID, "^user%.%d+%.", "")
		print('gameID not configured: defaulting to "' .. ach_root.gameID .. '"')
	elseif type(ach_root.gameID) ~= "string" then
		error("expected 'gameID' to be type string, got ".. type(ach_root.gameID), 3)
	end

	ach_root.version = metadata.version
	ach_root.specversion = achievements.specversion
	ach_root.libversion = achievements.libversion
	print("game version saved as \"" .. ach_root.version .. "\"")
	print("specification version saved as \"" .. ach_root.specversion .. "\"")
	print("library version saved as \"" .. ach_root.libversion .. "\"")

	if ach_root.imagePath == nil then
		ach_root.imagePath = shared_images_subfolder
	elseif type(ach_root.imagePath) ~= 'string' then
		error("expected 'imagePath' to be type string, got " .. type(ach.icon), 3)
	elseif string.sub(ach_root.imagePath, -1) ~= "/" then
		ach_root.imagePath = ach_root.imagePath .. "/"
	end
	if type(ach_root.defaultIcon) ~= 'string' and ach_root.defaultIcon ~= nil then
		error("expected 'defaultIcon' to be type string, got " .. type(ach_root.defaultIconcon), 3)
	end
	if type(ach_root.defaultIconLocked) ~= 'string' and ach_root.defaultIconLocked ~= nil then
		error("expected 'defaultIconLocked' to be type string, got " .. type(ach_root.defaultIconLocked), 3)
	end
	
	if ach_root.achievements == nil then
		print("WARNING: no achievements configured")
		ach_root.achievements = {}
	elseif type(ach_root.achievements) ~= "table" then
		error("achievements must be a table", 3)
	end
end

---@param ach achievement The achievement being validated.
-- Takes in an achievement table, validates correct data, and sets defaults.
local function validate_achievement(ach)
	for _, key in ipairs{"name", "description", "id",} do
		local valtype = type(ach[key])
		if valtype ~= "string" then
			error(("expected '%s' to be type string, got %s"):format(key, valtype), 3)
		end
	end

	if ach.is_secret == nil then
		ach.is_secret = false
	elseif type(ach.is_secret) ~= "boolean" then
		error("expected 'is_secret' to be type boolean, got " .. type(ach.is_secret), 3)
	end

	if type(ach.icon) ~= 'string' and ach.icon ~= nil then
		error("expected 'icon' to be type string, got " .. type(ach.icon), 3)
	end
	if type(ach.icon_locked) ~= 'string' and ach.icon_locked ~= nil then
		error("expected 'icon_locked' to be type string, got " .. type(ach.icon_locked), 3)
	end

	if ach.progress_max then
		if type(ach.progress_max) ~= 'number' then
			error("expected 'progress_max' to be type number, got ".. type(ach.progress_max), 3)
		end
		if ach.progress_is_percentage == nil then
			ach.progress_is_percentage = false
		elseif type(ach.progress_is_percentage) ~= 'boolean' then
			error("expected 'progress_is_percentage' to be type boolean, got " .. type(ach.progress_is_percentage), 3)
		end
	end
	
	if ach.score_value == nil then
		ach.score_value = 1
	elseif type(ach.score_value) ~= "number" then
		error("expected 'score_value' to be type number, got ".. type(ach.score_value), 3)
	end
end

---@param gamedata achievement_root
---@param prevent_debug boolean
function achievements.initialize(gamedata, prevent_debug)
	local print = (prevent_debug and donothing) or print
	print("------")
	print("Initializing achievements...")

	validate_gamedata(gamedata, prevent_debug)
	achievements.gameData = gamedata

	load_granted_data()

	achievements.keyedAchievements = {}
	for _, ach in ipairs(gamedata.achievements) do
		if achievements.keyedAchievements[ach.id] then
			error("achievement id '" .. ach.id .. "' defined multiple times", 2)
		end
		achievements.keyedAchievements[ach.id] = ach
		ach.granted_at = achievements.granted[ach.id] or false
		validate_achievement(ach)
	end

	playdate.file.mkdir(achievements.paths.get_achievement_folder_root_path(gamedata.gameID))
	export_data()
	export_images(gamedata.gameID, (tonumber(metadata.buildNumber) or 0))

	print("files exported to /Shared")
	print("Achievements have been initialized!")
	print("------")
end

--[[ Achievement Management Functions ]]--

achievements.getInfo = function(achievement_id)
	return achievements.keyedAchievements[achievement_id] or false
end

achievements.isGranted = function(achievement_id)
	return achievements.granted[achievement_id] ~= nil
end

achievements.grant = function(achievement_id)
	local ach = achievements.keyedAchievements[achievement_id]
	if not ach then
		error("attempt to grant unconfigured achievement '" .. achievement_id .. "'", 2)
		return false
	end
	local time, _ = playdate.getSecondsSinceEpoch()
	if ach.granted_at ~= false and ach.granted_at <= ( time ) then
		return false
	end
	achievements.granted[achievement_id] = ( time )
	ach.granted_at = time

	if achievements.forceSaveOnGrantOrRevoke then
		achievements.save()
	end
	return true
end

achievements.revoke = function(achievement_id)
	local ach = achievements.keyedAchievements[achievement_id]
	if not ach then
		error("attempt to revoke unconfigured achievement '" .. achievement_id .. "'", 2)
		return false
	end
	ach.granted_at = false
	achievements.granted[achievement_id] = nil
	if achievements.forceSaveOnGrantOrRevoke then
		achievements.save()
	end
	return true
end

function achievements.save()
	export_data()
	json.encodeToFile(achievement_file_name, false, achievements.granted)
end

--[[ External Game Functions ]]--

achievements.gamePlayed = function(game_id)
	return playdate.file.isdir(achievements.paths.get_achievement_folder_root_path(game_id))
end

achievements.gameData = function(game_id)
	if not achievements.gamePlayed(game_id) then
		error("No game with ID '" .. game_id .. "' was found", 2)
	end
	local data = json.decodeFile(achievements.paths.get_achievement_data_file_path(game_id))
	local keys = {}
	for _, ach in ipairs(data.achievements) do
		keys[ach.id] = ach
	end
	data.keyedAchievements = keys
	return data
end


return achievements
