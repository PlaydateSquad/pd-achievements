import "CoreLibs/graphics"

local gfx <const> = playdate.graphics

local FADE_AMOUNT <const> = 0.5
local FADE_FRAMES <const> = 16

local SCREEN_WIDTH <const> = playdate.display.getWidth()
local SCREEN_HEIGHT <const> = playdate.display.getHeight()

local CARD_CORNER <const> = 6
local CARD_WIDTH <const> = 300
local CARD_HEIGHT <const> = 80
local CARD_OUTLINE <const> = 2
local CARD_SPACING <const> = 10
local CARD_SPACING_ANIM <const> = SCREEN_HEIGHT - CARD_HEIGHT

-- layout of inside the card
local LAYOUT_MARGIN <const> = 6
local LAYOUT_SPACING <const> = 6
local LAYOUT_ICON_SIZE <const> = 32

local CHECKBOX_SIZE <const> = 15

local TITLE_CORNER <const> = 6
local TITLE_WIDTH <const> = CARD_WIDTH
local TITLE_HEIGHT <const> = math.floor(.75 * CARD_HEIGHT)
local TITLE_SPACING <const> = CARD_SPACING

local ANIM_FRAMES <const> = 24
local ANIM_EASING_IN = playdate.easingFunctions.outCubic
local ANIM_EASING_OUT = playdate.easingFunctions.inCubic

local SCROLL_EASING = playdate.easingFunctions.inQuad
local SCROLL_ACCEL <const> = 1
local SCROLL_ACCEL_DOWN <const> = 2
local SCROLL_SPEED <const> = 14


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
   m.backupPlaydateUpdate = playdate.update
   m.backdropImage = gfx.getDisplayImage()
   m.backupRefreshRate = playdate.display.getRefreshRate()
   playdate.display.setRefreshRate(50)

   m.fadeAmount = 0
   m.animFrame = 0

   m.gameData = gameData or achievements.gameData
   gameData = m.gameData

   m.cardBasePos = { x = 0, y = 0 }
   m.cardSpacing = 10
   m.cardImageCache = {}

   m.defaultIcon = av.loadFile(gfx.image.new, gameData.defaultIcon or gameData.default_icon)
   m.defaultIconLocked = av.loadFile(gfx.image.new, gameData.defaultIconLocked or gameData.default_icon_locked)
   m.secretIcon = av.loadFile(gfx.image.new, gameData.secretIcon or gameData.secret_icon)

   m.assetPath = assetPath

   m.fonts = {}
   m.fonts.title = av.loadFile(gfx.font.new, assetPath .. "/Roobert-20-Medium")

   m.fonts.name = {}
   m.fonts.name.locked = av.loadFile(gfx.font.new, assetPath .. "/Roobert-11-Medium")
   m.fonts.name.granted = av.loadFile(gfx.font.new, assetPath .. "/Roobert-11-Bold")
   m.fonts.description = {}
   m.fonts.description.locked = av.loadFile(gfx.font.new, assetPath .. "/Nontendo-Light")
   m.fonts.description.granted = av.loadFile(gfx.font.new, assetPath .. "/Nontendo-Bold")
   m.fonts.status = av.loadFile(gfx.font.new, assetPath .. "/font-Bitmore")

   m.checkBox = {}
   m.checkBox.locked = av.loadFile(gfx.image.new, assetPath .. "/check_box")
   m.checkBox.granted = av.loadFile(gfx.image.new, assetPath .. "/check_box_checked")
   m.checkBox.secret = av.loadFile(gfx.image.new, assetPath .. "/check_box_secret")

   m.launchSound = av.loadFile(playdate.sound.sampleplayer.new, assetPath .. "/launchSound")
   m.exitSound = av.loadFile(playdate.sound.sampleplayer.new, assetPath .. "/exitSound")
   --m.scrollSound = av.loadFile(playdate.sound.sampleplayer.new, assetPath .. "/scrollSound")
   --m.sortSound = av.loadFile(playdate.sound.sampleplayer.new, assetPath .. "/sortSound")

   m.scroll = 0
   m.scrollSpeed = 0

   m.icons = { }
   m.title = { x = SCREEN_WIDTH/2 - TITLE_WIDTH/2, y = 0 }
   m.card = { }
   m.achievementData = {}
   m.additionalAchievementData = {}
   for i = 1,#m.gameData.achievements do
      local data = m.gameData.achievements[i]
      local id = data.id
      m.achievementData[id] = data
      m.additionalAchievementData[id] = {}
      
      m.icons[id] = {}
      m.icons[id].locked = av.loadFile(gfx.image.new, data.iconLocked or data.icon_locked)
      m.icons[id].granted = av.loadFile(gfx.image.new, data.icon)
   
      m.card[i] = { x = SCREEN_WIDTH / 2 - CARD_WIDTH / 2,
		    y = TITLE_HEIGHT + TITLE_SPACING + (i-1) * (CARD_HEIGHT + CARD_SPACING),
		    hidden = false
      }
   end
   playdate.inputHandlers.push({}, true)
end

function av.destroy()
   playdate.display.setRefreshRate(m.backupRefreshRate)
   playdate.inputHandlers.pop()
   playdate.update = m.backupPlaydateUpdate
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

      gfx.popContext()
   end
   m.titleImageCache:draw(x, y)
