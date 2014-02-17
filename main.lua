function love.load()
    http = require("socket.http")
    JSON = love.filesystem.load("json.lua")()

    love.graphics.setBackgroundColor(0,0,0)
    state = "intro"
    version = "0.9.2"
    release = "Christmas Week - Indev"
    debugging = false

    love.physics.setMeter(32)
    world = love.physics.newWorld(0, 9.81*32, true)
    world:setCallbacks(beginContact,endContact,preSolve,postSolve)

    gametime = 0
    name = ""
    time = 0
    score = 0
    scores = {}
    ani = 0
    b=1
    w=1
    a=1

    currentdir = love.filesystem.getDirectoryItems(".")
    parentdir = love.filesystem.getDirectoryItems("..")
    levelpacks = {}
    levelfiles = {}
    for i, v in ipairs(currentdir) do table.insert(levelfiles,string.match(v,".*%.sbl")) end
    for i, v in ipairs(parentdir) do table.insert(levelfiles,string.match(v,".*%.sbl")) end
    for i, v in ipairs(levelfiles) do table.insert(levelpacks,packToLevelTable(love.filesystem.load(v)())) end
    levelfiles = {}
    levelpack = 1
    for i, v in ipairs(currentdir) do table.insert(levelfiles,string.match(v,".*%.sbt")) end
    for i, v in ipairs(parentdir) do table.insert(levelfiles,string.match(v,".*%.sbt")) end
    for i, v in ipairs(levelfiles) do table.insert(levelpacks,love.filesystem.load(v)()()) end
    levelfiles = {}
    currentLevelTable = loadLevelTable(levelpacks[levelpack])

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

    currentBlocks = {}

    ball = {}
    ball.body = love.physics.newBody(world, 64, 208, "dynamic")
    ball.shape = love.physics.newCircleShape(16)
    ball.fixture = love.physics.newFixture(ball.body, ball.shape, 1)
    ball.fixture:setRestitution(0.8)
    ball.fixture:setUserData(0)
    ball.body:setGravityScale(1)

    --love.graphics.setMode(640, 480)
    love.window.setTitle("Supersonic Ball")
    loadLevelTable(levelpacks[levelpack])
    loadSprites("sprites.png")
    love.graphics.setFont(hudfont)
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

function packToLevelTable(pack)
    local looping, loopdivisor
    local levelTable = {name = pack.name, shortname = pack.shortname, author = pack.author, spritesheet = pack.spritesheet, resetVelocity = pack.resetvelocity, maxTime = pack.maxtime, looping = pack.looping, loopDivisor = pack.loopdivisor}
    local levels = {}
    for i=1,pack.count do levels[i] = pack[i] end
    local level = 1
    levelTable.level = 1
    local loop = 1
    local function levelChange(n) levelTable.level=(levelTable.level+n); level=level+n end
    local rng = love.math.newRandomGenerator()
    local function currentLevel() return levels[level] end
    local function generateLevel()
        physicsClean(levelTable.levelBlocks); collectgarbage("collect"); levelTable.levelBlocks = {}
        rng:setSeed(currentLevel().seed)
        levelTable.levelBlocks = generateBlocks(rng,currentLevel().rndintrv,currentLevel().slope,currentLevel().minheight,currentLevel().maxheight,currentLevel().length) end
    function levelTable.levelName() return currentLevel().name end
    function levelTable.levelTime()
        return math.max(math.floor(currentLevel().time/loop),15)
    end
    function levelTable.levelLength() return currentLevel().length end
    function levelTable.levelBgspr() return currentLevel().bgspr end
    function levelTable.levelWallspr() return currentLevel().wallspr end
    function levelTable.levelBallspr() return currentLevel().ballspr end
    function levelTable.levelScrollspeed () return currentLevel().scrollspeed end
    function levelTable.levelAnispeed() return currentLevel().anispeed end
    levelTable.levelBlocks = {}
    function levelTable.gotoFirstLevel() levelTable.level, level = 1, 1; generateLevel() end
    if looping then function levelTable.gotoNextLevel()
        if levelTable.level == pack.count then level = 0 end
        levelChange(1); generateLevel(); return true
    end else function levelTable.gotoNextLevel()
        if level ~= pack.count
        then levelChange(1); generateLevel(); return true
        else return false end
    end end
    if looping then function levelTable.gotoPreviousLevel()
        if level ~= 1
        then levelChange(-1); generateLevel(); return true
        else return false end
    end else function levelTable.gotoPreviousLevel()
        if level ~= 1
        then levelChange(-1); generateLevel(); return true
        else return false end
    end end
    return levelTable
end

function loadSprites(ss)
    sprites = love.graphics.newImage(ss)
    sprites:setWrap("repeat", "repeat")
    sprites:setFilter("nearest", "nearest")
end

function loadLevelTable(lt)
    loadSprites(lt.spritesheet)
    return lt
end

function physicsClean(array)
    for i, v in ipairs(array) do
        v.fixture:destroy()
        v.body = nil
        v.shape = nil
        v.fixture = nil
        v = nil
    end
end

