try:
	from PIL import Image
except Exception as ex:
	print(f"original exception message: {str(ex)}")
	print()
	print("You need to have the PIL/Pillow (image handling) module installed in python. You can do so by `python -m pip install Pillow`.")
	print("If you have, but still get this message, see the original error message printed above.")
	exit(1)
import argparse
from os import path


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


def embedImagesToFile(variable_to_image_table: dict[str, str], lua_filename: str) -> None:
	b64_per_variable = {}
	for variable, image_filename in variable_to_image_table.items():
		imgbytes = []
		try:
			with Image.open(image_filename, "r") as original_img:
				img = original_img.convert("L")
				for y in range(0, img.height, _PATTERN_DIM):
					for x in range(0, img.width, _PATTERN_DIM):
						pattbytes = _getPattern(img, x, y, _PATTERN_DIM, _PATTERN_DIM)
						imgbytes += pattbytes
		except Exception as ex:
			print(f"Can't open or read image from {image_filename}, because '{str(ex)}'.")
			exit(1)
		b64_per_variable[variable] = _bytesToB64(imgbytes)
	writes=[]
	try:
		with open(lua_filename, "r") as code:
			reads = code.readlines()
			stage = 0
			for line in reads:
				if _START_AUTOGEN_TEXT in line:
					stage = 1
				if stage == 0:
					writes.append(line)
				elif stage == 1:
					writes.append(f"\t-- {_START_AUTOGEN_TEXT} --\n")
					for variable, b64 in b64_per_variable.items():
						writes.append(f'\t{variable} = "{b64}",\n')
					writes.append(f"\t-- {_END_AUTOGEN_TEXT} --\n")
					stage = 2
				elif stage == 2:
					if _END_AUTOGEN_TEXT in line:
						stage = 0
	except Exception as ex:
		print(f"Can't open or read code from {toast_lua_filename}, because '{str(ex)}'.")
		exit(1)
	try:
		with open(lua_filename, "w") as code:
			code.writelines(writes)
	except Exception as ex:
		print(f"Can't open or write code to {toast_lua_filename}, because '{str(ex)}'.")
		exit(1)


if __name__ == "__main__":
	# Parse args:
	parser = argparse.ArgumentParser(
                    prog="embed_images",
                    description="""Takes 32x32 pixel images (png-format) and (after converting to 1-bit)
						embeds them into lua code between start- and end-markers,
						as a list of comma separated lines of string assignments to variables.""",
                    epilog="""Used for the communvity achievement library for the Panic! Playdate handheld.\n
						This code isn't made or endorsed by Panic!\nUse at your own risk.""")
	parser.add_argument("-f", "--image-file", nargs=2, action="append", type=str, required = True, metavar=("FILENAME", "VARIABLE-NAME"))
	parser.add_argument("-e", "--embed-into", action="store", type=str, required = True, metavar="FILENAME")
	args = parser.parse_args()
	varname_to_imagefile = {}
	try:
		for input_info in args.image_file:
			if len(input_info) < 2:
				input_info.append(path.basename(input_info[0]).split(".")[0])
				print(f"WARNING: No variable-name specified for {input_info[0]}, attempt to fetch from filename (= '{input_info[1]}').")
			varname_to_imagefile[input_info[1]] = input_info[0]
	except Exception as _:
		parser.print_usage()
		exit(1)

	# Action!:
	embedImagesToFile(varname_to_imagefile, args.embed_into)
