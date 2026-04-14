import "CoreLibs/ui"
local gfx <const> = playdate.graphics

-- Let's generate some example data for our stock reader.
function remove_generated_game_data()
    -- for _, path in ipairs(playdate.file.listFiles(achievements.paths.shared_data_root)) do
    --     if string.match(path, "^com%.example%.achievementtest_generated_%d+/$") then
    --         print("deleting example data:" .. path)
    --         playdate.file.delete(achievements.paths.shared_data_root .. path, true)
	-- 	end
	-- end
end
function generate_slots(numslots, num_achievements)
    numslots = numslots or 3
    num_achievements = num_achievements or 100
   
    remove_generated_game_data()

    local base_id <const> = "com.example.achievementtest_slots_aggregate"
	playdate.resetElapsedTime()
    for j = 1, numslots do
        local gamedata = {
            gameID = base_id,
            name = "Save Slots Test",
            author = "Procedural Generation",
            description = "Auto-generated random game data for achievement viewer testing. (slots)",
            version = "0.0.0",
            specVersion = achievements.specVersion,
            achievements = {},
        }
        -- Begin generating achievement data.
        local achievement_number = 0
        for i = 1, num_achievements do
            print("generating " .. j .. " | " .. i)
            local ach = {
                id = "generated_achievement_" .. i,
                name = "Generated Achievement " .. i,
                description = "Auto-generated random achievement for achievement viewer testing.",
                -- grantedAt = false,
                -- isSecret = false,
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
            -- local achievement_type = math.random(1, 8)
            local achievement_type = (i % 8) + 1
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
                ach.progressMax = 20
                ach.progress = math.random(0, ach.progressMax - 1)
                -- ach.progressIsPercentage = false
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
        json.encodeToFile(achievements.paths.get_achievement_data_file_path(gamedata.gameID) .. "_slot_" .. j .. ".json", true, gamedata)
    end
end

local function compare_slots(numslots)
    local s = {}
    for i = 1, numslots do
        s[i] = json.decodeFile((achievements.paths.get_achievement_data_file_path("com.example.achievementtest_slots_aggregate")
            .. "_slot_" .. i ..".json"))
    end
    local final = table.deepcopy(s[1])
    for si = 2, #s do
        local slot = s[si]
        for ai = 1, #final.achievements do
            local ach1, ach2 = final.achievements[ai], slot.achievements[ai]
            --- First, check grantedAt timestamps and take the older one.
            --- Then, check progress, if progress-based..
            local g1, g2 = ach1.grantedAt, ach2.grantedAt
            if not g1 and not g2 then
                if ach1.progressMax then
                    ach1.progress = math.max(ach1.progress or 0, ach2.progress or 0)
                end
            else
                ach1.grantedAt = math.max(ach1.grantedAt or -1, ach2.grantedAt or -1)
                if ach1.grantedAt == -1 then ach1.grantedAt = nil end
            end
        end
    end
    playdate.file.mkdir(achievements.paths.get_achievement_folder_root_path("com.example.achievementtest_slots_aggregate_final"))
    json.encodeToFile(achievements.paths.get_achievement_data_file_path("com.example.achievementtest_slots_aggregate_final"), true, final)
end

local data_generate_screen = playdate.ui.gridview.new(0, 20)
local numslots, numach = 3, 100
data_generate_screen:setNumberOfRows(4)
function data_generate_screen:drawCell(section, row, column, selected, x, y, width, height)
    if selected then
        gfx.fillCircleInRect(x, y + (height/2) - 3, 6, 6, 3)
    end
    playdate.graphics.drawText(({
        "number of slots: " .. numslots,
        "minimum achievements per game: " .. numach,
        "generate",
        "compare"
        -- "maximum achievements per game: " .. achmax,
    })[row], x + 10, y)
end
local left_repeat, right_repeat = 0, 0
local just_pressed_a = false
increment_numbers = function(by)
    local sel = data_generate_screen:getSelectedRow()
    if sel == 1 then
        numslots = math.max(numslots + by, 0)
    elseif sel == 2 then
        numach = math.max(numach + by, 1)
    end
end
Scenes.GENERATE_SLOTS = {
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
    AButtonUp = function()
        just_pressed_a = false
    end,
	BButtonDown = function()
		CHANGE_SCENE("MAIN_DEBUG")
	end,
    update = function()
        if just_pressed_a then
            just_pressed_a = false
            local sel = data_generate_screen:getSelectedRow()
            if sel == 3 then
                gfx.clear()
                gfx.drawText("generating random game data...", 20, 20)
                playdate.display.flush()
                print("generating random game data...")
                generate_slots(numslots, numach)
                print("done")
                -- CHANGE_SCENE("MAIN_DEBUG")
            elseif sel == 4 then
                gfx.clear()
                gfx.drawText("comparing slots...", 20, 20)
                playdate.display.flush()
                print("merging slots...")
                print(playdate.getCurrentTimeMilliseconds())
                compare_slots(numslots)
                print(playdate.getCurrentTimeMilliseconds())
                print("done")
            end
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
