return function()
    local levelTable = {name = "Infinite Test", shortname = "infiniteTest", author = "DJ Omnimaga and bb010g", spritesheet = "sprites.png"}
    levelTable.level = 1
    levelTable.levelBlocks = {}
    levelTable.resetVelocity = false
	levelTable.winnable = false
    local initSeed, rndintrv, slope, minheight, maxheight, length = 1, 5, 5, 4, 5, 128
    local rngHistory
    local newRng
    local function generateLevel()
        physicsClean(levelTable.levelBlocks); collectgarbage("collect"); levelTable.levelBlocks = {}
        levelTable.levelBlocks, newRng = generateBlocks(rngHistory[#rngHistory],rndintrv,slope,minheight,maxheight,length) end
    function levelTable.levelName() return string.format("%03d",(levelTable.level-1)*length).." Meters" end
    function levelTable.levelTime() return 13 end
    function levelTable.levelLength() return length end
    function levelTable.levelBgspr() return {7} end
    function levelTable.levelWallspr() return {3,4,5,6} end
    function levelTable.levelBallspr() return {"ballnorm"} end
    function levelTable.levelScrollspeed() return 4 end
    function levelTable.levelAnispeed() return .1 end
    function levelTable.gotoFirstLevel() levelTable.level = 1; rngHistory = {love.math.newRandomGenerator(initSeed)}; generateLevel() end
    function levelTable.gotoNextLevel() levelTable.level = levelTable.level + 1; table.insert(rngHistory, newRng); generateLevel(); return true end
    function levelTable.gotoPreviousLevel() if levelTable.level ~= 1
        then levelTable.level = levelTable.level + 1; generateLevel(); return true
        else return false end
    end
    return levelTable
end
