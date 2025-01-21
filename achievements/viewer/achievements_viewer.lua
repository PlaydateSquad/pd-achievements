import "CoreLibs/graphics"
import "CoreLibs/object"

local gfx <const> = playdate.graphics

local FADE_AMOUNT <const> = 0.5
local FADE_FRAMES <const> = 16

local SCREEN_WIDTH <const> = playdate.display.getWidth()
local SCREEN_HEIGHT <const> = playdate.display.getHeight()

local CARD_CORNER <const> = 6
local CARD_WIDTH <const> = 300
local CARD_HEIGHT <const> = 90
local CARD_OUTLINE <const> = 2
local CARD_SPACING <const> = 10
local CARD_SPACING_ANIM <const> = SCREEN_HEIGHT - CARD_HEIGHT

-- layout of inside the card
local LAYOUT_MARGIN <const> = 8
local LAYOUT_SPACING <const> = 5
local LAYOUT_ICON_SIZE <const> = 32
local LAYOUT_ICON_SPACING <const> = 8
local LAYOUT_STATUS_SPACING <const> = 10

local CHECKBOX_SIZE <const> = 15

local TITLE_CORNER <const> = 6
local TITLE_WIDTH <const> = CARD_WIDTH
local TITLE_HEIGHT <const> = math.floor(.75 * CARD_HEIGHT)
local TITLE_SPACING <const> = CARD_SPACING
local TITLE_PERCENTAGE_TEXT <const> = "%s completed"
local TITLE_PERCENTAGE_MARGIN <const> = 4

local PROGRESS_BAR_HEIGHT <const> = 8
local PROGRESS_BAR_OUTLINE <const> = 1
local PROGRESS_BAR_RADIUS <const> = 2

local ANIM_FRAMES <const> = 24
local ANIM_EASING_IN <const> = playdate.easingFunctions.outCubic
local ANIM_EASING_OUT <const> = playdate.easingFunctions.inCubic

local SCROLL_EASING <const> = playdate.easingFunctions.inQuad
local SCROLL_ACCEL <const> = .75
local SCROLL_ACCEL_DOWN <const> = 2
local SCROLL_SPEED <const> = 16

local LOCKED_TEXT <const> = "Locked "
local GRANTED_TEXT <const> = "Granted at %s "
local DATE_FORMAT <const> = function(y, m, d) return string.format("%d-%02d-%02d", y, m, d) end

local SECRET_TEXT <const> = "This is a secret achievement."


local TOAST_WIDTH <const> = CARD_WIDTH + 20
local TOAST_HEIGHT <const> = CARD_HEIGHT - 12
local TOAST_SPACING <const> = 10
local TOAST_TEXT <const> = "Achievement unlocked!"
local TOAST_START_X <const> = SCREEN_WIDTH / 2 - CARD_WIDTH / 2
local TOAST_START_Y <const> = SCREEN_HEIGHT
local TOAST_FINISH_X <const> = SCREEN_WIDTH / 2 - CARD_WIDTH / 2
local TOAST_FINISH_Y <const> = SCREEN_HEIGHT - CARD_HEIGHT - TOAST_SPACING
local TOAST_EASING_IN <const> = playdate.easingFunctions.outCubic
local TOAST_EASING_OUT <const> = playdate.easingFunctions.inCubic
-- These animation timings use seconds because they need to work at any refresh rate.
local TOAST_ANIM_IN_SECONDS <const> = 0.25
local TOAST_ANIM_PAUSE_SECONDS <const> = 4
local TOAST_ANIM_OUT_SECONDS <const> = 0.25
local TOAST_ANIM_AFTER_SECONDS <const> = 0.25

local TOAST_ANIM_CHECKBOX_SECONDS <const> = 0.5

local av = {}
local m

local persistentCache = {} -- persists between launches

function av.loadFile(loader, path)
   if not path then return nil end

   if not persistentCache[path] then
      persistentCache[path] = loader(path)
   end
   return persistentCache[path]
end

