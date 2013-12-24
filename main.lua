function love.load()
	http = require("socket.http")
	JSON = (loadfile "json.lua")()
	
	--lil hack so it works with LÖVE 0.9.0
	love.graphics.drawq = love.graphics.drawq or love.graphics.draw
	love.graphics.setCaption = love.graphics.setCaption or love.window.setTitle
	
	love.graphics.setBackgroundColor(0,0,0)
	state = "intro"
	version = "0.9.1";

	love.physics.setMeter(32)
	world = love.physics.newWorld(0, 9.81*32, true)

	gametime = 0
	name = ""
	level = 1
	time = 0
	score = 0
	scores={}
	ani = 0
	b=1
	w=1
	a=1

	levelpack = "originallevels"
	levels = love.filesystem.load(levelpack..".lua")()
	
	sprites = love.graphics.newImage(levels.spritesheet)
	sprites:setWrap("repeat", "repeat")
	sprites:setFilter("nearest", "nearest")
	
	title = love.graphics.newImage("title.png")
	title:setWrap("repeat", "repeat")
	title:setFilter("nearest", "nearest")
	
	--deffont = love.graphics.newFont()
	hudfont = love.graphics.newImageFont("fonts.png",
		"0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ,'.!?:-*@ ")

		allowed = {32,33,39,44,45,46,48,49,50,51,52,53,54,55,56,57,58,63,
			65,66,67,68,69,70,71,72,73,74,75,76,77,78,79,80,81,82,83,84,85,86,87,88,89,90,
			97,98,99,100,101,102,103,104,105,106,107,108,109,110,111,112,113,114,115,116,117,118,119,120,121,122}

	music = love.audio.newSource("void.ogg")
	music:setLooping(true)

	plancher = {}
	plafond = {}

	ball = {}
	ball.body = love.physics.newBody(world, 64, 208, "dynamic")
	ball.shape = love.physics.newCircleShape(16)
	ball.fixture = love.physics.newFixture(ball.body, ball.shape, 1)
	ball.fixture:setRestitution(0.8)

	loadLevel(level)

	--love.graphics.setMode(640, 480)
	love.graphics.setCaption("Supersonic Ball")
	music:play()
end

function contains(table, element)
  for _, value in pairs(table) do
    if value == element then
      return true
    end
  end
  return false
end

function loadLevel(l)
	math.randomseed(levels[l].seed)

	for i=1,#plancher do
		plancher[i].fixture:setMask(1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16)
		plancher[i].body = nil
		plancher[i].shape = nil
		plancher[i].fixture = nil
		plancher[i] = nil
	end
	for i=1,#plafond do
		plafond[i].fixture:setMask(1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16)
		plafond[i].body = nil
		plafond[i].shape = nil
		plafond[i].fixture = nil
		plafond[i] = nil
	end
	collectgarbage("collect")
	plancher = {}
	plafond = {}

	ball.body:setPosition(64, 208)
	time = time + levels[l].time
	if time > 1000 then time = 1000 end
	b=1
	w=1
	a=1

	currentposl = 208
	currentposh = 240
	for i=1,levels[l].length do
		--[[if i%levels[l].rndintrv==0 and levels[l].slope>1 then
			levels[l].slope = levels[l].slope + math.random(-1,1)
		else
			levels[l].slope = levels[l].slope + math.random(0,1)
		end
		]]--
		if i>=1 and i<=3 then currentposl = currentposl + 32
		elseif i%levels[l].slope==0 then currentposl = currentposl + math.random(-1,1)*32
		end
		plancher[i] = {}
		plancher[i].body = love.physics.newBody(world, 32*i, currentposl)
		plancher[i].shape = love.physics.newRectangleShape(0, 0, 32, 32)
		plancher[i].fixture = love.physics.newFixture(plancher[i].body, plancher[i].shape)
		if i>=1 and i<=3 then currentposh = currentposh - 32
		else
			if i%levels[l].slope==0 then
				if currentposh>=plancher[i].body:getY()-(32*levels[l].minheight+32) then currentposh = currentposh - 32
				elseif currentposh<=plancher[i].body:getY()-(32*levels[l].maxheight+32) then currentposh = currentposh + 32
				else currentposh = currentposh + math.random(-1,1)*32
				end
			end
		end
		
		plafond[i] = {}
		plafond[i].body = love.physics.newBody(world, 32*i, currentposh)
		plafond[i].shape = love.physics.newRectangleShape(0, 0, 32, 32)
		plafond[i].fixture = love.physics.newFixture(plafond[i].body, plafond[i].shape)
	end
