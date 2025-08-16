--[[
	PlaydateSquad Achievements Library
	https://github.com/PlaydateSquad/pd-achievements

	This library provides an implementation of a shared format for achievements on Playdate.
	See the README.md file for more information.

	This software is released to the public domain using the Unlicense license agreement <https://unlicense.org>.
--]]

---@class game_data
---@field author string The author of the game.
---@field name string The name of the game.
---@field description string A description for the game.
---@field gameID string A unique identifier for the game, in reverse DNS notation.
---@field version string A game version number that is displayed to players.
---@field specVersion string The version string of the specification that achievements follow.
---@field iconPath string? The filepath to the game's 32x32 list icon.
---@field cardPath string? The filepath to the game's 380x90 card art.
---@field achievements achievement[] An array of achievements for the game.
---@field completionPercentage number The the fractional completion of all configured achievements as a unit interval [0..1], taking into account the `scoreValue` of any achievements if configured. Only calculated when loading a game's data through the crossgame module.
---@field keyedAchievements { [string]: achievement} All configured achievements for the game, indexed by their ID as string keys. Automatically assembled by achievements.initialize and crossgame.loadData.

---@class achievement
---@field name string The name of the achievement.
---@field description string The description of the achievement.
---@field descriptionLocked string? The description of the achievement to use when it hasn't beeen granted.
---@field id string A unique identifier for the achievement. This must be unique among achievements in the same bundle, but doesn't need to be unique across different bundles.
---@field grantedAt boolean | number The the number of seconds elapsed since midnight (hour 0), January 1 2000 UTC at which the achievement was granted, or `false` if it hasn't been granted.
---@field isSecret boolean? A reader hint indicating whether the achievement should be displayed while it has not been granted. Defaults to false.
---@field icon string? The filepath to the achievement's icon image.
---@field iconLocked string? The filepath of the achievement's icon image to use when it hasn't been granted.
---@field progress number? The progress towards granting the achievement for incremental achievements.
---@field progressMax number? The number  that `progress` must reach for the achievement to be granted for incremental achievements.
---@field progressIsPercentage boolean? A reader hint indicating whether the achievement's progress should be displayed as a percentage instead of a fraction. Defaults to false.
---@field scoreValue number? A reader hint indicating the relative importance of the achievement. This also influences the value returned by `achievements.completionPercentage`, where each achievement grants scoreValue/(total scores)% completion. Defaults to 1.

---@class initialize_options
---@field forceSaveOnGrantOrRevoke boolean? Whether to save game data immediately when granting or revoking an achievement. Defaults to false.
---@field generateGrantedFromShared boolean? Optionally generate the 'granted' data from shared data to avoid the need to save to the game's data folder. Defaults to false.
---@field preventDebug boolean? Whether to suppress debug output. Defaults to false.

local shared_achievement_folder <const> = "/Shared/Achievements/"
local achievement_file_name <const> = "Achievements.json"
local shared_images_subfolder <const> = "AchievementImages/"
local shared_images_updated_file <const> = "_last_seen_version.txt"

---@diagnostic disable-next-line: lowercase-global
achievements = {
	--- The version of the specification this library follows.
	specVersion = "1.0.0",
	flag_is_playdatesquad_api = true,

	--- Whether to save game data immediately when granting or revoking an achievement.
	forceSaveOnGrantOrRevoke = false,

	--- Optionally generate the 'granted' data from shared data to avoid the need to save to the game's data folder
	generateGrantedFromShared = false,

	--- Whether to suppress debug output. Defaults to false.
	preventDebug = false,

	paths = {},
}

--- Returns a game ID (aka. the bundle ID with user ID stripped out)
---
--- @return string # The formatted game ID.
local function get_game_id()
	return playdate.metadata.bundleID:gsub(
		'^user%.%d+%.',
		''
	)
end

achievements.paths.shared_data_root = shared_achievement_folder

--- Returns the path to the root folder for the game with the supplied `gameID`.
--- 
--- This function doesn't check if the folder at the resulting path exists.
--- 
--- @param gameID string The ID of the game for which to get the path.
--- @return string # The path to the root folder of the game.
function achievements.paths.get_achievement_folder_root_path(gameID)
	if type(gameID) ~= "string" then
		error("bad argument #1: expected string, got " .. type(gameID), 2)
	end
	local root = string.format(shared_achievement_folder .. "%s/", gameID)
	return root
