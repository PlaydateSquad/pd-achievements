-- Cross-game data reading module for the PlaydateSquad Achievements library.
import "./achievements"

local crossgame = {}
achievements.crossgame = crossgame

-- Returns whether a game has any listed achievement data.
crossgame.gamePlayed = function(game_id)
	return playdate.file.isdir(achievements.paths.get_achievement_folder_root_path(game_id))
end

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

---@param game_id string
---@return achievement_root
-- Returns the achievement data for the requested game if it exists. Otherwise returns false and a reason.
crossgame.getData = function(game_id)
	if not crossgame.gameHasAchievements then
		return false, "No achievements file for game '" .. game_id .. "' was found"
	end
	local data = json.decodeFile(achievements.paths.get_achievement_data_file_path(game_id))
	-- Quick sanity check...
	if not (data.libversion and data.specversion) then
		return false, "Achievement file was found but not valid."
	end
	local completion_total = 0
	local completion_obtained = 0
	local keys = {}
	for _, ach in ipairs(data.achievements) do
		keys[ach.id] = ach
		completion_total += score_value
		if ach.granted_at then
			completion_obtained += score_value
		end
	end
	data.keyedAchievements = keys
	data.completionPercentage = completion_obtained / completion_total
	return data
end

crossgame.loadImage(game_id, filepath)
	local image_path = achievements.paths.get_shared_images_path(game_id) .. filepath
	local img, err = gfx.image.new(image_path)
	if not img then
		error(("image '%s' could not be loaded: "):format(filename) .. err)
	else
		return img
	end
end