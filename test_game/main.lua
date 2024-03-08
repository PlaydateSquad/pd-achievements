local gfx = playdate.graphics

import "../achievements"

-- Copied from the comments in the other file...
local achievementData = {
    -- Technically, any string. We need to spell it out explicitly
    --   instead of using metadata.bundleID so that it won't get 
    --   mangled by online sideloading. Plus, this way multi-pdx
    --   games or demos can share achievements.
    gameID = "com.yourcompany.yourgame",
    -- These are optional, and will be auto-filled with metadata
    --   values if not specified here. This is also for multi-pdx
    --   games.
    name = "My Awesome Game",
    author = "You, Inc",
    description = "The next evolution in cranking technology.",
    -- And finally, a table of achievements.
    achievements = {
        {
            id = "test_achievement",
            name = "Achievement Name",
            description = "Achievement Description",
            is_secret = false,
            icon = "filepath" -- to be iterated on
            --[more to be determined]
        },
        {
            id = "test_achievement_2",
            name = "Achievement Name",
            description = "Achievement Description",
            is_secret = false,
            icon = "filepath" -- to be iterated on
            --[more to be determined]
        },
    }
}

achievements.initialize(achievementData)

function playdate.keyPressed(key)
    if key == "f" then
        if achievements.granted["test_achievement"] then
            print("revoking example achievement 1")
            achievements.revoke("test_achievement")
        else
            print("granting example achievement 1")
            achievements.grant("test_achievement")
        end
    elseif key == "g" then
        if achievements.granted["test_achievement_2"] then
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
    playdate.graphics.drawText("R: save/export data", 10, 100)

end