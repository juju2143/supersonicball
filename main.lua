function love.load()
    http = require("socket.http")
    JSON = love.filesystem.load("json.lua")()

    love.graphics.setBackgroundColor(0,0,0)
    state = "intro"
    version = "0.9.2"
    release = "Second Christmas"
    debugging = false

    love.physics.setMeter(32)
    world = love.physics.newWorld(0, 9.81*32, true)
    world:setCallbacks(beginContact,endContact,preSolve,postSolve)

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

    levelpacks = {"originallevels"}
    levelpack = 1

    csprites = {}

    function logistic(x)
        return 1/(1+math.exp(-x))
    end

    csprites.ballnorm = love.graphics.newCanvas(32,32)
    csprites.ballnorm:renderTo(function ()
        local r, g, b, a = love.graphics.getColor()
        for i=0,16,.5 do
            local ilog = logistic((i-2)*1.5)
            love.graphics.setColor(ilog*255,152+ilog*103,ilog*255)
            love.graphics.circle("fill",16,16,16/(i+1),100)
        end
        love.graphics.setColor(0,0,0)
        love.graphics.setLineWidth(1)
        love.graphics.line(2,16,30,16)
        love.graphics.line(16,2,16,30)
        love.graphics.setColor(r,g,b,a)
    end)

    title = love.graphics.newImage("title.png")
    title:setWrap("repeat", "repeat")
    title:setFilter("nearest", "nearest")

    --deffont = love.graphics.newFont()
    hudfont = love.graphics.newImageFont("fonts.png",
        "0123456789AaBbCcDdEeFfGgHhIiJjKkLlMmNnOÖoPpQqRrSsTtUuVvWwXxYyZz,'.!?:-*·⌚© ")

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
    ball.fixture:setUserData(0)
    ball.body:setGravityScale(1)

    --love.graphics.setMode(640, 480)
    love.window.setTitle("Supersonic Ball")
    loadLevelpack(levelpack)
    loadSprites("sprites.png")
    love.graphics.setFont(hudfont);
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

function loadSprites(ss)
    sprites = love.graphics.newImage(ss)
    sprites:setWrap("repeat", "repeat")
    sprites:setFilter("nearest", "nearest")
end

function loadLevelpack(p)
    levels = love.filesystem.load(levelpacks[p]..".lua")()
    loadSprites(levels.spritesheet)
end

function loadLevel(l)
    touchnorm = false
    love.math.setRandomSeed(levels[l].seed)

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
    ball.body:setLinearVelocity(0,0)
    time = time + levels[l].time
    if time > 1000 then time = 1000 end
    b=1
    w=1
    a=1

    currentposl = 208
    currentposh = 240
    for i=1,levels[l].length do
        --[[if i%levels[l].rndintrv==0 and levels[l].slope>1 then
            levels[l].slope = levels[l].slope + love.math.random(-1,1)
        else
            levels[l].slope = levels[l].slope + love.math.random(0,1)
        end
        ]]
        if i>=1 and i<=3 then currentposl = currentposl + 32
        elseif i%levels[l].slope==0 then currentposl = currentposl + love.math.random(-1,1)*32
        end
        plancher[i] = {}
        plancher[i].body = love.physics.newBody(world, 32*i, currentposl)
        plancher[i].shape = love.physics.newRectangleShape(0, 0, 32, 32)
        plancher[i].fixture = love.physics.newFixture(plancher[i].body, plancher[i].shape)
        plancher[i].fixture:setUserData(1)
        -- UserData: 0 = ball; 1 = normal block
        if i>=1 and i<=3 then currentposh = currentposh - 32
        else
            if i%levels[l].slope==0 then
                if currentposh>=plancher[i].body:getY()-(32*levels[l].minheight+32) then currentposh = currentposh - 32
                elseif currentposh<=plancher[i].body:getY()-(32*levels[l].maxheight+32) then currentposh = currentposh + 32
                else currentposh = currentposh + love.math.random(-1,1)*32
                end
            end
        end

        plafond[i] = {}
        plafond[i].body = love.physics.newBody(world, 32*i, currentposh)
        plafond[i].shape = love.physics.newRectangleShape(0, 0, 32, 32)
        plafond[i].fixture = love.physics.newFixture(plafond[i].body, plafond[i].shape)
    end
end

function loadScoreboard(version,levelPack) return http.request("http://julosoft.net/supersonicball/highscores.php?output=json&lvlpack="..levels.name.."&version="..version) end

