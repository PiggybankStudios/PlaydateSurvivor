local pd 	<const> = playdate
local gfx 	<const> = pd.graphics

local LOCK_FOCUS 			<const> = gfx.lockFocus
local UNLOCK_FOCUS 			<const> = gfx.unlockFocus

local GET_SIZE 				<const> = gfx.image.getSize
local DRAW_IMAGE 			<const> = gfx.image.draw
local DRAW_TEXT 			<const> = gfx.drawText
local SET_FONT				<const> = gfx.setFont

local SET_COLOR 			<const> = gfx.setColor
local COLOR_WHITE 			<const> = gfx.kColorWhite

local SET_IMAGE_DRAW_MODE 	<const> = gfx.setImageDrawMode
local DRAW_MODE_FILL_WHITE	<const> = gfx.kDrawModeFillWhite
local DRAW_MODE_COPY 		<const> = gfx.kDrawModeCopy

local SET_MENU_IMAGE	 	<const> = pd.setMenuImage

local SCREEN_WIDTH 			<const> = pd.display.getWidth()
local SCREEN_HEIGHT 		<const> = pd.display.getHeight()
local SCREEN_HALF_WIDTH 	<const> = SCREEN_WIDTH / 2
local SCREEN_HALF_HEIGHT 	<const> = SCREEN_HEIGHT / 2

local NEW_LINE_DISTANCE 	<const> = 12

-- Fonts
local font_stats = gfx.font.new('Resources/Fonts/onyx_9')
local font_guns = gfx.font.new('Resources/Fonts/peridot_7')


-- +--------------------------------------------------------------+
-- |                          Rendering                           |
-- +--------------------------------------------------------------+

-- Pause Menu Background
--local pauseImage = gfx.image.new('Resources/Sprites/menu/pauseMenu')
local pauseImage = gfx.image.new(SCREEN_WIDTH, SCREEN_HEIGHT)

local pauseBkgr = gfx.image.new('Resources/Sprites/menu/PauseMenu/pauseMenu_v2')
local width, height = GET_SIZE(pauseImage)
local PAUSEIMAGE_HALF_WIDTH, PAUSEIMAGE_HALF_HEIGHT <const> = width * 0.5, height * 0.5


-- Gun Images
local gunImage_X = gfx.image.new('Resources/Sprites/icon/gLocked')
local gunImage_E = gfx.image.new('Resources/Sprites/icon/gEmpty')
local gunImage_1 = gfx.image.new('Resources/Sprites/icon/gPea')
local gunImage_2 = gfx.image.new('Resources/Sprites/icon/gCannon')
local gunImage_3 = gfx.image.new('Resources/Sprites/icon/gMini')
local gunImage_4 = gfx.image.new('Resources/Sprites/icon/gShot')
local gunImage_5 = gfx.image.new('Resources/Sprites/icon/gBurst')
local gunImage_6 = gfx.image.new('Resources/Sprites/icon/gGrenade')
local gunImage_7 = gfx.image.new('Resources/Sprites/icon/gRang')
local gunImage_8 = gfx.image.new('Resources/Sprites/icon/gWave')

local GUN_IMAGES = {
	gunImage_X,
	gunImage_E,
	gunImage_1,
	gunImage_2,
	gunImage_3,
	gunImage_4,
	gunImage_5,
	gunImage_6,
	gunImage_7,
	gunImage_8
}

local GUN_NAMES = {
	"",
	"",
	"Peagun",
	"Cannon",
	"Minigun",
	"Shotgun",
	"Burstgun",
	"Grenader",
	"Rang Gun",
	"Wavey"
}

local statTexts = {
	"level:"		,	
	--"exp:" 			,
	--"health:" 		,
	"move speed:"		,
	--"attack rate:" 	,
	"magnet:" 		,
	--"slots:"		,
	--"bonus dmg:"		,
	"reflect dmg: "		,
	"bonus exp:"	,
	"luck:"			,
	--"bullet speed:" ,
	"armor:"		,
	"dodge:"		,
	"bonus heal:"	,
	--"vampire:"		,
	--"stun:"
}

