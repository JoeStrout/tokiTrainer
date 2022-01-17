for line in file.readLines("emoji.txt")
	fields = line.split(char(9))
	if not fields then continue
	if fields[0] <= "nanpa" then continue
	unicode = fields[2].split(",")[0].upper
	print fields[0] + " is unicode " + unicode
	url = "https://openmoji.org/php/download_asset.php?" +
	"type=emoji&emoji_hexcode=" + unicode +
	"&emoji_variant=color"
	data = http.get(url)
	if not data then
		print "Couldn't get data at:"
		print url
		break
	end if
	file.saveRaw "emoji/" + fields[0] + ".png", data
end for