function av.initialize(gameData, assetPath)
   m = {}

   m.fadeAmount = 0
   m.animFrame = 0

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
	 m.imagePath = achievements.paths.get_shared_images_path(gameData.gameID)
      end
   end

   m.cardSpacing = 10
   m.cardImageCache = {}
   m.titleImageCache = nil

   m.defaultIcons = {}
   --printTable(gameData)
   m.defaultIcons.granted = av.loadFile(gfx.image.new, m.imagePath .. (gameData.defaultIcon or gameData.default_icon))
   m.defaultIcons.locked = av.loadFile(gfx.image.new, m.imagePath .. (gameData.defaultIconLocked or gameData.default_icon_locked))
   m.defaultIcons.secret = av.loadFile(gfx.image.new, m.imagePath .. (gameData.secretIcon or gameData.secret_icon))

   m.assetPath = assetPath

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
   m.scrollSound = av.loadFile(playdate.sound.sampleplayer.new, assetPath .. "/scrollSound")

   m.scroll = 0
   m.scrollSpeed = 0

   m.icons = { }
   m.title = { x = SCREEN_WIDTH/2 - TITLE_WIDTH/2, y = 0, hidden = false }
   m.card = { }
   m.achievementData = {}
   m.additionalAchievementData = {}
   for i = 1,#m.gameData.achievements do
      local data = m.gameData.achievements[i]
      local id = data.id
      m.achievementData[id] = data
      m.additionalAchievementData[id] = {}
      
      m.icons[id] = {}
      local iconLocked = data.iconLocked or data.icon_locked
      local icon = data.icon
      if iconLocked then
	 m.icons[id].locked = av.loadFile(gfx.image.new, m.imagePath .. iconLocked)
      end
      if icon then
	 m.icons[id].granted = av.loadFile(gfx.image.new, m.imagePath .. data.icon)
      end
   
      m.card[i] = { x = SCREEN_WIDTH / 2 - CARD_WIDTH / 2,
		    y = TITLE_HEIGHT + TITLE_SPACING + (i-1) * (CARD_HEIGHT + CARD_SPACING),
		    hidden = false
      }
   end

   -- A few settings for showing an achievement toast.
   m.toasting = false
   m.toastQueue = {} -- additional toasts after this toast
   m.toastAnimFrame = 0
   m.toastSound = av.loadFile(playdate.sound.sampleplayer.new, assetPath .. "/toastSound")
   m.toastPos = { x = SCREEN_WIDTH / 2 - CARD_WIDTH / 2,
		  y = SCREEN_HEIGHT }
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
   local width = TITLE_WIDTH
   local height = TITLE_HEIGHT
   if not m.titleImageCache then
      local image = gfx.image.new(width, height)
      m.titleImageCache = image
      gfx.pushContext(image)

      local margin = 1
      local font = m.fonts.title
      
      gfx.setColor(gfx.kColorWhite)
      gfx.fillRoundRect(0, 0, width, height, TITLE_CORNER)
      
      gfx.setColor(gfx.kColorBlack)
      gfx.fillRoundRect(0+margin, 0+margin, width-2*margin, height-2*margin, TITLE_CORNER)

      gfx.setImageDrawMode(gfx.kDrawModeFillWhite)
      font:drawTextAligned("Achievements", width/2, height/2 - math.floor(font:getHeight()/2), kTextAlignment.center)

      font = m.fonts.status
      gfx.setFont(font)
      if m.gameData.completionPercentage then
	 local pct = tostring(math.floor(0.5 + 100 * m.gameData.completionPercentage)) .. "%"
	 local pctImg = gfx.imageWithText(string.format(TITLE_PERCENTAGE_TEXT, pct), TITLE_WIDTH, TITLE_HEIGHT)
	 pctImg:draw(width - LAYOUT_MARGIN - pctImg.width,
		     height - TITLE_PERCENTAGE_MARGIN - pctImg.height)
      end
      gfx.popContext()
   end
   m.titleImageCache:draw(x, y)
end

function av.formatDate(timestamp)
   local time = playdate.timeFromEpoch(timestamp, 0)
   return DATE_FORMAT(time.year, time.month, time.day)
end

