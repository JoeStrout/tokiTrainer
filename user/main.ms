// Toki Pona / Typing Tutor Fusion!

import "listUtil"
import "mathUtil"
import "turret"

if not globals.hasIndex("options") then
	options = {}
	options.level = 1
	options.writing = ["pona", "emoji", "kanji"]
end if

score = 0

cd

crateImg = file.loadImage("/sys/pics/Block.png")
burstImg = file.loadImage("/sys/pics/Burst.png")

pona = "pona"
emoji = "emoji"
kanji = "kanji"

blockSize = 108
floorY = 0

tpWords = []
tpToKeyword = {}
for line in file.readLines("wordList.tsv")
	parts = line.split(char(9))
	if parts[1] == "Keyword" then continue // (header line)
	tpWords.push parts[0]
	tpToKeyword[parts[0]] = parts[1]
end for

getWordsForLevel = function(level=1)
	result = []
	endIdx = level * 5 - 1
	// Most recent words, 3 times each
	for i in range(endIdx-4, endIdx)
		result.push tpWords[i]
		result.push tpWords[i]
		result.push tpWords[i]
	end for
	// 5 words before that, 2 times each
	if endIdx-9 >= 0 then
		for i in range(endIdx-9, endIdx-5)
			result.push tpWords[i]
			result.push tpWords[i]
		end for
	end if
	// 5 words before that, once each
	if endIdx-14 >= 0 then
		for i in range(endIdx-14, endIdx-10)
			result.push tpWords[i]
		end for
	end if
	// And finally, 20 randomly chosen words.
	for i in range(19)
		result.push tpWords[rnd * (endIdx + 1)]
	end for
	return result
end function

drawBlock = function(g, tpWord, system, drawTp=true, left=0, bottom=0)
	g.drawImage crateImg, left, bottom, blockSize, blockSize
	if not tpToKeyword.hasIndex(tpWord) then
		print "No such word: " + tpWord
		exit
	end if
	h = blockSize/2
	
	// draw the glyph
	glyph = file.loadImage(system + "/" + tpWord + ".png")
	if glyph == null then
		print "Couldn't find glyph for: " + tpWord
	else
		g.drawImage glyph, left + h - glyph.width/2, 
		bottom + h - glyph.height/2
	end if
	
	// draw the English keyword
	w = tpToKeyword[tpWord]
	g.print w, left + h - 8 * w.len/2, bottom + 9, color.black, "small"
	
	if drawTp then
		// draw the Toki Pona word
		g.print tpWord, left + h - 8 * tpWord.len/2, 
		bottom + blockSize - 23, color.black, "small"
	end if
end function

compositeBuffer = new PixelDisplay
makeSpriteImage = function(tpWord, system, drawTp=false)
	compositeBuffer.clear color.clear, blockSize, blockSize
	drawBlock compositeBuffer, tpWord, system , drawTp
	return compositeBuffer.getImage(0, 0, blockSize, blockSize)
end function

Block = new Sprite
Block.tpWord = ""
Block.system = "pona"
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
		self.image = makeSpriteImage(self.tpWord, self.system, true)
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
	if not wordsLeft then return null
	noob = new Block
	noob.tpWord = wordsLeft.pop
	noob.system = options.writing.any
	showLabel = false
	if labelsToShow.hasIndex(noob.tpWord) then
		showLabel = true
		labelsToShow.remove noob.tpWord
	end if
	noob.image = makeSpriteImage(noob.tpWord, noob.system, showLabel)
	noob.x = mathUtil.randRange(100, 860)
	noob.y = 640
	sd.sprites.push noob
	return noob
end function

clear
turret.initialize

fallingBlocks = []
landedBlocks = []

sd = display(4)

entry = ""

shootDown = function(block)
	turret.aimAt block
	gunX = turret.barrel.x
	gunY = turret.barrel.y
	gfx.line gunX, gunY, block.x, block.y, color.yellow, 3
	yield
	block.burst
	gfx.line gunX, gunY, block.x, block.y, color.clear, 3
	globals.score = score + block.y
	turret.showScore score
end function

fire = function
	for sp in sd.sprites
		if not sp isa Block then continue
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
	text.row = 6; text.column = 20; print " " * 35
	text.column = 34 - entry.len / 2
	text.print entry
	text.delimiter = char(13)
end function

// Prepare the level
nextNewBlockTime = 0
wordsLeft = getWordsForLevel(options.level)
labelsToShow = {}
for w in wordsLeft[:25]; labelsToShow.push w; end for
wordsLeft.shuffle
minDelay = 0.2
maxDelay = 4
totalWordCount = wordsLeft.len
turret.showLevel options.level
turret.showWordsLeft wordsLeft.len
turret.showScore score

// Main loop
while true
	yield
	if time > nextNewBlockTime and wordsLeft then
		Block.make
		turret.showWordsLeft wordsLeft.len
		delay = mathUtil.lerp(minDelay, maxDelay, wordsLeft.len / totalWordCount)
		nextNewBlockTime = time + delay * mathUtil.randRange(0.8, 1.2)
	end if
	for sp in sd.sprites
		sp.update
	end for
	if key.available then handleKey
end while

