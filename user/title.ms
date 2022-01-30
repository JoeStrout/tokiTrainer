import "chars"
import "textUtil"

optionsColor = "#CCCCFF"
optionsCol = 48
checkboxRow = 10
levelRow = 5

instColor = optionsColor
instRow = checkboxRow
instCol = 20

systems = ["pona", "emoji", "kanji"]
curSystemIdx = -1
nextBlockChangeTime = 0

isOn = function(system)
	return options.writing.contains(system)
end function

toggle = function(system)
	idx = options.writing.indexOf(system)
	if idx >= 0 then
		options.writing.remove idx
		if not options.writing then
			// gotta select *something*...
			other = systems.any
			while other == system; other = systems.any; end while			
			options.writing.push other
		end if
	else
		options.writing.push system
	end if
end function

drawBlocks = function
	outer.curSystemIdx = curSystemIdx + 1
	if curSystemIdx >= options.writing.len then
		outer.curSystemIdx = 0
	end if
	words = "toki pona jan sona".split
	system = options.writing[curSystemIdx]
	for i in words.indexes
		drawBlock display(2), words[i], system, true, 480+96*(i-2), 400
	end for
	outer.nextBlockChangeTime = time + 1
end function

drawLeftArrow = function
	text.row = levelRow; text.column = optionsCol
	print chars.inverseOn + chars.buttonCapLeft + chars.left +
	  " " + chars.inverseOff
end function

drawRightArrow = function
	text.row = levelRow; text.column = optionsCol + 7
	print chars.inverseOn + " " + chars.right + 
	  chars.buttonCapRight + chars.inverseOff
end function

drawOptions = function
	text.color = optionsColor
	text.row = checkboxRow + 2; text.column = optionsCol - 1
	print "GAME OPTIONS"
	display(2).line (optionsCol-1)*14, (checkboxRow+2)*24, 
	  (optionsCol+11)*14+7, (checkboxRow+2)*24, optionsColor, 2

	labels = ["Pona", "Emoji", "Kanji"]
	row = 10
	for i in range(0,2)
		if isOn(systems[i]) then s = chars.checkedBox else s = chars.emptyBox
		s = s + " " + labels[i]
		text.row = checkboxRow-i; text.column = optionsCol + 1
		print s
	end for
	
	text.row = levelRow+1; text.column = optionsCol - 1
	print "Start Level:"
	text.column = optionsCol
	print "    " + (" " + options.level)[-2:] + "    "
	drawLeftArrow
	drawRightArrow
end function

drawInstructions = function
	text.color = instColor
	row = instRow + 2
	textUtil.printCenteredAt instCol, row, "HOW TO PLAY"
	display(2).line (instCol-6)*14, (instRow+2)*24, 
	  (instCol+5)*14+7, (instRow+2)*24, instColor, 2
	print
	textUtil.printCenteredAt instCol, text.row, "Type the toni poka word for"
	textUtil.printCenteredAt instCol, text.row, "each block before it lands."
	textUtil.printCenteredAt instCol, text.row, "If three blocks land on one"
	textUtil.printCenteredAt instCol, text.row, "level, it's game over!"
	
	text.color = color.white
	textUtil.printCenteredAt instCol, 2, "Press spacebar to begin."
end function

waitForMouseUp = function
	while mouse.button; yield; end while
end function

handleClick = function
	col = textUtil.textCol(mouse.x); row = textUtil.textRow(mouse.y)
	if col < optionsCol or col > optionsCol + 10 then return waitForMouseUp
	if row <= checkboxRow and row >= checkboxRow-2 then
		toggle systems[checkboxRow - row]
		drawOptions
		waitForMouseUp
		drawBlocks
	else if row == levelRow then
		if col < optionsCol+5 then
			btnFunc = @drawLeftArrow
			minCol = optionsCol; maxCol = optionsCol+2
		else
			btnFunc = @drawRightArrow
			minCol = optionsCol+7; maxCol = optionsCol+9
		end if
		while mouse.button
			col = textUtil.textCol(mouse.x); row = textUtil.textRow(mouse.y)
			if row == levelRow and col >= minCol and col <= maxCol then
				text.color = "#8888CC"
			else
				text.color = optionsColor
			end if
			btnFunc
			yield
		end while
		if text.color != optionsColor then
			if @btnFunc == @drawLeftArrow then
				if options.level > 1 then options.level = options.level - 1
			else
				if options.level < 25 then options.level = options.level + 1
			end if
		end if
		drawOptions
	end if
end function

doTitle = function
	text.clear
	display(2).mode = displayMode.pixel
	display(2).clear
	display(4).clear
	printCentered "TOKI PONA TRAINER", 22, color.white
	drawBlocks
	drawOptions
	drawInstructions
	while true
		yield
		if mouse.button then handleClick
		if time > nextBlockChangeTime then drawBlocks
		if key.available and key.get == " " then break
	end while
	display(2).clear
	text.clear
end function