function av.drawCard(achievementId, x, y, width, height, toastOverride)
   if not m.cardImageCache[achievementId] or toastOverride.updateMinimally then
      local image
      if m.cardImageCache[achievementId] then
	 image = m.cardImageCache[achievementId]
      else
	 image = gfx.image.new(width, height)
	 toastOverride.updateMinimally = false
      end
      m.cardImageCache[achievementId] = image
      gfx.pushContext(image)
      local margin = 1

      if toastOverride and toastOverride.updateMinimally then
	 if toastOverride and toastOverride.checkBoxAnimFrame then
	    local img = m.checkBox.anim:getImage(toastOverride.checkBoxAnimFrame)
	    img:draw(LAYOUT_MARGIN, height - CHECKBOX_SIZE - LAYOUT_MARGIN)
	 end
      else
	 gfx.setColor(gfx.kColorWhite)
	 gfx.fillRoundRect(0, 0, width, height, CARD_CORNER)
	 
	 gfx.setStrokeLocation(gfx.kStrokeInside)
	 gfx.setLineWidth(CARD_OUTLINE)
	 gfx.setColor(gfx.kColorBlack)

	 gfx.drawRoundRect(margin, margin, width-2*margin, height-2*margin, CARD_CORNER)
	 
	 local info = m.achievementData[achievementId]
	 local granted = not not m.achievementData[achievementId].grantedAt
	 if toastOverride and toastOverride.granted ~= nil then
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
	    if info.secret then
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
	 
	 if toastOverride and toastOverride.checkBoxAnimFrame then
	    local img = m.checkBox.anim:getImage(toastOverride.checkBoxAnimFrame)
	    img:draw(LAYOUT_MARGIN, height - CHECKBOX_SIZE - LAYOUT_MARGIN)
	 elseif granted then
	    m.checkBox.granted:draw(LAYOUT_MARGIN, height - CHECKBOX_SIZE - LAYOUT_MARGIN)
	 elseif info.secret then
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
			   height - LAYOUT_MARGIN - statusImg.height)
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
	       progressText = tostring(amt) .. " / " .. tostring(math.floor(progressMax))
	       frac = amt / math.floor(progressMax)
	    end
	    progressTextImg = gfx.imageWithText(progressText, width - 2*LAYOUT_MARGIN -
						LAYOUT_STATUS_SPACING - CHECKBOX_SIZE -
						LAYOUT_STATUS_SPACING - statusImg.width,
						height - LAYOUT_MARGIN - iconSize - LAYOUT_SPACING)
	    progressTextImg:draw(width - LAYOUT_MARGIN - statusImg.width -
				 LAYOUT_STATUS_SPACING - progressTextImg.width,
				 height - LAYOUT_MARGIN - progressTextImg.height)

	    local progressBarWidth =
	       width - 2*LAYOUT_MARGIN -
	       LAYOUT_STATUS_SPACING - statusImg.width -
	       LAYOUT_STATUS_SPACING - progressTextImg.width-
	       LAYOUT_SPACING - CHECKBOX_SIZE
	    gfx.setColor(gfx.kColorBlack)
	    gfx.pushContext()
	    gfx.setDitherPattern(.5, gfx.image.kDitherTypeBayer2x2)
	    gfx.fillRoundRect(LAYOUT_MARGIN + CHECKBOX_SIZE + LAYOUT_STATUS_SPACING,
			      height - LAYOUT_MARGIN - CHECKBOX_SIZE/2 - PROGRESS_BAR_HEIGHT/2,
			      frac * progressBarWidth,
			      PROGRESS_BAR_HEIGHT, PROGRESS_BAR_RADIUS)
	    gfx.popContext()
	    gfx.setLineWidth(PROGRESS_BAR_OUTLINE)
	    gfx.drawRoundRect(LAYOUT_MARGIN + CHECKBOX_SIZE + LAYOUT_STATUS_SPACING,
			      height - LAYOUT_MARGIN - CHECKBOX_SIZE/2 - PROGRESS_BAR_HEIGHT/2,
			      progressBarWidth, PROGRESS_BAR_HEIGHT, PROGRESS_BAR_RADIUS)
	 elseif toastOverride then
	    font = m.fonts.status
	    gfx.setFont(font)
	    local extraImg = gfx.imageWithText(TOAST_TEXT, width - 2*LAYOUT_MARGIN - statusImg.width -
					       LAYOUT_STATUS_SPACING - LAYOUT_SPACING - CHECKBOX_SIZE,
					       height - LAYOUT_MARGIN - iconSize - LAYOUT_ICON_SPACING)
	    extraImg:draw(LAYOUT_MARGIN + CHECKBOX_SIZE + LAYOUT_SPACING,
			  height - LAYOUT_MARGIN - extraImg.height)
	    
	 end

      end
      gfx.popContext()
   end
   m.cardImageCache[achievementId]:draw(x, y)
end

function av.drawCards(x, y)
   local x = (x or 0)
   local y = (y or 0) - m.scroll
   local extraSpacing = m.cardSpacing

   local count = 0
   if not m.title.hidden then
      av.drawTitle(x + m.title.x, y + m.title.y)
      if y + TITLE_HEIGHT > 0 and y < SCREEN_HEIGHT then
	 m.title.isVisible = true
	 count = count + 1
      else
	 m.title.isVisible = false
      end
   end

   for i = 1,#m.card do
      if not m.card[i].hidden then
	 local card = m.card[i]
	 count = count + 1
	 card.drawY = m.card[i].y + count*extraSpacing
	 if y + card.drawY + CARD_HEIGHT > 0 and y + card.drawY < SCREEN_HEIGHT then
	    local id = m.gameData.achievements[i].id
	    av.drawCard(id,
			x + card.x,
			y + card.drawY,
			CARD_WIDTH, CARD_HEIGHT)
	    m.card[i].isVisible = true
	 else
	    m.card[i].isVisible = false
	 end
      end
   end
