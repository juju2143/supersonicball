function love.load()
	love.graphics.setBackgroundColor(0,0,0)
	state = "intro"

	love.physics.setMeter(32)
	world = love.physics.newWorld(0, 9.81*32, true)

	level = 1
	time = 0
	score = 0
	ani = 0
	b=1
	w=1
	a=1

	sprites = love.graphics.newImage("sprites.png")
	sprites:setWrap("repeat", "repeat")
	sprites:setFilter("nearest", "nearest")
	
	music = love.audio.newSource("void.ogg")
	music:setLooping(true)

	levelpack = "originallevels"
	levels = love.filesystem.load(levelpack..".lua")()

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
	if time > 999 then time = 999 end
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
	if state == "intro" then
		love.graphics.setCaption("Supersonic Ball")
		if love.keyboard.isDown("return") then
			state = "game"
		end
	elseif state == "game" then
		love.graphics.setCaption("Supersonic Ball - "..love.timer.getFPS().." FPS - "..levels[level].name.." - Time: "..string.format("%03d",time).. " - Score: "..string.format("%06d",score))
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
		elseif love.keyboard.isDown("left") then
			ball.body:applyForce(-400, 0)
		elseif love.keyboard.isDown("up") then
			--TODO: if ball collides with something
				ball.body:applyForce(0, -400)
			--TODO: end
		elseif love.keyboard.isDown("down") then
			--TODO: if ball collides with something
				ball.body:applyForce(0, 400)
			--TODO: end
		elseif love.keyboard.isDown("r") then
			ball.body:setPosition(64, 208)
		--[[elseif love.keyboard.isDown("o") then
			if level > 1 then
				level = level-1
				loadLevel(level)
			end
		elseif love.keyboard.isDown("p") then
			if level < levels.count then
				level = level+1
				loadLevel(level)
			end]]
		end
		if ball.body:getX() > 32*levels[level].length then
			level = level+1
			score = score+time
			if level > levels.count then
				state = "won"
			else
				loadLevel(level)
			end
		end
		if time < 0 then
			state = "lost"
		end
	elseif state == "pause" then
		love.graphics.setCaption("Supersonic Ball - "..love.timer.getFPS().." FPS - PAUSE - "..levels[level].name.." - Time: "..string.format("%03d",time).. " - Score: "..string.format("%06d",score))
	elseif state == "won" or state == "lost" then
		love.graphics.setCaption("Supersonic Ball")
		if love.keyboard.isDown("return") then
			score = 0
			time = 0
			level = 1
			loadLevel(1)
			state = "game"
		end
	end
end

function love.keypressed(key)
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
			state = "pause"
		elseif state == "pause" then
			state = "game"
		end
	end
end

function love.draw()
	if state == "intro" then
		love.graphics.printf([[supersonic ball pc
		october 4 release (0.9.0.131004)
		
		made with löve by Julien Savard-Gagnon (jusag4)
		http://juju2143.ca
		http://love2d.org
		
		original idea: DJ Omnimaga
		music: DJ Omnimaga - Void (Square Wave Remix) by Juju
		graphics: DJ Omnimaga
		levels: DJ Omnimaga
		the rest: Juju
		
		how to play
		arrow keys are for moving
		p is for pause
		m is for (un)mute music
		r is for restart level if stuck
		q is for quit
		
		goals
		get to the end before the time runs out
		try not to get epilepsy (i warned you!)
		good luck.
		
		(c) 2013 Omnimaga
		(c) 2013 Julosoft Games
		Université Laval 2013
		
		press enter]], 16, 16, 624, "left")
	elseif state == "game" or state == "pause" then
		geometry = love.graphics.newQuad(levels[level].bgspr[b]%8*32,math.floor(levels[level].bgspr[b]/8)*32,32,32,sprites:getWidth(),sprites:getHeight())
		for i=0,20 do
			for j=0,15 do
				love.graphics.drawq(sprites, geometry, 32*i-ball.body:getX()/levels[level].scrollspeed%32, 32*j-ball.body:getY()/levels[level].scrollspeed%32)
			end
		end
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
	elseif state == "won" then
		love.graphics.printf("congratulations you won!\nscore: "..string.format("%06d", score).."\n\npress enter", 16, 16, 624, "left")
	elseif state == "lost" then
		love.graphics.printf("congratulations you weren't fast enough so you died!\nscore: "..string.format("%06d", score).."\n\npress enter", 16, 16, 624, "left")
	end
end