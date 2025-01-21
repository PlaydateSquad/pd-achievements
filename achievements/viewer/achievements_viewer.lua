import "CoreLibs/graphics"
import "CoreLibs/object"
import "CoreLibs/crank"

local gfx <const> = playdate.graphics

-- These are the settings you can pass to initialize(), launch(), and toast() the first time.
-- initialize() is optional, and will be automatically run when you call launch() or toast().
local defaultConfig = {
   gameData = nil, -- get the game data directly from the achievements library
   assetPath = "achievements/viewer/",
   smallMode = false,  -- use shorter cards (only room for 1-line description)
   darkMode = true,  -- show dark cards instead of light cards

   sortOrder = "default",  -- sort order default, recent, or progress

   disableBackground = false,  -- disable the automatically captured background
   updateFunction = function() end,  -- this will be called every frame when the viewer is blocking the screen
   returnToGameFunction = function() end, -- this will be called when the viewer is returning to the game

   -- special options for toasts
   toastShadowColor = gfx.kColorBlack, -- set to white if rendering on a dark background
}

local FADE_AMOUNT <const> = 0.5
local FADE_FRAMES <const> = 16

local SCREEN_WIDTH <const> = playdate.display.getWidth()
local SCREEN_HEIGHT <const> = playdate.display.getHeight()

local CARD_CORNER <const> = 6
local CARD_WIDTH_LARGE <const> = 300
local CARD_WIDTH_SMALL <const> = 300
local CARD_HEIGHT_LARGE <const> = 90
local CARD_HEIGHT_SMALL <const> = 76
local CARD_OUTLINE <const> = 2
local CARD_SPACING <const> = 8
local CARD_SPACING_ANIM_LARGE <const> = SCREEN_HEIGHT - CARD_HEIGHT_LARGE
local CARD_SPACING_ANIM_SMALL <const> = SCREEN_HEIGHT - CARD_HEIGHT_SMALL

-- layout of inside the card
local LAYOUT_MARGIN <const> = 8
local LAYOUT_SPACING <const> = 4
local LAYOUT_ICON_SIZE <const> = 32
local LAYOUT_ICON_SPACING <const> = 8
local LAYOUT_STATUS_SPACING <const> = 10
local LAYOUT_STATUS_TWEAK_Y <const> = -1

local CHECKBOX_SIZE <const> = 15

local TITLE_CORNER <const> = 6
local TITLE_TWEAK_Y <const> = -2 -- tweak the Y position of the title text
local TITLE_WIDTH_LARGE <const> = CARD_WIDTH_LARGE
local TITLE_WIDTH_SMALL <const> = CARD_WIDTH_SMALL
local TITLE_HEIGHT_LARGE <const> = math.floor(64)
local TITLE_HEIGHT_SMALL <const> = math.floor(64)
local TITLE_LOCK_Y <const> = 19  -- lock in position at this point, or negative to not
local TITLE_SPACING <const> = CARD_SPACING
local TITLE_PERCENTAGE_TEXT <const> = "%s completed"
local TITLE_HELP_TEXT_MARGIN <const> = 4
local TITLE_ARROW_X_MARGIN <const> = 16
local TITLE_ARROW_Y_MARGIN <const> = 6
local TITLE_ARROW_WIDTH <const> = 5
local TITLE_ARROW_HEIGHT <const> = 10
local TITLE_ARROW_SPEED = 0.3
local TITLE_ARROW_MAG = 3

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

local LOCKED_TEXT <const> = "Locked "
local GRANTED_TEXT <const> = "Unlocked on %s "
local DATE_FORMAT <const> = function(y, m, d) return string.format("%d-%02d-%02d", y, m, d) end

local SECRET_DESCRIPTION <const> = "This is a secret achievement."

local TOAST_WIDTH_LARGE <const> = 300
local TOAST_WIDTH_SMALL <const> = 300
local TOAST_HEIGHT_LARGE <const> = 90
local TOAST_HEIGHT_SMALL <const> = 76
local TOAST_SPACING <const> = 20
local TOAST_TEXT <const> = "Achievement unlocked!"

local TOAST_START_X_LARGE <const> = SCREEN_WIDTH / 2 - TOAST_WIDTH_LARGE / 2
local TOAST_START_X_SMALL <const> = SCREEN_WIDTH / 2 - TOAST_WIDTH_SMALL / 2
local TOAST_START_Y_LARGE <const> = SCREEN_HEIGHT
local TOAST_START_Y_SMALL <const> = SCREEN_HEIGHT