end


function av.animateInUpdate()
   m.userUpdate()
   m.backdropImage:draw(0, 0)
   m.fadeAmount = m.fadeAmount + (FADE_AMOUNT / FADE_FRAMES)
   if m.fadeAmount >= FADE_AMOUNT then
      m.fadeAmount = FADE_AMOUNT
   end

   gfx.pushContext()
   gfx.setDitherPattern(1-m.fadeAmount, gfx.image.kDitherTypeBayer8x8)
   gfx.fillRect(0, 0, playdate.display.getWidth(), playdate.display.getHeight()) 
   gfx.popContext()

   if m.fadeAmount >= FADE_AMOUNT and m.fadedBackdropImage == nil then
      m.fadedBackdropImage = playdate.graphics.getWorkingImage()
   end


   local scrollOffset = 0
   local animFrame = ANIM_EASING_IN(m.animFrame, 0, ANIM_FRAMES, ANIM_FRAMES)
   if m.animFrame <= ANIM_FRAMES then
      scrollOffset = SCREEN_HEIGHT - SCREEN_HEIGHT * (animFrame / ANIM_FRAMES)
      m.animFrame = m.animFrame + 1
   end
   m.cardSpacing = CARD_SPACING_ANIM - CARD_SPACING_ANIM * (animFrame / ANIM_FRAMES)
   av.drawCards(0, scrollOffset)

   if m.fadeAmount >= FADE_AMOUNT and m.animFrame > ANIM_FRAMES then
      m.cardSpacing = 0
      playdate.update = av.mainUpdate
   end
end

function av.animateOutUpdate()
   m.userUpdate()
   m.backdropImage:draw(0, 0)
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
   m.cardSpacing = CARD_SPACING_ANIM * (animFrame / ANIM_FRAMES)
   av.drawCards(x, scrollOffset)
   if m.animFrame <= ANIM_FRAMES then
      m.animFrame = m.animFrame + 1
   end

   if m.fadeAmount >= FADE_AMOUNT and m.animFrame > ANIM_FRAMES then
      av.restoreUserSettings()
      av.destroy()
   end
end