end

--- Returns the path to the file containing the achievement data for the game with the supplied `gameID`.
--- 
--- This function doesn't check if the file at the resulting path exists.
--- 
--- @param gameID string The ID of the game for which to get the path.
--- @return string # The path to the file containing the achievement data for the game.
function achievements.paths.get_achievement_data_file_path(gameID)
	if type(gameID) ~= "string" then
		error("bad argument #1: expected string, got " .. type(gameID), 2)
	end
	local root = achievements.paths.get_achievement_folder_root_path(gameID)
	return root .. achievement_file_name
end

--- Returns the path to the folder containing shared images for the game with the supplied `gameID`.
--- 
--- This function doesn't check if the folder at the resulting path exists.
--- 
--- @param gameID string The ID of the game for which to get the path.
--- @return string # The path to the folder containing shared images for the game.
function achievements.paths.get_shared_images_path(gameID)
	if type(gameID) ~= "string" then
		error("bad argument #1: expected string, got " .. type(gameID), 2)
	end
	local root = achievements.paths.get_achievement_folder_root_path(gameID)
	return root .. shared_images_subfolder
end

--- Returns the path to the file containing the last seen version of the shared images for the game with the supplied `gameID`.
--- 
--- This function doesn't check if the file at the resulting path exists.
--- 
--- @param gameID string The ID of the game for which to get the path.
--- @return string # The path to the file containing the last seen version of the shared images for the game.
function achievements.paths.get_shared_images_updated_file_path(gameID)
	if type(gameID) ~= "string" then
		error("bad argument #1: expected string, got " .. type(gameID), 2)
	end
	local folder = achievements.paths.get_shared_images_path(gameID)
	return folder .. shared_images_updated_file
end

--- Generate progression data from existing shared data.
local function generate_granted_data(gameID)
	if type(gameID) ~= "string" then
		error("bad argument #1: expected string, got " .. type(gameID), 2)
	end

	local sharedData = json.decodeFile(achievements.paths.get_achievement_data_file_path(gameID))

	achievements.granted = {}
	achievements.progress = {}

	if not sharedData then
		return
	end

	local sharedAchievements = sharedData.achievements or {}

	for i = 1, #sharedAchievements do
		if sharedAchievements[i].id ~= nil then
			local id = sharedAchievements[i].id

			if sharedAchievements[i].grantedAt ~= nil then
				achievements.granted[id] = sharedAchievements[i].grantedAt
			end

			if sharedAchievements[i].progress ~= nil then
				achievements.progress[id] = sharedAchievements[i].progress
			end
		end
	end
end

--- Loads progression data.
local function load_granted_data()
	local data = json.decodeFile(achievement_file_name)
	if not data then
		data = {}
	end
	achievements.granted = data.grantedAt or {}
	achievements.progress = data.progress or {}
end

--- Serializes the current game data to JSON and writes it to the shared data folder.
---
--- @param force_minimize boolean Whether to minimize the output by excluding fields with default values. Defaults to false.
local function export_data(force_minimize)
	local data = achievements.gameData
	-- This shouldn't actually be necessary unless the developer starts adding redundant optional fields.
	-- I put it here temporarily and can't be bothered to remove it in case it ever becomes relevant.
	-- (Forcing correct output regardless of user error at the cost of extra time spent, perhaps?)
	if force_minimize then
		data = table.deepcopy(data)
		for _, ach in ipairs(data.achievements) do
			if ach.grantedAt == false then ach.grantedAt = nil end
			if ach.progress == 0 then ach.progress = nil end
			if ach.isSecret == false then ach.isSecret = nil end
			if ach.scoreValue == 1 then ach.scoreValue = nil end
			if ach.progressIsPercentage == false then ach.progressIsPercentage = nil end
		end
	end
	json.encodeToFile(achievements.paths.get_achievement_data_file_path(data.gameID), true, data)
end

--- Returns the parent directory of the supplied string path.
--- 
--- @param str string The string path of which to get the parent directory.
--- @return string # The parent directory of the supplied string path.
local function dirname(str)
	return (string.gsub(str, "[^/\\]*$", ""))
end