local TOAST_FINISH_X_LARGE <const> = SCREEN_WIDTH / 2 - TOAST_WIDTH_LARGE / 2
local TOAST_FINISH_X_SMALL <const> = SCREEN_WIDTH / 2 - TOAST_WIDTH_SMALL / 2
local TOAST_FINISH_Y_LARGE <const> = SCREEN_HEIGHT - TOAST_HEIGHT_LARGE - TOAST_SPACING
local TOAST_FINISH_Y_SMALL <const> = SCREEN_HEIGHT - TOAST_HEIGHT_SMALL - TOAST_SPACING
local TOAST_EASING_IN <const> = playdate.easingFunctions.outCubic
local TOAST_EASING_OUT <const> = playdate.easingFunctions.inCubic
-- These animation timings use seconds because they need to work at any refresh rate.
local TOAST_ANIM_IN_SECONDS <const> = 0.25
local TOAST_ANIM_PAUSE_SECONDS <const> = 4
local TOAST_ANIM_OUT_SECONDS <const> = 0.25
local TOAST_ANIM_AFTER_SECONDS <const> = 0.25
local TOAST_ANIM_CHECKBOX_SECONDS <const> = 0.5

local TOAST_DROP_SHADOW_SIZE <const> = 8
local TOAST_DROP_SHADOW_ALPHA <const> = .25 -- 0.875
local TOAST_DROP_SHADOW_CORNER <const> = 8

local SORT_ORDER = { "default", "recent", "progress" }

local av = {}
local m
local savedConfig = nil

local persistentCache = {} -- persists between launches

function av.loadFile(loader, path)
   if not path then return nil end

   if not persistentCache[path] then
      persistentCache[path] = loader(path)
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

function av.initialize(config)
   config = av.setupDefaults(config)

   gameData = config.gameData
   assetPath = config.assetPath
   
   m = {}
   m.config = table.deepcopy(config)

   local smallMode = config.smallMode
   m.c = {}
   m.c.CARD_WIDTH = smallMode and CARD_WIDTH_SMALL or CARD_WIDTH_LARGE
   m.c.CARD_HEIGHT = smallMode and CARD_HEIGHT_SMALL or CARD_HEIGHT_LARGE
   m.c.CARD_SPACING_ANIM = smallMode and CARD_SPACING_ANIM_SMALL or CARD_SPACING_ANIM_LARGE
   m.c.TITLE_WIDTH = smallMode and TITLE_WIDTH_SMALL or TITLE_WIDTH_LARGE
   m.c.TITLE_HEIGHT = smallMode and TITLE_HEIGHT_SMALL or TITLE_HEIGHT_LARGE
   
   m.c.TOAST_WIDTH = smallMode and TOAST_WIDTH_SMALL or TOAST_WIDTH_LARGE
   m.c.TOAST_HEIGHT = smallMode and TOAST_HEIGHT_SMALL or TOAST_HEIGHT_LARGE
   m.c.TOAST_START_Y = smallMode and TOAST_START_Y_SMALL or TOAST_START_Y_LARGE
   m.c.TOAST_START_X = smallMode and TOAST_START_X_SMALL or TOAST_START_X_LARGE
   m.c.TOAST_FINISH_Y = smallMode and TOAST_FINISH_Y_SMALL or TOAST_FINISH_Y_LARGE
   m.c.TOAST_FINISH_X = smallMode and TOAST_FINISH_X_SMALL or TOAST_FINISH_X_LARGE

   m.launched = false
   
   m.imagePath = ""
   if not gameData then
      gameData = achievements.gameData
   end
   if not gameData then
      error("achievement_viewer.initialize() invalid gameData")
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

   m.defaultIcons = {}
   if (gameData.defaultIcon) then
      m.defaultIcons.granted = av.loadFile(gfx.image.new, m.imagePath .. (gameData.defaultIcon or gameData.default_icon))
   end
   if (gameData.defaultIconLocked or gameData.default_icon_locked) then
      m.defaultIcons.locked = av.loadFile(gfx.image.new, m.imagePath .. (gameData.defaultIconLocked or gameData.default_icon_locked))
   end
   if (gameData.secretIcon or gameData.secret_icon) then
      m.defaultIcons.secret = av.loadFile(gfx.image.new, m.imagePath .. (gameData.secretIcon or gameData.secret_icon))
   end

   m.assetPath = assetPath
   savedAssetPath = assetPath

   m.fonts = {}
   m.fonts.title = av.loadFile(gfx.font.new, assetPath .. "/Roobert-20-Medium")

   m.fonts.name = {}
   m.fonts.name.locked = av.loadFile(gfx.font.new, assetPath .. "/Roobert-11-Medium")
   m.fonts.name.granted = av.loadFile(gfx.font.new, assetPath .. "/Roobert-11-Bold")
   m.fonts.description = {}
   m.fonts.description.locked = av.loadFile(gfx.font.new, assetPath .. "/Nontendo-Light")
   m.fonts.description.locked:setLeading(3)
   m.fonts.description.granted = av.loadFile(gfx.font.new, assetPath .. "/Nontendo-Bold")
   m.fonts.description.granted:setLeading(3)
   m.fonts.status = av.loadFile(gfx.font.new, assetPath .. "/font-Bitmore")
   m.fonts.status:setTracking(1)

   m.checkBox = {}
   m.checkBox.anim = av.loadFile(gfx.imagetable.new, assetPath .. "/check_box_anim")
   m.checkBox.locked = av.loadFile(gfx.image.new, assetPath .. "/check_box")
   m.checkBox.granted = av.loadFile(gfx.image.new, assetPath .. "/check_box_checked")
   m.checkBox.secret = av.loadFile(gfx.image.new, assetPath .. "/check_box_secret")

   m.launchSound = av.loadFile(playdate.sound.sampleplayer.new, assetPath .. "/launchSound")
   m.exitSound = av.loadFile(playdate.sound.sampleplayer.new, assetPath .. "/exitSound")
   m.sortSound = av.loadFile(playdate.sound.sampleplayer.new, assetPath .. "/sortSound")
   m.scrollSound = av.loadFile(playdate.sound.sampleplayer.new, assetPath .. "/scrollSound")

   m.icons = { }
   m.achievementData = {}
   m.additionalAchievementData = {}

   for i = 1,#m.gameData.achievements do
      local data = m.gameData.achievements[i]
      local id = data.id
      m.achievementData[id] = data
      m.additionalAchievementData[id] = { idx = i }
      
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
   -- A few settings for showing an achievement toast.
   m.toasting = false
   m.toastQueue = {} -- additional toasts after this toast
   m.toastAnimFrame = 0
   m.toastSound = av.loadFile(playdate.sound.sampleplayer.new, assetPath .. "/toastSound")
   m.toastPos = { x = SCREEN_WIDTH / 2 - m.c.CARD_WIDTH / 2,
		  y = SCREEN_HEIGHT }
