// Draws and animates the background sky.

botColor = "#740033FF"
topColor = "#16002BFF"

colors = [""] * 640

for y in range(0,639)
	colors[y] = color.lerp(botColor, topColor, y/640)
	gfx.line 0, y, 960, y, colors[y]
end for

stars = []
for i in range(300)
	y = round(640 + 400 * (rnd + rnd + rnd + rnd - 2))
	if y > 640 then y = 640 - (y-640)
	x = round(10 + 940 * rnd)
	c = color.lerp("#FEFE88", "#8888FE", rnd)
	stars.push [x,y,c]
	gfx.setPixel x,y, c
end for

curStarIdx = null
twinkleFramesLeft = 0
update = function()
	if twinkleFramesLeft then
		outer.twinkleFramesLeft = twinkleFramesLeft - 1
		if not twinkleFramesLeft then
			star = stars[curStarIdx]
			gfx.setPixel star[0], star[1], star[2]			
		end if
	else
		outer.curStarIdx = floor(rnd * stars.len)
		star = stars[curStarIdx]
		gfx.setPixel star[0],star[1], color.white
		outer.twinkleFramesLeft = 4 + round(rnd*10)
	end if
end function

if globals == locals then
	while not key.available
		update
		yield
	end while
	key.clear
end if
