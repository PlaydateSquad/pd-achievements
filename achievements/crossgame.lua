--[[
	PlaydateSquad Achievements Library
	https://github.com/PlaydateSquad/pd-achievements

	This library provides an implementation of a shared format for achievements on Playdate.
	See the README.md file for more information.

	This software is released to the public domain using the Unlicense license agreement <https://unlicense.org>.
--]]

if not (achievements and achievements.flag_is_playdatesquad_api) then
	error("Achievements 'crossgame' module must be loaded after the base PlaydateSquad achievement library.")
end

local crossgame = {}
local gfx <const> = playdate.graphics
achievements.crossgame = crossgame

--- Checks if a shared data folder exists for a game with the supplied `game_id`.
--- 
--- @param game_id string The ID of the game to check.
--- @return boolean # Whether a shared data folder exists for the game.
crossgame.gamePlayed = function(game_id)
	return playdate.file.isdir(achievements.paths.get_achievement_folder_root_path(game_id))
end

--- Returns a list of game IDs with shared data folders.
--- 
--- @return table # A list of game IDs with shared data folders.
crossgame.listGames = function()
	local games = {}
	for _, path in ipairs(playdate.file.listFiles(achievements.paths.shared_data_root)) do
		if string.sub(path, -1) == "/" then
			local gameid = string.sub(path, 1, -2)
			table.insert(games, gameid)
		end
	end
	return games
end

--- Deserializes the shared achievement data for the game with the supplied `game_id`.
--- 
--- This function doesn't validate that the data is valid.
--- 
--- @param game_id string The ID of the game for which to get data.
--- @return game_data # The achievement data for the game, or false if it doesn't exist.
crossgame.getData = function(game_id)
	if not crossgame.gamePlayed then
		return false, "No achievement data for game '" .. game_id .. "' was found."
	end
	local data = json.decodeFile(achievements.paths.get_achievement_data_file_path(game_id))
	-- Quick sanity check...
	if not data.specVersion then
		return false, "Achievement file was found but not valid."
	end
	local completion_total = 0
	local completion_obtained = 0
	local keys = {}
	for _, ach in ipairs(data.achievements) do
		keys[ach.id] = ach
		if not ach.scoreValue then ach.scoreValue = 1 end
		completion_total += ach.scoreValue
		-- granted achievements score their full weight
		if ach.grantedAt then
			completion_obtained += ach.scoreValue
		-- progressive achievements score partial progress
		elseif ach.progressMax and ach.progress then
			completion_obtained += ach.scoreValue * (ach.progress / ach.progressMax)
		end
	end
	data.keyedAchievements = keys
	data.completionPercentage = completion_total > 0 and completion_obtained / completion_total or 1
	return data
end

--- Loads an image from the shared images folder for the game with the supplied `game_id`.
--- 
--- @param game_id string The ID of the game for which to load the image.
--- @param filepath string The path to the image file, relative to the shared images folder.
--- @return playdate.graphics.image # The loaded image, or nil if it couldn't be loaded.
function crossgame.loadImage(game_id, filepath)
	local image_path = achievements.paths.get_shared_images_path(game_id) .. filepath
	local img, err = gfx.image.new(image_path)
	return img, err
end