end

function av.reinitialize()
   m.continuousAnimFrame = 0
   m.animFrame = 0
   m.fadeAmount = 0
   m.scroll = 0
   m.scrollSpeed = 0
   m.title = { x = SCREEN_WIDTH/2 - m.c.TITLE_WIDTH/2, y = 0, hidden = false }
   m.card = { }
   m.scorePossible = 0
   m.currentScore = 0
   for i = 1,#m.gameData.achievements do
      local data = m.gameData.achievements[i]
      local achScore = data.score_value or data.scoreValue or 0
      m.scorePossible += achScore
      if data.grantedAt then
	 m.currentScore += achScore
      end
      m.card[i] = {
	 x = SCREEN_WIDTH / 2 - m.c.CARD_WIDTH / 2,
	 y = m.c.TITLE_HEIGHT + TITLE_SPACING + (i-1) * (m.c.CARD_HEIGHT + CARD_SPACING),
	 hidden = false
      }
   end
   m.completionPercentage = achievements.completionPercentage
   if not m.completionPercentage and m.scorePossible > 0 then
      m.completionPercentage = m.currentScore / m.scorePossible
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
		    if m.achievementData[a].grantedAt and not m.achievementData[b].grantedAt then
		       return false
		    elseif m.achievementData[b].grantedAt and not m.achievementData[a].grantedAt then
		       return true
		    elseif m.achievementData[a].grantedAt and m.achievementData[b].grantedAt and
		       m.achievementData[a].grantedAt ~= m.achievementData[b].grantedAt then
		       return m.achievementData[a].grantedAt > m.achievementData[b].grantedAt
		    elseif m.achievementData[a].isSecret ~= m.achievementData[b].isSecret then
		       return m.achievementData[b].isSecret
		    else
		       local progressMaxA = m.achievementData[a].progressMax or m.achievementData[a].progress_max or 0
		       local progressMaxB = m.achievementData[b].progressMax or m.achievementData[b].progress_max or 0
		       if progressMaxA ~= 0 and progressMaxB == 0 then
			  return true
		       elseif progressMaxB ~= 0 and progressMaxA == 0 then
			  return false
		       elseif progressMaxA ~= 0 and progressMaxB ~= 0 then
			  -- both have progress, return the one with higher progress
			  local progressA = m.achievementData[a].progress or 0
			  local progressB = m.achievementData[b].progress or 0
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
		    if m.achievementData[a].grantedAt and not m.achievementData[b].grantedAt then
		       return true
		    elseif m.achievementData[b].grantedAt and not m.achievementData[a].grantedAt then
		       return false
		    elseif m.achievementData[a].grantedAt and m.achievementData[b].grantedAt and
		       m.achievementData[a].grantedAt ~= m.achievementData[b].grantedAt then
		       return m.achievementData[a].grantedAt > m.achievementData[b].grantedAt
		    else
		       return m.additionalAchievementData[a].idx <  m.additionalAchievementData[b].idx
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
end

