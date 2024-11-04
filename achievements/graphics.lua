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
achievements.toast_graphics = toast_graphics

local details = {
	-- NOTE: Please don't edit the auto-generated part below by hand (unless you really know what you're doing); use the 'embed_images' script(s) instead.
	-- #START AUTOGEN# --
	b64_default_icon = { pattern = "AcfAQQTAQRBA/DAA/////Dw/AAw///vPA8OCAyCCgiSJTRfPTRdMT8/589w4+888DH////f/fPvSs+yysuCyMScGRTRAQQQA/ea7PjPHABB/f++885gAgMSi4iCCACCCQQQAQQQAfDADBHf/AAw/Awwg+8OAA8PAACCCACCC/CA" },
	b64_default_locked = { pattern = "AcfAQQQBQTDA/DAA//vBAAw/AAAAgwwAA8OCACCCACSDQTTATTfPTDAAAAw/////wwwAA8ww88DCACCCACCCcSfPTTfPTTfP5zzDw73n573z8/z39/ww8cCCACCCACCCTTfPTTQAfDw/////AAw/A8ww88AAA8PAACCCACCC/CA" },
	b64_default_secret = { pattern = "AcfAQQQFQRHA/DAAAAAAwBw/AAgAgggDA8OCACiig6SBQRQAQQQATjBBADDHDf+9gxwAw4wwfsvCgCCCACCCgSRAQQQAQQRB/NOPBDDDAjh/f+wgwwgAg9CCACCCAiiCRTRFQQQAfDwBABBBAAw/AgDAAAAAA8PA4iiiACCC/CA" },
	-- #END AUTOGEN# --
	-- Additional variables may be added to details below/(around) if needed though, as long as the start/end lines and in-between aren't altered.
}

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
	["*_default_icon"] = gfx.image.new(toast_graphics.iconWidth, toast_graphics.iconHeight),
	["*_default_locked"] = gfx.image.new(toast_graphics.iconWidth, toast_graphics.iconHeight),
	["*_default_secret"] = gfx.image.new(toast_graphics.iconWidth, toast_graphics.iconHeight),
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

local base64 <const> = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
local lookup_base64 = table.create(0, 65)
local lookup_base64_reverse = table.create(65, 0)
local i_b64 = 0
for ch in base64:gmatch(".") do
    lookup_base64[ch] = i_b64
	lookup_base64_reverse[i_b64] = ch
    i_b64 += 1
end

local function b64ToBytes(str_b64)
	local max_6bit <const> = 63
	local res_table = {}
	local bitcount = 0
	local part_a = 0
	local bitmask_a = max_6bit
	for ch in str_b64:gmatch(".") do
		-- parse and paste the next 6-bit value into the next byte(s)
		bitcount += 6
		local mod8 = bitcount % 8
		local part_b = part_a       -- b is the first one read
		part_a = lookup_base64[ch]  -- a is the current 'head'
		if part_a == nil then
			error("out-of-charset character '"..ch.."' in base-64 near position "..(bitcount//6))
			part_a = lookup_base64["A"]
		end
		local bitmask_b = max_6bit - bitmask_a
		bitmask_a = (1 << (6 - mod8)) - 1
		-- write the next byte, unless the last 6-bit value didn't fill up the current output-byte completely
		if mod8 ~= 6 then
			local next_byte = (part_a & bitmask_a) + ((part_b & bitmask_b) << 2)
			table.insert(res_table, string.pack("B", next_byte))
		end
	end
	return table.concat(res_table, "")
end

local function parse_and_draw_b64(str_b64)
	-- set some constants
	local pattern_dim <const> = 8

	-- get all bytes from the string in a format that can be iterated over
	local byte_str = b64ToBytes(str_b64)

	-- iterate over all bytes (draw an 8x8 block each time we've got enough)
	local start_x = 0
	local start_y = 0
	local pattern = {}
	for ch in byte_str:gmatch(".") do
		local byte = string.unpack("B", ch)
		table.insert(pattern, byte)
		if #pattern == pattern_dim then
			-- if the pattern-buffer is full then draw & empty it
			gfx.setPattern(pattern)
			gfx.fillRect(start_x, start_y, pattern_dim, pattern_dim)
			pattern = {}
			-- (re)set position
			start_x += pattern_dim
			if start_x >= toast_graphics.iconWidth then
				start_y += pattern_dim
				start_x = 0
			end
		end
	end
	gfx.setColor(gfx.kColorBlack)  -- unset pattern
end

local function create_default_image(path, icon_def)
	if icon_def.pattern == nil then
		error("please run the 'embed images' script to fill values for '"..path.."'")
		return
	end
	local icon_data = path_to_image_data[path]
	gfx.pushContext(icon_data)
	parse_and_draw_b64(icon_def.pattern)
	gfx.popContext()
	if icon_def.alpha ~= nil then
		gfx.pushContext(icon_data:getMaskImage())
		parse_and_draw_b64(icon_def.alpha)
		gfx.popContext()
	end
end

local function create_default_images()
	create_default_image("*_default_icon", details.b64_default_icon)
	create_default_image("*_default_locked", details.b64_default_locked)
	create_default_image("*_default_secret", details.b64_default_secret)
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
				local select_icon = ach.icon_locked or achievements.gameData.defaultIconLocked or "*_default_locked"
				if ach.granted_at then
					select_icon = ach.icon or achievements.gameData.defaultIcon or "*_default_icon"
				elseif ach.is_secret then
					-- NOTE: icon_locked instead of icon_secret isn't a typo, since if specified, it's the same
					select_icon = ach.icon_locked or achievements.gameData.secretIcon or "*_default_secret"
				end
				get_image(select_icon):draw(4, 4)
				get_image(select_icon):draw(324, 4)
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
toast_graphics.updateVisuals = function ()
	for achievement_id, coro_func in pairs(animate_coros) do
		if not coroutine.resume(coro_func) then
			animate_coros[achievement_id] = nil
		end
	end
end

local last_grant_display_msec = -toast_graphics.displayGrantedDelayNext
local function start_granted_animation(ach, draw_card_func)
	draw_card_cache[ach.id] = nil
	-- tie display-coroutine to achievement-id, so that the system doesn't get confused by rapid grant/revoke
	animate_coros[ach.id] = coroutine.create(
		function ()
			-- NOTE: use getCurrentTimeMilliseconds here (regardless of time granted), since that'll take into account game-pausing.
			local start_msec = 0
			repeat
				start_msec = playdate.getCurrentTimeMilliseconds()
				coroutine.yield()
			until start_msec > (last_grant_display_msec + toast_graphics.displayGrantedDelayNext)
			last_grant_display_msec = start_msec
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
end

--[[ Achievement Management Functions ]]--

-- Yes, this is now decorating the base functions in-place.
-- This is by far the easier option to understand.

local original_init = achievements.initialize
local original_grant = achievements.grant
local original_revoke = achievements.revoke

function achievements.initialize(gamedata, prevent_debug)
	original_init(gamedata, prevent_debug)
	create_default_images()
end

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
