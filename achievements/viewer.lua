import "CoreLibs/graphics"
import "CoreLibs/object"
import "CoreLibs/crank"
import "CoreLibs/ui"

local gfx <const> = playdate.graphics

--[[ Achievements Viewer

   This provides a modal "achievements viewer" screen that you can easily use in
   your game to display achievements using a consistent UI that feels like part
   of the Playdate OS.

   To use it:

   - Import achievements.lua, then graphics.lua, then viewer.lua. If you are
     also using toasts.lua, you can import either viewer.lua or toasts.lua
     first, it doesn't matter which.

   - Ensure all of the required assets are in the "achievements/assets"
     directory of your game. Many of these assets are also used by toasts.lua.

   - Call achievements.viewer.launch() when you want to display the achievements
     viewer. (Ensure that you return out from your playdate.update function
     immediately after making this call, or at least as soon as possible.)

   - When you run achievements.viewer.launch(), the viewer will temporarily take
     over your playdate.update function, blocking execution of your game. When
     the user exits the achievements viewer by pressing the B button, control
     will be returned to your previous playdate.update function.

   For more advanced use, you can set various config options below, for example:
   achievements.viewer.launch({
   numDescriptionLines = 1,
   fadeColor = gfx.kColorWhite,
   }).

   Startup delay: The first time you call launch(), there will be a slight delay
   as it loads assets; to prevent this, call achievements.viewer.initialize()
   ahead of time. You can also pass in config settings to initialize().

   Device state: The viewer attempts to back up and restore as much device state
   as possible to avoid affecting your game, including refresh rate, display
   scale, and input handlers. If you find that it's overriding any settings
   you'd otherwise like to keep, you can either restore them using the
   returnToGameFunction config setting, or modify the backupUserSettings and
   restoreUserSettings functions below (and feel free to submit a PR).

   Note: launching the viewer does not affect the Playdate system menu, so if
   you have any menu items set up, they will still be usable while the viewer
   is on screen. If you ever need to force the viewer to exit (for example if the
   user chooses a "exit" menu option), call achievements.viewer.forceExit().
]]

