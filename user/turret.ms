// Draws the gun turret.

base = new Sprite
base.image = file.loadImage("base.png")
base.x = 480
base.y = 30
base.update = function(dt); end function

barrel = new Sprite
barrel.image = file.loadImage("gun.png")
barrel.x = base.x
barrel.y = base.y + 40
barrel.update = function(dt); end function

aimAt = function(xyMap)
	barrel.rotation = atan(xyMap.y - barrel.y, xyMap.x - barrel.x) * 180/pi
end function

displayBgColor = "#5E5E5E"
initialize = function()
	display(2).mode = displayMode.pixel
	display(2).clear color.clear
	
	display(4).sprites.push barrel
	display(4).sprites.push base
end function

showLevel = function(level=88)
	display(2).fillRect base.x+9, base.y+22, 18, 14, displayBgColor
	s = str(level)
	if s.len < 2 then s = "0" + s
	display(2).print s, base.x+9, base.y+22, color.red, "small"
end function

showWordsLeft = function(left=88)
	display(2).fillRect base.x+9, base.y+2, 18, 14, displayBgColor
	s = str(left)
	if s.len < 2 then s = "0" + s
	display(2).print s, base.x+9, base.y+2, color.red, "small"
end function

showScore = function(score=999999)
	display(2).fillRect base.x-26, base.y-24, 53, 14, displayBgColor
	s = "000000" + str(score)
	s = s[-6:]
	display(2).print s, base.x-24, base.y-24, color.red, "small"
end function

if globals == locals then
	clear
	initialize
	showLevel
	showWordsLeft
	showScore
	while not key.available
		aimAt mouse
		yield
	end while
	key.clear
end if