local statNumbers = {
	function(stats) return stats[1] end,
	function(stats) return stats[2] end,
	function(stats) return stats[3] end,
	function(stats) return stats[4] end,
	function(stats) return stats[5] end,
	function(stats) return stats[6] .. "%" end,
	function(stats) return stats[7] end,
	function(stats) return stats[8] .. "%" end,
	function(stats) return stats[9] end,
}

--[[
local statNumbers = {
	function(stats) return stats[1] end,
	function(stats) return stats[2] .. " / " .. stats[3] end,
	function(stats) return stats[4] .. " / " .. stats[5] end,
	function(stats) return stats[6] end,
	function(stats) return stats[7] end,
	function(stats) return stats[8] end,
	function(stats) return stats[9] .. " / 4" end,
	function(stats) return stats[10] end,
	function(stats) return stats[11] end,
	function(stats) return stats[12] end,
	function(stats) return stats[13] .. "%" end,
	function(stats) return stats[14] end,
	function(stats) return stats[15] end,
	function(stats) return stats[16] .. "%" end,
	function(stats) return stats[17] end,
	function(stats) return stats[18] .. "%" end,
	function(stats) return stats[19] .. "%" end
}
]]

function openPauseMenu_OLDSTYLE(camX, camY)
	--addDifficulty()

	-- Background
	DRAW_IMAGE(pauseImage, camX - PAUSEIMAGE_HALF_WIDTH, camY - PAUSEIMAGE_HALF_HEIGHT)

	-- Images
	local g1, g2, g3, g4, t1, t2, t3, t4 = getEquippedGunData()
	DRAW_IMAGE(GUN_IMAGES[g1 + 2], camX + 136, camY - 90)
	DRAW_IMAGE(GUN_IMAGES[g2 + 2], camX + 136, camY - 45)
	DRAW_IMAGE(GUN_IMAGES[g3 + 2], camX + 136, camY)
	DRAW_IMAGE(GUN_IMAGES[g4 + 2], camX + 136, camY + 45)

	-- Text
	SET_IMAGE_DRAW_MODE(DRAW_MODE_FILL_WHITE) -- draw text white
	SET_FONT(font_stats)

	-- Stat Text
	local columnText 	= camX - 180
	local columnNumbers = camX - 80
	local row 			= camY - 100
	local pstats 		= getPlayerStats()
	for i = 1, #statTexts do
		DRAW_TEXT(statTexts[i], 			columnText, 	(i - 1) * NEW_LINE_DISTANCE + row)
		DRAW_TEXT(statNumbers[i](pstats), 	columnNumbers, 	(i - 1) * NEW_LINE_DISTANCE + row)
	end

	-- Gun Tier Text
	DRAW_TEXT("Tier: " .. t1, camX + 130, camY - 63)
	DRAW_TEXT("Tier: " .. t2, camX + 130, camY - 18)
	DRAW_TEXT("Tier: " .. t3, camX + 130, camY + 27)
	DRAW_TEXT("Tier: " .. t4, camX + 130, camY + 72)

	SET_IMAGE_DRAW_MODE(DRAW_MODE_COPY)		-- reset drawing mode
end


--[[[]
function addDifficulty()
	local sentence = ("difficulty --" .. tostring(getDifficulty()) .. "--")
	writeTextToScreen(162, 20, sentence, false, true)
	local sentence = ("mun:" .. tostring(getMun()))
	writeTextToScreen(162, 27, sentence, false, true)
end
]]


-- +--------------------------------------------------------------+
-- |                           Pausing                            |
-- +--------------------------------------------------------------+

local previousGameState

local GET_EQUIPPED_GUN_DATA <const> = getEquippedGunData
local GET_PLAYER_STATS 		<const> = getPlayerStats


-- TO DO:
	-- Don't show gun info part when pausing on splash screen or main menu.
	-- Also try to hide any irrelevant custom menu buttons if possible if pausing on menu pages.
