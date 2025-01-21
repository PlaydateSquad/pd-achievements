import "CoreLibs/graphics"

local gfx <const> = playdate.graphics

local FADE_AMOUNT <const> = 0.5
local FADE_FRAMES <const> = 16

local SCREEN_WIDTH <const> = playdate.display.getWidth()
local SCREEN_HEIGHT <const> = playdate.display.getHeight()

local CARD_CORNER <const> = 6
local CARD_WIDTH <const> = 300
local CARD_HEIGHT <const> = 70
local CARD_OUTLINE <const> = 2
local CARD_SPACING <const> = 10
local CARD_SPACING_ANIM <const> = SCREEN_HEIGHT - CARD_HEIGHT

local TITLE_WIDTH <const> = CARD_WIDTH
local TITLE_HEIGHT <const> = CARD_HEIGHT

local ANIM_FRAMES <const> = 24
local ANIM_EASING_IN = playdate.easingFunctions.outCubic
local ANIM_EASING_OUT = playdate.easingFunctions.inCubic

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

   m.cardBasePos = { 0, 0 }
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

   m.icons = {}
   m.cardPos = { }
   for i = 1,#m.gameData.achievements do
      local data = m.gameData.achievements[i]
      local id = data.id
      m.icons[id] = {}
      m.icons[id].locked = av.loadFile(gfx.image.new, data.iconLocked or data.icon_locked)
      m.icons[id].granted = av.loadFile(gfx.image.new, data.icon)
   
      m.cardPos[i] = { SCREEN_WIDTH / 2 - CARD_WIDTH / 2,
		       (i-1) * (CARD_HEIGHT + CARD_SPACING) }
   end
   playdate.inputHandlers.push({}, true)
end

function av.destroy()
   playdate.display.setRefreshRate(m.backupRefreshRate)
   playdate.inputHandlers.pop()
   playdate.update = m.backupPlaydateUpdate
   m = nil
end
   
function av.drawTitle(x, y, width, height)
   if not m.titleImageCache then
      
   end
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
      
      gfx.popContext()
   end
   m.cardImageCache[achievementId]:draw(x, y)
end

function av.drawCards()
   local x = m.cardBasePos[1]
   local y = m.cardBasePos[2]
   local extraSpacing = m.cardSpacing
   for i = 1,#m.cardPos do
      if y + CARD_HEIGHT > 0 and y < SCREEN_HEIGHT then
	 local id = m.gameData.achievements[i].id  -- later on allow sorting
	 av.drawCard(id, x + m.cardPos[i][1], y + m.cardPos[i][2] + (i-1)*extraSpacing, CARD_WIDTH, CARD_HEIGHT)
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
      m.cardBasePos = { 0, SCREEN_HEIGHT - SCREEN_HEIGHT * (animFrame / ANIM_FRAMES) }
      m.animFrame = m.animFrame + 1
   else
      m.cardBasePos = { 0, 0 }
   end
   m.cardSpacing = CARD_SPACING_ANIM - CARD_SPACING_ANIM * (animFrame / ANIM_FRAMES)
   av.drawCards()

   if m.fadeAmount >= FADE_AMOUNT and m.animFrame > ANIM_FRAMES then
      m.cardSpacing = 0
      m.cardBasePos = { 0, 0 }
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
   m.cardBasePos = { 0, SCREEN_HEIGHT * (animFrame / ANIM_FRAMES) }
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

   if playdate.buttonJustPressed(playdate.kButtonB) then
      av.beginExit()
   end
end


function av.beginExit()
   m.animFrame = 0
   m.fadeAmount = 0
   playdate.update = av.animateOutUpdate   
   m.exitSound:play()
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
