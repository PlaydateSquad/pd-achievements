import "CoreLibs/graphics"
import "CoreLibs/object"
import "CoreLibs/crank"

local gfx <const> = playdate.graphics


--[[ Achievement Toasts

   This provides a "toast" popup that can display achievements when
   they are granted, or give a progress update when their progress is
   advanced.

   To use it, ensure all of the required assets are in the "achievements/assets"
   directory of your game.

   Then you can trigger a toast to display in one of two ways: Either call
   achievements.toasts.toast("achievement_id") when you want to display the
   toast, or call achievements.toasts.setAutoToastOnGrant(true) to automatically
   display a toast whenever an achievement is granted.
]]

-- These are the settings you can pass to initialize() and toast() the first time.
-- initialize() is optional, and will be automatically run when you call toast().
local defaultConfig = {
   -- Set the path that you've placed the achievements viewer's fonts, images,
   -- and sounds.
   assetPath = "achievements/assets", 

   -- Number of lines of the achievement description to display. Setting this to 1
   -- lets you fit more achievements on screen, if they all have very short
   -- descriptions. If you have long descriptions, you may need to set this to 3.
   -- This has been tested in the range of 0 (don't show descriptions) to 3.
   -- Mini toasts always show 0 lines of description.
   numDescriptionLines = 2,

   -- Normally, a toast is rendered as a white card with black text. Set this to
   -- render a black card with white text.
   invertToasts = false,

   -- The default audio volume to use for the toast's sound
   -- effects. This should range from 0 to 1. You can modify this after the
   -- first time by calling achievementToasts.setSoundVolume(), for example if
   -- the user changes a "sound effects volume" in-game option..
   soundVolume = 1,

   -- Which achievement data to use. Normally you will set this to nil to have
   -- it retrieve the current game's data directly from the achievements
   -- library, but if you want to display a different game's data, you can get
   -- the gameData using the crossgame module and pass it in here.
   gameData = nil,

   -- Normally the toast is rendered with a black dithered background. You can
   -- use a lighter shadow by setting this to white, or no shadow by setting
   -- this to clear.
   shadowColor = gfx.kColorBlack,

   -- Advanced setting: how to render toasts. Currently the only way implemented
   -- is "update", but "sprite" and "manual" will be implemented in the future.
   --
   --   update: override the developer's playdate.update while the toast displays,
   --   which will draw the toast after everything else has rendered.
   --
   --   sprite: draw the toast into a playdate.gfx.sprite with a very
   --   high priority
   --
   --   manual: the developer must call achievements.toasts.manualUpdate() at
   --   the end of their playdate.update, after everything else has rendered.
   renderMethod = "update",

   -- The following can be overridden toast-by-toast via overrideConfig.
   -- This sets the defaults for any toasts where these are unspecified.

   -- Set this to true to render a mini-toast instead of a full-sized
   -- toast. This takes up much less space on the screen by using a
   -- smaller font and showing no description.
   miniMode = false,

   -- Normally, toasting an achievement that isn't already unlocked
   -- shows an "in progress" toast. Setting this to true assumes any
   -- achievement you toast is granted.
   assumeGranted = false,

   -- Animate the checkbox and the icon changing over (only for
   -- granted achievements, not on "in progress" toasts).
   animateUnlocking = true,
}

local FADE_AMOUNT <const> = 0.5
local FADE_FRAMES <const> = 16

local SCREEN_WIDTH <const> = 400
local SCREEN_HEIGHT <const> = 240

-- layout of inside the card
local LAYOUT_MARGIN <const> = 8
local LAYOUT_SPACING <const> = 4
local LAYOUT_ICON_SIZE <const> = 32
local LAYOUT_ICON_SPACING <const> = 8
local LAYOUT_STATUS_SPACING <const> = 10
local LAYOUT_STATUS_TWEAK_Y <const> = 0
local LAYOUT_PROGRESS_TWEAK_Y <const> = 0

local CHECKBOX_SIZE <const> = 15

local PROGRESS_BAR_HEIGHT <const> = 8
local PROGRESS_BAR_OUTLINE <const> = 1
local PROGRESS_BAR_CORNER <const> = 2

local LOCKED_TEXT <const> = "Locked "
local PROGRESS_TEXT <const> = "Locked "  -- could also be "Progress "
local GRANTED_TEXT <const> = "Unlocked on %s "
local DATE_FORMAT <const> = function(y, m, d) return string.format("%d-%02d-%02d", y, m, d) end

local SECRET_DESCRIPTION <const> = "This is a secret achievement."

local TOAST_CORNER <const> = 6
local TOAST_OUTLINE <const> = 2
local TOAST_WIDTH <const> = 300
-- Base height of each toast...
local TOAST_HEIGHT_BASE <const> = 58
-- ...plus this height per description line...
local TOAST_HEIGHT_PER_LINE <const> = 16
-- ...but with a minimum of this height.
local TOAST_HEIGHT_MIN <const> = 64
local TOAST_SPACING <const> = 12
local TOAST_TEXT <const> = "Achievement unlocked!"

local MINI_TOAST_WIDTH <const> = 184
local MINI_TOAST_HEIGHT <const> = 44
local MINI_TOAST_MARGIN <const> = 6
local MINI_TOAST_SPACING <const> = 7
local MINI_TOAST_START_X <const> = SCREEN_WIDTH / 2 - MINI_TOAST_WIDTH / 2
local MINI_TOAST_START_Y <const> = SCREEN_HEIGHT
local MINI_TOAST_FINISH_X <const> = SCREEN_WIDTH / 2 - MINI_TOAST_WIDTH / 2
local MINI_TOAST_FINISH_Y <const> = SCREEN_HEIGHT - MINI_TOAST_HEIGHT - MINI_TOAST_SPACING

local TOAST_START_X <const> = SCREEN_WIDTH / 2 - TOAST_WIDTH / 2
local TOAST_START_Y <const> = SCREEN_HEIGHT
local TOAST_FINISH_X <const> = SCREEN_WIDTH / 2 - TOAST_WIDTH / 2
local TOAST_FINISH_Y_BASE <const> = SCREEN_HEIGHT - TOAST_SPACING

local TOAST_EASING_IN <const> = playdate.easingFunctions.outCubic
local TOAST_EASING_OUT <const> = playdate.easingFunctions.inCubic

-- These animation timings use seconds because they need to work at any refresh rate.
local TOAST_ANIM_IN_SECONDS <const> = 0.25
local TOAST_ANIM_PAUSE_SECONDS <const> = 4
local TOAST_ANIM_PAUSE_SECONDS_NOANIM <const> = 3
local TOAST_ANIM_OUT_SECONDS <const> = 0.25
local TOAST_ANIM_AFTER_SECONDS <const> = 0.25
-- animation length and start delay for checkbox and icon
local TOAST_ANIM_CHECKBOX_SECONDS <const> = 0.5
local TOAST_ANIM_CHECKBOX_DELAY <const> = 0
-- animate the locked icon into the unlocked icon. set these to 0,0 to disable this animation.
local TOAST_ANIM_ICON_SECONDS <const> = .5
local TOAST_ANIM_ICON_DELAY <const> = .6

local TOAST_DROP_SHADOW_SIZE <const> = 8
local MINI_TOAST_DROP_SHADOW_SIZE <const> = 5
local TOAST_DROP_SHADOW_ALPHA <const> = .25 -- 0.875
local TOAST_DROP_SHADOW_CORNER <const> = 8

local at = {}
local m
local savedConfig = nil

local persistentCache

if achievements and achievements.viewer and achievements.viewer.getCache then
   persistentCache = achievements.viewer.getCache()  -- share cache between toasts and viewewr
else
   persistentCache = {}
end

function at.loadFile(loader, path)
   if not path then return nil end

   if not persistentCache[path] then
      local item = loader(path)
      persistentCache[path] = item
      -- For images, make sure they have a mask. This is needed for toast animation.
      if loader == gfx.image.new and item and item.hasMask and not item:hasMask() then
	 item:addMask(true)
      end
   end
   return persistentCache[path]
end

function at.setupDefaults(config)
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

function at.setConstants(config)
   config = config or m.config
   local numLines = config.numDescriptionLines
   m.c = {}
   m.c.TOAST_WIDTH = TOAST_WIDTH
   m.c.TOAST_HEIGHT = math.max(TOAST_HEIGHT_MIN, TOAST_HEIGHT_BASE + numLines * TOAST_HEIGHT_PER_LINE)
   m.c.TOAST_START_Y = TOAST_START_Y
   m.c.TOAST_START_X = TOAST_START_X
   m.c.TOAST_FINISH_X = TOAST_FINISH_X
   m.c.TOAST_FINISH_Y = TOAST_FINISH_Y_BASE - m.c.TOAST_HEIGHT

   if m.currentToast and m.currentToast.mini then
      m.c.TOAST_WIDTH = MINI_TOAST_WIDTH
      m.c.TOAST_HEIGHT = MINI_TOAST_HEIGHT
      m.c.TOAST_START_Y = MINI_TOAST_START_Y
      m.c.TOAST_START_X = MINI_TOAST_START_X
      m.c.TOAST_FINISH_Y = MINI_TOAST_FINISH_Y
      m.c.TOAST_FINISH_X = MINI_TOAST_FINISH_X
   end
end

function at.initialize(config)
   config = at.setupDefaults(config)

   gameData = config.gameData
   assetPath = config.assetPath

   m = {}
   m.config = table.deepcopy(config)

   m.currentToast = nil
   at.setConstants(config)

   m.imagePath = ""
   if not gameData then
      gameData = achievements.gameData
   end
   if not gameData then
      print("ERROR: achievement_viewer.initialize() invalid gameData")
      m = nil
      return
   end
   m.gameData = gameData
   if achievements.crossgame then
      if achievements.gameData == nil or achievements.gameData.gameID ~= gameData.gameID then
	 m.imagePath = achievements.paths.get_shared_images_path(gameData.gameID) or ""
      end
   end

   m.toastImageCache = {}

   m.defaultIcons = {}
   if (gameData.defaultIcon) then
      m.defaultIcons.granted = at.loadFile(gfx.image.new, m.imagePath .. (gameData.defaultIcon or gameData.default_icon))
   else
      m.defaultIcons.granted = achievements.graphics.get_image("*_default_icon")
   end
   if (gameData.defaultIconLocked or gameData.default_icon_locked) then
      m.defaultIcons.locked = at.loadFile(gfx.image.new, m.imagePath .. (gameData.defaultIconLocked or gameData.default_icon_locked))
   else
      m.defaultIcons.locked = achievements.graphics.get_image("*_default_locked")
   end
   if (gameData.secretIcon or gameData.secret_icon) then
      m.defaultIcons.secret = at.loadFile(gfx.image.new, m.imagePath .. (gameData.secretIcon or gameData.secret_icon))
   else
      m.defaultIcons.secret = achievements.graphics.get_image("*_default_secret")
   end

   m.assetPath = assetPath
   savedAssetPath = assetPath

   m.fonts = {}
   m.fonts.title = at.loadFile(gfx.font.new, assetPath .. "/Roobert-20-Medium")

   m.fonts.name = {}
   m.fonts.name.locked = at.loadFile(gfx.font.new, assetPath .. "/Roobert-11-Medium")
   m.fonts.name.granted = at.loadFile(gfx.font.new, assetPath .. "/Roobert-11-Bold")
   m.fonts.description = {}
   m.fonts.description.locked = at.loadFile(gfx.font.new, assetPath .. "/Nontendo-Light")
   m.fonts.description.locked:setLeading(3)
   m.fonts.description.granted = at.loadFile(gfx.font.new, assetPath .. "/Nontendo-Bold")
   m.fonts.name.miniToast = m.fonts.description.granted
   m.fonts.name.miniToastLocked = m.fonts.description.locked
   m.fonts.description.granted:setLeading(3)
   m.fonts.status = at.loadFile(gfx.font.new, assetPath .. "/font-Bitmore")
   m.fonts.status:setTracking(1)

   m.maskAnim = at.loadFile(gfx.imagetable.new, assetPath .. "/mask_anim")

   m.checkBox = {}
   m.checkBox.anim = at.loadFile(gfx.imagetable.new, assetPath .. "/check_box_anim")
   m.checkBox.locked = at.loadFile(gfx.image.new, assetPath .. "/check_box")
   m.checkBox.granted = at.loadFile(gfx.image.new, assetPath .. "/check_box_checked")
   m.checkBox.secret = at.loadFile(gfx.image.new, assetPath .. "/check_box_secret")

   m.icons = { }
   m.iconBuffer = gfx.image.new(LAYOUT_ICON_SIZE, LAYOUT_ICON_SIZE)  -- for masking
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
	 m.icons[id].locked = at.loadFile(gfx.image.new, m.imagePath .. iconLocked)
      end
      if icon then
	 m.icons[id].granted = at.loadFile(gfx.image.new, m.imagePath .. data.icon)
      end
   end

   m.toasting = false
   m.toastQueue = {} -- additional toasts after this toast
   m.toastSound = at.loadFile(playdate.sound.sampleplayer.new, assetPath .. "/toastSound")
   m.toastProgressSound = at.loadFile(playdate.sound.sampleplayer.new, assetPath .. "/toastProgressSound")
end

function at.reinitialize(config)
   if config then
      for k,v in pairs(config) do
	 m.config[k] = v
      end
   end
   at.setConstants()
end

function at.formatDate(timestamp)
   local time = playdate.timeFromEpoch(timestamp, 0)
   return DATE_FORMAT(time.year, time.month, time.day)
end

function at.drawCard(achievementId, x, y, width, height, toastOptions)
   if not toastOptions then toastOptions = {} end

   local fgColor = m.config.darkMode and gfx.kColorWhite or gfx.kColorBlack
   local bgColor = m.config.darkMode and gfx.kColorBlack or gfx.kColorWhite
   local textDrawMode = m.config.darkMode and gfx.kDrawModeCopy or  gfx.kDrawModeFillWhite

   local wantWidth = width + (toastOptions.dropShadowSize or 0)
   local wantHeight = height + (toastOptions.dropShadowSize or 0)
   local image = m.toastImageCache[achievementId]
   if image and (image.width ~= wantWidth or image.height ~= wantHeight) then
      image = nil
   end
   if not image or toastOptions.updateMinimally then
      if not image then
	 image = gfx.image.new(wantWidth, wantHeight)
	 toastOptions.updateMinimally = false
      end
      m.toastImageCache[achievementId] = image
      gfx.pushContext(image)
      local margin = 1

      local info = m.achievementData[achievementId]

      local iconImgGranted = m.icons[achievementId].granted or m.defaultIcons.granted or
	    m.icons[achievementId].locked or m.defaultIcons.locked
      local iconImgLocked
      if info.secret then
	 iconImgLocked = m.icons[achievementId].locked or m.defaultIcons.secret or m.defaultIcons.locked or
	    m.icons[achievementId].granted or m.defaultIcons.granted
      else
	 iconImgLocked = m.icons[achievementId].locked or m.defaultIcons.locked or
	    m.icons[achievementId].granted or m.defaultIcons.granted
      end
      if toastOptions.updateMinimally then
	 local image_margin = toastOptions.miniToast and MINI_TOAST_MARGIN or LAYOUT_MARGIN
	 if toastOptions.checkBoxAnimFrame ~= nil then
	    local img = m.checkBox.anim:getImage(toastOptions.checkBoxAnimFrame)
	    img:draw(image_margin, height - CHECKBOX_SIZE - image_margin)
	 end

	 if toastOptions.maskAnimFrame ~= nil then
	    if toastOptions.maskAnimFrame == false then
	       -- locked icon
	       iconImgLocked:draw(width - image_margin - iconImgLocked.width, image_margin)
	    elseif toastOptions.maskAnimFrame == true then
	       -- unlocked icon
	       iconImgGranted:draw(width - image_margin - iconImgGranted.width, image_margin)
	    elseif type(toastOptions.maskAnimFrame) == "number" then
	       local backupMask = iconImgLocked:getMaskImage():copy()
	       gfx.pushContext(m.iconBuffer)
	       gfx.clear(gfx.kColorClear)
	       iconImgGranted:draw(0, 0)
	       iconImgLocked:setMaskImage(m.maskAnim:getImage(toastOptions.maskAnimFrame))
	       iconImgLocked:draw(0, 0)
	       iconImgLocked:setMaskImage(backupMask)
	       gfx.popContext()
	       m.iconBuffer:setMaskImage(backupMask)
	       m.iconBuffer:draw(width - image_margin - m.iconBuffer.width, image_margin)
	    end
	 end
      else
	 if toastOptions.dropShadowSize and toastOptions.dropShadowSize > 0 then
	    gfx.pushContext()
	    gfx.setColor(m.config.shadowColor)
	    gfx.setDitherPattern(TOAST_DROP_SHADOW_ALPHA, gfx.image.kDitherTypeBayer8x8)
	    gfx.fillRoundRect(toastOptions.dropShadowSize, toastOptions.dropShadowSize,
			      width, height, TOAST_DROP_SHADOW_CORNER)
	    gfx.popContext()
	 end

	 gfx.setColor(gfx.kColorWhite)
	 gfx.fillRoundRect(0, 0, width, height, TOAST_CORNER)
	
	 gfx.setStrokeLocation(gfx.kStrokeInside)
	 gfx.setLineWidth(TOAST_OUTLINE)
	 gfx.setColor(gfx.kColorBlack)

	 gfx.drawRoundRect(margin, margin, width-2*margin, height-2*margin, TOAST_CORNER)

	 local granted = not not m.achievementData[achievementId].grantedAt
	 --if toastOptions.granted ~= nil then
	    --granted = toastOptions.granted
         --end
	 local iconSize = LAYOUT_ICON_SIZE
	 local image_margin = toastOptions.miniToast and MINI_TOAST_MARGIN or LAYOUT_MARGIN
	 if toastOptions.maskAnimFrame == nil then
	    local iconImg = granted and iconImgGranted or iconImgLocked
	    if iconImg then
	       iconSize = math.min(iconSize, iconImg.width)
	       iconImg:draw(width - image_margin - iconImg.width, image_margin)
	    end
	 elseif toastOptions.maskAnimFrame == false then
	    -- locked icon
	    iconImgLocked:draw(width - image_margin - iconImgLocked.width, image_margin)
	 elseif toastOptions.maskAnimFrame == true then
	    -- unlocked icon
	    iconImgGranted:draw(width - image_margin - iconImgGranted.width, image_margin)
	 elseif type(toastOptions.maskAnimFrame) == "number" then
	    -- this will be handled via the redraw above
	 end
	
	 if toastOptions.miniToast then
	    local font = granted and m.fonts.name.miniToast or m.fonts.name.miniToastLocked
	    gfx.setFont(font)
	    local nameImg = gfx.imageWithText(info.name, width - 2*LAYOUT_MARGIN - LAYOUT_ICON_SPACING - LAYOUT_ICON_SIZE,
					      height - 2*LAYOUT_MARGIN - CHECKBOX_SIZE)
	    if nameImg then nameImg:draw(MINI_TOAST_MARGIN, MINI_TOAST_MARGIN+2) end
	 else
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
	 end

	 local toastMargin = LAYOUT_MARGIN
	 if toastOptions.miniToast then
	    toastMargin = MINI_TOAST_MARGIN
	 end
	 if toastOptions.checkBoxAnimFrame then
	    local img = m.checkBox.anim:getImage(toastOptions.checkBoxAnimFrame)
	    img:draw(toastMargin, height - CHECKBOX_SIZE - toastMargin)
	 elseif granted then
	    m.checkBox.granted:draw(toastMargin, height - CHECKBOX_SIZE - toastMargin)
	 elseif info.isSecret then
	    m.checkBox.secret:draw(toastMargin, height - CHECKBOX_SIZE - toastMargin)
	 else
	    m.checkBox.locked:draw(toastMargin, height - CHECKBOX_SIZE - toastMargin)
	 end

	 local progressMax = info.progress_max or info.progressMax
	 local statusImgWidth, statusImgHeight = 0, 0
	 if toastOptions.miniToast then
	    if toastOptions.showAchievementUnlockedText then
	       font = m.fonts.status
	       gfx.setFont(font)
	       local extraImg = gfx.imageWithText(TOAST_TEXT, width, height)
	       extraImg:draw(MINI_TOAST_MARGIN + CHECKBOX_SIZE + MINI_TOAST_MARGIN,
			     height - MINI_TOAST_MARGIN - extraImg.height + LAYOUT_STATUS_TWEAK_Y)
	    elseif not granted then
	       if not progressMax then
		  font = m.fonts.status
		  gfx.setFont(font)
		  local extraImg = gfx.imageWithText(LOCKED_TEXT, width, height)
		  extraImg:draw(width - extraImg.width - MINI_TOAST_MARGIN - LAYOUT_ICON_SIZE - LAYOUT_SPACING,
				height - MINI_TOAST_MARGIN - extraImg.height + LAYOUT_STATUS_TWEAK_Y)
	       end
	    end
	    statusImgWidth = LAYOUT_ICON_SIZE
	 else
	    local font = m.fonts.status
	    local statusText = ""
	    gfx.setFont(font)
	    if granted then
	       local dateStr = at.formatDate(info.grantedAt or playdate.getSecondsSinceEpoch())
	       if dateStr then
		  statusText = string.format(GRANTED_TEXT, dateStr)
	       end
	    else
	       statusText = LOCKED_TEXT
	       if progressMax and toastOptions.isToast then
		  statusText = PROGRESS_TEXT
	       end
	    end
	    statusImg = gfx.imageWithText(statusText, width - 2*LAYOUT_MARGIN - LAYOUT_SPACING - CHECKBOX_SIZE,
					  height - LAYOUT_MARGIN - iconSize - LAYOUT_ICON_SPACING)
	    if statusImg then
	       statusImg:draw(width - LAYOUT_MARGIN - statusImg.width,
			      height - LAYOUT_MARGIN - statusImg.height + LAYOUT_STATUS_TWEAK_Y)
	       statusImgWidth = statusImg.width
	    end
	 end
	 if not granted and progressMax then
	    local font = m.fonts.status
	    gfx.setFont(font)
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
	       local slash = (m.config.smallMode or toastOptions.miniToast) and "/" or " / "
	       progressText = tostring(amt) .. slash .. tostring(math.floor(progressMax))
	       frac = amt / math.floor(progressMax)
	    end
	    local progressTextWidth = width - 2*LAYOUT_MARGIN -
	       LAYOUT_STATUS_SPACING - CHECKBOX_SIZE -
	       LAYOUT_STATUS_SPACING - statusImgWidth
	    local progressTextHeight = height - LAYOUT_MARGIN - iconSize - LAYOUT_SPACING
	    local progressSpacing = LAYOUT_STATUS_SPACING
	    local progressMargin = LAYOUT_MARGIN
	    if toastOptions.miniToast then
	       progressTextWidth = width
	       progressTextHeight = height
	       progressSpacing = MINI_TOAST_SPACING
	       progressMargin = MINI_TOAST_MARGIN
	    end
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
	    if toastOptions.miniToast then
	       progressBarWidth = progressBarWidth + 2*LAYOUT_STATUS_SPACING - 2*MINI_TOAST_MARGIN
	       progressBarTweakY = 0
	    end
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
	 elseif toastOptions.showAchievementUnlockedText and not toastOptions.miniToast then
	       font = m.fonts.status
	       gfx.setFont(font)
	       local extraImg = gfx.imageWithText(TOAST_TEXT, width - 2*LAYOUT_MARGIN - statusImgWidth -
						  LAYOUT_STATUS_SPACING - LAYOUT_SPACING - CHECKBOX_SIZE,
						  height - LAYOUT_MARGIN - iconSize - LAYOUT_ICON_SPACING)
	       if extraImg then
		  extraImg:draw(LAYOUT_MARGIN + CHECKBOX_SIZE + LAYOUT_SPACING,
				height - LAYOUT_MARGIN - extraImg.height + LAYOUT_STATUS_TWEAK_Y)
	       end
	
	 end
      end
      gfx.popContext()
   end
   m.toastImageCache[achievementId]:draw(x, y)
end

function at.destroy()
   m = nil
end


function at.clearCaches()
   m.toastImageCache = nil
end

function at.updateToast()
   if m.toastBackupPlaydateUpdate then m.toastBackupPlaydateUpdate() end

   if m.currentToast == nil then
      -- don't change whether we're mini-toasting except between toasts.
      m.currentToast = {
	 mini = not not m.config.miniMode,
	 anim = not not m.config.animateUnlocking,
	 granted = not not m.config.assumeGranted,
      }
      if m.overrideConfig then
	 if m.overrideConfig.miniMode ~= nil then
	    m.currentToast.mini = m.overrideConfig.miniMode
	 end
	 if m.overrideConfig.assumeGranted ~= nil then
	    m.currentToast.granted = m.overrideConfig.assumeGranted
	 end
	 if m.overrideConfig.animateUnlocking ~= nil then
	    m.currentToast.anim = m.overrideConfig.animateUnlocking
	 end
      end
      at.setConstants()
   end
   local isGranted = (m.achievementData[m.toastAchievement] and m.achievementData[m.toastAchievement].grantedAt)
   if m.currentToast.granted then isGranted = true end -- assume granted

   if m.toastAnim == 0 then
      if m.config.soundVolume > 0 then
	 if isGranted then
	    m.toastSound:setVolume(m.config.soundVolume)
	    m.toastSound:play()
	 else
	    m.toastProgressSound:setVolume(m.config.soundVolume)
	    m.toastProgressSound:play()
	 end
      end
      m.toastImageCache[m.toastAchievement] = nil
   end
   m.toastAnim = m.toastAnim + 1 / m.toastRefreshRate

   local toastOptions = {
      -- false = locked icon, true = unlocked icon, number = anim frame
      isToast = true,
      checkBoxAnimFrame = isGranted and m.checkBox.anim:getLength() or nil,
      maskAnimFrame = isGranted and true or nil,
      updateMinimally = true,
      granted = isGranted,
      showAchievementUnlockedText = isGranted,
      dropShadowSize = m.config.shadowColor and
	 (m.currentToast.mini and MINI_TOAST_DROP_SHADOW_SIZE or TOAST_DROP_SHADOW_SIZE)
	 or nil,
      miniToast = m.currentToast.mini
   }
   if not isGranted then
      m.currentToast.anim = false
   end

   if m.toastAnim <= TOAST_ANIM_IN_SECONDS then
      -- sliding up
      local ratio = m.toastAnim / TOAST_ANIM_IN_SECONDS
      ratio = TOAST_EASING_IN(ratio, 0, 1, 1)
      local negRatio = 1 - ratio
      local x = math.floor(0.5 + ratio * m.c.TOAST_FINISH_X + negRatio * m.c.TOAST_START_X)
      local y = math.floor(0.5 + ratio * m.c.TOAST_FINISH_Y + negRatio * m.c.TOAST_START_Y)
      if m.currentToast.anim then
	 toastOptions.checkBoxAnimFrame = 1
	 if TOAST_ANIM_ICON_SECONDS > 0 then
	    toastOptions.maskAnimFrame = false
	 end
      end
      at.drawCard(m.toastAchievement, x, y, m.c.TOAST_WIDTH, m.c.TOAST_HEIGHT, toastOptions)
   elseif m.toastAnim - TOAST_ANIM_IN_SECONDS <= TOAST_ANIM_PAUSE_SECONDS then
      -- pausing
      local maskRatio = (m.toastAnim - TOAST_ANIM_IN_SECONDS - TOAST_ANIM_ICON_DELAY) / TOAST_ANIM_ICON_SECONDS
      local checkBoxRatio = (m.toastAnim - TOAST_ANIM_IN_SECONDS - TOAST_ANIM_CHECKBOX_DELAY) / TOAST_ANIM_CHECKBOX_SECONDS
      if m.currentToast.anim then
	 toastOptions.checkBoxAnimFrame = math.min(math.max(1, math.ceil(m.checkBox.anim:getLength() * checkBoxRatio)), m.checkBox.anim:getLength())
	 if TOAST_ANIM_ICON_SECONDS > 0 then
	    toastOptions.maskAnimFrame = math.min(math.max(1, math.ceil(m.maskAnim:getLength() * maskRatio)), m.maskAnim:getLength())
	 end
      end
      local ratio = (m.toastAnim - TOAST_ANIM_IN_SECONDS) / TOAST_ANIM_PAUSE_SECONDS
      local x = m.c.TOAST_FINISH_X
      local y = m.c.TOAST_FINISH_Y
      at.drawCard(m.toastAchievement, x, y, m.c.TOAST_WIDTH, m.c.TOAST_HEIGHT, toastOptions)
      if m.toastAnim - TOAST_ANIM_IN_SECONDS >= TOAST_ANIM_PAUSE_SECONDS_NOANIM then
	 -- early-out the pause if there is no animation
	 m.toastAnim = TOAST_ANIM_IN_SECONDS + TOAST_ANIM_PAUSE_SECONDS - 1/m.toastRefreshRate + 0.001
      end
   elseif m.toastAnim - TOAST_ANIM_IN_SECONDS - TOAST_ANIM_PAUSE_SECONDS <= TOAST_ANIM_OUT_SECONDS then
      -- sliding down
      local ratio = (m.toastAnim - TOAST_ANIM_IN_SECONDS - TOAST_ANIM_PAUSE_SECONDS) / TOAST_ANIM_OUT_SECONDS
      ratio = TOAST_EASING_OUT(ratio, 0, 1, 1)
      if m.currentToast.anim then
	 toastOptions.checkBoxAnimFrame = m.checkBox.anim:getLength()
	 if TOAST_ANIM_ICON_SECONDS > 0 then
	    toastOptions.maskAnimFrame = true
	 end
      end
      local negRatio = 1 - ratio
      local x = math.floor(0.5 + negRatio * m.c.TOAST_FINISH_X + ratio * m.c.TOAST_START_X)
      local y = math.floor(0.5 + negRatio * m.c.TOAST_FINISH_Y + ratio * m.c.TOAST_START_Y)
      at.drawCard(m.toastAchievement, x, y, m.c.TOAST_WIDTH, m.c.TOAST_HEIGHT, toastOptions)
   elseif m.toastAnim - TOAST_ANIM_IN_SECONDS - TOAST_ANIM_PAUSE_SECONDS - TOAST_ANIM_OUT_SECONDS <= TOAST_ANIM_AFTER_SECONDS then
      -- wait a moment with the toast totally off screen
      local x = m.c.TOAST_START_X
      local y = m.c.TOAST_START_Y
      if m.currentToast.anim then
	 toastOptions.checkBoxAnimFrame = m.checkBox.anim:getLength()
	 toastOptions.maskAnimFrame = true
      end
      at.drawCard(m.toastAchievement, x, y, m.c.TOAST_WIDTH, m.c.TOAST_HEIGHT, toastOptions)
   elseif m.toastQueue and #m.toastQueue > 0 then
      local nextToast = table.remove(m.toastQueue, 1)
      m.toastAchievement = nextToast.id
      m.currentToast = {
	 granted = nextToast.granted,
	 mini = nextToast.mini,
	 anim = nextToast.anim,
      }
      if m.overrideConfig then
	 if m.overrideConfig.miniMode ~= nil then
	    m.currentToast.mini = m.overrideConfig.miniMode
	 end
	 if m.overrideConfig.assumeGranted ~= nil then
	    m.currentToast.granted = m.overrideConfig.assumeGranted
	 end
	 if m.overrideConfig.animateUnlocking ~= nil then
	    m.currentToast.anim = m.overrideConfig.animateUnlocking
	 end
      end
      m.toastImageCache[m.toastAchievement] = nil
      m.toastAnim = 0
      at.setConstants()
   else
      m.toasting = false
      playdate.update = m.toastBackupPlaydateUpdate
      m.toastBackupPlaydateUpdate = nil
      m.currentToast = nil
      at.destroy()
   end
end

function at.abortToasts()
   if not m or not m.toasting then
      return
   end
   if m.toastAnim > TOAST_ANIM_IN_SECONDS + TOAST_ANIM_CHECKBOX_SECONDS and
      m.toastAnim < TOAST_ANIM_IN_SECONDS + TOAST_ANIM_CHECKBOX_SECONDS then
      m.toastAnim = TOAST_ANIM_IN_SECONDS + TOAST_ANIM_PAUSE_SECONDS
   end
   m.toastQueue = nil
end

function at.toast(achievementId, config)
   config = at.setupDefaults(config)
   if not m then
      at.initialize(config)
   end
   at.reinitialize(config)
   config = m.config
   if not m.achievementData[achievementId] then
      print("ERROR: achievement_viewer: toast() called with invalid achievement " .. achievementId)
      return
   end
   if m and m.toasting then
      -- queue up this toast for later
      local mini, anim, granted = not not config.miniMode, not not config.animateUnlocking, not not config.assumeGranted
      if m.overrideConfig then
	 if m.overrideConfig.miniMode ~= nil then
	    mini = m.overrideConfig.miniMode
	 end
	 if m.overrideConfig.assumeGranted ~= nil then
	    granted = m.overrideConfig.assumeGranted
	 end
	 if m.overrideConfig.animateUnlocking ~= nil then
	    anim = m.overrideConfig.animateUnlocking
	 end
      end

      table.insert(m.toastQueue, { id = achievementId,
				   mini = mini,
				   anim = anim,
				   granted = granted,
      })
      return
   end

   m.toastBackupPlaydateUpdate = playdate.update

   m.toasting = true
   m.toastAnim = 0
   m.toastAchievement = achievementId
   m.toastRefreshRate = playdate.display.getRefreshRate() or 30
   m.toastImageCache[m.toastAchievement] = nil
   if m.toastRefreshRate == 0 then m.toastRefreshRate = 30 end

   playdate.update = at.updateToast
end

function at.isToasting()
   return m and m.toasting
end

-- 0 to 1
function at.setVolume(v)
   if m and m.config then m.config.soundVolume = v end
   if savedConfig then savedConfig.soundVolume = v end
   if defaultConfig then defaultConfig.soundVolume = v end
end

-- Specify a config with miniMode, animateUnlocking, assumeGranted set that
-- overrides what the toast was queued up with. Or nil to stop overriding.
function at.overrideConfig(config)
   m.overrideConfig = config
end

local originalGrantFunction = nil
local function grantWithToast()
end

function at.setAutoToastOnGrant(autoToast)
   if not originalGrantFunction then
      originalGrantFunction = achievements.grant
   end
   
   achievements.grant = autoToast and grantWithToast or originalGrantFunction
end

local originalAdvanceToFunction = nil
local originalAdvanceByFunction = nil
local function advanceToWithToast()
end
local function advanceByWithToast()
end


function at.setAutoToastOnAdvance(autoToast)
   if not originalAdvanceToFunction then
      originalAdvanceToFunction = achievements.advanceTo
   end
   if not originalAdvanceByFunction then
      originalAdvanceByFunction = achievements.advanceBy
   end
   
   achievements.advanceTo = autoToast and advanceToWithToast or originalAdvanceToFunction
   achievements.advanceBy = autoToast and advanceByWithToast or originalAdvanceByFunction
end

achievements.toasts = {
   initialize = at.initialize,
   toast = at.toast,
   isToasting = at.isToasting,
   overrideConfig = at.overrideConfig,
   abortToasts = at.abortToasts,
   setVolume = at.setVolume,

   manualUpdate = at.updateToast,

   setAutoToastOnGrant = at.setAutoToastOnGrant,
   setAutoToastOnAdvance = at.setAutoToastOnAdvance,
}