--- Changes the file extension of a string path to the supplied extension.
--- 
--- @param str string The string path of which to change the extension.
--- @param new_ext string The new extension to use.
--- @return string # The modified string path.
local function force_extension(str, new_ext)
	return str:gsub("%.%w+$", "") .. new_ext
end

--- Returns a set of the unique image paths for the supplied fields in configured achievements.
--- 
--- This function automatically adds the ".pdi" extension to the paths.
--- 
--- @param ... string The names of the fields to copy.
--- @return table # A set of the unique image paths for the supplied fields.
local function crawlImagePaths(...)
	local filepaths = {}
	local desired_fields = {...}
	for _, fieldname in ipairs(desired_fields) do
		for _, achievement_data in pairs(achievements.keyedAchievements) do
			if achievement_data[fieldname] ~= nil then
				 -- Images are always compiled to .pdi, so we need the real runtime filename for copy.
				 -- We're using a set here as an easy way to prevent duplications.
				filepaths[force_extension(achievement_data[fieldname], ".pdi")] = true
			end
		end
	end
	return filepaths
end

--- Copies the file at `src_path` to the supplied `dest_path`, creating any intermediate directories.
--- 
--- @param src_path string The path to the source file to copy.
--- @param dest_path string The path to the destination file to copy to.
--- @throws If the source file does not exist or if the destination path is invalid.
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
	playdate.file.mkdir(subfolder)

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

--- Copies the images from the game's data folder to the shared images folder.
--- 
--- This function skips copying if the shared folder already contains the images for the current build.
--- 
--- @param gameID string The ID of the game for which to copy the images.
--- @param current_build_nr number The current build number of the game.
--- @throws If the the version file in the shared folder can't be read or written to, or if there's an error copying the images.
local function export_images(gameID, current_build_nr)
	local shared_images_path = achievements.paths.get_shared_images_path(gameID)
	playdate.file.mkdir(shared_images_path)
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
	-- This is a set, so the iteration is a little different than usual.
	for filename, _ in pairs(crawlImagePaths("icon", "iconLocked")) do
		copy_file(filename, shared_images_path .. filename)
	end
	-- These files go in the top-level shared game files directory,
	-- not in the AchievementImages subdirectory.
	local shared_game_data_path = achievements.paths.get_achievement_folder_root_path(gameID)
	for _, metadata_asset in ipairs{"iconPath", "cardPath"} do
		local asset_path = achievements.gameData[metadata_asset]
		if asset_path then
			asset_path = force_extension(asset_path, ".pdi")
			copy_file(asset_path, shared_game_data_path .. asset_path)
		end
	end

	-- also write the version-file
	local ver_file, err = playdate.file.open(verfile_path, playdate.file.kFileWrite)
	if not ver_file then
		error("Couldn't write version file at '" .. verfile_path .. "', because: " .. err, 2)
	end
	ver_file:write(tostring(current_build_nr))
	ver_file:close()
end

--- Does nothing and returns immediately.
local function donothing(...) end

--- Validates the values of the supplied game data.
--- 
--- @param ach_root game_data The game data to validate.
--- @throws If any fields are invalid or if any non-optional fields are missing.
local function validate_gamedata(ach_root)
	local print = (achievements.preventDebug and donothing) or print

	for _, field in ipairs{ "name", "author", "description", "version", } do
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
		ach_root.gameID = get_game_id()
		print('gameID not configured: defaulting to "' .. ach_root.gameID .. '"')
	elseif type(ach_root.gameID) ~= "string" then
		error("expected 'gameID' to be type string, got ".. type(ach_root.gameID), 3)
	end

	ach_root.specVersion = achievements.specVersion
	print("game version saved as \"" .. ach_root.version .. "\"")
	print("specification version saved as \"" .. ach_root.specVersion .. "\"")


	if type(ach_root.iconPath) ~= 'string' and ach_root.iconPath ~= nil then
		error("expected 'iconPath' to be type string, got " .. type(ach_root.iconPath), 3)
	end
	if type(ach_root.cardPath) ~= 'string' and ach_root.cardPath ~= nil then
		error("expected 'cardPath' to be type string, got " .. type(ach_root.cardPath), 3)
	end

	if ach_root.achievements == nil then
		print("WARNING: no achievements configured")
		ach_root.achievements = {}
	elseif type(ach_root.achievements) ~= "table" then
		error("achievements must be a table", 3)
	end
end