function av.restoreUserSettings()
   if m.backupPlaydateUpdate then
      playdate.update = m.backupPlaydateUpdate
      m.backupPlaydateUpdate = nil
   end
   if m.backupRefreshRate then
      playdate.display.setRefreshRate(m.backupRefreshRate)
   end
   if m.handlingInput then
      playdate.inputHandlers.pop()
   end
   m.backupPlaydateUpdate = nil
   m.backupRefreshRate = nil
end

function av.destroy()
   m = nil
end

function av.drawTitle(x, y)
   local width = m.c.TITLE_WIDTH
   local height = m.c.TITLE_HEIGHT
   local image = m.titleImageCache
   local updateMinimally = false
   if not image then
      m.titleImageCache = gfx.image.new(width, height)
      image = m.titleImageCache
   else
      updateMinimally = true
   end
   local fgColor = m.config.darkMode and gfx.kColorBlack or gfx.kColorWhite
   local bgColor = m.config.darkMode and gfx.kColorWhite or gfx.kColorBlack
   local textDrawMode = m.config.darkMode and gfx.kDrawModeFillWhite or gfx.kDrawModeCopy
   
   gfx.pushContext(image)
   if not updateMinimally then

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
      local pctImg
      if m.completionPercentage then
	 local pct = tostring(math.floor(0.5 + 100 * m.completionPercentage)) .. "%"
	 pctImg = gfx.imageWithText(string.format(TITLE_PERCENTAGE_TEXT, pct), m.c.TITLE_WIDTH, m.c.TITLE_HEIGHT)
      end
      if pctImg then
	 pctImg:draw(LAYOUT_MARGIN,
		     height - TITLE_HELP_TEXT_MARGIN - pctImg.height)
      end
   end
   -- updateMinimally still does these
   -- clear the sort order that's already there
   font = m.fonts.status
   gfx.setFont(font)
   gfx.setImageDrawMode(gfx.kDrawModeFillWhite)
   local sortImg = gfx.imageWithText("Sort:", m.c.TITLE_WIDTH, m.c.TITLE_HEIGHT)
   local sortImg2 = gfx.imageWithText(tostring(m.sortOrder), m.c.TITLE_WIDTH, m.c.TITLE_HEIGHT)
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