-- These are the settings you can pass to initialize() and launch() the first time.
-- initialize() is optional, and will be automatically run when you call launch().
local defaultConfig = {
   -- Set the path that you've placed the achievements viewer's fonts, images,
   -- and sounds. Be sure to include the trailing slash.
   assetPath = "achievements/assets/",

   -- Number of lines of the achievement description to display. Setting this to 1
   -- lets you fit more achievements on screen, if they all have very short
   -- descriptions. If you have long descriptions, you may need to set this to 3.
   -- This has been tested in the range of 0 (don't show descriptions) to 3.
   numDescriptionLines = 2,

   -- What color to fade the background with when launching?  Typically, if your
   -- game looks dark, the viewer will look best if you set this to white. You
   -- can also use clear to not fade the BG at all.
   fadeColor = gfx.kColorBlack,

   -- Allow the user to press the A button to view a popup with a QR code with
   -- more information about Playdate Achievements. Set this to false to remove
   -- the About popup.
   enableAboutScreen = true,

   -- Normally, a black header row is displayed, followed by white cards for the
   -- achievements. Set this to true to show dark cards with a light header row
   -- instead. (Achievement icons will still display normally and won't be
   -- inverted.)
   invertCards = false,

   -- The default audio volume to use for the achievement viewer's sound
   -- effects. This should range from 0 to 1. You can modify this after the
   -- first time by calling achievements.viewer.setSoundVolume(), for example if
   -- the user changes a "sound effects volume" in-game option..
   soundVolume = 1,

   -- The default sort order to display achievements in. Options are: "default",
   -- "recent", "progress", or "name"
   --
   --  - "default" - sort by the order achievements are defined in the game's
   --    achievement_data.
   --
   --  - "recent" - show the most recently earned achievements first, followed
   --    by locked achievements in the order they are defined.
   --
   --  - "progress" - show locked in-progress achievements first, in order of
   --    closest to completion to farthest from completion. Then other locked
   --    achievements in definition order, then granted achievements in
   --    definition order.
   --
   --  - "name" - sort alphabetically by achievement name
   --
   -- The user can press the D-pad left/right to toggle between these; this just
   -- sets the default.
   sortOrder = "default",

   -- How to summarize achievements in the header: "count", "percent", "score",
   -- or "none".
   --
   --  - "count" - display a count of how many achievements you've unlocked out
   --    of the total number of achievements. This includes all achievements,
   --    even optional ones.
   --
   --  - "percent" - display a percentage completion, weighted by the scoreValue
   --    of each achievement.
   --
   --  - "score" - display the raw scoreValue earned / total.
   summaryMode = "count",

   -- Disable the automatically captured / fading background.  If you disable
   -- the background, you will need to set an updateFunction and draw something
   -- there, or maybe call gfx.sprite.update() or something.
   disableBackground = false,

   -- Which achievement data to use. Normally you will set this to nil to have
   -- it retrieve the current game's data directly from the achievements
   -- library, but if you want to display a different game's data, you can get
   -- the gameData using the crossgame module and pass it in here.
   gameData = nil,

   -- This will be called every frame when the viewer is blocking the screen,
   -- prior to drawing the viewer. The parameter passed in will range from 0 to
   -- 1 as the viewer fades in, stay 1 while the viewer is being displayed, then
   -- go from 1 back down to 0 while the viewer fades out.
   updateFunction = function(anim) end,

   -- This will be called when the viewer is returning to the game.
   returnToGameFunction = function() end,
}

local FADE_AMOUNT <const> = 0.5
local FADE_FRAMES <const> = 16

-- hard-coded because we will always use 1x scale
local SCREEN_WIDTH <const> = 400
local SCREEN_HEIGHT <const> = 240

local CARD_CORNER <const> = 6
local CARD_WIDTH <const> = 300
-- Base height of each card...
local CARD_HEIGHT_BASE <const> = 58
-- ...plus this height per description line...
local CARD_HEIGHT_PER_LINE <const> = 16
-- ...but with a minimum of this height.
local CARD_HEIGHT_MIN <const> = 64
local CARD_OUTLINE <const> = 2
local CARD_SPACING <const> = 8
local SUMMARY_CARD_HEIGHT <const> = 40
local SUMMARY_TWEAK_Y <const> = 0 -- tweak the Y position of the summary text

-- layout of inside the card
local LAYOUT_MARGIN <const> = 8
local LAYOUT_SPACING <const> = 4
local LAYOUT_ICON_SIZE <const> = 32
local LAYOUT_ICON_SPACING <const> = 8
local LAYOUT_STATUS_SPACING <const> = 10
local LAYOUT_STATUS_TWEAK_Y <const> = -1
local LAYOUT_PROGRESS_TWEAK_Y <const> = 0

local CHECKBOX_SIZE <const> = 15

local TITLE_CORNER <const> = 6
local TITLE_TWEAK_Y <const> = -2 -- tweak the Y position of the title text
local TITLE_WIDTH <const> = CARD_WIDTH
local TITLE_HEIGHT <const> = 64
local TITLE_LOCK_Y <const> = 19  -- lock in position at this point, or negative to not
local TITLE_SPACING <const> = CARD_SPACING
local TITLE_PERCENTAGE_TEXT <const> = "%s completed"
local TITLE_COUNT_TEXT <const> = "Completed: %s / %s"
local TITLE_SCORE_TEXT <const> = "Completion score: %s / %s"
local TITLE_HELP_TEXT_MARGIN <const> = 4
local TITLE_ARROW_X_MARGIN <const> = 16
local TITLE_ARROW_Y_MARGIN <const> = 6
local TITLE_ARROW_WIDTH <const> = 5
local TITLE_ARROW_HEIGHT <const> = 10
local TITLE_ARROW_SPEED <const> = 0.3
local TITLE_ARROW_MAG <const> = 3

local BACK_BUTTON_X <const> = 4
local BACK_BUTTON_Y <const> = 240 - 24
local BACK_BUTTON_START_X <const> = 4
local BACK_BUTTON_START_Y <const> = 242
local BACK_BUTTON_EASING_IN <const> = playdate.easingFunctions.outQuint
local BACK_BUTTON_EASING_OUT <const> = playdate.easingFunctions.inQuint

local ABOUT_BUTTON_X <const> = 352
local ABOUT_BUTTON_Y <const> = 216
local ABOUT_BUTTON_START_X <const> = 352
local ABOUT_BUTTON_START_Y <const> = 242
local ABOUT_BUTTON_EASING_IN <const> = playdate.easingFunctions.outQuint
local ABOUT_BUTTON_EASING_OUT <const> = playdate.easingFunctions.inQuint

local ABOUT_SCREEN_ANIM_FRAMES <const> = 12
local ABOUT_SCREEN_X <const> = SCREEN_WIDTH/2 - 154/2
local ABOUT_SCREEN_Y <const> = SCREEN_HEIGHT/2 - 130/2
local ABOUT_SCREEN_DITHER <const> = gfx.image.kDitherTypeBayer8x8

local PROGRESS_BAR_HEIGHT <const> = 8
local PROGRESS_BAR_OUTLINE <const> = 1
local PROGRESS_BAR_CORNER <const> = 2

local ANIM_FRAMES <const> = 20
local ANIM_EASING_IN <const> = playdate.easingFunctions.outBack -- outCubic
local ANIM_EASING_OUT <const> = playdate.easingFunctions.inCubic

local SCROLL_EASING <const> = playdate.easingFunctions.inQuad
local SCROLL_ACCEL <const> = .75
local SCROLL_ACCEL_DOWN <const> = 2
local SCROLL_SPEED <const> = 16
local SCROLLBAR_WIDTH <const> = 6
local SCROLLBAR_PAGE_WIDTH <const> = 10
local SCROLLBAR_CORNER <const> = 4
local SCROLLBAR_SPACING <const> = 6
local SCROLLBAR_Y_BUFFER <const> = 10
local SCROLLBAR_EASING_IN <const> = playdate.easingFunctions.outQuint
local SCROLLBAR_EASING_OUT <const> = playdate.easingFunctions.inQuint

local LOCKED_TEXT <const> = "Locked "
local PROGRESS_TEXT <const> = "Locked "  -- could also be "Progress "
local GRANTED_TEXT <const> = "Unlocked on %s "
local NUM_HIDDEN_ACHIEVEMENTS_TEXT = "+ %d secret achievement%s."
local EXTRA_SECRET_TEXT = "Secret achievement"
local EXTRA_OPTIONAL_TEXT = "Optional achievement"
local DATE_FORMAT <const> = function(y, m, d) return string.format("%d-%02d-%02d", y, m, d) end
local SORT_ORDER = { "default", "recent", "progress", "name" }
local CRANK_MULT <const> = 1.1

local av = {}
local m
local savedConfig = nil

local persistentCache

if achievements and achievements.toasts and achievements.toasts.getCache then
   persistentCache = achievements.toasts.getCache()  -- share cache between toasts and viewewr, whichever was loaded first
else
   persistentCache = {}
end

function av.loadFile(loader, path)
   if not path then return nil end

   if not persistentCache[path] then
      local item = loader(path)
      persistentCache[path] = item
   end
   return persistentCache[path]
end

function av.setupDefaults(config)
   if config then
      config = table.deepcopy(config)
      for k,v in pairs(defaultConfig) do
         if config[k] == nil then
            -- fill in anything missing from the current config or from the defaults
            if m and m.config[k] then
               config[k] = m.config[k]
            elseif savedConfig and savedConfig[k] then
               config[k] = savedConfig[k]
            else
               config[k] = defaultConfig[k]
            end
         end
      end
   else
      config = table.deepcopy(savedConfig or defaultConfig)
   end
   savedConfig = table.deepcopy(config)
   return config
end

function av.setConstants(config)
   config = config or m.config
   local numLines = config.numDescriptionLines
   m.c = {}
   m.c.CARD_HEIGHT = math.max(CARD_HEIGHT_MIN, CARD_HEIGHT_BASE + numLines * CARD_HEIGHT_PER_LINE)
   m.c.CARD_SPACING_ANIM = SCREEN_HEIGHT - m.c.CARD_HEIGHT
end

function av.initialize(config)
   if not (achievements and achievements.flag_is_playdatesquad_api) then
      error("ERROR: achievements library achievements.lua not loaded")
   end

   config = av.setupDefaults(config)

   gameData = config.gameData
   assetPath = config.assetPath

   m = {}
   m.config = table.deepcopy(config)

   av.setConstants(config)
   m.launched = false

   m.imagePath = ""
   if not gameData then
      gameData = achievements.gameData
   end
   if not gameData then
      print("ERROR: achievements.viewer.initialize() invalid gameData")
      m = nil
      return
   end
   m.gameData = gameData
   if achievements.crossgame then
      if achievements.gameData == nil or achievements.gameData.gameID ~= gameData.gameID then
         m.imagePath = achievements.paths.get_shared_images_path(gameData.gameID) or ""
      end
   end

   m.cardSpacing = 10
   m.cardImageCache = {}
   m.titleImageCache = nil

   m.scrollToTop = false

   m.assetPath = assetPath
   savedAssetPath = assetPath

   m.fonts = {}
   local fontPath = "/System/Fonts"
   local fontExt = ".pft"
   m.fonts.title = av.loadFile(gfx.font.new, fontPath .. "/Roobert-20-Medium")

   m.fonts.name = {}
   m.fonts.name.locked = av.loadFile(gfx.font.new, fontPath .. "/Roobert-11-Medium")
   m.fonts.name.granted = av.loadFile(gfx.font.new, fontPath .. "/Roobert-11-Bold")
   m.fonts.description = {}
   m.fonts.description.locked = av.loadFile(gfx.font.new, assetPath .. "/Nontendo-Light")
   m.fonts.description.locked:setLeading(3)
   m.fonts.description.granted = av.loadFile(gfx.font.new, assetPath .. "/Nontendo-Bold")
   m.fonts.description.granted:setLeading(3)
   m.fonts.status = av.loadFile(gfx.font.new, assetPath .. "/font-Bitmore")
   m.fonts.status:setTracking(1)

   m.maskAnim = av.loadFile(gfx.imagetable.new, assetPath .. "/mask_anim")

   m.checkBox = {}
   m.checkBox.anim = av.loadFile(gfx.imagetable.new, assetPath .. "/check_box_anim")
   m.checkBox.locked = av.loadFile(gfx.image.new, assetPath .. "/check_box")
   m.checkBox.granted = av.loadFile(gfx.image.new, assetPath .. "/check_box_checked")

   m.backButtonImg = av.loadFile(gfx.image.new, assetPath .. "/back_button")
   m.aboutButtonImg = av.loadFile(gfx.image.new, assetPath .. "/about_button")
   m.aboutScreenImg = av.loadFile(gfx.image.new, assetPath .. "/about_screen")

   m.launchSound = av.loadFile(playdate.sound.sampleplayer.new, assetPath .. "/launchSound")
   m.exitSound = av.loadFile(playdate.sound.sampleplayer.new, assetPath .. "/exitSound")
   m.sortSound = av.loadFile(playdate.sound.sampleplayer.new, assetPath .. "/sortSound")
   m.scrollSound = av.loadFile(playdate.sound.sampleplayer.new, assetPath .. "/scrollSound")

   m.icons = { }
   m.iconBuffer = gfx.image.new(LAYOUT_ICON_SIZE, LAYOUT_ICON_SIZE)  -- for masking
   m.achievementData = {}
   m.additionalAchievementData = {}

   for i = 1,#m.gameData.achievements do
      local data = m.gameData.achievements[i]
      local id = data.id
      m.achievementData[id] = data
      m.additionalAchievementData[id] = {
         idx = i,
         grantedAt = data.grantedAt,
         progress = data.progress
      }
      if m.config.gameData == nil then
         -- reading from achievements library directly
         m.additionalAchievementData[id].grantedAt = achievements.granted[id]
         m.additionalAchievementData[id].progress = achievements.progress[id]
      end

      m.icons[id] = {}
      local iconLocked = data.iconLocked or data.icon_locked
      local icon = data.icon
      if iconLocked then
         m.icons[id].locked = av.loadFile(gfx.image.new, m.imagePath .. iconLocked)
      end
      if icon then
         m.icons[id].granted = av.loadFile(gfx.image.new, m.imagePath .. data.icon)
      end
   end
end

function av.reinitialize(config)
   if config then
      for k,v in pairs(config) do
         m.config[k] = v
      end
   end
   av.setConstants()
   m.continuousAnimFrame = 0
   m.animFrame = 0
   m.fadeAmount = 0
   m.scroll = 0
   m.scrollSpeed = 0
   m.title = { x = SCREEN_WIDTH/2 - TITLE_WIDTH/2, y = 0, hidden = false }
   m.card = { }
   m.numCompleted = 0
   m.possibleScore = 0
   m.completionScore = 0
   m.numHiddenCards = 0
   m.secretAchievementSummaryCache = nil

   for i = 1,#m.gameData.achievements do

      local data = m.gameData.achievements[i]
      local id = data.id
      if m.config.gameData == nil then
         -- reading from achievements library directly
         m.additionalAchievementData[id].grantedAt = achievements.granted[id]
         m.additionalAchievementData[id].progress = achievements.progress[id]
      end
      local data2 = m.additionalAchievementData[id]
      local isHidden = not not (data.isSecret and not data2.grantedAt)
      if isHidden then
         m.numHiddenCards = m.numHiddenCards + 1
      end
      local achScore = data.score_value or data.scoreValue or 0
      m.possibleScore += achScore
      if data.grantedAt then
         m.completionScore += achScore
         m.numCompleted += 1
      end
      m.card[i] = {
         x = SCREEN_WIDTH / 2 - CARD_WIDTH / 2,
         y = TITLE_HEIGHT + TITLE_SPACING + (i-1) * (m.c.CARD_HEIGHT + CARD_SPACING),
         hidden = false
      }
   end
   m.completionPercentage = achievements.completionPercentage
   if not m.completionPercentage and m.possibleScore > 0 then
      m.completionPercentage = m.completionScore / m.possibleScore
   else
      m.completionPercentage = 1
   end
   m.sortOrder = m.config.sortOrder or "default"
   m.cardSort = {}
   av.sortCards()
   m.maxSortTextWidth = 0
   for i = 1,#SORT_ORDER do
      local width = m.fonts.status:getTextWidth(SORT_ORDER[i])
      if width > m.maxSortTextWidth then
         m.maxSortTextWidth = width
      end
   end
   m.maxSortTextWidth += 1  --  give it an extra pixel of space

end

function av.sortCards()
   m.cardSort = {}
   for i = 1,#m.gameData.achievements do
      m.cardSort[i] = m.gameData.achievements[i].id
   end

   if m.sortOrder == "progress" then
      table.sort(m.cardSort,
                 function(a, b)
                    local hideA = not not (m.achievementData[a].isSecret and not m.additionalAchievementData[a].grantedAt)
                    local hideB = not not (m.achievementData[b].isSecret and not m.additionalAchievementData[b].grantedAt)
                    if hideA ~= hideB then
                       return hideB
                    elseif m.additionalAchievementData[a].grantedAt and not m.additionalAchievementData[b].grantedAt then
                       return false
                    elseif m.additionalAchievementData[b].grantedAt and not m.additionalAchievementData[a].grantedAt then
                       return true
                    elseif m.additionalAchievementData[a].grantedAt and m.additionalAchievementData[b].grantedAt and
                       m.additionalAchievementData[a].grantedAt ~= m.additionalAchievementData[b].grantedAt then
                       return m.additionalAchievementData[a].idx <  m.additionalAchievementData[b].idx
                    else
                       local progressMaxA = m.achievementData[a].progressMax or m.achievementData[a].progress_max or 0
                       local progressMaxB = m.achievementData[b].progressMax or m.achievementData[b].progress_max or 0
                       if progressMaxA ~= 0 and progressMaxB == 0 then
                          return true
                       elseif progressMaxB ~= 0 and progressMaxA == 0 then
                          return false
                       elseif progressMaxA ~= 0 and progressMaxB ~= 0 then
                          -- both have progress, return the one with higher progress
                          local progressA = m.additionalAchievementData[a].progress or 0
                          local progressB = m.additionalAchievementData[b].progress or 0
                          local progessIsPctA = m.achievementData[a].progressIsPercentage or
                             m.achievementData[a].progress_is_percentage
                          local progessIsPctB = m.achievementData[b].progressIsPercentage or
                             m.achievementData[b].progress_is_percentage

                          if progressA ~= progressB then
                             return (progressA / progressMaxA) > (progressB / progressMaxB)
                          elseif progressIsPercentageA ~= progressIsPercentageB then
                             return progressIsPercentageA  -- show percentages first
                          elseif progressMaxA ~= progressMaxB then
                             return progressMaxA > progressMaxB
                          end
                       else
                          -- neither has progress, use index as fallback
                          return m.additionalAchievementData[a].idx <  m.additionalAchievementData[b].idx
                       end
                    end
                 end
      )
   elseif m.sortOrder == "recent" then
      table.sort(m.cardSort,
                 function(a, b)
                    local hideA = not not (m.achievementData[a].isSecret and not m.additionalAchievementData[a].grantedAt)
                    local hideB = not not (m.achievementData[b].isSecret and not m.additionalAchievementData[b].grantedAt)
                    if hideA ~= hideB then
                       return hideB
                    elseif m.additionalAchievementData[a].grantedAt and not m.additionalAchievementData[b].grantedAt then
                       return true
                    elseif m.additionalAchievementData[b].grantedAt and not m.additionalAchievementData[a].grantedAt then
                       return false
                    elseif m.additionalAchievementData[a].grantedAt and m.additionalAchievementData[b].grantedAt and
                       m.additionalAchievementData[a].grantedAt ~= m.additionalAchievementData[b].grantedAt then
                       return m.additionalAchievementData[a].grantedAt > m.additionalAchievementData[b].grantedAt
                    else
                       return m.additionalAchievementData[a].idx <  m.additionalAchievementData[b].idx
                    end
                 end
      )
   elseif m.sortOrder == "name" then
      table.sort(m.cardSort,
                 function(a, b)
                    local hideA = not not (m.achievementData[a].isSecret and not m.additionalAchievementData[a].grantedAt)
                    local hideB = not not (m.achievementData[b].isSecret and not m.additionalAchievementData[b].grantedAt)
                    if hideA ~= hideB then
                       return hideB
                    else
                       return m.achievementData[a].name < m.achievementData[b].name
                    end
                 end
      )
   elseif m.sortOrder == "default" then
      table.sort(m.cardSort,
                 function(a, b)
                    local hideA = not not (m.achievementData[a].isSecret and not m.additionalAchievementData[a].grantedAt)
                    local hideB = not not (m.achievementData[b].isSecret and not m.additionalAchievementData[b].grantedAt)
                    if hideA ~= hideB then
                       return hideB
                    else
                       return m.additionalAchievementData[a].idx < m.additionalAchievementData[b].idx
                    end
                 end
      )
   end
   if savedConfig then
      savedConfig.sortOrder = m.sortOrder
   end
end

function av.backupUserSettings()
   if m.backupPlaydateUpdate == nil then
      m.backupPlaydateUpdate = playdate.update
   end
   if m.backupRefreshRate == nil then
      m.backupRefreshRate = playdate.display.getRefreshRate()
   end
   if m.backupDisplayScale == nil then
      m.backupDisplayScale = playdate.display.getScale()
   end
end

function av.restoreUserSettings()
   if m.backupPlaydateUpdate then
      playdate.update = m.backupPlaydateUpdate
      m.backupPlaydateUpdate = nil
   end
   if m.backupRefreshRate then
      playdate.display.setRefreshRate(m.backupRefreshRate)
      m.backupRefreshRate = nil
   end
   if m.backupDisplayScale then
      playdate.display.setScale(m.backupDisplayScale)
      m.backupDisplayScale = nil
   end
   if m.handlingInput then
      playdate.inputHandlers.pop()
      m.handlingInput = false
   end
end

function av.destroy()
   m = nil
end

function av.drawTitle(x, y)
   local width = TITLE_WIDTH
   local height = TITLE_HEIGHT
   local image = m.titleImageCache
   if not image then
      image = gfx.image.new(width, height)

      gfx.pushContext(image)
      local font = m.fonts.title

      gfx.setColor(gfx.kColorWhite)
      gfx.fillRoundRect(0, 0, width, height, TITLE_CORNER)

      local margin = 1
      gfx.setColor(gfx.kColorBlack)
      gfx.fillRoundRect(0+margin, 0+margin, width-2*margin, height-2*margin, TITLE_CORNER)

      gfx.setImageDrawMode(gfx.kDrawModeFillWhite)
      font:drawTextAligned("Achievements", width/2, height/2 - math.floor(font:getHeight()/2) + TITLE_TWEAK_Y, kTextAlignment.center)

      font = m.fonts.status
      gfx.setFont(font)
      local summaryImg
      if m.config.summaryMode == "percent" or m.config.summaryMode == "percentage" then
         local pct = tostring(math.floor(0.5 + 100 * (m.completionPercentage or 0))) .. "%"
         summaryImg = gfx.imageWithText(string.format(TITLE_PERCENTAGE_TEXT, pct), TITLE_WIDTH, TITLE_HEIGHT)
      elseif m.config.summaryMode == "count" then
         summaryImg = gfx.imageWithText(string.format(TITLE_COUNT_TEXT,
                                                      tostring(m.numCompleted or 0),
                                                      tostring((#m.gameData.achievements or 0))),
                                        TITLE_WIDTH, TITLE_HEIGHT)
      elseif m.config.summaryMode == "score" then
         summaryImg = gfx.imageWithText(string.format(TITLE_SCORE_TEXT,
                                                      tostring(m.completionScore or 0),
                                                      tostring(m.possibleScore or 0)),
                                        TITLE_WIDTH, TITLE_HEIGHT)
      end
      if summaryImg then
         summaryImg:draw(LAYOUT_MARGIN,
                         height - TITLE_HELP_TEXT_MARGIN - summaryImg.height)
      end

      gfx.popContext()
      m.titleImageCache = image
      if m.config.invertCards then
         m.titleImageCache:setInverted(true)
      end
   end
   gfx.pushContext(image)
   font = m.fonts.status
   gfx.setFont(font)
   gfx.setImageDrawMode(gfx.kDrawModeFillWhite)
   local sortImg = gfx.imageWithText("Sort:", TITLE_WIDTH, TITLE_HEIGHT)
   local sortImg2 = gfx.imageWithText(tostring(m.sortOrder), TITLE_WIDTH, TITLE_HEIGHT)
   gfx.setImageDrawMode(gfx.kDrawModeCopy)
   gfx.setColor(gfx.kColorBlack)
   gfx.fillRect(width / 2, height - TITLE_HELP_TEXT_MARGIN - sortImg.height - 2,
                width / 2 - LAYOUT_MARGIN, sortImg.height + 4)
   sortImg2:draw(width - LAYOUT_MARGIN - TITLE_ARROW_X_MARGIN - m.maxSortTextWidth + (
                    m.maxSortTextWidth / 2 - sortImg2.width/2),
                 height - TITLE_HELP_TEXT_MARGIN - sortImg2.height)

   sortImg:draw(width - LAYOUT_MARGIN - sortImg.width - 2 * TITLE_ARROW_X_MARGIN - m.maxSortTextWidth,
                height - TITLE_HELP_TEXT_MARGIN - sortImg.height)
   gfx.setColor(gfx.kColorWhite)
   gfx.setLineWidth(1)
   local arrowAnim = math.sin(TITLE_ARROW_SPEED * m.continuousAnimFrame) * TITLE_ARROW_MAG

   local triX = width - LAYOUT_MARGIN - TITLE_ARROW_X_MARGIN/2 + arrowAnim
   local triY = height - TITLE_ARROW_Y_MARGIN - sortImg.height/2

   gfx.fillPolygon(triX - TITLE_ARROW_WIDTH/2, triY - TITLE_ARROW_HEIGHT/2,
                   triX + TITLE_ARROW_WIDTH/2, triY,
                   triX - TITLE_ARROW_WIDTH/2, triY + TITLE_ARROW_HEIGHT/2)
   triX = width - LAYOUT_MARGIN - TITLE_ARROW_X_MARGIN - m.maxSortTextWidth - TITLE_ARROW_X_MARGIN/2 - arrowAnim
   triY = height - TITLE_ARROW_Y_MARGIN - sortImg.height/2

   gfx.fillPolygon(triX + TITLE_ARROW_WIDTH/2, triY - TITLE_ARROW_HEIGHT/2,
                   triX - TITLE_ARROW_WIDTH/2, triY,
                   triX + TITLE_ARROW_WIDTH/2, triY + TITLE_ARROW_HEIGHT/2)
   gfx.popContext()

   m.titleImageCache:draw(x, y)
end

function av.formatDate(timestamp)
   local time = playdate.timeFromEpoch(timestamp, 0)
   return DATE_FORMAT(time.year, time.month, time.day)
end

function av.drawSecretAchievementSummary(x, y, width, height)
   local wantWidth = width
   local wantHeight = height
   local image = m.secretAchievementSummaryCache
   if image and (image.width ~= wantWidth or image.height ~= wantHeight) then
      image = nil
   end
   if not image then
      image = gfx.image.new(wantWidth, wantHeight)

      gfx.pushContext(image)

      local margin = 1

      gfx.setColor(gfx.kColorWhite)
      gfx.fillRoundRect(0, 0, width, height, CARD_CORNER)

      gfx.setStrokeLocation(gfx.kStrokeInside)
      gfx.setLineWidth(CARD_OUTLINE)
      gfx.setColor(gfx.kColorBlack)

      gfx.drawRoundRect(margin, margin, width-2*margin, height-2*margin, CARD_CORNER)

      local font = m.fonts.name.locked
      local summaryText = string.format(NUM_HIDDEN_ACHIEVEMENTS_TEXT, m.numHiddenCards, m.numHiddenCards == 1 and "" or "s")

      font:drawTextAligned(summaryText, width/2, height/2 - math.floor(font:getHeight()/2) + SUMMARY_TWEAK_Y, kTextAlignment.center)

      gfx.popContext()

      m.secretAchievementSummaryCache = image
      if m.config.invertCards then
         m.secretAchievementSummaryCache:setInverted(true)
      end
   end
   m.secretAchievementSummaryCache:draw(x, y)
end

function av.drawCard(achievementId, x, y, width, height)
   local wantWidth = width
   local wantHeight = height
   local image = m.cardImageCache[achievementId]
   if image and (image.width ~= wantWidth or image.height ~= wantHeight) then
      image = nil
   end
   if not image then
      image = gfx.image.new(wantWidth, wantHeight)

      gfx.pushContext(image)
      local margin = 1

      local info = m.achievementData[achievementId]

      local iconImgGranted = m.icons[achievementId].granted
      local iconImgLocked = m.icons[achievementId].locked

      gfx.setColor(gfx.kColorWhite)
      gfx.fillRoundRect(0, 0, width, height, CARD_CORNER)

      gfx.setStrokeLocation(gfx.kStrokeInside)
      gfx.setLineWidth(CARD_OUTLINE)
      gfx.setColor(gfx.kColorBlack)

      gfx.drawRoundRect(margin, margin, width-2*margin, height-2*margin, CARD_CORNER)

      local granted = not not m.additionalAchievementData[achievementId].grantedAt
      local iconSize = LAYOUT_ICON_SIZE
      local imageMargin = LAYOUT_MARGIN

      local iconImg = granted and iconImgGranted or iconImgLocked
      if m.config.invertCards and iconImg then
         iconImg = iconImg:invertedImage()
      end
      if iconImg then
         iconSize = math.min(iconSize, iconImg.width)
         iconImg:draw(width - imageMargin - iconImg.width, imageMargin)
      else
         iconSize = 0
      end

      local font = granted and m.fonts.name.granted or m.fonts.name.locked
      gfx.setFont(font)
      local name = info.name

      local nameImg = gfx.imageWithText(name,
                                        width - 2*LAYOUT_MARGIN - LAYOUT_ICON_SPACING - iconSize,
                                        height - 2*LAYOUT_MARGIN - LAYOUT_SPACING - CHECKBOX_SIZE)

      font = granted and m.fonts.description.granted or m.fonts.description.locked
      gfx.setFont(font)
      local heightRemaining = height - 2*LAYOUT_MARGIN - 2*LAYOUT_SPACING - nameImg.height - CHECKBOX_SIZE
      local descImg
      if heightRemaining >= font:getHeight() then
         local description = info.description
         if info.descriptionLocked and not granted then
            description = info.descriptionLocked
         end

         descImg = gfx.imageWithText(description,
                                     width - 2*LAYOUT_MARGIN - LAYOUT_ICON_SPACING - iconSize,
                                     heightRemaining)
      end

      nameImg:draw(LAYOUT_MARGIN, LAYOUT_MARGIN)
      if descImg then
         descImg:draw(LAYOUT_MARGIN, LAYOUT_MARGIN + nameImg.height + LAYOUT_SPACING)
      end

      if granted then
         m.checkBox.granted:draw(LAYOUT_MARGIN, height - CHECKBOX_SIZE - LAYOUT_MARGIN)
      else
         m.checkBox.locked:draw(LAYOUT_MARGIN, height - CHECKBOX_SIZE - LAYOUT_MARGIN)
      end

      local progressMax = info.progress_max or info.progressMax
      local statusImg
      local statusImgWidth, statusImgHeight = 0, 0
      local font = m.fonts.status
      local statusText = ""
      gfx.setFont(font)
      if granted then
         local dateStr = av.formatDate(info.grantedAt or playdate.getSecondsSinceEpoch())
         if dateStr then
            statusText = string.format(GRANTED_TEXT, dateStr)
         end
      else
         statusText = LOCKED_TEXT
      end
      statusImg = gfx.imageWithText(statusText, width - 2*LAYOUT_MARGIN - LAYOUT_SPACING - CHECKBOX_SIZE,
                                    height - LAYOUT_MARGIN - iconSize - LAYOUT_ICON_SPACING)
      if statusImg then
         statusImg:draw(width - LAYOUT_MARGIN - statusImg.width,
                        height - LAYOUT_MARGIN - statusImg.height + LAYOUT_STATUS_TWEAK_Y)
         statusImgWidth = statusImg.width
      end

      if not granted and progressMax then
         local font = m.fonts.status
         gfx.setFont(font)
         local progress = m.additionalAchievementData[achievementId].progress or info.progress or 0
         local progressIsPercentage = info.progressIsPercentage

         local progressText, frac
         if progressIsPercentage then
            local pct = math.floor((progress or 0) * 100 / progressMax)
            pct = math.max(math.min(pct, 100), 0)
            progressText = tostring(pct) .. "%"
            frac = pct / 100
         else
            local amt = math.floor((progress or 0))
            amt = math.max(math.min(amt, math.floor(progressMax)), 0)
            local slash = "/"
            progressText = tostring(amt) .. slash .. tostring(math.floor(progressMax))
            frac = amt / math.floor(progressMax)
         end
         local progressTextWidth = width - 2*LAYOUT_MARGIN -
            LAYOUT_STATUS_SPACING - CHECKBOX_SIZE -
            LAYOUT_STATUS_SPACING - statusImgWidth
         local progressTextHeight = height - LAYOUT_MARGIN - iconSize - LAYOUT_SPACING
         local progressSpacing = LAYOUT_STATUS_SPACING
         local progressMargin = LAYOUT_MARGIN
         local progressTextImg = gfx.imageWithText(progressText, progressTextWidth, progressTextHeight)

         progressTextImg:draw(width - progressMargin - statusImgWidth -
                              progressSpacing - progressTextImg.width,
                              height - progressMargin - progressTextImg.height + LAYOUT_STATUS_TWEAK_Y)

         local progressBarWidth =
            width - 2*LAYOUT_MARGIN -
            LAYOUT_STATUS_SPACING - statusImgWidth -
            LAYOUT_STATUS_SPACING - progressTextImg.width-
            LAYOUT_SPACING - CHECKBOX_SIZE
         local progressBarTweakY = LAYOUT_PROGRESS_TWEAK_Y
         gfx.setColor(gfx.kColorBlack)
         gfx.pushContext()
         gfx.setDitherPattern(.5, gfx.image.kDitherTypeBayer8x8)
         gfx.fillRoundRect(progressMargin + CHECKBOX_SIZE + progressSpacing,
                           height - progressMargin - CHECKBOX_SIZE/2 - PROGRESS_BAR_HEIGHT/2 + progressBarTweakY,
                           frac * progressBarWidth,
                           PROGRESS_BAR_HEIGHT, PROGRESS_BAR_CORNER)
         gfx.popContext()
         gfx.setLineWidth(PROGRESS_BAR_OUTLINE)
         gfx.drawRoundRect(progressMargin + CHECKBOX_SIZE + progressSpacing,
                           height - progressMargin - CHECKBOX_SIZE/2 - PROGRESS_BAR_HEIGHT/2 + progressBarTweakY,
                           progressBarWidth, PROGRESS_BAR_HEIGHT, PROGRESS_BAR_CORNER)
      end
      if granted and (info.isSecret or info.scoreValue == 0) then
         local extraText, extraImg
         if info.isSecret then
            extraText = EXTRA_SECRET_TEXT
         elseif info.scoreValue == 0 then
            extraText = EXTRA_OPTIONAL_TEXT
         end
         if extraText then
            extraImg = gfx.imageWithText(extraText,
                                         width - 2*LAYOUT_MARGIN - LAYOUT_SPACING - CHECKBOX_SIZE,
                                         height - LAYOUT_MARGIN - iconSize - LAYOUT_ICON_SPACING)
         end
         if extraImg then
            extraImg:draw(LAYOUT_MARGIN + CHECKBOX_SIZE + LAYOUT_SPACING,
                          height - LAYOUT_MARGIN - statusImg.height + LAYOUT_STATUS_TWEAK_Y)
         end
      end
      gfx.popContext()
      if m.config.invertCards then
         m.cardImageCache[achievementId] = image:invertedImage()
      else
         m.cardImageCache[achievementId] = image
      end
   end
   m.cardImageCache[achievementId]:draw(x, y)
end

function av.drawScrollbar(x, y)
   if m.maxScroll == nil or m.maxScroll <= CARD_SPACING then return end

   local barPageFrac = SCREEN_HEIGHT / (m.maxScroll+SCREEN_HEIGHT)
   barPageFrac = math.max(barPageFrac, 0.25)
   local barPosFrac = (m.scroll) / (m.maxScroll)

   gfx.pushContext()
   gfx.setColor(gfx.kColorWhite)
   local scrollbarYLimit = SCREEN_HEIGHT
   if m.config.enableAboutScreen then
      scrollbarYLimit = ABOUT_BUTTON_Y+4
   end

   gfx.fillRoundRect(x, SCROLLBAR_Y_BUFFER, SCROLLBAR_WIDTH, scrollbarYLimit - 2*SCROLLBAR_Y_BUFFER, SCROLLBAR_CORNER)
   local margin = 1
   gfx.setColor(gfx.kColorBlack)
   gfx.drawRoundRect(x+margin, SCROLLBAR_Y_BUFFER+margin,
                     SCROLLBAR_WIDTH-2*margin, scrollbarYLimit - 2*SCROLLBAR_Y_BUFFER-2*margin,
                     SCROLLBAR_CORNER)
   local totalHeight = scrollbarYLimit - 2*SCROLLBAR_Y_BUFFER

   local barPagePixels = barPageFrac * totalHeight
   local startPos = (totalHeight - barPagePixels) * barPosFrac
   gfx.setColor(gfx.kColorWhite)
   gfx.fillRoundRect(x + SCROLLBAR_WIDTH/2 - SCROLLBAR_PAGE_WIDTH/2,
                     startPos + SCROLLBAR_Y_BUFFER,
                     SCROLLBAR_PAGE_WIDTH, barPagePixels, SCROLLBAR_CORNER)
   gfx.setColor(gfx.kColorBlack)
   gfx.drawRoundRect(x + SCROLLBAR_WIDTH/2 - SCROLLBAR_PAGE_WIDTH/2 + margin,
                     margin + startPos + SCROLLBAR_Y_BUFFER,
                     SCROLLBAR_PAGE_WIDTH - 2*margin, barPagePixels - 2*margin, SCROLLBAR_CORNER)

   gfx.popContext()
end

function av.drawCards(x, y, animating)
   local x = (x or 0)
   local y = (y or 0) - m.scroll + CARD_SPACING


   local scrollBarX = x + m.title.x + math.max(TITLE_WIDTH, CARD_WIDTH) + SCROLLBAR_SPACING
   local scrollBarHidden = SCREEN_WIDTH + SCROLLBAR_SPACING
   local animFrac
   if animating > 0 then
      animFrac = SCROLLBAR_EASING_IN(m.rawAnimFrac, 0, 1, 1)
   else
      animFrac = SCROLLBAR_EASING_OUT(m.rawAnimFrac, 0, 1, 1)
   end
   av.drawScrollbar((1-animFrac) * scrollBarHidden + (animFrac) * scrollBarX, 0)

   local extraSpacing = m.cardSpacing

   local count = 0
   local titleY = y + m.title.y
   if not m.title.hidden then
      if titleY + TITLE_HEIGHT > 0 and titleY < SCREEN_HEIGHT then
         m.title.isVisible = true
         count = count + 1
      else
         m.title.isVisible = false
      end
   else
      m.title.isVisible = false
   end

   local isHidden
   local showedSummary = false
   for i = 1,#m.card do
      if not m.card[i].hidden then
         local card = m.card[i]
         local id = m.cardSort[i]
         isHidden = not not (m.achievementData[id].isSecret and not m.additionalAchievementData[id].grantedAt)
         card.drawY = m.card[i].y + count*extraSpacing
         if not isHidden then
            count = count + 1
            if y + card.drawY + m.c.CARD_HEIGHT > 0 and y + card.drawY < SCREEN_HEIGHT then
               av.drawCard(id,
                           x + card.x,
                           y + card.drawY,
                           CARD_WIDTH, m.c.CARD_HEIGHT)
               m.card[i].isVisible = true
            else
               m.card[i].isVisible = false
            end
         else
            if not showedSummary and m.numHiddenCards > 0 then
               showedSummary = true
               count = count + 1
               if y + card.drawY + SUMMARY_CARD_HEIGHT > 0 and y + card.drawY < SCREEN_HEIGHT then
                  av.drawSecretAchievementSummary(x + card.x,
                                                  y + card.drawY,
                                                  CARD_WIDTH, SUMMARY_CARD_HEIGHT)
                  m.card[i].isVisible = true
               else
                  m.card[i].isVisible = false
               end
            else
               m.card[i].isVisible = false
            end
         end
      end
   end
   if m.title.isVisible then
      av.drawTitle(x + m.title.x, titleY)
   end
end


function av.animateInUpdate()
   m.fadeAmount = m.fadeAmount + (FADE_AMOUNT / FADE_FRAMES)
   if m.fadeAmount >= FADE_AMOUNT then
      m.fadeAmount = FADE_AMOUNT
   end
   m.userUpdate(m.fadeAmount / FADE_AMOUNT)
   if m.backdropImage then
      m.backdropImage:draw(0, 0)
   end
   m.continuousAnimFrame = m.continuousAnimFrame + 1

   local maxCard = #m.card
   local summarySpace = 0
   if m.numHiddenCards > 0 then
      maxCard = maxCard - m.numHiddenCards  -- one extra card to say "plus X hidden achievements!"
      if m.numHiddenCards > 0 then
         summarySpace = SUMMARY_CARD_HEIGHT + CARD_SPACING
      end
   end
   m.maxScroll = m.card[maxCard].y + m.c.CARD_HEIGHT - SCREEN_HEIGHT + 2*CARD_SPACING + summarySpace

   if m.config.fadeColor ~= gfx.kColorClear and not m.config.disableBackground then
      gfx.pushContext()
      gfx.setColor(m.config.fadeColor)
      gfx.setDitherPattern(1-m.fadeAmount, gfx.image.kDitherTypeBayer8x8)
      gfx.fillRect(0, 0, playdate.display.getWidth(), playdate.display.getHeight())
      gfx.popContext()
   end

   if m.fadeAmount >= FADE_AMOUNT and m.fadedBackdropImage == nil and m.backdropImage then
      m.fadedBackdropImage = playdate.graphics.getWorkingImage()
   end

   local scrollOffset = 0
   m.rawAnimFrac = m.animFrame / ANIM_FRAMES
   local animFrame = ANIM_EASING_IN(m.animFrame, 0, ANIM_FRAMES, ANIM_FRAMES, .75)
   if m.animFrame <= ANIM_FRAMES then
      scrollOffset = SCREEN_HEIGHT - SCREEN_HEIGHT * (animFrame / ANIM_FRAMES)
      m.animFrame = m.animFrame + 1
   end
   m.cardSpacing = m.c.CARD_SPACING_ANIM - m.c.CARD_SPACING_ANIM * (animFrame / ANIM_FRAMES)
   av.drawCards(0, scrollOffset, 1)

   local backButtonAnimFrac = BACK_BUTTON_EASING_IN(m.rawAnimFrac, 0, 1, 1)
   local backButtonX = BACK_BUTTON_X * backButtonAnimFrac + BACK_BUTTON_START_X * (1-backButtonAnimFrac)
   local backButtonY = BACK_BUTTON_Y * backButtonAnimFrac + BACK_BUTTON_START_Y * (1-backButtonAnimFrac)
   m.backButtonImg:draw(backButtonX, backButtonY)

   if m.config.enableAboutScreen then
      local aboutButtonAnimFrac = ABOUT_BUTTON_EASING_IN(m.rawAnimFrac, 0, 1, 1)
      local aboutButtonX = ABOUT_BUTTON_X * aboutButtonAnimFrac + ABOUT_BUTTON_START_X * (1-aboutButtonAnimFrac)
      local aboutButtonY = ABOUT_BUTTON_Y * aboutButtonAnimFrac + ABOUT_BUTTON_START_Y * (1-aboutButtonAnimFrac)
      m.aboutButtonImg:draw(aboutButtonX, aboutButtonY)
   end

   if m.fadeAmount >= FADE_AMOUNT and m.animFrame > ANIM_FRAMES then
      m.cardSpacing = 0
      m.animFrame = 0
      playdate.update = av.mainUpdate
   end
end

function av.animateOutUpdate()
   m.continuousAnimFrame = m.continuousAnimFrame + 1
   m.fadeAmount = m.fadeAmount + (FADE_AMOUNT / FADE_FRAMES)
   if m.fadeAmount >= FADE_AMOUNT then
      m.fadeAmount = FADE_AMOUNT
   end
   m.userUpdate(1-m.fadeAmount / FADE_AMOUNT)
   if m.backdropImage then
      m.backdropImage:draw(0, 0)
   end
   if m.config.fadeColor ~= gfx.kColorClear and not m.config.disableBackground then
      gfx.pushContext()
      gfx.setColor(m.config.fadeColor)
      gfx.setDitherPattern(FADE_AMOUNT + m.fadeAmount, gfx.image.kDitherTypeBayer8x8)
      gfx.fillRect(0, 0, playdate.display.getWidth(), playdate.display.getHeight())
      gfx.popContext()
   end


   m.rawAnimFrac = 1-m.animFrame / ANIM_FRAMES
   local animFrame = ANIM_EASING_OUT(m.animFrame, 0, ANIM_FRAMES, ANIM_FRAMES)

   local scrollOffset = SCREEN_HEIGHT * (animFrame / ANIM_FRAMES)
   m.cardSpacing = m.c.CARD_SPACING_ANIM * (animFrame / ANIM_FRAMES)
   av.drawCards(x, scrollOffset, -1)
   if m.animFrame <= ANIM_FRAMES then
      m.animFrame = m.animFrame + 1
   end

   local backButtonAnimFrac = BACK_BUTTON_EASING_OUT(m.rawAnimFrac, 0, 1, 1)
   local backButtonX = BACK_BUTTON_X * backButtonAnimFrac + BACK_BUTTON_START_X * (1-backButtonAnimFrac)
   local backButtonY = BACK_BUTTON_Y * backButtonAnimFrac + BACK_BUTTON_START_Y * (1-backButtonAnimFrac)
   m.backButtonImg:draw(backButtonX, backButtonY)

   if m.config.enableAboutScreen then
      local aboutButtonAnimFrac = ABOUT_BUTTON_EASING_OUT(m.rawAnimFrac, 0, 1, 1)
      local aboutButtonX = ABOUT_BUTTON_X * aboutButtonAnimFrac + ABOUT_BUTTON_START_X * (1-aboutButtonAnimFrac)
      local aboutButtonY = ABOUT_BUTTON_Y * aboutButtonAnimFrac + ABOUT_BUTTON_START_Y * (1-aboutButtonAnimFrac)
      m.aboutButtonImg:draw(aboutButtonX, aboutButtonY)
   end

   if m.fadeAmount >= FADE_AMOUNT and m.animFrame > ANIM_FRAMES then
      if m.backdropImage then
         m.backdropImage:drawScaled(0, 0, 1/m.backupDisplayScale, 1/m.backupDisplayScale)
      end
      av.restoreUserSettings()
      playdate.getCrankTicks(1)
      local returnFunction = m.returnToGameFunction
      av.destroy()
      if returnFunction then returnFunction() end
   end
end

function av.mainUpdate()
   m.userUpdate(1)
   if m.fadedBackdropImage then
      m.fadedBackdropImage:draw(0, 0)
   end

   if m.aboutScreenAnim == nil then
      m.continuousAnimFrame = m.continuousAnimFrame + 1
   end
   m.animFrame = m.animFrame + 1

   local maxCard = #m.card
   local summarySpace = 0
   if m.numHiddenCards > 0 then
      maxCard = maxCard - m.numHiddenCards  -- one extra card to say "plus X hidden achievements!"
      if m.numHiddenCards > 0 then
         summarySpace = SUMMARY_CARD_HEIGHT + CARD_SPACING
      end
   end
   m.maxScroll = m.card[maxCard].y + m.c.CARD_HEIGHT - SCREEN_HEIGHT + 2*CARD_SPACING + summarySpace

   av.drawCards(0, 0, 0)

   if m.aboutScreenAnim == nil then
      if playdate.buttonJustPressed(playdate.kButtonRight) then
         local i = table.indexOfElement(SORT_ORDER, m.sortOrder)
         if i < #SORT_ORDER then i = i + 1 else i = 1 end
         m.sortOrder = SORT_ORDER[i] or SORT_ORDER[1]
         av.sortCards()
         if m.config.soundVolume > 0 then
            m.sortSound:setVolume(m.config.soundVolume)
            m.sortSound:play()
         end
         m.scrollToTop = true
      elseif playdate.buttonJustPressed(playdate.kButtonLeft) then
         local i = table.indexOfElement(SORT_ORDER, m.sortOrder)
         if i > 1 then i = i - 1 else i = #SORT_ORDER end
         m.sortOrder = SORT_ORDER[i] or SORT_ORDER[1]
         av.sortCards()
         if m.config.soundVolume > 0 then
            m.sortSound:setVolume(m.config.soundVolume)
            m.sortSound:play()
         end
         m.scrollToTop = true
      end
   end
   local oldScroll = m.scroll
   if m.scrollToTop then
      m.scroll = m.scroll * .7
      if m.scroll < SCROLL_ACCEL then
         m.scroll = 0
      end
      m.scrollSpeed = math.max(m.scrollSpeed - SCROLL_ACCEL_DOWN, 0)
   else
      if playdate.buttonIsPressed(playdate.kButtonUp) and m.aboutScreenAnim == nil then
         m.scrollSpeed = math.min(m.scrollSpeed + SCROLL_ACCEL, SCROLL_SPEED)
      elseif playdate.buttonIsPressed(playdate.kButtonDown) and m.aboutScreenAnim == nil then
         m.scrollSpeed = math.max(m.scrollSpeed - SCROLL_ACCEL, -SCROLL_SPEED)
      elseif m.scrollSpeed > 0 then
         m.scrollSpeed = math.max(m.scrollSpeed - SCROLL_ACCEL_DOWN, 0)
      elseif m.scrollSpeed < 0 then
         m.scrollSpeed = math.min(m.scrollSpeed + SCROLL_ACCEL_DOWN, 0)
      end
   end

   if m.scrollSpeed ~= 0 then
      local scrollMax = SCROLL_SPEED *  m.scrollSpeed / math.abs(m.scrollSpeed)
      local scrollAmount = SCROLL_EASING(m.scrollSpeed, 0, scrollMax, scrollMax)
      m.scroll = m.scroll - scrollAmount
   end

   local crankChanged, accelChanged = 0,0
   if m.aboutScreenAnim == nil then
      crankChanged, accelChanged = playdate.getCrankChange()
   end
   m.scroll = m.scroll + (CRANK_MULT*accelChanged)
   if m.scroll < 3 and m.scrollSpeed == 0 then m.scroll = m.scroll - 1 end

   if m.scroll < 0 then
      m.scroll = 0
      m.scrollSpeed = 0
   elseif m.scroll > m.maxScroll then
      m.scroll = m.maxScroll
      m.scrollSpeed = 0
   end

   if m.scroll == 0 then
      if m.scrollToTop then
         m.scrollToTop = false
      end
   end

   if not m.scrollToTop and m.scroll // 32 ~= oldScroll // 32 then
      if m.config.soundVolume > 0 then
         m.scrollSound:setVolume(m.config.soundVolume)
         m.scrollSound:play()
      end
   end

   m.backButtonImg:draw(BACK_BUTTON_X, BACK_BUTTON_Y)
   if m.config.enableAboutScreen then
      m.aboutButtonImg:draw(ABOUT_BUTTON_X, ABOUT_BUTTON_Y)
   end

   if playdate.buttonJustPressed(playdate.kButtonB) then
      if m.aboutScreenAnim == ABOUT_SCREEN_ANIM_FRAMES then
         m.exitSound:setVolume(m.config.soundVolume)
         m.exitSound:play(1, 1.2)
         m.aboutScreenAnimSpeed = -1
      elseif m.aboutScreenAnim == nil then
         m.fadedBackdropImage = nil
         av.beginExit()
      end
   elseif m.config.enableAboutScreen and playdate.buttonJustPressed(playdate.kButtonA) then
      if m.aboutScreenAnim == nil then
         m.launchSound:setVolume(m.config.soundVolume)
         m.launchSound:play(1, 1.2)
         m.aboutScreenAnimSpeed = 1
         m.aboutScreenAnim = (m.aboutScreenAnim or 0)
      end
   end

   if m.aboutScreenAnim ~= nil then
      m.aboutScreenAnim = m.aboutScreenAnim + (m.aboutScreenAnimSpeed or 0)
      if m.aboutScreenAnimSpeed > 0 and m.aboutScreenAnim >= ABOUT_SCREEN_ANIM_FRAMES then
         m.aboutScreenAnim = ABOUT_SCREEN_ANIM_FRAMES
         gfx.pushContext()
         gfx.setColor(m.config.fadeColor)
         gfx.setDitherPattern(0.5, gfx.image.kDitherTypeBayer8x8)
         gfx.fillRect(0, 0, 400, 240)
         gfx.popContext()
         m.aboutScreenImg:draw(math.floor(SCREEN_WIDTH/2 - m.aboutScreenImg.width/2),
                               math.floor(SCREEN_HEIGHT/2 - m.aboutScreenImg.height/2))
      elseif m.aboutScreenAnimSpeed < 0 and m.aboutScreenAnim <= 0 then
         m.aboutScreenAnim = nil
         m.aboutScreenAnimSpeed = 0
      else
         gfx.pushContext()
         gfx.setColor(m.config.fadeColor)
         gfx.setDitherPattern(1 - (m.aboutScreenAnim / ABOUT_SCREEN_ANIM_FRAMES / 2), gfx.image.kDitherTypeBayer8x8)
         gfx.fillRect(0, 0, 400, 240)
         gfx.popContext()
         m.aboutScreenImg:drawFaded(math.floor(SCREEN_WIDTH/2 - m.aboutScreenImg.width/2),
                                    math.floor(SCREEN_HEIGHT/2 - m.aboutScreenImg.height/2),
                                    m.aboutScreenAnim / ABOUT_SCREEN_ANIM_FRAMES, ABOUT_SCREEN_DITHER)
      end
      m.backButtonImg:draw(BACK_BUTTON_X, BACK_BUTTON_Y)
   end
end


function av.beginExit()
   m.animFrame = 0
   m.fadeAmount = 0
   playdate.update = av.animateOutUpdate
   if m.config.soundVolume > 0 then
      m.exitSound:setVolume(m.config.soundVolume)
      m.exitSound:play()
   end
   for i = 1,#m.card do
      if not m.card[i].isVisible then
         m.card[i].hidden = true
      end
   end
   if not m.title.isVisible then
      m.title.hidden = true
   end
end


function av.clearCaches()
   m.cardImageCache = {}
   m.titleImageCache = nil
end

function av.launch(config)
   config = av.setupDefaults(config)
   if not m then
      av.initialize(config)
   end
   av.reinitialize(config)
   if m.launched then
      print("ERROR: achievement_viewer: can't run launch() more than once at a time")
      return
   end
   m.userUpdate = config.updateFunction or function() end
   m.returnToGame = config.returnToGameFunction or function() end

   if not config.disableBackground then
      local backdropImage = gfx.getDisplayImage()
      local displayScale = playdate.display.getScale()
      if displayScale == 1 then
         m.backdropImage = backdropImage
      else
         -- scale the 2x or 4x or 8x background to 1x pixels
         m.backdropImage = gfx.image.new(SCREEN_WIDTH, SCREEN_HEIGHT)
         gfx.pushContext(m.backdropImage)
         backdropImage:drawScaled(0, 0, displayScale, displayScale)
         gfx.popContext()
      end
   end
   av.clearCaches()
   m.launched = true

   av.backupUserSettings()

   playdate.display.setRefreshRate(50)
   playdate.display.setScale(1)
   playdate.inputHandlers.push({}, true)
   m.handlingInput = true

   playdate.update = av.animateInUpdate
   if m.config.soundVolume > 0 then
      m.launchSound:setVolume(m.config.soundVolume)
      m.launchSound:play()
   end
end

function av.forceExit()
   m.fadedBackdropImage = nil
   av.beginExit()
end

function av.hasLaunched()
   return m and m.launched
end

-- 0 to 1
function av.setVolume(v)
   if m and m.config then m.config.soundVolume = v end
   if savedConfig then savedConfig.soundVolume = v end
   if defaultConfig then defaultConfig.soundVolume = v end
end

achievements.viewer = {
   initialize = av.initialize,
   launch = av.launch,
   forceExit = av.forceExit,
   hasLaunched = av.hasLaunched,
   setVolume = av.setVolume,

   getCache = function() return persistentCache end,
}
