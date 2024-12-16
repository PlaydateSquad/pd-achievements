try:
	from PIL import Image
except Exception as ex:
	print(f"original exception message: {str(ex)}", file=sys.stderr)
	print(file=sys.stderr)
	print("You need to have the PIL/Pillow (image handling) module installed in python.", file=sys.stderr)
	print("You can do so on most systems by `python -m pip install Pillow`.", file=sys.stderr)
	print("If you have, but still get this message, see the original error message printed above.", file=sys.stderr)
	exit(1)
import argparse
from os import path
import sys


_BASE64 = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
_PATTERN_DIM = 8
_START_AUTOGEN_TEXT = "#START AUTOGEN#"
_END_AUTOGEN_TEXT = "#END AUTOGEN#"


def _bytesToB64(bytelist: list[int]) -> str:	
	result = []
	bitcount = 0
	leftover = 0
	for byt in bytelist:
		bitcount = bitcount + 8
		nmod6 = ((bitcount - 1) % 6) + 1
		bitmask_a = (1 << nmod6) - 1
		bitmask_b = 0xFF - bitmask_a
		val_6bits = ((byt & bitmask_b) >> 2) + leftover
		leftover = (byt & bitmask_a)
		result.append(_BASE64[val_6bits])
		if bitcount % 24 == 0:
			result.append(_BASE64[leftover])
			leftover = 0
	if bitcount % 24 != 0:
		result.append(_BASE64[leftover])
	return "".join(result)


def _getPattern(img: Image, sx: int, sy: int, wx: int, wy: int) -> list[int]:
	bytelist = []
	bit=0
	nextbyte=0
	for y in range(sy, sy + wy):
		for x in range(sx + wx - 1, sx - 1, -1):
			bwpixel = 1 if img.getpixel((x,y)) >= 127 else 0
			nextbyte += bwpixel << bit
			bit+=1
			if bit >= 8:
				bit = 0
				bytelist.append(nextbyte)
				nextbyte = 0
	return bytelist


def _getAlphaImage(img: Image) -> Image:
	# Returns the alpha-channel of the image as as separate greyscale image, if there's any translucent pixels.
	if any([(band in "AP") for band in img.getbands()]):
		img.apply_transparency()
		res = img.convert("RGBA").getchannel("A")
		return res if any([c[1] < 0xFF for c in res.getcolors()]) else None


def _convertToBase64(variable_to_image_table: dict[str, str]) -> (dict[str, str], dict[str, str]):
	b64_per_variable = {}
	opacity_b64_per_variable = {}
	for variable, image_filename in variable_to_image_table.items():
		imgbytes = []
		alphabytes = []
		try:
			with Image.open(image_filename, "r") as original_img:
				img = original_img.convert("L")
				alpha_img = _getAlphaImage(original_img)
				for y in range(0, img.height, _PATTERN_DIM):
					for x in range(0, img.width, _PATTERN_DIM):
						imgbytes += _getPattern(img, x, y, _PATTERN_DIM, _PATTERN_DIM)
						if alpha_img != None:
							alphabytes += _getPattern(alpha_img, x, y, _PATTERN_DIM, _PATTERN_DIM)
		except Exception as ex:
			print(f"Can't open or read image from {image_filename}, because '{str(ex)}'.", file=sys.stderr)
			exit(1)
		b64_per_variable[variable] = _bytesToB64(imgbytes)
		if len(alphabytes) > 0:
			opacity_b64_per_variable[variable] = _bytesToB64(alphabytes)
	return b64_per_variable, opacity_b64_per_variable


def _embedBase64StringsToFile(b64_per_var: dict[str, str], opacity_b64_per_var: dict[str, str], lua_file: str) -> None:
	writes=[]
	try:
		with open(lua_file, "r") as code:
			reads = code.readlines()
			stage = 0
			for line in reads:
				if _START_AUTOGEN_TEXT in line:
					stage = 1
				if stage == 0:
					writes.append(line)
				elif stage == 1:
					writes.append(f"\t-- {_START_AUTOGEN_TEXT} --\n")
					for var, b64 in b64_per_var.items():
						alpha_b64_str = ("" if var not in opacity_b64_per_var
							else f',\n\t\talpha = "{opacity_b64_per_var[var]}"')
						writes.append(f'\t{var} = {{ pattern = "{b64}"{alpha_b64_str} }},\n')
					writes.append(f"\t-- {_END_AUTOGEN_TEXT} --\n")
					stage = 2
				elif stage == 2:
					if _END_AUTOGEN_TEXT in line:
						stage = 0
	except Exception as ex:
		print(f"Can't open or read code from {lua_file}, because '{str(ex)}'.", file=sys.stderr)
		exit(1)
	try:
		with open(lua_file, "w") as code:
			code.writelines(writes)
	except Exception as ex:
		print(f"Can't open or write code to {lua_file}, because '{str(ex)}'.", file=sys.stderr)
		exit(1)


if __name__ == "__main__":
	# Argument parser:
	parser = argparse.ArgumentParser(
                    prog="embed_images",
                    description=f"""Takes 32x32 pixel images (png-format) and (after converting to 1-bit) embeds them
						within a lua table as lines (`\\t<variable name> = "<base-64 string>",\\n`). The insertion is
						done between lines that contain these: start- and end-markers: `{_START_AUTOGEN_TEXT}`
						`{_END_AUTOGEN_TEXT}`. Repeat the image file argument (`-f ...` or `--image-file ...`) for
						multiple image/variable pairs. (Old values will be overwritten, so using multiple arguments is
						the only way to put more than one in.) Prints to stdout if `-e` or `--embed-into` isn't given.
						""",
                    epilog="""Used for the community achievement library for the Panic! Playdate handheld.\n
						This code isn't made or endorsed by Panic!\nUse at your own risk.""")
	parser.add_argument("-f", "--image-file", nargs=2, action="append", type=str, required = True,
		metavar=("<image filename>", "<lua-table variable-name>"))
	parser.add_argument("-e", "--embed-into", action="store", type=str, metavar="<lua filename>")
	args = parser.parse_args()

	# Parse image-file/variable pairs:
	varname_to_imagefile = {}
	try:
		for input_info in args.image_file:
			if len(input_info) < 2:
				input_info.append(path.basename(input_info[0]).split(".")[0])
			varname_to_imagefile[input_info[1]] = input_info[0]
	except Exception as _:
		parser.print_usage()
		exit(1)

	# Action!:
	b64_per_variable, opacity_b64_per_variable = _convertToBase64(varname_to_imagefile)
	if args.embed_into != None:
		_embedBase64StringsToFile(b64_per_variable, opacity_b64_per_variable, args.embed_into)
	else:
		for variable, b64 in b64_per_variable.items():
			print(f'{variable}.pattern  =  "{b64}"')
		for variable, b64 in opacity_b64_per_variable.items():
			print(f'{variable}.alpha    =  "{b64}"')