function av.mainUpdate()
   m.userUpdate()
   m.fadedBackdropImage:draw(0, 0)

   av.drawCards()

   if playdate.buttonIsPressed(playdate.kButtonUp) then
      m.scrollSpeed = math.min(m.scrollSpeed + SCROLL_ACCEL, SCROLL_SPEED)
   elseif playdate.buttonIsPressed(playdate.kButtonDown) then
      m.scrollSpeed = math.max(m.scrollSpeed - SCROLL_ACCEL, -SCROLL_SPEED)
   elseif m.scrollSpeed > 0 then
      m.scrollSpeed = math.max(m.scrollSpeed - SCROLL_ACCEL_DOWN, 0)
   elseif m.scrollSpeed < 0 then
      m.scrollSpeed = math.min(m.scrollSpeed + SCROLL_ACCEL_DOWN, 0)
   end

   if m.scrollSpeed ~= 0 then
      local scrollMax = SCROLL_SPEED *  m.scrollSpeed / math.abs(m.scrollSpeed)
      local scrollAmount = SCROLL_EASING(m.scrollSpeed, 0, scrollMax, scrollMax)
      m.scroll = m.scroll - scrollAmount
   end

   m.scroll = m.scroll + playdate.getCrankChange()

   m.maxScroll = m.card[#m.card].y + CARD_HEIGHT - SCREEN_HEIGHT
   
   if m.scroll < 0 then
      m.scroll = 0
      m.scrollSpeed = 0
   elseif m.scroll > m.maxScroll then
      m.scroll = m.maxScroll
      m.scrollSpeed = 0
   end
   
   if playdate.buttonJustPressed(playdate.kButtonB) then
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

function av.launch(gameData, assetPath, userUpdate)
   if not m then
      av.initialize(gameData, assetPath or "achievements/viewer")
   end
   m.userUpdate = userUpdate or function() end

   m.backdropImage = gfx.getDisplayImage()
   av.clearCaches()
   av.launched = true
   
   av.backupUserSettings()

   playdate.display.setRefreshRate(50)
   playdate.inputHandlers.push({}, true)
   m.handlingInput = true

   playdate.update = av.animateInUpdate
   m.launchSound:play()
end

function updateToast()
   m.backupPlaydateUpdate()

   m.toastAnim = m.toastAnim + 1 / m.toastRefreshRate
   local toastOverride = {
      checkBoxAnimFrame = 1,
      updateMinimally = true,
      granted = true,
   }
   
   if m.toastAnim <= TOAST_ANIM_IN_SECONDS then
      -- sliding up
      local ratio = m.toastAnim / TOAST_ANIM_IN_SECONDS
      ratio = TOAST_EASING_IN(ratio, 0, 1, 1)
      local negratio = 1 - ratio
      local x = ratio * TOAST_FINISH_X + negratio * TOAST_START_X
      local y = ratio * TOAST_FINISH_Y + negratio * TOAST_START_Y
      toastOverride.checkBoxAnimFrame = 1
      av.drawCard(m.toastAchievement, x, y, TOAST_WIDTH, TOAST_HEIGHT, toastOverride)
   elseif m.toastAnim - TOAST_ANIM_IN_SECONDS <= TOAST_ANIM_PAUSE_SECONDS then
      -- pausing
      local checkBoxRatio = (m.toastAnim - TOAST_ANIM_IN_SECONDS) / TOAST_ANIM_CHECKBOX_SECONDS
      toastOverride.checkBoxAnimFrame = math.min(math.max(1, math.ceil(m.checkBox.anim:getLength() * checkBoxRatio)), m.checkBox.anim:getLength())
      local ratio = (m.toastAnim - TOAST_ANIM_IN_SECONDS) / TOAST_ANIM_PAUSE_SECONDS
      local x = TOAST_FINISH_X
      local y = TOAST_FINISH_Y
      av.drawCard(m.toastAchievement, x, y, TOAST_WIDTH, TOAST_HEIGHT, toastOverride)
   elseif m.toastAnim - TOAST_ANIM_IN_SECONDS - TOAST_ANIM_PAUSE_SECONDS <= TOAST_ANIM_OUT_SECONDS then
      -- sliding down
      local ratio = (m.toastAnim - TOAST_ANIM_IN_SECONDS - TOAST_ANIM_PAUSE_SECONDS) / TOAST_ANIM_OUT_SECONDS
      ratio = TOAST_EASING_OUT(ratio, 0, 1, 1)
      toastOverride.checkBoxAnimFrame = m.checkBox.anim:getLength()
      local negratio = 1 - ratio
      local x = negratio * TOAST_FINISH_X + ratio * TOAST_START_X
      local y = negratio * TOAST_FINISH_Y + ratio * TOAST_START_Y
      av.drawCard(m.toastAchievement, x, y, TOAST_WIDTH, TOAST_HEIGHT, toastOverride)
   elseif m.toastAnim - TOAST_ANIM_IN_SECONDS - TOAST_ANIM_PAUSE_SECONDS - TOAST_ANIM_OUT_SECONDS <= TOAST_ANIM_AFTER_SECONDS then
      -- wait a moment with the toast totally off screen
      local x = TOAST_START_X
      local y = TOAST_START_Y
      toastOverride.checkBoxAnimFrame = m.checkBox.anim:getLength()
      av.drawCard(m.toastAchievement, x, y, TOAST_WIDTH, TOAST_HEIGHT, toastOverride)
   elseif m.toastQueue and #m.toastQueue > 0 then
      m.toastAchievement = table.remove(m.toastQueue, 1)
      m.toastAnim = 0
   else
      m.toasting = false
      av.restoreUserSettings()
      av.destroy()
   end
end

function av.toast(achievementId, gameData, assetPath)
   if not m then
      av.initialize(gameData, assetPath or "achievements/viewer")
   end
   if m.launched then
      print("achievement_viewer: can't run toast() while launch() is active")
      return
   end
   if m and m.toasting then
      table.insert(m.toastQueue, achievementId)
      return
   end
   
   av.backupUserSettings()

   m.toasting = true
   m.toastAnim = 0
   m.toastAchievement = achievementId
   m.toastRefreshRate = playdate.display.getRefreshRate() or 30
   if m.toastRefreshRate == 0 then m.toastRefreshRate = 30 end

   playdate.update = updateToast
end

achievementsViewer = {
   initialize = av.initialize,
   launch = av.launch,
   toast = av.toast
}