function generateBlocks(rng,rndintrv,slope,minheight,maxheight,length)
    local floor,roof,blockset,currentposl,currentposh
    currentposl, currentposh = 208, 240
    floor, roof = {}, {}
    for i=1,length do
        --[[if i%rndintrv==0 and slope>1 then
            slope = slope + love.math.random(-1,1)
        else
            slope = slope + love.math.random(0,1)
        end
        ]]
        if i>=1 and i<=3 then currentposl = currentposl + 32
        elseif i%slope==0 then currentposl = currentposl + rng:random(-1,1)*32
        end
        floor[i] = {}
        floor[i].body = love.physics.newBody(world, 32*i, currentposl)
        floor[i].shape = love.physics.newRectangleShape(0, 0, 32, 32)
        floor[i].fixture = love.physics.newFixture(floor[i].body, floor[i].shape)
        floor[i].fixture:setUserData(1)
        -- UserData: 0 = ball; 1 = normal block
        if i>=1 and i<=3 then currentposh = currentposh - 32
        else
            if i%slope==0 then
                if currentposh>=floor[i].body:getY()-(32*minheight+32) then currentposh = currentposh - 32
                elseif currentposh<=floor[i].body:getY()-(32*maxheight+32) then currentposh = currentposh + 32
                else currentposh = currentposh + rng:random(-1,1)*32
                end
            end
        end

        roof[i] = {}
        roof[i].body = love.physics.newBody(world, 32*i, currentposh)
        roof[i].shape = love.physics.newRectangleShape(0, 0, 32, 32)
        roof[i].fixture = love.physics.newFixture(roof[i].body, roof[i].shape)
        roof[i].fixture:setUserData(1)
    end
    blockset = {}
    for i=1,length do
        table.insert(blockset,floor[i])
        table.insert(blockset,roof[i])
    end
    return blockset, rng
end

function loadLevel(levelTable)
    touchnorm = false

    currentBlocks = {}

    ball.body:setPosition(64, 208)
    if levelTable.resetVelocity then ball.body:setLinearVelocity(0,0) end
    time = time + currentLevelTable.levelTime()
    time = math.min(time,currentLevelTable.maxTime or time)
    b=1
    w=1
    a=1

    currentBlocks = levelTable.levelBlocks
end

function loadScoreboard(version,levelPack) return http.request("http://julosoft.net/supersonicball/highscores.php?output=json&lvlpack="..currentLevelTable.shortname.."&version="..version) end

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
        if love.keyboard.isDown("return") then
            score = 0
            time = 0
            currentLevelTable = loadLevelTable(levelpacks[levelpack])
            currentLevelTable.gotoFirstLevel()
            loadLevel(currentLevelTable)
            state = "game"
        end
    elseif state == "game" then
        love.window.setTitle("Supersonic Ball - "..love.timer.getFPS().." FPS - "..currentLevelTable.levelName()) --.." - Time: "..string.format("%03d",time).. " - Score: "..string.format("%06d",score))
        world:update(dt)
        time = time-dt
        ani = ani+dt

        if ani > currentLevelTable.levelAnispeed() then
            if b == #currentLevelTable.levelBgspr() then b=1 else b=b+1 end
            if w == #currentLevelTable.levelWallspr() then w=1 else w=w+1 end
            if a == #currentLevelTable.levelBallspr() then a=1 else a=a+1 end
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
            physicsClean(currentBlocks)
            state = "intro"
        end
        --[[if love.keyboard.isDown("z") then
            if level > 1 then
                level = level-1
                loadLevel(levels,level)
            end
        end
        if love.keyboard.isDown("x") then
            if level < levels.count then
                level = level+1
                loadLevel(levels,level)
            end
        end]]--
        if ball.body:getX() > 32*currentLevelTable.levelLength() then
            score = score+time*10
            if currentLevelTable.gotoNextLevel() then
                loadLevel(currentLevelTable)
            else
                name = ""
                state = "won"
            end
        end
        if time < 0 then
            state = "lost"
        end
    elseif state == "pause" then
        love.window.setTitle("Supersonic Ball - "..love.timer.getFPS().." FPS - PAUSE - "..currentLevelTable.levelName())--.." - Time: "..string.format("%03d",time).. " - Score: "..string.format("%06d",score))
    elseif state == "won" or state == "lost" then
        love.window.setTitle("Supersonic Ball")
        if love.keyboard.isDown("return") then
            http.request("http://julosoft.net/supersonicball/submit.php?name="..name.."&score="..score.."&version="..version.."&lvlpack="..currentLevelTable.shortname)
            scoreboard = nil
            state = "scoreboard"
        end
    elseif state == "scoreboard" then
        if scoreboard == nil then
            scoreboard = loadScoreboard(version,currentLevelTable.shortname)
            if scoreboard ~= nil then
                --[[i=1
                for c, k, v in string.gmatch(scoreboard, "(%w+)\t(%w+)\t(%w+)") do
                    scores[i] = {country=c, name=k, score=v}
                    i=i+1
                end]]
                scores = JSON:decode(scoreboard)
                flags = {}
                for i, v in ipairs(scores) do
                    if love.filesystem.exists("flags/"..string.lower(v["country"])..".png") then
                        flags[i] = love.graphics.newImage("flags/"..string.lower(v["country"])..".png")
                    else
                        flags[i] = love.graphics.newImage("flags/xx.png")
                    end
                end
            end
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
    if state ~= "won" or state ~= "lost" then
    if state == "intro" or state == "scoreboard" then
        if love.keyboard.isDown("left") then
            levelpack = (levelpack-2)%#levelpacks+1
            currentLevelTable = loadLevelTable(levelpacks[levelpack])
            if state == "scoreboard" then scoreboard = loadScoreboard(version,currentLevelTable.shortname) end
        end
        if love.keyboard.isDown("right") then
            levelpack = levelpack%#levelpacks+1
            currentLevelTable = loadLevelTable(levelpacks[levelpack])
            if state == "scoreboard" then scoreboard = loadScoreboard(version,currentLevelTable.shortname) end
        end
    end
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
    elseif key=='f' then
        love.window.setFullscreen(not love.window.getFullscreen())
    end