function av.drawCard(achievementId, x, y, width, height, toastOverride)
   if not toastOverride then toastOverride = {} end
   
   local fgColor = m.config.darkMode and gfx.kColorWhite or gfx.kColorBlack
   local bgColor = m.config.darkMode and gfx.kColorBlack or gfx.kColorWhite
   local textDrawMode = m.config.darkMode and gfx.kDrawModeCopy or  gfx.kDrawModeFillWhite
   
   local wantWidth = width + (toastOverride.dropShadowSize or 0)
   local wantHeight = height + (toastOverride.dropShadowSize or 0)
   local image = m.cardImageCache[achievementId]
   if image and (image.width ~= wantWidth or image.height ~= wantHeight) then
      image = nil
   end
   if not image or toastOverride.updateMinimally then
      if not image then
	 image = gfx.image.new(wantWidth, wantHeight)
	 toastOverride.updateMinimally = false
      end
      m.cardImageCache[achievementId] = image
      gfx.pushContext(image)
      local margin = 1

      if toastOverride.updateMinimally then
	 if toastOverride.checkBoxAnimFrame then
	    local img = m.checkBox.anim:getImage(toastOverride.checkBoxAnimFrame)
	    img:draw(LAYOUT_MARGIN, height - CHECKBOX_SIZE - LAYOUT_MARGIN)
	 end
      else
	 if toastOverride.dropShadowSize and toastOverride.dropShadowSize > 0 then
	    gfx.pushContext()
	    gfx.setColor(m.config.toastShadowColor)
	    gfx.setDitherPattern(TOAST_DROP_SHADOW_ALPHA, gfx.image.kDitherTypeBayer8x8)
	    gfx.fillRoundRect(toastOverride.dropShadowSize, toastOverride.dropShadowSize,
			      width, height, TOAST_DROP_SHADOW_CORNER)
	    gfx.popContext()
	 end

	 gfx.setColor(gfx.kColorWhite)
	 gfx.fillRoundRect(0, 0, width, height, CARD_CORNER)
	 
	 gfx.setStrokeLocation(gfx.kStrokeInside)
	 gfx.setLineWidth(CARD_OUTLINE)
	 gfx.setColor(gfx.kColorBlack)

	 gfx.drawRoundRect(margin, margin, width-2*margin, height-2*margin, CARD_CORNER)
	 
	 local info = m.achievementData[achievementId]
	 local granted = not not m.achievementData[achievementId].grantedAt
	 if toastOverride.granted ~= nil then
	    granted = toastOverride.granted
	 end

	 local iconImg
	 if granted then
	    iconImg = m.icons[achievementId].granted or m.defaultIcons.granted or
	       m.icons[achievementId].locked or m.defaultIcons.locked
	 elseif info.secret then
	    iconImg = m.icons[achievementId].locked or m.defaultIcons.secret or m.defaultIcons.locked or
	       m.icons[achievementId].granted or m.defaultIcons.granted
	 else
	    iconImg = m.icons[achievementId].locked or m.defaultIcons.locked or
	       m.icons[achievementId].granted or m.defaultIcons.granted
	 end
	 local iconSize = LAYOUT_ICON_SIZE
	 if iconImg then
	    iconSize = math.min(iconSize, iconImg.width)
	    iconImg:draw(width - LAYOUT_MARGIN - iconImg.width, LAYOUT_MARGIN)
	 end

	 local font = granted and m.fonts.name.granted or m.fonts.name.locked
	 gfx.setFont(font)
	 local nameImg = gfx.imageWithText(info.name,
					   width - 2*LAYOUT_MARGIN - LAYOUT_ICON_SPACING - LAYOUT_ICON_SIZE,
					   height - 2*LAYOUT_MARGIN - LAYOUT_SPACING - CHECKBOX_SIZE)

	 font = granted and m.fonts.description.granted or m.fonts.description.locked
	 gfx.setFont(font)
	 local heightRemaining = height - 2*LAYOUT_MARGIN - 2*LAYOUT_SPACING - nameImg.height - CHECKBOX_SIZE
	 local descImage
	 if heightRemaining >= font:getHeight() then
	    local description = info.description
	    if info.isSecret and not granted then
	       description = SECRET_DESCRIPTION
	    end
	    
	    descImg = gfx.imageWithText(description,
					width - 2*LAYOUT_MARGIN - LAYOUT_ICON_SPACING - LAYOUT_ICON_SIZE,
					heightRemaining)
	 end

	 nameImg:draw(LAYOUT_MARGIN, LAYOUT_MARGIN)
	 if descImg then
	    descImg:draw(LAYOUT_MARGIN, LAYOUT_MARGIN + nameImg.height + LAYOUT_SPACING)
	 end
	 
	 if toastOverride.checkBoxAnimFrame then
	    local img = m.checkBox.anim:getImage(toastOverride.checkBoxAnimFrame)
	    img:draw(LAYOUT_MARGIN, height - CHECKBOX_SIZE - LAYOUT_MARGIN)
	 elseif granted then
	    m.checkBox.granted:draw(LAYOUT_MARGIN, height - CHECKBOX_SIZE - LAYOUT_MARGIN)
	 elseif info.isSecret then
	    m.checkBox.secret:draw(LAYOUT_MARGIN, height - CHECKBOX_SIZE - LAYOUT_MARGIN)
	 else
	    m.checkBox.locked:draw(LAYOUT_MARGIN, height - CHECKBOX_SIZE - LAYOUT_MARGIN)
	 end

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
	 end

	 local progressMax = info.progress_max or info.progressMax
	 if not granted and progressMax then
	    local progress = info.progress or 0
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
	       local slash = m.config.smallMode and "/" or " / "
	       progressText = tostring(amt) .. slash .. tostring(math.floor(progressMax))
	       frac = amt / math.floor(progressMax)
	    end
	    progressTextImg = gfx.imageWithText(progressText, width - 2*LAYOUT_MARGIN -
						LAYOUT_STATUS_SPACING - CHECKBOX_SIZE -
						LAYOUT_STATUS_SPACING - statusImg.width,
						height - LAYOUT_MARGIN - iconSize - LAYOUT_SPACING)
	    progressTextImg:draw(width - LAYOUT_MARGIN - statusImg.width -
				 LAYOUT_STATUS_SPACING - progressTextImg.width,
				 height - LAYOUT_MARGIN - progressTextImg.height + LAYOUT_STATUS_TWEAK_Y)

	    local progressBarWidth =
	       width - 2*LAYOUT_MARGIN -
	       LAYOUT_STATUS_SPACING - statusImg.width -
	       LAYOUT_STATUS_SPACING - progressTextImg.width-
	       LAYOUT_SPACING - CHECKBOX_SIZE
	    gfx.setColor(gfx.kColorBlack)
	    gfx.pushContext()
	    gfx.setDitherPattern(.5, gfx.image.kDitherTypeBayer8x8)
	    gfx.fillRoundRect(LAYOUT_MARGIN + CHECKBOX_SIZE + LAYOUT_STATUS_SPACING,
			      height - LAYOUT_MARGIN - CHECKBOX_SIZE/2 - PROGRESS_BAR_HEIGHT/2,
			      frac * progressBarWidth,
			      PROGRESS_BAR_HEIGHT, PROGRESS_BAR_CORNER)
	    gfx.popContext()
	    gfx.setLineWidth(PROGRESS_BAR_OUTLINE)
	    gfx.drawRoundRect(LAYOUT_MARGIN + CHECKBOX_SIZE + LAYOUT_STATUS_SPACING,
			      height - LAYOUT_MARGIN - CHECKBOX_SIZE/2 - PROGRESS_BAR_HEIGHT/2,
			      progressBarWidth, PROGRESS_BAR_HEIGHT, PROGRESS_BAR_CORNER)
	 elseif toastOverride.showAchievementUnlockedText then
	    font = m.fonts.status
	    gfx.setFont(font)
	    local extraImg = gfx.imageWithText(TOAST_TEXT, width - 2*LAYOUT_MARGIN - statusImg.width -
					       LAYOUT_STATUS_SPACING - LAYOUT_SPACING - CHECKBOX_SIZE,
					       height - LAYOUT_MARGIN - iconSize - LAYOUT_ICON_SPACING)
	    extraImg:draw(LAYOUT_MARGIN + CHECKBOX_SIZE + LAYOUT_SPACING,
			  height - LAYOUT_MARGIN - extraImg.height + LAYOUT_STATUS_TWEAK_Y)
	    
	 end

      end
      gfx.popContext()
   end
   m.cardImageCache[achievementId]:draw(x, y)
