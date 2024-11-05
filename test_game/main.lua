local gfx = playdate.graphics

import "achievements/all"

-- Copied from the comments in the other file...
---@type achievement_root
local achievementData = {
    gameID = "com.example.achievementtest",
    name = "My Awesome Game",
    author = "You, Inc",
    description = "The next (r)evolution in cranking technology.",
    defaultIcon = "default/test (default)",
    defaultIconLocked = "default/test_locked (default)",
    achievements = {
        {
            id = "test_achievement",
            name = "Achievement Name",
            description = "Achievement Description",
            is_secret = false,
            icon = "achievements/graphics/achievement-unlock",
            icon_locked = "test_locked",
        },
        {
            id = "test_achievement_2",
            name = "Name Of Achievement",
            description = "Achievement Description",
            is_secret = false,
            icon = nil,
            icon_locked = nil,
        },
        {
            id = "test_achievement_3",
            name = "Name Of Achievement",
            description = "Achievement Description",
            is_secret = false,
            icon = nil,
            icon_locked = nil,
            progress_max = 5,
        },
    }
}

achievements.initialize(achievementData)

local sheet = gfx.imagetable.new("achievements/graphics/achievement-lock")
function animate_unlock(ach, x, y, elapsed)
    local msec_threshhold = 50
    local frames = math.floor(elapsed / msec_threshhold)
    if frames < 24 then
        frames = math.floor(frames / 2)
    end
    if frames <= 4 then
        sheet:drawImage(frames, 300, 10)
    elseif frames > 4 and frames <= 8 then
        sheet:drawImage(5 - (frames - 5), 300, 10)
    elseif frames >= 9 and frames < 12 then
        sheet:drawImage(6, 300, 10)
    elseif frames >= 24 and frames < (24 + 16) then
        gfx.setClipRect(300, 10, 32, 32)
        local select_icon = ach.icon or achievements.gameData.defaultIcon or "*_default_icon"
        achievements.graphics.get_image(select_icon):draw(300, 10)
        sheet:drawImage(6, 300, 10 + ((frames - 24) * 2))
        gfx.clearClipRect()
    elseif frames >= (24 + 16) and frames < 70 then
        local select_icon = ach.icon or achievements.gameData.defaultIcon or "*_default_icon"
        achievements.graphics.get_image(select_icon):draw(300, 10)
    elseif frames >= 70 then
        return false
    end
    return true
end

local sheet = gfx.imagetable.new("achievements/graphics/achievement-secret")
function animate_secret(ach, x, y, elapsed)
    local msec_threshhold = 200
    local frames = math.floor(elapsed / msec_threshhold)
    local offset = (frames % 2 == 0) and 2 or 1
    -- gfx.setClipRect(300, 10, 32, 32)
    if frames <= 6 then
        sheet:drawImage(offset, 300, 10)
    elseif frames > 6 and frames <= 20 then
        local select_icon = ach.icon or achievements.gameData.defaultIcon or "*_default_icon"
        achievements.graphics.get_image(select_icon):draw(300, 10)
        sheet:getImage(offset):drawFaded(300, 10, 1-((frames - 6)/14), gfx.image.kDitherTypeBayer8x8)
    elseif frames <= 30 then
        local select_icon = ach.icon or achievements.gameData.defaultIcon or "*_default_icon"
        achievements.graphics.get_image(select_icon):draw(300, 10)
    else
        return false
    end
    return true
end

function playdate.keyPressed(key)
    if key == "f" then
        if achievements.isGranted("test_achievement") then
            print("revoking example achievement 1")
            achievements.revoke("test_achievement")
        else
            print("granting example achievement 1")
            achievements.grant("test_achievement", animate_unlock)
        end
    elseif key == "g" then
        if achievements.isGranted("test_achievement_2") then
            print("revoking example achievement 2")
            achievements.revoke("test_achievement_2")
        else
            print("granting example achievement 2")
            achievements.grant("test_achievement_2", animate_secret)
        end
    elseif key == "h" then
        print("granting invalid achievement")
        achievements.grant("invalid")
    elseif key == "j" then
        print("revoking invalid achievement")
        achievements.revoke("invalid")
    elseif key == "r" then
        print("saving/exporting")
        achievements.save()
    elseif key == "x" then
        print("achiement 3: -1 completion")
        achievements.advance("test_achievement_3", -1)
    elseif key == "c" then
        print("achiement 3: +1 completion")
        achievements.advance("test_achievement_3", 1)
    end
end

gfx.setColor(gfx.kColorBlack)

function playdate.update()
    gfx.fillRect(0, 0, 400, 240)
    playdate.drawFPS(0,0)
    gfx.pushContext()
    playdate.graphics.setImageDrawMode(playdate.graphics.kDrawModeFillWhite)
    playdate.graphics.drawText("F: grant/revoke 1", 10, 20)
    playdate.graphics.drawText("G: grant/revoke 2", 10, 40)
    playdate.graphics.drawText("H: grant invalid", 10, 60)
    playdate.graphics.drawText("J: invoke invalid", 10, 80)
    playdate.graphics.drawText("X: achievement 3 progress: -1", 10, 120)
    playdate.graphics.drawText("C: achievement 3 progress: +1", 10, 140)
    playdate.graphics.drawText("R: save/export data", 10, 100)
    gfx.popContext()
    achievements.graphics.updateVisuals()
end