end

function love.update(dt)
	gametime = gametime+dt
	if state == "intro" then
		love.graphics.setCaption("Supersonic Ball")
		if love.keyboard.isDown("s") then
			scoreboard = nil
			state = "scoreboard"
		end
		if love.keyboard.isDown("h") then
			state = "help"
		end
		if love.keyboard.isDown("return") then
			score = 0
			time = 0
			level = 1
			loadLevel(1)
			state = "game"
		end
	elseif state == "game" then
		love.graphics.setCaption("Supersonic Ball - "..love.timer.getFPS().." FPS - "..levels[level].name) --.." - Time: "..string.format("%03d",time).. " - Score: "..string.format("%06d",score))
		world:update(dt)
		time = time-dt
		ani = ani+dt
		
		if ani > .1 then
			if b == #levels[level].bgspr then b=1 else b=b+1 end
			if w == #levels[level].wallspr then w=1 else w=w+1 end
			if a == #levels[level].ballspr then a=1 else a=a+1 end
			ani = 0
		end

		if love.keyboard.isDown("right") then
			ball.body:applyForce(400, 0)
		end
		if love.keyboard.isDown("left") then
			ball.body:applyForce(-400, 0)
		end
		if love.keyboard.isDown("up") then
			--TODO: if ball collides with something
				ball.body:applyForce(0, -400)
			--TODO: end
		end
		if love.keyboard.isDown("down") then
			--TODO: if ball collides with something
				ball.body:applyForce(0, 400)
			--TODO: end
		end
		if love.keyboard.isDown("r") then
			ball.body:setPosition(64, 208)
		end
		--[[elseif love.keyboard.isDown("o") then
			if level > 1 then
				level = level-1
				loadLevel(level)
			end
		elseif love.keyboard.isDown("p") then
			if level < levels.count then
				level = level+1
				loadLevel(level)
			end
		end]]
		if ball.body:getX() > 32*levels[level].length then
			level = level+1
			score = score+time*10
			if level > levels.count then
				name = ""
				state = "won"
			else
				loadLevel(level)
			end
		end
		if time < 0 then
			state = "lost"
		end
	elseif state == "pause" then
		love.graphics.setCaption("Supersonic Ball - "..love.timer.getFPS().." FPS - PAUSE - "..levels[level].name)--.." - Time: "..string.format("%03d",time).. " - Score: "..string.format("%06d",score))
	elseif state == "won" or state == "lost" then
		love.graphics.setCaption("Supersonic Ball")
		if state == "won" then
			if love.keyboard.isDown("return") then
				http.request("http://julosoft.net/supersonicball/submit.php?name="..name.."&score="..score.."&version="..version.."&lvlpack="..levelpack)
				scoreboard = nil
				state = "scoreboard"
			end
		else
			if love.keyboard.isDown("return") then
				scoreboard = nil
				state = "scoreboard"
			end
		end
	elseif state == "scoreboard" then
		if scoreboard == nil then
			scoreboard = http.request("http://julosoft.net/supersonicball/highscores.php?output=json&lvlpack="..levelpack.."&version="..version)
			if scoreboard ~= nil then
				--[[i=1
				for c, k, v in string.gmatch(scoreboard, "(%w+)\t(%w+)\t(%w+)") do
					scores[i] = {country=c, name=k, score=v}
					i=i+1
				end]]
				scores = JSON:decode(scoreboard)
				flags = {}
				for i=1,#scores do
					if love.filesystem.exists("flags/"..string.lower(scores[i]["country"])..".png") then
						flags[i] = love.graphics.newImage("flags/"..string.lower(scores[i]["country"])..".png")
					else
						flags[i] = love.graphics.newImage("flags/xx.png")
					end
				end
			end
		end
		if love.keyboard.isDown(" ") then
			state = "intro"
		end
	elseif state == "help" then
		if love.keyboard.isDown(" ") then
			state = "intro"
		end
	end
