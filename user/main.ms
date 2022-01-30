// Toki Pona / Typing Tutor Fusion!

import "listUtil"
import "mathUtil"
import "turret"
import "title"

if not globals.hasIndex("options") then
	options = {}
	options.level = 1
	options.writing = ["pona", "emoji", "kanji"]
end if

score = 0

cd

crateImg = file.loadImage("/sys/pics/Block.png")
burstImg = file.loadImage("/sys/pics/Burst.png")

hitSound = file.loadSound("/sys/sounds/pew.wav")
popSound = file.loadSound("/sys/sounds/pop.wav")
missSound = file.loadSound("/sys/sounds/swoosh.wav")
keySound = file.loadSound("/sys/sounds/hihat.wav")
backspaceSound = file.loadSound("/sys/sounds/hihat2.wav")
lossSound = file.loadSound("/sys/sounds/airburst.wav")

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
			checkLevelOver
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
		checkGameOver
	else
		self.y = self.y + dy
	end if
end function

Block.burst = function()
	self.image = burstImg
	self.rotation = mathUtil.randRange(0, 360)
	self.bursting = true
	self.tpWord = ""
	popSound.play
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
	if rnd < 0.5 then
		noob.x = mathUtil.randRange(100, 380)
	else
		noob.x = mathUtil.randRange(570, 860)
	end if
	noob.y = 640
	sd.sprites.push noob
	return noob
end function

sd = display(4)

checkLevelOver = function()
	// check for level-over
	if wordsLeft then return
	for sp in sd.sprites
		if sp isa Block then return
	end for
	endLevel
end function

checkGameOver = function()
	count = 0
	for sp in sd.sprites
		if sp isa Block and sp.landed then count = count + 1
	end for
	if count > 2 then
		outer.gameOver = true
		printCentered "GAME OVER", 15
		printCentered "Your Score:", 13
		printCentered ("000000" + score)[-6:], 12
	end if
end function

shootDown = function(block)
	hitSound.play 1, 0, mathUtil.randRange(0.8, 1.2)
	turret.aimAt block
	ang = turret.barrel.rotation * pi/180
	gunX = turret.barrel.x + 54 * cos(ang)
	gunY = turret.barrel.y + 54 * sin(ang)
	display(2).line gunX, gunY, block.x, block.y, color.yellow, 4
	yield
	block.burst
	display(2).line gunX, gunY, block.x, block.y, color.clear, 5
	globals.score = score + round(block.y/5)
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
	missSound.play 1, 0, mathUtil.randRange(0.8, 1.2)
end function

printCentered = function(s, row, color="#CCCCCC")
	text.delimiter = ""
	text.row = row; text.column = 0; print " " * 68
	if s then
		text.row = row; text.column = 34 - s.len/2
		text.color = color; print s
	end if
	text.delimiter = char(13)
end function

handleKey = function
	k = key.get
	if k == " " or k == char(10) or k == char(3) then
		fire
		outer.entry = ""
	else if k == char(8) then  // backspace
		if entry then outer.entry = entry[:-1]
		backspaceSound.play 0.5, 0, mathUtil.randRange(0.9, 1.0)
	else if entry.len < 20 then
		outer.entry = entry + k.upper
		keySound.play 0.5, 0, mathUtil.randRange(0.9, 1.0)
	end if
	printCentered entry, 6, "#FFFF88"
end function

endLevel = function()
	text.clear
	printCentered "LEVEL " + options.level + " COMPLETE!", 15
	wait 3
	text.clear
	outer.levelDone = true
end function

startLevel = function()
	outer.levelDone = false
	outer.gameOver = false
	
	// Remove all blocks from the screen
	for i in range(sd.sprites.len-1)
		if sd.sprites[i] isa Block then sd.sprites.remove i
	end for
	
	// Prepare the new word list
	outer.wordsLeft = getWordsForLevel(options.level)
	outer.labelsToShow = {}
	for w in wordsLeft[:25]; labelsToShow.push w; end for
	
	// Show the level info
	printCentered "LEVEL " + options.level, 20, color.yellow
	g = display(2)
	for i in range(0,4)  // including new words
		img = makeSpriteImage(wordsLeft[i*3], options.writing.any, true)
		g.drawImage img, 480 + (i-2) * 100 - img.width/2, 350
	end for
	if options.level > 1 then
		sc = 0.75  // scale factor
		for i in range(0,4)  // and last-round words
			img = makeSpriteImage(wordsLeft[15+i*2], options.writing.any, true)
			g.drawImage img, 
			480 + (i-2) * 100*sc - img.width*sc/2, 250,
			img.width*sc, img.height*sc			
		end for
	end if
	
	turret.showLevel options.level
	turret.showWordsLeft wordsLeft.len
	turret.showScore score
	
	wait
	printCentered "Press Spacebar to continue", 6, color.silver
	while true
		if key.get == " " then break
	end while
	
	wordsLeft.shuffle	
	
	text.clear
	g.clear color.clear
	turret.showLevel options.level
	turret.showWordsLeft wordsLeft.len
	turret.showScore score
end function

gameLoop = function()
	nextNewBlockTime = 0
	minDelay = 0.2
	maxDelay = 4
	totalWordCount = wordsLeft.len
	while not levelDone and not gameOver
		yield
		background.update
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
end function

// Main loop
clear
import "background"

fallingBlocks = []
landedBlocks = []
entry = ""

startingLevel = 1
while true
	score = 0
	options.level = startingLevel
	title.doTitle
	startingLevel = options.level
	turret.initialize
	while true
		startLevel
		gameLoop
		if gameOver then break
		options.level = options.level + 1
	end while
	key.clear; key.get
end while

