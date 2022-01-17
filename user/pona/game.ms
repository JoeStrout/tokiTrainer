emojiFolder = "emoji"
ponaFolder = "pona"

composeG = new PixelDisplay
blockImage = file.loadImage("/sys/pics/Block.png")
blockSize = 100

loadGlyph = function(tpWord, folder)
	path = folder + "/" + tpWord + ".png"
	print "Loading: " + path
	glyph = file.loadImage(path)
	print "Loaded: " + glyph
	composeG.clear color.clear, blockSize, blockSize
	composeG.drawImage blockImage, 0, 0, blockSize, blockSize
	composeG.drawImage glyph, 
	  blockSize/2-glyph.width/2, blockSize/2-glyph.height/2
	return composeG.getImage(0, 0, blockSize, blockSize)
end function


test = loadGlyph("akesi", emojiFolder)
view test