function love.update(dt)
    gametime = gametime+dt
    if state == "intro" then
        love.window.setTitle("Supersonic Ball")
        if love.keyboard.isDown("s") then
            scoreboard = nil
            state = "scoreboard"
        end
        if love.keyboard.isDown("h") then
            state = "help"
        end
        if love.keyboard.isDown("left") then
            levelpack = (levelpack-2)%#levelpacks+1
            loadLevelpack(levelpack)
        end
        if love.keyboard.isDown("right") then
            levelpack = levelpack%#levelpacks+1
            loadLevelpack(levelpack)
        end
        if love.keyboard.isDown("return") then
            score = 0
            time = 0
            level = 1
            loadLevelpack(levelpack)
            loadLevel(1)
            state = "game"
        end
    elseif state == "game" then
        love.window.setTitle("Supersonic Ball - "..love.timer.getFPS().." FPS - "..levels[level].name) --.." - Time: "..string.format("%03d",time).. " - Score: "..string.format("%06d",score))
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
        if touchnorm then
            if love.keyboard.isDown("up") then
                ball.body:applyForce(0, -5000)
            end
            if love.keyboard.isDown("down") then
                ball.body:applyForce(0, 5000)
            end
        end
        if love.keyboard.isDown("r") then
            touchnorm = false
            ball.body:setPosition(64, 208)
            ball.body:setLinearVelocity(0,0)
        end
        if love.keyboard.isDown("escape") then
            state = "intro"
        end
        --[[if love.keyboard.isDown("z") then
            if level > 1 then
                level = level-1
                loadLevel(level)
            end
        end
        if love.keyboard.isDown("x") then
            if level < levels.count then
                level = level+1
                loadLevel(level)
            end
        end]]--
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
        love.window.setTitle("Supersonic Ball - "..love.timer.getFPS().." FPS - PAUSE - "..levels[level].name)--.." - Time: "..string.format("%03d",time).. " - Score: "..string.format("%06d",score))
    elseif state == "won" or state == "lost" then
        love.window.setTitle("Supersonic Ball")
        if love.keyboard.isDown("return") then
            if state == "won" then
                http.request("http://julosoft.net/supersonicball/submit.php?name="..name.."&score="..score.."&version="..version.."&lvlpack="..levels.name)
            end
            scoreboard = nil
            state = "scoreboard"
        end
    elseif state == "scoreboard" then
        if scoreboard == nil then
            scoreboard = loadScoreboard(version,levels.name)
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
        if love.keyboard.isDown("left") then
            levelpack = (levelpack-2)%#levelpacks+1
            loadLevelpack(levelpack)
            scoreboard = loadScoreboard(version,levels.name)
        end
        if love.keyboard.isDown("right") then
            levelpack = levelpack%#levelpacks+1
            loadLevelpack(levelpack)
            scoreboard = loadScoreboard(version,levels.name)
        end
        if love.keyboard.isDown("escape") then
            state = "intro"
        end
    elseif state == "help" then
        if love.keyboard.isDown("escape") then
            state = "intro"
        end
    end
end

function pairMatch(a,b,x,y)
    return a == x and b == y or b == x and a == y
end

function beginContact(a, b, coll)
    --print("begin collision",a:getUserData(),b:getUserData())
    if pairMatch(a:getUserData(),b:getUserData(),0,1) then
        touchnorm = true
    end
end

function endContact(a, b, coll)
    --print("end   collision",a:getUserData(),b:getUserData())
    if pairMatch(a:getUserData(),b:getUserData(),0,1) then
        touchnorm = false
    end
end

function preSolve(a, b, coll)
end

function postSolve(a, b, coll)
end

function love.keypressed(key, isrepeat)
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

function tileBackground(image,quad,adjX,adjY,windowWidth,windowHeight)
    for i=0,windowWidth+32,32 do
        for j=0,windowHeight+32,32 do
            love.graphics.draw(image,quad,i-adjX%32,j-adjY%32)
        end
    end
end

function printCenter(text,x) love.graphics.printf(text,0,x,windowWidth,"center") end