function pd.gameWillPause()

	-- Save the gameState we are pausing from
	previousGameState = getGameState()
	gameState_SaveTimeAtPause()

	-- Create the menu image
	LOCK_FOCUS(pauseImage)

		-- Bkgr Image
		DRAW_IMAGE(pauseBkgr, SCREEN_HALF_WIDTH - PAUSEIMAGE_HALF_WIDTH, SCREEN_HALF_HEIGHT - PAUSEIMAGE_HALF_HEIGHT)

		-- Gun Images
		local g1, g2, g3, g4, t1, t2, t3, t4 = GET_EQUIPPED_GUN_DATA()
		DRAW_IMAGE(GUN_IMAGES[g1 + 2], 66, 139)
		DRAW_IMAGE(GUN_IMAGES[g2 + 2], 158, 159)
		DRAW_IMAGE(GUN_IMAGES[g3 + 2], 114, 179)
		DRAW_IMAGE(GUN_IMAGES[g4 + 2], 22, 159)

		-- Text - draw white
		SET_IMAGE_DRAW_MODE(DRAW_MODE_FILL_WHITE)

			-- Stat Text
			SET_FONT(font_stats)
			local columnText 	= 16
			local columnNumbers = 116
			local row 			= 6
			local pstats 		= GET_PLAYER_STATS()
			for i = 1, #statTexts do
				DRAW_TEXT(statTexts[i], columnText, 	(i - 1) * NEW_LINE_DISTANCE + row)
				DRAW_TEXT(pstats[i], 	columnNumbers, 	(i - 1) * NEW_LINE_DISTANCE + row)
			end

			-- Gun Tier Text
			SET_FONT(font_guns)
			DRAW_TEXT(GUN_NAMES[g1 + 2], 60, 115)		
			if g1 > 2 then DRAW_TEXT("Lv " .. t1, 60, 125) end

			DRAW_TEXT(GUN_NAMES[g2 + 2], 152, 135) 		
			if g2 > 2 then DRAW_TEXT("Lv " .. t2, 152, 145) end

			DRAW_TEXT(GUN_NAMES[g3 + 2], 108, 155) 		
			if g3 > 2 then DRAW_TEXT("Lv " .. t3, 108, 165) end

			DRAW_TEXT(GUN_NAMES[g4 + 2], 16, 135) 		
			if g4 > 2 then DRAW_TEXT("Lv " .. t4, 16, 145) end

		SET_IMAGE_DRAW_MODE(DRAW_MODE_COPY)

	UNLOCK_FOCUS()

	-- Set the final menu image
	SET_MENU_IMAGE(pauseImage)
end



-- Perform a complete garbage collection pass when returning to the game.
-- Also gives a small pause before resuming gameplay (on hardware), which is actually pretty nice.
function pd.gameWillResume()
	gameState_SwitchToPauseMenu()
end



-- +--------------------------------------------------------------+
-- |                         Menu Buttons                         |
-- +--------------------------------------------------------------+

local clearFunction = {
	gameScene_ClearState,			-- maingame 		
	_,								-- pauseMenu 		
	flowerMiniGame_ClearState,		-- flowerMinigame	
	_,								-- newWeaponMenu 	
	_,								-- playerUpgradeMenu
	_,								-- levelModifierMenu
	_,								-- deathscreen 	
	startMenu_ClearState,			-- startscreen 	
	mainMenu_ClearState,			-- mainmenu 		
	_								-- loadGame 		
}


local function menu_MainMenu()
	gameState_CancelCountdownTimer() -- if coming from the main game, then don't run the countdown timer for this transition.
	local clearState = clearFunction[ previousGameState ]
	runTransitionStart( GAMESTATE.mainmenu, TRANSITION_TYPE.growingCircles, mainMenu_StateStart, clearState, true )
end


local function menu_ExitLevel()
	print("exited from level")
end


-------------------------------
--- Playdate's Menu Buttons ---
local menu = pd.getSystemMenu()

local mainMenu = menu:addMenuItem("main menu", menu_MainMenu)
local exitLevel = menu:addMenuItem("exit level", menu_ExitLevel)