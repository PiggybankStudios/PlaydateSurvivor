local gfx <const> = playdate.graphics

local screenWidth <const> = playdate.display.getWidth()
local screenHeight <const> = playdate.display.getHeight()
local halfScreenWidth <const> = screenWidth / 2
local halfScreenHeight <const> = screenHeight / 2

local blinking = false
local lastBlink = 0
local whichSlot = 0
local currentSlot = "save 1"
local menuSpot = 0
local menuState = 0
local menuOptions = 4
local MENU = {
	main = 1,
	upgrade = 2,
	options = 3,
	save = 4,
	saveEdit = 5,
	pauseSpeed = 6,
	stats = 7
}

local currArray = {}
local wordArrayMain = {"play", "upgrade", "options", "savefile"}
local wordArrayUpgrade = {"chars", "stats", "weaps", "charms", "back"}
local wordArrayStats = {"health", "damage", "exp_bonus", "speed", "back"}
local wordArrayOption = {"run_mode", "pause_time", "invincible", "one_hit_kill", "back"}
local wordArraySave = {"save 1", "save 2", "save 3", "save 4", "back"}
local wordArrayPauseTimer = {"none", "1 sec", "2 sec", "3 sec", "4 sec", "5 sec","back"}
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
	menuState = MENU.main
	currentSlot = getConfigValue("Default_Save")
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
	if menuState == MENU.options then
		local tArray = {
			get_file_value_text(wordArrayOption[1]),
			wordArrayPauseTimer[getConfigValue(wordArrayOption[2]) + 1],
			get_file_value_text(wordArrayOption[3]),
			get_file_value_text(wordArrayOption[4])
		}
		for Ind, tWord in pairs(tArray) do
			writeTextToScreen(halfScreenWidth + 110, halfScreenHeight + 30 * (Ind - menuSpot), tWord, true, false)
		end
	elseif menuState == MENU.save then
		local tArray = {
			MainMenuSaveCheckText(wordArraySave[1]),
			MainMenuSaveCheckText(wordArraySave[2]),
			MainMenuSaveCheckText(wordArraySave[3]),
			MainMenuSaveCheckText(wordArraySave[4])
		}
		for Ind, tWord in pairs(tArray) do
			writeTextToScreen(halfScreenWidth + 80, halfScreenHeight + 30 * (Ind - menuSpot), tWord, true, false)
		end
	elseif menuState == MENU.saveEdit then
		local tArray = {
			"save " .. tostring(whichSlot),
			MainMenuSaveCheckText(wordArraySave[whichSlot])
		}
		for Ind, tWord in pairs(tArray) do
			writeTextToScreen(halfScreenWidth + 120, halfScreenHeight - 50 + 30 * Ind, tWord, true, false)
		end
	elseif menuState == MENU.stats then
		local tArray = {
			tostring(getSaveValue(wordArrayStats[1])) .. " +1(10)",
			tostring(getSaveValue(wordArrayStats[2])) .. " +1(50)",
			tostring(getSaveValue(wordArrayStats[3])) .. " +1(20)",
			tostring(getSaveValue(wordArrayStats[4])) .. " +5(30)"
		}
		for Ind, tWord in pairs(tArray) do
			writeTextToScreen(halfScreenWidth + 120, halfScreenHeight + 30 * (Ind - menuSpot), tWord, true, false)
		end
		updateTotalMun()
	end
end

function MainMenuSaveCheckText(tStr)
	if check_file_exists(tStr) == true then
		if currentSlot == tStr then return "*full" end
		return "full"
	else
		if currentSlot == tStr then return "*empty" end
		return "empty"
	end
end

