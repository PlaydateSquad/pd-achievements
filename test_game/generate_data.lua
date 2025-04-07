import "CoreLibs/ui"
local gfx <const> = playdate.graphics

-- Let's generate some example data for our stock reader.
function remove_generated_game_data()
    for _, path in ipairs(playdate.file.listFiles(achievements.paths.shared_data_root)) do
        if string.match(path, "^com%.example%.achievementtest_generated_%d+/$") then
            print("deleting example data:" .. path)
            playdate.file.delete(achievements.paths.shared_data_root .. path, true)
		end
	end
end
function generate_game_data(numgames, achievements_min, achievements_max)
    numgames = numgames or 10
    achievements_min = achievements_min or 10
    achievements_max = achievements_max or 20
    local score_min, score_max = 0, 3
    local prog_min, prog_max = 5, 20
    remove_generated_game_data()
    local base_id <const> = "com.example.achievementtest_generated_"
	playdate.resetElapsedTime()
    for i = 1, numgames do
        local gamedata = {
            gameID = base_id .. i,
            name = "Generated Example " .. i,
            author = "Procedural Generation",
            description = "Auto-generated random game data for achievement viewer testing. (#" .. i ..")",
            version = "0.0.0",
            specVersion = achievements.specVersion,
            achievements = {},
        }
        -- Begin generating achievement data.
        local achievement_number = 0
        local max = math.random(achievements_min, achievements_max)
        for i = 1, max do
            achievement_number += 1
            local ach = {
                id = "generated_achievement_" .. achievement_number,
                name = "Generated Achievement " .. achievement_number,
                description = "Auto-generated random achievement for achievement viewer testing.",
                grantedAt = false,
                isSecret = false,
                scoreValue = math.random(score_min, score_max),
            }
            --[[
                Testing, in order:
                - normal ungranted
                - normal granted
                - secret but ungranted
                - secret but granted
                - progress-based ungranted normal
                - progress-bases granted normal
                - progress-based ungranted percentage
                - progress-based granted percentage
            --]]
            local achievement_type = math.random(1, 8)
            -- Every other category is granted.
            if achievement_type % 2 == 0 then
                ach.grantedAt = playdate.getSecondsSinceEpoch()
            end
            -- Secret achievements
            if achievement_type == 3 or achievement_type == 4 then
                ach.isSecret = true
            end
            -- Progress-based achievements
            if achievement_type > 4 then
                ach.progressMax = math.random(prog_min, prog_max)
                ach.progress = math.random(0, ach.progressMax - 1)
                ach.progressIsPercentage = false
                -- Ensure continuity between completion and progress.
                if ach.grantedAt then
                    ach.progress = ach.progressMax
                end
            end
            if achievement_type > 6 then
                ach.progressIsPercentage = true
            end
            table.insert(gamedata.achievements, ach)
			local time_taken = playdate.getElapsedTime()
			if time_taken > 8 then
				playdate.resetElapsedTime()
				coroutine.yield()
			end
        end
        -- End generating achievement data.
        playdate.file.mkdir(achievements.paths.get_achievement_folder_root_path(gamedata.gameID))
        json.encodeToFile(achievements.paths.get_achievement_data_file_path(gamedata.gameID), true, gamedata)
    end
end

local data_generate_screen = playdate.ui.gridview.new(0, 20)
local numgame, achmin, achmax = 10, 10, 20
data_generate_screen:setNumberOfRows(3)
function data_generate_screen:drawCell(section, row, column, selected, x, y, width, height)
    if selected then
        gfx.fillCircleInRect(x, y + (height/2) - 3, 6, 6, 3)
    end
    playdate.graphics.drawText(({
        "number of games: " .. numgame,
        "minimum achievements per game: " .. achmin,
        "maximum achievements per game: " .. achmax,
    })[row], x + 10, y)
end
local left_repeat, right_repeat = 0, 0
local just_pressed_a = false
increment_numbers = function(by)
    local sel = data_generate_screen:getSelectedRow()
    if sel == 1 then
        numgame = math.max(numgame + by, 0)
    elseif sel == 2 then
        achmin = math.max(achmin + by, 1)
    else
        achmax = math.max(achmax + by, 2)
    end
end
Scenes.GENERATE_DATA = {
    enter = function()
        left_repeat, right_repeat = 0, 0
        just_pressed_a = false
    end,
    downButtonDown = function()
        data_generate_screen:selectNextRow(true)
    end,
    upButtonDown = function()
        data_generate_screen:selectPreviousRow(true)
    end,
    AButtonDown = function()
        just_pressed_a = true
    end,
	BButtonDown = function()
		CHANGE_SCENE("MAIN_DEBUG")
	end,
    update = function()
        if just_pressed_a then
            gfx.clear()
            gfx.drawText("generating random game data...", 20, 20)
            playdate.display.flush()
            print("generating random game data...")
            generate_game_data(numgame, achmin, achmax)
            print("done")
            CHANGE_SCENE("MAIN_DEBUG")
        end
        if playdate.buttonIsPressed("left") then
            left_repeat += 1
            if left_repeat == 1 or left_repeat > 30 then
                increment_numbers(-1)
            end
        else
            left_repeat = 0
        end
        if playdate.buttonIsPressed("right") then
            right_repeat += 1
            if right_repeat == 1 or right_repeat > 30 then
                increment_numbers(1)
            end
        else
            right_repeat = 0
        end
        gfx.clear()
        data_generate_screen:drawInRect(10, 10, 390, 230)
        playdate.drawFPS(0,0)
    end
}