end

function av.drawCards(x, y)
   local x = (x or 0)
   local y = (y or 0) - m.scroll + CARD_SPACING
   local extraSpacing = m.cardSpacing

   local count = 0
   local titleY = y + m.title.y
   if not m.title.hidden then
      if titleY + m.c.TITLE_HEIGHT > 0 and titleY < SCREEN_HEIGHT then
	 m.title.isVisible = true
	 count = count + 1
      else
	 m.title.isVisible = false
      end
   else
      m.title.isVisible = false
   end

   for i = 1,#m.card do
      if not m.card[i].hidden then
	 local card = m.card[i]
	 count = count + 1
	 card.drawY = m.card[i].y + count*extraSpacing
	 if y + card.drawY + m.c.CARD_HEIGHT > 0 and y + card.drawY < SCREEN_HEIGHT then
	    local id = m.cardSort[i]
	    av.drawCard(id,
			x + card.x,
			y + card.drawY,
			m.c.CARD_WIDTH, m.c.CARD_HEIGHT)
	    m.card[i].isVisible = true
	 else
	    m.card[i].isVisible = false
	 end
      end
   end
   if m.title.isVisible then
      av.drawTitle(x + m.title.x, titleY)
   end
end


function av.animateInUpdate()
   m.userUpdate()
   if m.backdropImage then
      m.backdropImage:draw(0, 0)
   end
   m.continuousAnimFrame = m.continuousAnimFrame + 1
   m.fadeAmount = m.fadeAmount + (FADE_AMOUNT / FADE_FRAMES)
   if m.fadeAmount >= FADE_AMOUNT then
      m.fadeAmount = FADE_AMOUNT
   end

   gfx.pushContext()
   gfx.setDitherPattern(1-m.fadeAmount, gfx.image.kDitherTypeBayer8x8)
   gfx.fillRect(0, 0, playdate.display.getWidth(), playdate.display.getHeight()) 
   gfx.popContext()

   if m.fadeAmount >= FADE_AMOUNT and m.fadedBackdropImage == nil and m.backdropImage then
      m.fadedBackdropImage = playdate.graphics.getWorkingImage()
   end

   local scrollOffset = 0
   local animFrame = ANIM_EASING_IN(m.animFrame, 0, ANIM_FRAMES, ANIM_FRAMES, .75)
   if m.animFrame <= ANIM_FRAMES then
      scrollOffset = SCREEN_HEIGHT - SCREEN_HEIGHT * (animFrame / ANIM_FRAMES)
      m.animFrame = m.animFrame + 1
   end
   m.cardSpacing = m.c.CARD_SPACING_ANIM - m.c.CARD_SPACING_ANIM * (animFrame / ANIM_FRAMES)
   av.drawCards(0, scrollOffset)

   if m.fadeAmount >= FADE_AMOUNT and m.animFrame > ANIM_FRAMES then
      m.cardSpacing = 0
      m.animFrame = 0
      playdate.update = av.mainUpdate
   end
end