end

function av.drawCard(achievementId, x, y, width, height)
   if not m.cardImageCache[achievementId] then
      local image = gfx.image.new(width, height)
      m.cardImageCache[achievementId] = image
      gfx.pushContext(image)
      local margin = 1
      
      gfx.setColor(gfx.kColorWhite)
      gfx.fillRoundRect(0, 0, width, height, CARD_CORNER)
      
      gfx.setStrokeLocation(gfx.kStrokeInside)
      gfx.setLineWidth(CARD_OUTLINE)
      gfx.setColor(gfx.kColorBlack)

      gfx.drawRoundRect(margin, margin, width-2*margin, height-2*margin, CARD_CORNER)
      
      local info = m.achievementData[achievementId]
      
      local font = info.granted and m.fonts.name.granted or m.fonts.name.locked
      gfx.setFont(font)
      local nameImg = gfx.imageWithText(info.name,
					width - 2*LAYOUT_MARGIN - LAYOUT_SPACING - LAYOUT_ICON_SIZE,
					height - 2*LAYOUT_MARGIN - LAYOUT_SPACING - CHECKBOX_SIZE)

      font = info.granted and m.fonts.description.granted or m.fonts.description.locked
      gfx.setFont(font)
      local heightRemaining = height - 2*LAYOUT_MARGIN - 2*LAYOUT_SPACING - nameImg.height - CHECKBOX_SIZE
      local descImage
      if heightRemaining >= font:getHeight() then
	 descImg = gfx.imageWithText(info.description,
				       width - 2*LAYOUT_MARGIN - LAYOUT_SPACING - LAYOUT_ICON_SIZE,
				       heightRemaining)
      end

      nameImg:draw(LAYOUT_MARGIN, LAYOUT_MARGIN)
      if descImg then
	 descImg:draw(LAYOUT_MARGIN, LAYOUT_MARGIN + nameImg.height + LAYOUT_SPACING)
      end
      
      if info.granted then
	 m.checkBox.granted:draw(LAYOUT_MARGIN, height - CHECKBOX_SIZE - LAYOUT_MARGIN)
      elseif info.secret then
	 m.checkBox.secret:draw(LAYOUT_MARGIN, height - CHECKBOX_SIZE - LAYOUT_MARGIN)
      else
	 m.checkBox.locked:draw(LAYOUT_MARGIN, height - CHECKBOX_SIZE - LAYOUT_MARGIN)
      end	 
	 
      
      gfx.popContext()
   end
   m.cardImageCache[achievementId]:draw(x, y)
end

function av.drawCards()
   local x = m.cardBasePos.x
   local y = m.cardBasePos.y - m.scroll
   local extraSpacing = m.cardSpacing

   local count = 0
   av.drawTitle(x + m.title.x, y + m.title.y)
   if y < SCREEN_HEIGHT then
      count = count + 1
   end

   for i = 1,#m.card do
      if not m.card[i].hidden then
	 count = count + 1
	 local cardY = y + m.card[i].y + count*extraSpacing
	 if cardY + CARD_HEIGHT > 0 and cardY < SCREEN_HEIGHT then
	    local id = m.gameData.achievements[i].id  -- later on allow sorting
	    av.drawCard(id, x + m.card[i].x, cardY, CARD_WIDTH, CARD_HEIGHT)
	    m.card[i].onScreen = true
	 else
	    m.card[i].onScreen = false
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


   local animFrame = ANIM_EASING_IN(m.animFrame, 0, ANIM_FRAMES, ANIM_FRAMES)
   if m.animFrame <= ANIM_FRAMES then
      m.cardBasePos = { x = 0, y = SCREEN_HEIGHT - SCREEN_HEIGHT * (animFrame / ANIM_FRAMES) }
      m.animFrame = m.animFrame + 1
   else
      m.cardBasePos = { x = 0, y = 0 }
   end
   m.cardSpacing = CARD_SPACING_ANIM - CARD_SPACING_ANIM * (animFrame / ANIM_FRAMES)
   av.drawCards()

   if m.fadeAmount >= FADE_AMOUNT and m.animFrame > ANIM_FRAMES then
      m.cardSpacing = 0
      m.cardBasePos = { x = 0, y = 0 }
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
   
   m.cardBasePos = { x = 0, y = SCREEN_HEIGHT * (animFrame / ANIM_FRAMES) }
   m.cardSpacing = CARD_SPACING_ANIM * (animFrame / ANIM_FRAMES)
   av.drawCards()
   if m.animFrame <= ANIM_FRAMES then
      m.animFrame = m.animFrame + 1
   end

   if m.fadeAmount >= FADE_AMOUNT and m.animFrame > ANIM_FRAMES then
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
   print(m.scroll, m.maxScroll)
   
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
      if not m.card[i].onScreen then
	 m.card[i].hidden = true
      end
   end
end


function av.launch(gameData, assetPath, userUpdate)
   if not m then
      av.initialize(gameData, assetPath or "achievements/viewer")
   end
   m.userUpdate = userUpdate or function() end
   playdate.update = av.animateInUpdate
   m.launchSound:play()
end

achievementsViewer = {
   initialize = av.initialize,
   launch = av.launch
}