end

function love.textinput(t)
    if (state == "won" or state == "lost") and t:match("^[0-9a-zA-Z%,%'%.%!%?%:%-% ]$") ~= nil then
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
        printCenter(currentLevelTable.name,288)
        printCenter("by "..currentLevelTable.author,304)
        printCenter([[PRESS ENTER
        
        
        PRESS S FOR HIGHSCORES
        PRESS H FOR HELP AND CREDITS
        
        ©2013 DJ OMNIMAGA - OMNIMAGA.ORG
        ©2013 JUJU2143 - JULOSOFT.NET]],336)
        love.graphics.print(version, 0, windowHeight-16)
    elseif state == "game" or state == "pause" then
        geometry = love.graphics.newQuad(currentLevelTable.levelBgspr()[b]%8*32,math.floor(currentLevelTable.levelBgspr()[b]/8)*32,32,32,sprites:getWidth(),sprites:getHeight())
        tileBackground(sprites,geometry,ball.body:getX()/currentLevelTable.levelScrollspeed(),ball.body:getY()/currentLevelTable.levelScrollspeed(),windowWidth,windowHeight)
        love.graphics.push();
        love.graphics.translate(-ball.body:getX()+windowWidth/2, -ball.body:getY()+windowHeight/2)

        love.graphics.setColor(255,255,255)
        love.graphics.draw(csprites[currentLevelTable.levelBallspr()[a]], ball.body:getX(), ball.body:getY(), ball.body:getAngle(), 1, 1, ball.shape:getRadius(), ball.shape:getRadius())

        geometry = love.graphics.newQuad(currentLevelTable.levelWallspr()[w]%8*32,math.floor(currentLevelTable.levelWallspr()[w]/8)*32,32,32,sprites:getWidth(),sprites:getHeight())
        for i, v in ipairs(currentBlocks) do
            love.graphics.draw(sprites, geometry, v.body:getX()-16, v.body:getY()-16)
        end
        love.graphics.pop();
        love.graphics.print("SCORE", 16, 16);
        love.graphics.print("LV", 128, 16);
        love.graphics.print("TIME", windowWidth-80, 16);
        love.graphics.print(string.format("%06d", score), 16, 32);
        love.graphics.print(string.format("%02d", currentLevelTable.level), 128, 32);
        love.graphics.print(string.format("⌚%03d",time), windowWidth-80, 32);
        printCenter(currentLevelTable.levelName(),windowHeight-16)
        if state == "pause" then
            printCenter("PAUSE",windowHeight/2-7)
        end
    elseif state == "won" then
        geometry = love.graphics.newQuad(64,32,32,32,sprites:getWidth(),sprites:getHeight())
        tileBackground(sprites,geometry,gametime*30,gametime*30,windowWidth,windowHeight)
        love.graphics.printf("Congratulations! You finished the pack!\nScore: "..string.format("%06d", score).."\n\nEnter your name and press enter:\n"..name, 16, 16, windowWidth-32, "left")
    elseif state == "lost" then
        geometry = love.graphics.newQuad(64,32,32,32,sprites:getWidth(),sprites:getHeight())
        tileBackground(sprites,geometry,gametime*30,gametime*30,windowWidth,windowHeight)
        love.graphics.printf("Congratulations!\nYou died with a score of: "..string.format("%06d", score).."\n\nEnter your name and press enter:\n"..name, 16, 16, windowWidth-32, "left")
    elseif state == "scoreboard" then
        geometry = love.graphics.newQuad(64,32,32,32,sprites:getWidth(),sprites:getHeight())
        tileBackground(sprites,geometry,gametime*30,gametime*30,windowWidth,windowHeight)
        printCenter("HIGH SCORES",16)
        printCenter(currentLevelTable.name,32)
        if scoreboard == nil then
            love.graphics.printf("LOADING...", 16, 64, windowWidth-32, "left")
        else
            for i, v in ipairs(scores) do
                love.graphics.draw(flags[i], 16, 50+16*i)
                love.graphics.printf(v["name"], 32, 50+16*i, windowWidth-32, "left")
                love.graphics.printf(v["score"], 16, 50+16*i, windowWidth-32, "right")
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