--- Validates the values of the supplied achievement.
--- 
--- @param ach achievement The achievement to validate.
--- @throws If any fields are invalid or if any non-optional fields are missing.
local function validate_achievement(ach)
	-- Required Strings
	for _, key in ipairs{"name", "description", "id",} do
		local valtype = type(ach[key])
		if valtype ~= "string" then
			error(("expected '%s' to be type string, got %s"):format(key, valtype), 3)
		end
	end

	-- Optional Strings
	for _, key in ipairs{"descriptionLocked", "icon", "iconLocked",} do
		local valtype = type(ach[key])
		if valtype ~= "string" and valtype ~= "nil" then
			error(("expected '%s' to be type string, got %s"):format(key, valtype), 3)
		end
	end

	if ach.isSecret == nil then
		-- ach.isSecret = false
	elseif type(ach.isSecret) ~= "boolean" then
		error("expected 'isSecret' to be type boolean, got " .. type(ach.isSecret), 3)
	end

	if ach.progressMax then
		if type(ach.progressMax) ~= 'number' then
			error("expected 'progressMax' to be type number, got ".. type(ach.progressMax), 3)
		end
		if ach.progress == nil then
			-- ach.progress = 0
		elseif type(ach.progress) ~= 'number' then
			error("expected 'progress' to be type number, got ".. type(ach.progress), 3)
		end
		if ach.progressIsPercentage == nil then
			-- ach.progressIsPercentage = false
		elseif type(ach.progressIsPercentage) ~= 'boolean' then
			error("expected 'progressIsPercentage' to be type boolean, got " .. type(ach.progressIsPercentage), 3)
		end
	end

	if ach.scoreValue == nil then
		-- ach.scoreValue = 1
	elseif type(ach.scoreValue) ~= "number" then
		error("expected 'scoreValue' to be type number, got ".. type(ach.scoreValue), 3)
	elseif ach.scoreValue < 0 then
		error("field 'scoreValue' cannot be less than 0", 3)
	end
end

--- Initializes the achievement system for the game.
--- 
--- Call this function once, before using other functions in the library.
--- 
--- @param gamedata game_data The game data and achievement definitions to manage.
--- @param options initialize_options Any option to set when initializing.
--- @throws If the supplied data is invalid.
function achievements.initialize(gamedata, options)
	achievements.preventDebug = options.preventDebug or false
	achievements.forceSaveOnGrantOrRevoke = options.forceSaveOnGrantOrRevoke or false
	achievements.generateGrantedFromShared = options.generateGrantedFromShared or false

	local print = (achievements.preventDebug and donothing) or print

	print("------")
	print("Initializing achievements...")


	validate_gamedata(gamedata)
	achievements.gameData = gamedata

	if achievements.generateGrantedFromShared then
		generate_granted_data(gamedata.gameID)
	else
		load_granted_data()
	end

	achievements.keyedAchievements = {}
	for _, ach in ipairs(gamedata.achievements) do
		if achievements.keyedAchievements[ach.id] then
			error("achievement id '" .. ach.id .. "' defined multiple times", 2)
		end
		achievements.keyedAchievements[ach.id] = ach
		ach.grantedAt = achievements.granted[ach.id]
		if ach.progressMax then
			ach.progress = achievements.progress[ach.id]
		end
		validate_achievement(ach)
	end

	playdate.file.mkdir(achievements.paths.get_achievement_folder_root_path(gamedata.gameID))
	export_data()
	export_images(gamedata.gameID, (tonumber(playdate.metadata.buildNumber) or 0))

	print("files exported to /Shared")
	print("Achievements have been initialized!")
	print("------")
end

--- Returns the achievement with the supplied `achievement_id`.
--- 
--- @param achievement_id string The ID of the achievement to retrieve.
--- @return achievement|boolean # The achievement, or false if it doesn't exist.
achievements.getInfo = function(achievement_id)
	return achievements.keyedAchievements[achievement_id] or false
end

--- Returns whether the achievement with the supplied `achievement_id` has been granted.
--- 
--- @param achievement_id string The ID of the achievement to check.
--- @return boolean # Whether the achievement has been granted.
achievements.isGranted = function(achievement_id)
	return achievements.granted[achievement_id] ~= nil
end

