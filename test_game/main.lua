local gfx = playdate.graphics

import "../achievements"
import "../toast_graphics"

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
            icon = "test",
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

function playdate.keyPressed(key)
    if key == "f" then
        if achievements.isGranted("test_achievement") then
            print("revoking example achievement 1")
            achievements.revoke("test_achievement")
        else
            print("granting example achievement 1")
            achievements.grant("test_achievement")
        end
    elseif key == "g" then
        if achievements.isGranted("test_achievement_2") then
            print("revoking example achievement 2")
            achievements.revoke("test_achievement_2")
        else
            print("granting example achievement 2")
            achievements.grant("test_achievement_2")
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
playdate.graphics.setImageDrawMode(playdate.graphics.kDrawModeFillWhite)

function playdate.update()
    gfx.fillRect(0, 0, 400, 240)
    playdate.drawFPS(0,0)
    playdate.graphics.drawText("F: grant/revoke 1", 10, 20)
    playdate.graphics.drawText("G: grant/revoke 2", 10, 40)
    playdate.graphics.drawText("H: grant invalid", 10, 60)
    playdate.graphics.drawText("J: invoke invalid", 10, 80)
    playdate.graphics.drawText("X: achievement 3 progress: -1", 10, 120)
    playdate.graphics.drawText("C: achievement 3 progress: +1", 10, 140)
    playdate.graphics.drawText("R: save/export data", 10, 100)
    achievements.toast_graphics.updateVisuals()
end
