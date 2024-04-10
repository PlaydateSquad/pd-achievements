
--[[
	==prototype achievements library==
	This is an initial prototype implementation in order to help effect a standard.
	This prototype will have no strong error checks and be small in scope. Any
	  wider-scope implementation of the standard will be separate.
--]]

-- Right, we're gonna make this easier to change in the future.
-- Another note: changing the data directory to `/Shared/gameID`
--   rather than the previously penciled in `/Shared/Achievements/gameID`
local shared_achievement_folder <const> = "/Shared/Data/"
local achievement_file_name <const> = "Achievements.json"
local shared_images_subfolder <const> = "AchievementImages/"
local shared_images_updated_file <const> = "_last_seen_version.txt"

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

local function get_achievement_folder_root_path(gameID)
	if type(gameID) ~= "string" then
		error("bad argument #1: expected string, got " .. type(gameID), 2)
	end
	local root = string.format(shared_achievement_folder .. "%s/", gameID)
	return root
end
local function get_achievement_data_file_path(gameID)
	if type(gameID) ~= "string" then
		error("bad argument #1: expected string, got " .. type(gameID), 2)
	end
	local root = get_achievement_folder_root_path(gameID)
	return root .. achievement_file_name
end
local function get_shared_images_path(gameID)
	if type(gameID) ~= "string" then
		error("bad argument #1: expected string, got " .. type(gameID), 2)
	end
	local root = get_achievement_folder_root_path(gameID)
	return root .. shared_images_subfolder
end
local function get_shared_images_updated_file_path(gameID)
	if type(gameID) ~= "string" then
		error("bad argument #1: expected string, got " .. type(gameID), 2)
	end
	local folder = get_shared_images_path(gameID)
	return folder .. shared_images_updated_file
end

local metadata <const> = playdate.metadata

---@diagnostic disable-next-line: lowercase-global
achievements = {
	specversion = "0.1+prototype",
	libversion = "0.2-alpha+prototype",

	forceSaveOnGrantOrRevoke = false,
}

local function load_granted_data()
	local data = json.decodeFile(achievement_file_name)
	if not data then
		data = {}
	end
	achievements.granted = data
end

local function export_data()
	local data = achievements.gameData
	json.encodeToFile(get_achievement_data_file_path(data.gameID), true, data)
end
function achievements.save()
	export_data()
	json.encodeToFile(achievement_file_name, false, achievements.granted)
end

achievements.getPaths = function(gameID, variables)
	local shared_folder = get_shared_images_path(gameID)
	local result = {}
	for _, variable in ipairs(variables) do
		for _, value in pairs(achievements.keyedAchievements) do
			if value[variable] ~= nil then
				local ref = value[variable]
				local filename = force_extension(value[variable], "pdi") -- Always compiled to .pdi, (so use like pd.image.new).
				result[ref] = { native = filename, shared = ( shared_folder .. filename ) }
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

local function copy_images_to_shared(gameID, current_build_nr)
	-- if >= the current version of the gamedata already exists, no need to re-copy the images
	local path = get_shared_images_updated_file_path(gameID)
	if playdate.file.exists(path) and not playdate.file.isdir(path) then
		local ver_file, err = playdate.file.open(path, playdate.file.kFileRead)
		if not ver_file then
			error("Couldn't read version file at '" .. path .. "', because: " .. err, 2)
		end
		local ver_str = ver_file:readline() or "0.0.0"
		ver_file:close()
		local ver = tonumber(ver_str) or -1
		if ver >= current_build_nr then
			return
		end
	end

	-- otherwise, the structure should be copied
	local folder = get_shared_images_path(gameID)
	if playdate.file.exists(folder) then
		playdate.file.delete(folder, true)
	end
	playdate.file.mkdir(folder)
	for _, paths in pairs(achievements.getPaths(gameID, { "icon", "icon_locked" })) do
		if paths.native:sub(1,1) ~= "*" then
			copy_file(paths.native, paths.shared)
		end
	end

	-- also write the version-file
	local ver_file, err = playdate.file.open(path, playdate.file.kFileWrite)
	if not ver_file then
		error("Couldn't write version file at '" .. path .. "', because: " .. err, 2)
	end
	ver_file:write(tostring(current_build_nr))
	ver_file:close()
end

local function donothing(...) end
function achievements.initialize(gamedata, prevent_debug)
	local print = (prevent_debug and donothing) or print
	print("------")
	print("Initializing achievements...")
	if gamedata.achievements == nil then
		print("WARNING: no achievements configured")
		gamedata.achievements = {}
	elseif type(gamedata.achievements) ~= "table" then
		error("achievements must be a table", 2)
	end
	if gamedata.gameID == nil then
		gamedata.gameID = string.gsub(metadata.bundleID, "^user%.%d+%.", "")
		print('gameID not configured: defaulting to "' .. gamedata.gameID .. '"')
	elseif type(gamedata.gameID) ~= "string" then
		error("gameID must be a string", 2)
	end
	for _, field in ipairs{ "name", "author", "description", "version", "buildNumber", } do
		if gamedata[field] == nil then
			if playdate.metadata[field] ~= nil then
				gamedata[field] = playdate.metadata[field]
				print(field .. ' not configured: defaulting to "' .. gamedata[field] .. '"')
			else
				print("WARNING: " .. field .. " not configured AND not present in pxinfo metadata")
			end
		elseif type(gamedata[field]) ~= "string" then
			error(field .. " must be a string", 2)
		end
	end
	gamedata.version = metadata.version
	gamedata.specversion = achievements.specversion
	gamedata.libversion = achievements.libversion
	print("game version saved as \"" .. gamedata.version .. "\"")
	print("specification version saved as \"" .. gamedata.specversion .. "\"")
	print("library version saved as \"" .. gamedata.libversion .. "\"")
	achievements.gameData = gamedata

	load_granted_data()

	achievements.keyedAchievements = {}
	for _, ach in ipairs(gamedata.achievements) do
		if achievements.keyedAchievements[ach.id] then
			error("achievement id '" .. ach.id .. "' defined multiple times", 2)
		end
		achievements.keyedAchievements[ach.id] = ach
		ach.granted_at = achievements.granted[ach.id] or false
	end

	playdate.file.mkdir(get_achievement_folder_root_path(gamedata.gameID))
	export_data()
	copy_images_to_shared(gamedata.gameID, (tonumber(gamedata.buildNumber) or 0))

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

--[[ External Game Functions ]]--

achievements.gamePlayed = function(game_id)
	return playdate.file.isdir(get_achievement_folder_root_path(game_id))
end

achievements.gameData = function(game_id)
	if not achievements.gamePlayed(game_id) then
		error("No game with ID '" .. game_id .. "' was found", 2)
	end
	local data = json.decodeFile(get_achievement_data_file_path(game_id))
	local keys = {}
	for _, ach in ipairs(data.achievements) do
		keys[ach.id] = ach
	end
	data.keyedAchievements = keys
	return data
end


return achievements