function av.animateOutUpdate()
   m.userUpdate()
   if m.backdropImage then
      m.backdropImage:draw(0, 0)
   end
   m.continuousAnimFrame = m.continuousAnimFrame + 1
   m.fadeAmount = m.fadeAmount + (FADE_AMOUNT / FADE_FRAMES)
   if m.fadeAmount >= FADE_AMOUNT then
      m.fadeAmount = FADE_AMOUNT
   end
   gfx.pushContext()
   gfx.setDitherPattern(FADE_AMOUNT + m.fadeAmount, gfx.image.kDitherTypeBayer8x8)
   gfx.fillRect(0, 0, playdate.display.getWidth(), playdate.display.getHeight()) 
   gfx.popContext()
   

   local animFrame = ANIM_EASING_OUT(m.animFrame, 0, ANIM_FRAMES, ANIM_FRAMES)
   
   local scrollOffset = SCREEN_HEIGHT * (animFrame / ANIM_FRAMES)
   m.cardSpacing = m.c.CARD_SPACING_ANIM * (animFrame / ANIM_FRAMES)
   av.drawCards(x, scrollOffset)
   if m.animFrame <= ANIM_FRAMES then
      m.animFrame = m.animFrame + 1
   end

   if m.fadeAmount >= FADE_AMOUNT and m.animFrame > ANIM_FRAMES then
      av.restoreUserSettings()
      playdate.getCrankTicks(1)
      local returnFunction = m.returnToGameFunction
      if not m.toasting then av.destroy() else av.clearCaches() end
      if returnFunction then returnFunction() end
   end
end