--- Grants the achievement with the supplied `achievement_id`.
--- 
--- @param achievement_id string The ID of the achievement to grant.
--- @return boolean # Whether the achievement was successfully granted.
--- @throws If the achievement doesn't exist.
achievements.grant = function(achievement_id)
	local ach = achievements.keyedAchievements[achievement_id]
	if not ach then
		error("attempt to grant unconfigured achievement '" .. achievement_id .. "'", 2)
		return false
	end
	local time, _ = playdate.getSecondsSinceEpoch()
	if ach.grantedAt and ach.grantedAt <= ( time ) then
		return false
	end
	achievements.granted[achievement_id] = ( time )
	ach.grantedAt = time

	if achievements.forceSaveOnGrantOrRevoke then
		achievements.save()
	end
	return true
end

--- Revokes the achievement with the supplied `achievement_id`.
--- 
--- @param achievement_id string The ID of the achievement to revoke.
--- @return boolean # Whether the achievement was successfully revoked.
--- @throws If the achievement doesn't exist.
achievements.revoke = function(achievement_id)
	local ach = achievements.keyedAchievements[achievement_id]
	if not ach then
		error("attempt to revoke unconfigured achievement '" .. achievement_id .. "'", 2)
		return false
	end
	ach.grantedAt = nil
	achievements.granted[achievement_id] = nil
	if achievements.forceSaveOnGrantOrRevoke then
		achievements.save()
	end
	return true
end

--- Advances the achievement with the supplied `achievement_id` to the specified progress.
--- 
--- @param achievement_id string The ID of the achievement to advance.
--- @param advance_to number The progress to advance to.
--- @return boolean # Whether the achievement was successfully advanced.
--- @throws If the achievement doesn't exist or doesn't support incremental progress.
achievements.advanceTo = function(achievement_id, advance_to)
	local ach = achievements.keyedAchievements[achievement_id]
	if not ach then
		error("attempt to progress unconfigured achievement '" .. achievement_id .. "'", 2)
		return false
	end
	if not ach.progressMax then
		error("attempt to progress an achievement without a configured 'progressMax'", 2)
		return false
	end
	local progress = math.max(0, math.min(advance_to, ach.progressMax))
	if progress == ach.progressMax then
		achievements.grant(achievement_id)
	elseif (progress < ach.progressMax) and ach.grantedAt then
		achievements.revoke(achievement_id)
	end
	if progress == 0 then progress = nil end
	achievements.progress[achievement_id] = progress
	ach.progress = progress
	return true
end

--- Advances the achievement with the supplied `achievement_id` by the specified amount.
--- 
--- @param achievement_id string The ID of the achievement to advance.
--- @param advance_by number The amount to advance the achievement by.
--- @return boolean # Whether the achievement was successfully advanced.
--- @throws If the achievement doesn't exist or doesn't support incremental progress.
achievements.advance = function(achievement_id, advance_by)
	local ach = achievements.keyedAchievements[achievement_id]
	if not ach then
		error("attempt to progress unconfigured achievement '" .. achievement_id .. "'", 2)
		return false
	end
	if not ach.progressMax then
		error("attempt to progress an achievement without a configured 'progressMax'", 2)
		return false
	end
	local progress = achievements.progress[achievement_id] or 0
	return achievements.advanceTo(achievement_id, progress + advance_by)
end

--- Returns the fractional completion of all configured achievements, taking into account the `scoreValue` of any achievements if configured.
--- 
--- @return number # The completion percentage as a float between 0 and 1.
achievements.completionPercentage = function()
	local completion_total = 0
	local completion_obtained = 0
	for _, ach in pairs(achievements.keyedAchievements) do
		completion_total += ach.scoreValue or 1
		-- granted achievements score their full weight
		if ach.grantedAt then
			completion_obtained += ach.scoreValue or 1
		-- progressive achievements score partial progress
		elseif ach.progressMax and ach.progress then
			completion_obtained += ach.scoreValue * (ach.progress / ach.progressMax)
		end
	end
	return completion_total > 0 and completion_obtained / completion_total or 1
end

--- Serializes the current game data to JSON and writes it to the data folder.
function achievements.save()
	export_data()

	if not achievements.generateGrantedFromShared then
		local save_table = {
			grantedAt = achievements.granted,
			progress = achievements.progress,
		}

		json.encodeToFile(achievement_file_name, false, save_table)
	end
end

return achievements