function MainMenuNavigate()
	if menuState == MENU.main then
		if menuSpot == 1 then
			return true
		elseif menuSpot == 2 then
			currArray = wordArrayUpgrade
			menuState = MENU.upgrade
			menuSpot = 1
			promptSprite:setImage(promptImageL)
		elseif menuSpot == 3 then
			currArray = wordArrayOption
			menuState = MENU.options
			menuSpot = 1
			promptSprite:setImage(promptImageL)
		elseif menuSpot == 4 then
			currArray = wordArraySave
			menuState = MENU.save
			menuSpot = 1
		else
			return false
		end
	elseif menuState == MENU.upgrade then --look at all save files
		if menuSpot == 2 then
			currArray = wordArrayStats
			menuState = MENU.stats
			menuSpot = 1
		elseif menuSpot == 5 then
			currArray = wordArrayMain
			menuState = MENU.main
			menuSpot = 1
			promptSprite:setImage(promptImage)
		else
			return false
		end
	elseif menuState == MENU.options then --look at all save files
		if menuSpot == 1 then
			toggle_config_value(wordArrayOption[1])
		elseif menuSpot == 2 then
			currArray = wordArrayPauseTimer
			menuState = MENU.pauseSpeed
			menuSpot = 1
			promptSprite:setImage(promptImage)
		elseif menuSpot == 3 then
			toggle_config_value(wordArrayOption[3])
		elseif menuSpot == 4 then
			toggle_config_value(wordArrayOption[4])
		elseif menuSpot == 5 then
			currArray = wordArrayMain
			menuState = MENU.main
			menuSpot = 1
			promptSprite:setImage(promptImage)
		else
			return false
		end
	elseif menuState == MENU.save then --look at all save files
		if menuSpot == 5 then --go back
			currArray = wordArrayMain
			menuState = MENU.main
			menuSpot = 1
		elseif menuSpot ~= 5 then --delve into one of the save files
			menuState = MENU.saveEdit
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
		else
			return false
		end
	elseif menuState == MENU.saveEdit then --editing a save file
		if menuSpot == 1 then --select save file
			if check_file_exists(wordArraySave[whichSlot]) == true then 
				readSaveFile(wordArraySave[whichSlot])
			else
				writeSaveFile(wordArraySave[whichSlot])
			end
			setConfigValue("Default_Save", wordArraySave[whichSlot])
		elseif menuSpot == 2 then --save to save file
			writeSaveFile(wordArraySave[whichSlot])
		elseif menuSpot == 3 then --delete save file
			deleteSaveFile(wordArraySave[whichSlot])
		elseif menuSpot == 4 then --go back
			currArray = wordArraySave
			menuState = MENU.save
			promptSprite:setImage(promptImage)
			menuSpot = 1
		else
			return false
		end
	elseif menuState == MENU.pauseSpeed then --set pause timer
		if menuSpot == 1 then
			setConfigValue(wordArrayOption[2], 0)
		elseif menuSpot == 2 then
			setConfigValue(wordArrayOption[2], 1)
		elseif menuSpot == 3 then
			setConfigValue(wordArrayOption[2], 2)
		elseif menuSpot == 4 then
			setConfigValue(wordArrayOption[2], 3)
		elseif menuSpot == 5 then
			setConfigValue(wordArrayOption[2], 4)
		elseif menuSpot == 6 then
			setConfigValue(wordArrayOption[2], 5)
		elseif menuSpot == 7 then
			currArray = wordArrayOption
			menuState = MENU.options
			menuSpot = 1
			promptSprite:setImage(promptImageL)
		else
			return false
		end
	elseif menuState == MENU.stats then --buy stats {"health", "damage", "exp_bonus", "speed", "back"}
		if menuSpot == 1 then
			setSaveValue(wordArrayStats[1], getSaveValue(wordArrayStats[1]) + 1)
			addTotalMun(-10)
		elseif menuSpot == 2 then
			setSaveValue(wordArrayStats[2], getSaveValue(wordArrayStats[2]) + 1)
			addTotalMun(-50)
		elseif menuSpot == 3 then
			setSaveValue(wordArrayStats[3], getSaveValue(wordArrayStats[3]) + 1)
			addTotalMun(-20)
		elseif menuSpot == 4 then
			setSaveValue(wordArrayStats[4], getSaveValue(wordArrayStats[4]) + 5)
			addTotalMun(-30)
		elseif menuSpot == 5 then
			currArray = wordArrayUpgrade
			menuState = MENU.upgrade
			menuSpot = 1
		else
			return false
		end
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
end