function av.mainUpdate()
   m.userUpdate()
   if m.fadedBackdropImage then
      m.fadedBackdropImage:draw(0, 0)
   end

   m.continuousAnimFrame = m.continuousAnimFrame + 1
   m.animFrame = m.animFrame + 1
   
   av.drawCards()

   if playdate.buttonJustPressed(playdate.kButtonRight) then
      local i = table.indexOfElement(SORT_ORDER, m.sortOrder)
      if i < #SORT_ORDER then i = i + 1 else i = 1 end
      m.sortOrder = SORT_ORDER[i] or SORT_ORDER[1]
      av.sortCards()
      m.sortSound:play()
      m.scrollToTop = true
   elseif playdate.buttonJustPressed(playdate.kButtonLeft) then
      local i = table.indexOfElement(SORT_ORDER, m.sortOrder)
      if i > 1 then i = i - 1 else i = #SORT_ORDER end
      m.sortOrder = SORT_ORDER[i] or SORT_ORDER[1]
      av.sortCards()
      m.sortSound:play()
      m.scrollToTop = true
   end
   local oldScroll = m.scroll
   if m.scrollToTop then
      m.scroll = m.scroll * .7
      if m.scroll < SCROLL_ACCEL then
	 m.scroll = 0
      end
      m.scrollSpeed = math.max(m.scrollSpeed - SCROLL_ACCEL_DOWN, 0)
   else
      if playdate.buttonIsPressed(playdate.kButtonUp) then
	 m.scrollSpeed = math.min(m.scrollSpeed + SCROLL_ACCEL, SCROLL_SPEED)
      elseif playdate.buttonIsPressed(playdate.kButtonDown) then
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

   local crankChanged, accelChanged = playdate.getCrankChange()
   m.scroll = m.scroll + accelChanged
   if m.scroll < 3 and m.scrollSpeed == 0 then m.scroll = m.scroll - 1 end

   m.maxScroll = m.card[#m.card].y + m.c.CARD_HEIGHT - SCREEN_HEIGHT + 2*CARD_SPACING
   
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
      m.scrollSound:play()
   end
   
   if playdate.buttonJustPressed(playdate.kButtonB) then
      m.fadedBackdropImage = nil
      av.beginExit()
   end
end


function av.beginExit()
   m.animFrame = 0
   m.fadeAmount = 0
   playdate.update = av.animateOutUpdate   
   m.exitSound:play()
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
   av.reinitialize()
   if m.launched then
      error("achievement_viewer: can't run launch() more than once at a time")
      return
   end
   m.userUpdate = config.updateFunction or function() end
   m.returnToGame = config.returnToGameFunction or function() end

   m.backdropImage = config.disableBackground and nil or gfx.getDisplayImage()
   av.clearCaches()
   av.launched = true
   
   av.backupUserSettings()

   playdate.display.setRefreshRate(50)
   playdate.inputHandlers.push({}, true)
   m.handlingInput = true

   playdate.update = av.animateInUpdate
   m.launchSound:play()
end

function av.updateToast()
   if m.toastBackupPlaydateUpdate then m.toastBackupPlaydateUpdate() end

   if m.toastAnim == 0 then
      m.toastSound:play()
   end

   m.toastAnim = m.toastAnim + 1 / m.toastRefreshRate
   local toastOverride = {
      checkBoxAnimFrame = 1,
      updateMinimally = true,
      granted = true,
      showAchievementUnlockedText = true,
      dropShadowSize = m.config.toastShadowColor and TOAST_DROP_SHADOW_SIZE or nil,
   }
   
   if m.toastAnim <= TOAST_ANIM_IN_SECONDS then
      -- sliding up
      local ratio = m.toastAnim / TOAST_ANIM_IN_SECONDS
      ratio = TOAST_EASING_IN(ratio, 0, 1, 1)
      local negRatio = 1 - ratio
      local x = math.floor(0.5 + ratio * m.c.TOAST_FINISH_X + negRatio * m.c.TOAST_START_X)
      local y = math.floor(0.5 + ratio * m.c.TOAST_FINISH_Y + negRatio * m.c.TOAST_START_Y)
      toastOverride.checkBoxAnimFrame = 1
      av.drawCard(m.toastAchievement, x, y, m.c.TOAST_WIDTH, m.c.TOAST_HEIGHT, toastOverride)
   elseif m.toastAnim - TOAST_ANIM_IN_SECONDS <= TOAST_ANIM_PAUSE_SECONDS then
      -- pausing
      local checkBoxRatio = (m.toastAnim - TOAST_ANIM_IN_SECONDS) / TOAST_ANIM_CHECKBOX_SECONDS
      toastOverride.checkBoxAnimFrame = math.min(math.max(1, math.ceil(m.checkBox.anim:getLength() * checkBoxRatio)), m.checkBox.anim:getLength())
      local ratio = (m.toastAnim - TOAST_ANIM_IN_SECONDS) / TOAST_ANIM_PAUSE_SECONDS
      local x = m.c.TOAST_FINISH_X
      local y = m.c.TOAST_FINISH_Y
      av.drawCard(m.toastAchievement, x, y, m.c.TOAST_WIDTH, m.c.TOAST_HEIGHT, toastOverride)
   elseif m.toastAnim - TOAST_ANIM_IN_SECONDS - TOAST_ANIM_PAUSE_SECONDS <= TOAST_ANIM_OUT_SECONDS then
      -- sliding down
      local ratio = (m.toastAnim - TOAST_ANIM_IN_SECONDS - TOAST_ANIM_PAUSE_SECONDS) / TOAST_ANIM_OUT_SECONDS
      ratio = TOAST_EASING_OUT(ratio, 0, 1, 1)
      toastOverride.checkBoxAnimFrame = m.checkBox.anim:getLength()
      local negRatio = 1 - ratio
      local x = math.floor(0.5 + negRatio * m.c.TOAST_FINISH_X + ratio * m.c.TOAST_START_X)
      local y = math.floor(0.5 + negRatio * m.c.TOAST_FINISH_Y + ratio * m.c.TOAST_START_Y)
      av.drawCard(m.toastAchievement, x, y, m.c.TOAST_WIDTH, m.c.TOAST_HEIGHT, toastOverride)
   elseif m.toastAnim - TOAST_ANIM_IN_SECONDS - TOAST_ANIM_PAUSE_SECONDS - TOAST_ANIM_OUT_SECONDS <= TOAST_ANIM_AFTER_SECONDS then
      -- wait a moment with the toast totally off screen
      local x = m.c.TOAST_START_X
      local y = m.c.TOAST_START_Y
      toastOverride.checkBoxAnimFrame = m.checkBox.anim:getLength()
      av.drawCard(m.toastAchievement, x, y, m.c.TOAST_WIDTH, m.c.TOAST_HEIGHT, toastOverride)
   elseif m.toastQueue and #m.toastQueue > 0 then
      m.toastAchievement = table.remove(m.toastQueue, 1)
      m.cardImageCache[m.toastAchievement] = nil
      m.toastAnim = 0
   else
      m.toasting = false
      playdate.update = m.toastBackupPlaydateUpdate
      m.toastBackupPlaydateUpdate = nil
      playdate.display.setRefreshRate(30)
      av.destroy()
   end
end

function av.abortToasts()
   if not m or not m.toasting then
      return
   end
   if m.toastAnim > TOAST_ANIM_IN_SECONDS + TOAST_ANIM_CHECKBOX_SECONDS and
      m.toastAnim < TOAST_ANIM_IN_SECONDS + TOAST_ANIM_CHECKBOX_SECONDS then
      m.toastAnim = TOAST_ANIM_IN_SECONDS + TOAST_ANIM_PAUSE_SECONDS
   end
   m.toastQueue = nil
end

function av.toast(achievementId, config)
   config = av.setupDefaults(config)
   if not m then
      av.initialize(config)
   end
   av.reinitialize()
   if m.launched then
      error("achievement_viewer: can't run toast() while launch() is active")
      return
   end
   if m and m.toasting then
      table.insert(m.toastQueue, achievementId)
      return
   end

   m.toastBackupPlaydateUpdate = playdate.update

   m.toasting = true
   m.toastAnim = 0
   m.toastAchievement = achievementId
   m.toastRefreshRate = playdate.display.getRefreshRate() or 30
   m.cardImageCache[m.toastAchievement] = nil
   if m.toastRefreshRate == 0 then m.toastRefreshRate = 30 end

   playdate.update = av.updateToast
end

achievementsViewer = {
   initialize = av.initialize,
   launch = av.launch,
   toast = av.toast,
   abortToasts = av.abortToasts,
   getCache = function() return persistentCache end
}
achievementViewer = achievementsViewer  -- typos yay
