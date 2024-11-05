-- Toast animation display module for the PlaydateSquad Achievements library.
if not (achievements and achievements.flag_is_playdatesquad_api) then
	error("Achievements 'graphics' module must be loaded after the base PlaydateSquad achievement library.")
end
import "CoreLibs/graphics"

local gfx <const> = playdate.graphics

---@diagnostic disable-next-line: lowercase-global
local toast_graphics = {
	displayGrantedMilliseconds = 2000,
	displayGrantedDefaultX = 20,
	displayGrantedDefaultY = 0,
	displayGrantedDelayNext = 400,
	iconWidth = 32,
	iconHeight = 32,
}
achievements.graphics = toast_graphics

local function set_rounded_mask(img, width, height, round)
	gfx.pushContext(img:getMaskImage())
	gfx.clear(gfx.kColorBlack)
	gfx.setColor(gfx.kColorWhite)
	gfx.fillRoundRect(0, 0, width, height, round)
	gfx.popContext()
end

-- make 'defaults' start with a *, so they can't show up in the file system, so any file-name the user can choose is valid
-- since lua's variable naming is more restrictive than the file-systems, we need to set them as strings
local path_to_image_data = {
	["*_default_icon"] = gfx.image.new("achievements/graphics/achievement-unlock"),
	["*_default_locked"] = gfx.imagetable.new("achievements/graphics/achievement-lock"):getImage(1),
}
function toast_graphics.get_image(path)
	if not path_to_image_data[path] then
		local img, err = gfx.image.new(path)
		if not img then
			error(("image '%s' could not be loaded: "):format(path) .. err)
		else
			path_to_image_data[path] = img
		end
	end
	return path_to_image_data[path]
end

--[[ Achievement Drawing & Animation ]]--

local function resolve_achievement_or_id(achievement_or_id)
	if type(achievement_or_id) == "string" then
		return achievements.keyedAchievements[achievement_or_id]
	end
	return achievement_or_id
end

local function create_card(width, height, round, draw_func)
	local img = gfx.image.new(width, height)
	if draw_func ~= nil then
		gfx.pushContext(img)
		draw_func()
		gfx.popContext()
	end
	-- mask image, for rounded corners
	if round ~= nil and round > 0 then
		set_rounded_mask(img, width, height, round)
	end
	return img
end

local draw_card_cache = {} -- NOTE: don't forget to invalidate the cache on grant/revoke/progress!
local function draw_card_unsafe(ach, x, y, msec_since_granted)
	-- if not in cache yet, create the card for quick drawing later
	if draw_card_cache[ach.id] == nil then
		-- TODO: properly draw this, have someone with better art-experience look at it
		draw_card_cache[ach.id] = create_card(
			360,
			40,
			3,
			function()
				-- TODO?: 'achievement unlocked', progress, time, etc.??
				gfx.clear(gfx.kColorBlack)
				gfx.setImageDrawMode(gfx.kDrawModeCopy)
				gfx.setColor(gfx.kColorWhite)
				gfx.drawRoundRect(0, 0, 360, 40, 3, 3)
				-- TODO: either do these next 2 separately, or make the entire card into an animation
				local select_icon = ach.icon_locked or achievements.gameData.defaultIconLocked or "*_default_locked"
				if ach.granted_at then
					select_icon = ach.icon or achievements.gameData.defaultIcon or "*_default_icon"
				end
				toast_graphics.get_image(select_icon):draw(4, 4)
				toast_graphics.get_image(select_icon):draw(324, 4)
				gfx.setImageDrawMode(gfx.kDrawModeFillWhite)
				-- TODO: get our own font in here, so we don't use the font users have set outside of the lib
				gfx.drawTextInRect(ach.name, 40, 14, 292, 60, nil, "...", kTextAlignment.center)
			end
		)
	end

	-- animation
	if msec_since_granted ~= 0 then
		x = x + 7.0 * math.sin(msec_since_granted / 90.0)
		y = y + (msec_since_granted / 10.0)
	end

	-- draw to screen
	gfx.pushContext()
	gfx.setImageDrawMode(gfx.kDrawModeCopy)
	draw_card_cache[ach.id]:draw(x, y);
	gfx.popContext()

	return msec_since_granted <= toast_graphics.displayGrantedMilliseconds
end

toast_graphics.drawCard = function(achievement_or_id, x, y, msec_since_granted)
	local ach = resolve_achievement_or_id(achievement_or_id)
	if not ach then
		error("attempt to draw unconfigured achievement '" .. achievement_or_id .. "'", 2)
		return
	end
	if x == nil or y == nil then
		x = toast_graphics.displayGrantedDefaultX
		y = toast_graphics.displayGrantedDefaultY
	end
	if msec_since_granted == nil then
		msec_since_granted = 0
	end
	-- split into 'unsafe' function, so that can be called internally without all the checks above each time
	return draw_card_unsafe(ach, x, y, msec_since_granted)
end

local animate_coros = {}
local animate_queue = {}
local last_grant_display_msec = -toast_graphics.displayGrantedDelayNext
toast_graphics.updateVisuals = function ()
	if animate_queue[1] then
		-- Delay until it's time to start drawing.
		-- NOTE: use getCurrentTimeMilliseconds here (regardless of time granted), since that'll take into account game-pausing.
		if playdate.getCurrentTimeMilliseconds() > last_grant_display_msec + toast_graphics.displayGrantedDelayNext then
			local coro_func = animate_coros[animate_queue[1]]
			if not coroutine.resume(coro_func) then
				animate_coros[animate_queue[1]] = nil
				table.remove(animate_queue, 1)
				last_grant_display_msec = playdate.getCurrentTimeMilliseconds()
			end
		end
	end
end

local function start_granted_animation(ach, draw_card_func)
	draw_card_cache[ach.id] = nil
	local coro = coroutine.create(
		function ()
			local start_msec = playdate.getCurrentTimeMilliseconds()
			local current_msec = start_msec
			while draw_card_func(
				ach,
				toast_graphics.displayGrantedDefaultX,
				toast_graphics.displayGrantedDefaultY,
				current_msec - start_msec
			) do
				coroutine.yield()
				current_msec = playdate.getCurrentTimeMilliseconds()
			end
		end
	)
	-- tie display-coroutine to achievement-id, so that the system doesn't get confused by rapid grant/revoke
	-- also nsure there's only one instance of achievement-id in the queue.
	if animate_coros[ach.id] then
		for i, v in ipairs(animate_queue) do
			if v == ach.id then
				table.remove(animate_queue, i)
				break
			end
		end
	end
	animate_coros[ach.id] = coro
	table.insert(animate_queue, ach.id)
end

--[[ Achievement Management Functions ]]--

-- Yes, this is now decorating the base functions in-place.
-- This is by far the easier option to understand.

local original_grant = achievements.grant
local original_revoke = achievements.revoke

achievements.grant = function(achievement_id, draw_card_func)
	local result = original_grant(achievement_id)
	if result then
		local ach = achievements.keyedAchievements[achievement_id]
		if draw_card_func == nil then
			draw_card_func = draw_card_unsafe
		end
		start_granted_animation(ach, draw_card_func)
	end
	return result
end

achievements.revoke = function(achievement_id)
	local result = original_revoke(achievement_id)
	if result then
		draw_card_cache[achievement_id] = nil
	end
	return result
end
