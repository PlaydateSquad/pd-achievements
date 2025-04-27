-- Cross-game data reading module for the PlaydateSquad Achievements library.
if not (achievements and achievements.flag_is_playdatesquad_api) then
	error("Achievements 'crossgame' module must be loaded after the base PlaydateSquad achievement library.")
end

local crossgame = {}
local gfx <const> = playdate.graphics
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
---@return game_data
-- Returns the achievement data for the requested game if it exists. Otherwise returns false and a reason.
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

function crossgame.loadImage(game_id, filepath)
	local image_path = achievements.paths.get_shared_images_path(game_id) .. filepath
	local img, err = gfx.image.new(image_path)
	return img, err
end
