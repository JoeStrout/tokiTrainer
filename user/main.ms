// Toki Pona / Typing Tutor Fusion!

import "listUtil"
import "mathUtil"

cd

crateImg = file.loadImage("/sys/pics/Block.png")
burstImg = file.loadImage("/sys/pics/Burst.png")

pona = "pona"
emoji = "emoji"
kanji = "kanji"
writingSystems = [pona, emoji, kanji]

blockSize = 108
floorY = 20

tpWords = []
engWords = []
for line in file.readLines("wordList.tsv")
	parts = line.split(char(9))
	tpWords.push parts[0]
	engWords.push parts[1]
end for

drawBlock = function(g, tpWord, system, left=0, bottom=0)
	g.drawImage crateImg, left, bottom, blockSize, blockSize
	idx = tpWords.indexOf(tpWord)
	if idx == null then 
		print "No such word: " + tpWord
		exit
	end if
	h = blockSize/2
	// draw the glyph
	glyph = file.loadImage(system + "/" + tpWord + ".png")
	g.drawImage glyph, left + h - glyph.width/2, 
	   bottom + h - glyph.height/2
	// draw the English keyword
	w = engWords[idx]
	g.print w, left + h - 8 * w.len/2, bottom + 9, color.black, "small"
	// draw the Toki Pona word
	g.print tpWord, left + h - 8 * tpWord.len/2, 
	   bottom + blockSize - 23, color.black, "small"
end function

compositeBuffer = new PixelDisplay
makeSpriteImage = function(tpWord, system, drawTP=false)
	compositeBuffer.clear color.clear, blockSize, blockSize
	drawBlock compositeBuffer, tpWord, system
	return compositeBuffer.getImage(0, 0, blockSize, blockSize)
end function

Block = new Sprite
Block.tpWord = ""
Block.landed = false
Block.bursting = false
Block.burstFrames = 0

Block.update = function
	if self.landed then return
	if self.bursting then
		self.burstFrames = self.burstFrames + 1
		if self.burstFrames > 5 then
			sd.sprites.removeVal self
		else
			t = self.burstFrames / 5
			self.scale = mathUtil.lerp(1, 1.5, t)
			self.tint = color.lerp(color.white, color.clear, t)
		end if
		return
	end if
	
	dy = -1
	if self.y + dy - blockSize/2 < floorY then
		self.y = floorY + blockSize/2
		self.landed = true
	else
		self.y = self.y + dy
	end if
end function

Block.burst = function()
	self.image = burstImg
	self.rotation = mathUtil.randRange(0, 360)
	self.bursting = true
	self.tpWord = ""
end function

Block.make = function()
	noob = new Block
	noob.tpWord = tpWords[:5].any
	noob.image = makeSpriteImage(noob.tpWord, writingSystems.any, true)
	noob.x = mathUtil.randRange(100, 860)
	noob.y = 640
	sd.sprites.push noob
	return noob
end function

clear

fallingBlocks = []
landedBlocks = []

sd = display(4)

entry = ""

shootDown = function(block)
	gunX = 480
	gunY = floorY + 20
	gfx.line gunX, gunY, block.x, block.y, color.yellow, 3
	yield
	block.burst
	gfx.line gunX, gunY, block.x, block.y, color.clear, 3
end function

fire = function
	for sp in sd.sprites
		if not sp.landed and sp.tpWord.upper == entry then
			shootDown sp
			return
		end if
	end for
	// ToDo: sound effect of mistyping
end function

handleKey = function
	k = key.get
	if k == " " or k == char(10) or k == char(3) then
		fire
		outer.entry = ""
	else if k == char(8) then  // backspace
		if entry then outer.entry = entry[:-1]
	else if entry.len < 20 then
		outer.entry = entry + k.upper
	end if
	text.delimiter = ""
	text.row = 0; text.column = 20; print " " * 35
	text.column = 34 - entry.len / 2
	text.print entry
	text.delimiter = char(13)
end function

// Main loop
nextNewBlockTime = 0
while true
	yield
	if time > nextNewBlockTime then
		Block.make
		nextNewBlockTime = time + mathUtil.randRange(1,4)
	end if
	for sp in sd.sprites
		sp.update
	end for
	if key.available then handleKey
end while

