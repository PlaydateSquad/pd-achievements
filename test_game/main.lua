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
            isSecret = false,
            -- icon = "achievements/graphics/achievement-unlock",
            iconLocked = "test_locked",
        },
        {
            id = "test_achievement_2",
            name = "Name Of Achievement",
            description = "Achievement Description",
            isSecret = false,
            icon = nil,
            iconLocked = nil,
        },
        {
            id = "test_achievement_3",
            name = "Name Of Achievement",
            description = "Achievement Description",
            isSecret = false,
            icon = nil,
            iconLocked = nil,
            progressMax = 5,
        },
    }
}

achievements.initialize(achievementData)
achievements.graphics.default_toast = achievements.graphics.toasts.falling_card

gfx.setColor(gfx.kColorBlack)

Scenes = {}
Scenes.fallback = {
    update = function()
        playdate.graphics.clear()
        playdate.graphics.drawText("error: please switch to an actual scene", 10, 20)
    end
}
local CURRENT_SCENE = "fallback"

function CHANGE_SCENE(new_scene, ...)
    assert(type(new_scene) == "string", "argument[1] 'new_scene' must be a string")
    assert(Scenes[new_scene], "attempt to switch to an invalid scene: " .. new_scene)
    playdate.inputHandlers.pop()
    playdate.inputHandlers.push(Scenes[new_scene])
    CURRENT_SCENE = Scenes[new_scene]
    if Scenes[new_scene].enter then
        Scenes[new_scene].enter(...)
    end
end

import "CoreLibs/ui"
import "generate_data"
import "simple_viewer"
import "achievements/viewer/achievements_viewer"

local main_screen = playdate.ui.gridview.new(0, 20)
local options = {
    {"GENERATE RANDOM DATA", function() 
        CHANGE_SCENE("GENERATE_DATA")
    end},
    {"GO TO BASIC VIEWER", function()
        CHANGE_SCENE("simple_viewer")
    end},
    {"GO TO FANCY VIEWER", function()
	achievementsViewer.launch()
    end},
    {"fancy toast", function()
	achievementsViewer.toast("test_achievement")
    end},
    {"grant/revoke 1", function() 
        if achievements.isGranted("test_achievement") then
            print("revoking example achievement 1")
            achievements.revoke("test_achievement")
        else
            print("granting example achievement 1")
            achievements.grant("test_achievement", achievements.graphics.toasts.unlock)
        end
    end},
    {"grant/revoke 2", function() 
        if achievements.isGranted("test_achievement_2") then
            print("revoking example achievement 2")
            achievements.revoke("test_achievement_2")
        else
            print("granting example achievement 2")
            achievements.grant("test_achievement_2", achievements.graphics.toasts.secret)
        end
    end},
    {"grant invalid", function() 
        print("granting invalid achievement")
        achievements.grant("invalid")
    end},
    {"revoke invalid", function() 
        print("revoking invalid achievement")
        achievements.revoke("invalid")
    end},
    {"save/export data", function() 
        print("saving/exporting")
        achievements.save()
    end},
    {"achievement 3 progress -1", function() 
        print("achiement 3: -1 completion")
        achievements.advance("test_achievement_3", -1)
    end},
    {"achievement 3 progress +1", function() 
        print("achiement 3: +1 completion")
        achievements.advance("test_achievement_3", 1)
    end},
}
main_screen:setNumberOfRows(#options)
function main_screen:drawCell(section, row, column, selected, x, y, width, height)
    gfx.pushContext()
    gfx.setImageDrawMode(gfx.kDrawModeFillWhite)
    gfx.setColor(gfx.kColorWhite)
    if selected then
        gfx.fillCircleInRect(x, y + (height/2) - 3, 6, 6, 3)
    end
    playdate.graphics.drawText(options[row][1], x + 10, y)
    gfx.popContext()
end
Scenes.MAIN_DEBUG = {
    downButtonDown = function()
        main_screen:selectNextRow(true)
    end,
    upButtonDown = function()
        main_screen:selectPreviousRow(true)
    end,
    AButtonDown = function()
        options[main_screen:getSelectedRow()][2]()
    end,
    update = function()
        gfx.fillRect(0, 0, 400, 240)
        main_screen:drawInRect(10, 10, 390, 230)
        playdate.drawFPS(0,0)
        achievements.graphics.updateVisuals()
    end
}

function playdate.update()
    CURRENT_SCENE.update()
    playdate.timer.updateTimers()
end

CHANGE_SCENE("MAIN_DEBUG")