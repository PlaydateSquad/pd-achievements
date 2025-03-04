-- Toast animation display module for the PlaydateSquad Achievements library.
if not (achievements and achievements.flag_is_playdatesquad_api) then
	error("Achievements 'graphics' module must be loaded after the base PlaydateSquad achievement library.")
end
import "CoreLibs/graphics"

local gfx <const> = playdate.graphics

---@diagnostic disable-next-line: lowercase-global
local toast_graphics = {
	iconWidth = 32,
	iconHeight = 32,
	toasts = {},
}
achievements.graphics = toast_graphics

local details = {
	-- NOTE: Please don't edit the auto-generated part below by hand (unless you really know what you're doing); use the 'embed_images' script(s) instead.
	-- #START AUTOGEN# --
	b64_default_icon = { pattern = "AcfAQQTAQRBA/DAA/////Dw/AAw///vPA8OCAyCCgiSJTRfPTRdMT8/589w4+888DH////f/fPvSs+yysuCyMScGRTRAQQQA/ea7PjPHABB/f++885gAgMSi4iCCACCCQQQAQQQAfDADBHf/AAw/Awwg+8OAA8PAACCCACCC/CA" },
	b64_default_locked = { pattern = "AcfAQQQBQTDA/DAA//vBAAw/AAAAgwwAA8OCACCCACSDQTTATTfPTDAAAAw/////wwwAA8ww88DCACCCACCCcSfPTTfPTTfP5zzDw73n573z8/z39/ww8cCCACCCACCCTTfPTTQAfDw/////AAw/A8ww88AAA8PAACCCACCC/CA" },
	b64_default_secret = { pattern = "AcfAQQQFQRHA/DAAAAAAwBw/AAgAgggDA8OCACiig6SBQRQAQQQATjBBADDHDf+9gxwAw4wwfsvCgCCCACCCgSRAQQQAQQRB/NOPBDDDAjh/f+wgwwgAg9CCACCCAiiCRTRFQQQAfDwBABBBAAw/AgDAAAAAA8PA4iiiACCC/CA" },
	-- #END AUTOGEN# --
	-- Additional variables may be added to details below/(around) if needed though, as long as the start/end lines and in-between aren't altered.
}

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

create_default_images()
