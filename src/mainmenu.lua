local gfx <const> = playdate.graphics

local screenWidth <const> = playdate.display.getWidth()
local screenHeight <const> = playdate.display.getHeight()
local halfScreenWidth <const> = screenWidth / 2
local halfScreenHeight <const> = screenHeight / 2

local blinking = false
local lastBlink = 0
local whichSlot = 0
local currentSlot = 0
local menuSpot = 0
local menuState = 0
local menuOptions = 4

local currArray = {}
local wordArrayMain = {"play", "upgrade", "options", "savefile"}
local wordArraySave = {"save 1", "save 2", "save 3", "save 4", "back"}
--local wordArraySaveSel = {"use", "delete", "back"}

--setup main menu
local mainImage = gfx.image.new('Resources/Sprites/menu/mainMenu')
local mainSprite = gfx.sprite.new(mainImage)
mainSprite:setIgnoresDrawOffset(true)	-- forces sprite to be draw to screen, not world
mainSprite:setZIndex(ZINDEX.ui)
mainSprite:moveTo(halfScreenWidth, halfScreenHeight)

--setup prompt
local promptImage = gfx.image.new('Resources/Sprites/menu/mainselect')
local promptImageL = gfx.image.new('Resources/Sprites/menu/mainselectL')
local promptSprite = gfx.sprite.new(promptImage)
promptSprite:setIgnoresDrawOffset(true)	-- forces sprite to be draw to screen, not world
promptSprite:setZIndex(ZINDEX.uidetails)
promptSprite:moveTo(halfScreenWidth, halfScreenHeight)

function openMainMenu()
	mainSprite:add()
	blinking = true
	menuSpot = 1
	menuState = 1
	currentSlot = getConfigValue(CONFIG_REF.Default_Save)
	currArray = wordArrayMain
	promptSprite:setImage(promptImage)
	MainMenuText(currArray)
	promptSprite:add()
end

function MainMenuText(wordArray)
	cleanLetters()
	for Ind, tWord in pairs(wordArray) do
		writeTextToScreen(halfScreenWidth - 5, halfScreenHeight + 30 * (Ind - menuSpot), tWord, true, false)
	end
	if menuState == 4 then
		local tArray = {
			MainMenuSaveCheckText(wordArraySave[1]),
			MainMenuSaveCheckText(wordArraySave[2]),
			MainMenuSaveCheckText(wordArraySave[3]),
			MainMenuSaveCheckText(wordArraySave[4])
		}
		for Ind, tWord in pairs(tArray) do
			writeTextToScreen(halfScreenWidth + 80, halfScreenHeight + 30 * (Ind - menuSpot), tWord, true, false)
		end
	end
	if menuState == 5 then
		local tArray = {
			"save " .. tostring(whichSlot),
			MainMenuSaveCheckText(wordArraySave[whichSlot])
		}
		for Ind, tWord in pairs(tArray) do
			writeTextToScreen(halfScreenWidth + 120, halfScreenHeight - 50 + 30 * Ind, tWord, true, false)
		end
	end
end

function MainMenuSaveCheckText(tStr)
	if check_file_exists(tStr) == true then
		if tostring(currentSlot) == string.sub(tStr,6,6) then return "*full" end
		print(tostring(currentSlot) .. "vs".. tostring(string.sub(tStr,6,6)))
		return "full"
	else
		if tostring(currentSlot) == string.sub(tStr,6,6) then return "*empty" end
		return "empty"
	end
end

function MainMenuNavigate()
	if menuSpot == 1 and menuState == 1 then
		return true
	elseif menuSpot == 4 and menuState == 1 then
		currArray = wordArraySave
		menuState = 4
		menuSpot = 1
	elseif menuSpot == 5 and menuState == 4 then
		currArray = wordArrayMain
		menuState = 1
		menuSpot = 1
	elseif menuSpot ~= 5 and menuState == 4 then
		menuState = 5
		whichSlot = menuSpot
		local tArray = {
			"load save " .. tostring(menuSpot),
			"update save " .. tostring(menuSpot),
			"delete save " .. tostring(menuSpot),
			"back"
		}
		currArray = tArray
		promptSprite:setImage(promptImageL)
		menuSpot = 1
	elseif menuSpot == 1 and menuState == 5 then
		if check_file_exists(wordArraySave[whichSlot]) == true then readSaveFile(wordArraySave[whichSlot]) end
	elseif menuSpot == 2 and menuState == 5 then
		writeSaveFile(wordArraySave[whichSlot])
	elseif menuSpot == 3 and menuState == 5 then
		deleteSaveFile(wordArraySave[whichSlot])
	elseif menuSpot == 4 and menuState == 5 then
		currArray = wordArraySave
		menuState = 4
		promptSprite:setImage(promptImage)
		menuSpot = 1
	else
		return false
	end
	menuOptions = #currArray
	MainMenuText(currArray)
	return false
end

function updateMainManu()
	local theCurrTime = playdate.getCurrentTimeMilliseconds()
	if theCurrTime > lastBlink then
		lastBlink = theCurrTime + 500
		if blinking then
			promptSprite:remove()
			blinking = false
		else
			promptSprite:add()
			blinking = true
		end
	end
end

function mainMenuMoveU()
	menuSpot -= 1
	if menuSpot < 1 then menuSpot = menuOptions end
	MainMenuText(currArray)
end

function mainMenuMoveD()
	menuSpot += 1
	if menuSpot > menuOptions then menuSpot = 1 end
	MainMenuText(currArray)
end

function getMainMenuSelection()
	return menuSpot
end

function closeMainMenu()
	mainSprite:remove()
	if blinking == true then promptSprite:remove() end
	cleanLetters()
	--print("unpaused")
end