function love.draw()
    windowWidth = love.window.getWidth()
    windowHeight = love.window.getHeight()
    if state == "intro" then
        geometry = love.graphics.newQuad(64,32,32,32,sprites:getWidth(),sprites:getHeight())
        tileBackground(sprites,geometry,gametime*30,gametime*30,windowWidth,windowHeight)
        for i=16,windowHeight+16,32 do
            love.graphics.draw(csprites.ballnorm,16,i,gametime*5,1,1,16,16)
            love.graphics.draw(csprites.ballnorm,windowWidth-16,i,gametime*5,1,1,16,16)
        end
        printCenter("JULOSOFT PRESENTS",32)
        love.graphics.draw(title, windowWidth/2-248, 72)
        printCenter(levels.name,288)
        printCenter([[PRESS ENTER
        PRESS S FOR HIGHSCORES
        PRESS H FOR HELP AND CREDITS
        ©2013 DJ OMNIMAGA - OMNIMAGA.ORG
        ©2013 JUJU2143 - JULOSOFT.NET]],320)
        love.graphics.print(version, 0, windowHeight-16)
    elseif state == "game" or state == "pause" then
        geometry = love.graphics.newQuad(levels[level].bgspr[b]%8*32,math.floor(levels[level].bgspr[b]/8)*32,32,32,sprites:getWidth(),sprites:getHeight())
        tileBackground(sprites,geometry,ball.body:getX()/levels[level].scrollspeed,ball.body:getY()/levels[level].scrollspeed,windowWidth,windowHeight)
        love.graphics.push();
        love.graphics.translate(-ball.body:getX()+windowWidth/2, -ball.body:getY()+windowHeight/2)

        love.graphics.setColor(255,255,255)
        love.graphics.draw(csprites[levels[level].ballspr[a]], ball.body:getX(), ball.body:getY(), ball.body:getAngle(), 1, 1, ball.shape:getRadius(), ball.shape:getRadius())

        geometry = love.graphics.newQuad(levels[level].wallspr[w]%8*32,math.floor(levels[level].wallspr[w]/8)*32,32,32,sprites:getWidth(),sprites:getHeight())
        for i=1,levels[level].length do
            love.graphics.draw(sprites, geometry, plancher[i].body:getX()-16, plancher[i].body:getY()-16)
        end
        for i=1,levels[level].length do
            love.graphics.draw(sprites, geometry, plafond[i].body:getX()-16, plafond[i].body:getY()-16)
        end
        love.graphics.pop();
        love.graphics.print("SCORE", 16, 16);
        love.graphics.print("LV", 128, 16);
        love.graphics.print("TIME", windowWidth-80, 16);
        love.graphics.print(string.format("%06d", score), 16, 32);
        love.graphics.print(string.format("%02d", level), 128, 32);
        love.graphics.print(string.format("⌚%03d",time), windowWidth-80, 32);
        if state == "pause" then
            printCenter("PAUSE",windowHeight/2-7)
        end
    elseif state == "won" then
        geometry = love.graphics.newQuad(64,32,32,32,sprites:getWidth(),sprites:getHeight())
        tileBackground(sprites,geometry,gametime*30,gametime*30,windowWidth,windowHeight)
        love.graphics.printf(string.upper("congratulations you won!\nscore: "..string.format("%06d", score).."\n\nenter your name and press enter:\n"..name), 16, 16, 624, "left")
    elseif state == "lost" then
        geometry = love.graphics.newQuad(64,32,32,32,sprites:getWidth(),sprites:getHeight())
        tileBackground(sprites,geometry,gametime*30,gametime*30,windowWidth,windowHeight)
        love.graphics.printf(string.upper("congratulations you weren't fast enough so you died!\nscore: "..string.format("%06d", score).."\n\npress enter"), 16, 16, 624, "left")
    elseif state == "scoreboard" then
        geometry = love.graphics.newQuad(64,32,32,32,sprites:getWidth(),sprites:getHeight())
        tileBackground(sprites,geometry,gametime*30,gametime*30,windowWidth,windowHeight)
        printCenter("HIGH SCORES",16)
        printCenter(levels.name,32)
        if scoreboard == nil then
            love.graphics.printf("LOADING...", 16, 64, windowWidth-32, "left")
        else
            for i=1,#scores do
                love.graphics.draw(flags[i], 16, 50+16*i)
                love.graphics.printf(scores[i]["name"], 32, 50+16*i, windowWidth-32, "left")
                love.graphics.printf(scores[i]["score"], 16, 50+16*i, windowWidth-32, "right")
            end
        end
        love.graphics.printf("PRESS ESCAPE", 0, windowHeight-32, windowWidth, "center")
    elseif state == "help" then
        geometry = love.graphics.newQuad(64,32,32,32,sprites:getWidth(),sprites:getHeight())
        tileBackground(sprites,geometry,gametime*30,gametime*30,windowWidth,windowHeight)
        love.graphics.printf([[Supersonic Ball PC ]]..version..[[

        ]]..release..[[ Release
        Port by: juju2143
        Contributions by:
        · bb010g
        Original by DJ Omnimaga
        Made with LÖVE

        How to play
        Arrow keys: Move
        M: Mute
        P: Pause
        Q: Quit
        R: Restart
        Escape: Return to menu

        Goal:
        Get to the end before time runs out
        Try not to get epilepsy
        Good luck.

        In memory of Tribal 1992-2013

        Omnimaga.org
        Julosoft.net

        ]], 16, 16, windowWidth-32, "left")
    end
    --love.graphics.printf(love.timer.getFPS(),0,windowHeight-16,windowWidth,"right")
end