end

function love.keypressed(key, unicode)
	if state ~= "won" then
		if key=='m' then
			if music:getVolume() == 1 then
				music:setVolume(0)
			else
				music:setVolume(1)
			end
		elseif key=='q' then
			love.event.quit()
		elseif key=='p' then
			if state == "game" then
				music:pause()
				state = "pause"
			elseif state == "pause" then
				music:play()
				state = "game"
			end
		end
	else
		if contains(allowed, unicode) then
			name = name..string.char(unicode);
		elseif key=="backspace" then
			name = string.sub(name, 1, -2)
		end
	end
end

function love.textinput(t)
	if state == "won" and t:match("^[0-9a-zA-Z%,%'%.%!%?%:%-% ]$") ~= nil then
		name = name..t
	end
end

function love.focus(f)
	if not f and state == "game" then
		music:pause()
		state = "pause"
	end
end

function love.draw()
	love.graphics.setFont(hudfont);
	if state == "intro" then
		geometry = love.graphics.newQuad(64,32,32,32,sprites:getWidth(),sprites:getHeight())
		ballgeo = love.graphics.newQuad(160,96,32,32,sprites:getWidth(),sprites:getHeight())
		for i=0,20 do
			for j=0,15 do
				love.graphics.drawq(sprites, geometry, 32*i-(gametime*30)%32, 32*j-(gametime*30)%32)
			end
		end
		for i=0,15 do
			love.graphics.drawq(sprites, ballgeo, 0, 32*i)
			love.graphics.drawq(sprites, ballgeo, 608, 32*i)
		end
		love.graphics.printf("JULOSOFT PRESENTS", 0, 32, 640, "center")
		love.graphics.draw(title, 72, 72)
		love.graphics.printf("PRESS ENTER", 0, 320, 640, "center")
		love.graphics.printf("PRESS S FOR HIGHSCORES", 0, 400, 640, "center")
		love.graphics.printf("PRESS H FOR HELP AND CREDITS", 0, 416, 640, "center")
		love.graphics.printf("@2013 DJ OMNIMAGA - OMNIMAGA.ORG", 0, 432, 640, "center")
		love.graphics.printf("@2013 JUJU2143 - JULOSOFT.NET", 0, 448, 640, "center")
		love.graphics.printf(version, 0, 464, 640, "left")
	elseif state == "game" or state == "pause" then
		geometry = love.graphics.newQuad(levels[level].bgspr[b]%8*32,math.floor(levels[level].bgspr[b]/8)*32,32,32,sprites:getWidth(),sprites:getHeight())
		for i=0,20 do
			for j=0,15 do
				love.graphics.drawq(sprites, geometry, 32*i-ball.body:getX()/levels[level].scrollspeed%32, 32*j-ball.body:getY()/levels[level].scrollspeed%32)
			end
		end
		love.graphics.push();
		love.graphics.translate(-ball.body:getX()+320, -ball.body:getY()+240)

		love.graphics.setColor(255,255,255)
		geometry = love.graphics.newQuad(levels[level].ballspr[a]%8*32,math.floor(levels[level].ballspr[a]/8)*32,32,32,sprites:getWidth(),sprites:getHeight())
		love.graphics.drawq(sprites, geometry, ball.body:getX(), ball.body:getY(), ball.body:getAngle(), 1, 1, ball.shape:getRadius(), ball.shape:getRadius())

		geometry = love.graphics.newQuad(levels[level].wallspr[w]%8*32,math.floor(levels[level].wallspr[w]/8)*32,32,32,sprites:getWidth(),sprites:getHeight())
		for i=1,levels[level].length do
			love.graphics.drawq(sprites, geometry, plancher[i].body:getX()-16, plancher[i].body:getY()-16)
		end
		for i=1,levels[level].length do
			love.graphics.drawq(sprites, geometry, plafond[i].body:getX()-16, plafond[i].body:getY()-16)
		end
		love.graphics.pop();
		love.graphics.print("SCORE", 16, 16);
		love.graphics.print("LV", 128, 16);
		love.graphics.print("TIME", 560, 16);
		love.graphics.print(string.format("%06d", score), 16, 32);
		love.graphics.print(string.format("%02d", level), 128, 32);
		love.graphics.print(string.format("*%03d",time), 560, 32);
		if state == "pause" then
			love.graphics.print("PAUSE", 280, 200)
		end
	elseif state == "won" then
		geometry = love.graphics.newQuad(64,32,32,32,sprites:getWidth(),sprites:getHeight())
		for i=0,20 do
			for j=0,15 do
				love.graphics.drawq(sprites, geometry, 32*i-(gametime*30)%32, 32*j-(gametime*30)%32)
			end
		end
		love.graphics.printf(string.upper("congratulations you won!\nscore: "..string.format("%06d", score).."\n\nenter your name and press enter:\n"..name), 16, 16, 624, "left")
	elseif state == "lost" then
		geometry = love.graphics.newQuad(64,32,32,32,sprites:getWidth(),sprites:getHeight())
		for i=0,20 do
			for j=0,15 do
				love.graphics.drawq(sprites, geometry, 32*i-(gametime*30)%32, 32*j-(gametime*30)%32)
			end
		end
		love.graphics.printf(string.upper("congratulations you weren't fast enough so you died!\nscore: "..string.format("%06d", score).."\n\npress enter"), 16, 16, 624, "left")
	elseif state == "scoreboard" then
		geometry = love.graphics.newQuad(64,32,32,32,sprites:getWidth(),sprites:getHeight())
		for i=0,20 do
			for j=0,15 do
				love.graphics.drawq(sprites, geometry, 32*i-(gametime*30)%32, 32*j-(gametime*30)%32)
			end
		end
		love.graphics.printf("HIGH SCORES", 16, 16, 608, "center")
		if scoreboard == nil then
			love.graphics.printf("LOADING...", 16, 48, 608, "left")
		else
			for i=1,#scores do
				love.graphics.draw(flags[i], 16, 34+16*i)
				love.graphics.printf(string.upper(scores[i]["name"]), 32, 32+16*i, 608, "left")
				love.graphics.printf(scores[i]["score"], 16, 32+16*i, 608, "right")
			end
		end
		love.graphics.printf("PRESS SPACE", 0, 448, 640, "center")
	elseif state == "help" then
		geometry = love.graphics.newQuad(64,32,32,32,sprites:getWidth(),sprites:getHeight())
		for i=0,20 do
			for j=0,15 do
				love.graphics.drawq(sprites, geometry, 32*i-(gametime*30)%32, 32*j-(gametime*30)%32)
			end
		end
		love.graphics.printf(string.upper([[Supersonic Ball PC ]]..version..[[
		
		Christmas Release
		Port by juju2143
		Original by DJ Omnimaga
		
		How to play
		Arrow keys: move
		M: Mute
		P: Pause
		Q: Quit
		R: Restart
		
		Goal
		get to the end before time runs out
		try not to get epilepsy
		good luck.
		
		In memory of Tribal 1992-2013
		
		Omnimaga.org
		Julosoft.net
		
		Press space
		]]), 16, 16, 608, "left")
	end
end