local pd 	<const> = playdate
local gfx 	<const> = pd.graphics

-- math
local min 		<const> = math.min  
local max 		<const> = math.max

-- garbage collector
local COLLECT_GARBAGE 		<const> = collectgarbage

-- drawing
local LOCK_FOCUS 			<const> = gfx.lockFocus
local UNLOCK_FOCUS 			<const> = gfx.unlockFocus

local SET_DRAW_OFFSET	 	<const> = gfx.setDrawOffset
local NEW_IMAGE 			<const> = gfx.image.new

local SET_IMAGE_DRAW_MODE 	<const> = gfx.setImageDrawMode
local DRAW_MODE_FILL_WHITE	<const> = gfx.kDrawModeFillWhite
local DRAW_MODE_COPY 		<const> = gfx.kDrawModeCopy
local DRAW_TEXT 			<const> = gfx.drawText
local SET_FONT				<const> = gfx.setFont

local DRAW_IMAGE_STATIC		<const> = gfx.image.drawIgnoringOffset
local DRAW_RECT 			<const> = gfx.drawRect
local SET_COLOR 			<const> = gfx.setColor
local COLOR_WHITE 			<const> = gfx.kColorWhite

local SCREEN_WIDTH 			<const> = pd.display.getWidth()
local SCREEN_HEIGHT 		<const> = pd.display.getHeight()
local SCREEN_HALF_WIDTH 	<const> = SCREEN_WIDTH / 2
local SCREEN_HALF_HEIGHT 	<const> = SCREEN_HEIGHT / 2

-- input
local BUTTON_PRESSED 		<const> = pd.buttonJustPressed
local UP 					<const> = pd.kButtonUp
local DOWN 					<const> = pd.kButtonDown
local LEFT 					<const> = pd.kButtonLeft
local RIGHT 				<const> = pd.kButtonRight
local A_BUTTON 				<const> = pd.kButtonA
local B_BUTTON 				<const> = pd.kButtonB

-- Bubble Selector
local SETUP_BUBBLE_SELECTOR 			<const> = setupBubbleSelector
local CLEAR_BUBBLE_SELECTOR 			<const> = clearBubbleSelector
local UPDATE_BUBBLE_INDEX 				<const> = updateBubbleIndex
local UPDATE_ACTION_BAR 				<const> = updateActionBar
local APPLY_SELECTION_BUMP_FORCE 		<const> = applySelectionBumpForce
local DRAW_SELECTION_BUBBLE				<const> = drawSelectionBubble



-- +--------------------------------------------------------------+
-- |                            Render                            |
-- +--------------------------------------------------------------+

local img_MainMenuBackground = nil
local path_MainMenuBackground = 'Resources/Sprites/menu/MainMenu/MainMenu_background_v2'

local img_MenuOptionText = gfx.image.new(SCREEN_WIDTH, SCREEN_HEIGHT)

local font_MenuOptions = gfx.font.new('Resources/Fonts/diamond_20')



-- +--------------------------------------------------------------+
-- |                     Variables and Arrays                     |
-- +--------------------------------------------------------------+

local text_images = {}
local textPos_x = {}
local textPos_y = {}
local text_width = {}
local text_height = 0

local TEXT_START_POS_Y 		<const> = SCREEN_HALF_HEIGHT - 10
local NEW_LINE_DISTANCE 	<const> = 30

local menuOptions = {	
	"Play", 
	"Upgrade",
	"Settings", 
	"Credits"
}

local MENU_SIZE <const> = #menuOptions
local menuIndex = 1
local menuItemSelected = false

--[[
local selectorState = true
local selectorTimer = 0
local SELECTOR_TIMER_SET 	<const> = 200
local SELECTOR_SIZE			<const> = 12
local SELECTOR_LEFT			<const> = -SELECTOR_SIZE * 0.5 - 1
local SELECTOR_RIGHT 		<const> = SELECTOR_SIZE
local SELECTOR_TOP 			<const> = -SELECTOR_SIZE * 0.5 + 1
local SELECTOR_BOT 			<const> = SELECTOR_SIZE
]]


-- Bubble Selector
local BUBBLE_MIDL_X <const> = 200

local BUBBLE_PLAY_Y 	<const> = 118
local BUBBLE_UPGRADE_Y 	<const> = BUBBLE_PLAY_Y + NEW_LINE_DISTANCE
local BUBBLE_SETTING_Y 	<const> = BUBBLE_UPGRADE_Y + NEW_LINE_DISTANCE
local BUBBLE_CREDITS_Y 	<const> = BUBBLE_SETTING_Y + NEW_LINE_DISTANCE

local PLAY_WIDTH 		<const> = 40
local PLAY_HEIGHT 		<const> = 17 

local UPGRADE_WIDTH 	<const> = 60
local UPGRADE_HEIGHT 	<const> = 17

local SETTINGS_WIDTH 	<const> = 70 
local SETTINGS_HEIGHT 	<const> = 17 

local CREDITS_WIDTH 	<const> = 55
local CREDITS_HEIGHT 	<const> = 17

local bubble_target_x = { 
	BUBBLE_MIDL_X, 
	BUBBLE_MIDL_X,
	BUBBLE_MIDL_X,
	BUBBLE_MIDL_X
}
local bubble_target_y = {
	BUBBLE_PLAY_Y,
	BUBBLE_UPGRADE_Y,
	BUBBLE_SETTING_Y,
	BUBBLE_CREDITS_Y
}
local bubble_target_w = {
	PLAY_WIDTH,
	UPGRADE_WIDTH,
	SETTINGS_WIDTH,
	CREDITS_WIDTH
}
local bubble_target_h = {
	PLAY_HEIGHT,
	UPGRADE_HEIGHT, 
	SETTINGS_HEIGHT,
	CREDITS_HEIGHT
}


-- +--------------------------------------------------------------+
-- |                   Init, State Start, Drawing                 |
-- +--------------------------------------------------------------+

local function createMenuOptionText()

	-- create the image
	img_MenuOptionText = NEW_IMAGE(SCREEN_WIDTH, SCREEN_HEIGHT)

	-- draw to the new image
	SET_IMAGE_DRAW_MODE(DRAW_MODE_FILL_WHITE) -- draw text white
	SET_FONT(font_MenuOptions)
	
	for i = 1, MENU_SIZE do 
		text_images[i] = gfx.image.new(SCREEN_WIDTH, SCREEN_HEIGHT)
		LOCK_FOCUS(text_images[i])
			local width, height = DRAW_TEXT(menuOptions[i], 0, 0)
			local offset = ((i-1) * NEW_LINE_DISTANCE)
			textPos_x[i] = SCREEN_HALF_WIDTH - (width * 0.5)
			textPos_y[i] = TEXT_START_POS_Y + offset
			text_width[i] = width
			text_height = height
		UNLOCK_FOCUS()
	end

	SET_IMAGE_DRAW_MODE(DRAW_MODE_COPY)		-- reset drawing mode


	-- Draw all the predrawn text to the final image, centered and at the correct height.
	LOCK_FOCUS(img_MenuOptionText)
		for i = 1, MENU_SIZE do 
			DRAW_IMAGE_STATIC(text_images[i], textPos_x[i], textPos_y[i])
		end
	UNLOCK_FOCUS()
end


-- Passed into the 'runTransitionEnd' function call by the 'startmenu.lua' file.
function mainMenu_StateStart()

	-- reset the draw offset so the selector boxes are drawn correctly
	SET_DRAW_OFFSET(0, 0)

	-- setup variables
	menuItemSelected = false

	-- create background and text images
	img_MainMenuBackground = NEW_IMAGE(path_MainMenuBackground)
	createMenuOptionText()

	-- setup the bubble selector
	menuIndex = UPDATE_BUBBLE_INDEX(1) -- starts on first menu option: 'Play'
	SETUP_BUBBLE_SELECTOR(	bubble_target_x, bubble_target_y, 
							bubble_target_w, bubble_target_h
							)

	-- Run the 'End Transition' animation
	runTransitionEnd()
end


local function mainMenu_ClearState()

	-- clear background images
	img_MainMenuBackground = nil 
	img_MenuOptionText = nil 

	-- clear text images
	for i = 1, #text_images do 
		text_images[i] = nil
	end  

	-- clear the bubble selector
	CLEAR_BUBBLE_SELECTOR()

	print("main menu cleared")

	-- Clean up all the data that was disconnected via being set to nil
	COLLECT_GARBAGE()
end

--[[
local function drawSelectorBox(time)
	-- draw flashing menu selector
	if selectorTimer < time then 
		selectorTimer = time + SELECTOR_TIMER_SET
		selectorState = not selectorState
	end
	if selectorState then  
		local i = menuIndex
		SET_COLOR(COLOR_WHITE)
		DRAW_RECT(	textPos_x[i] + SELECTOR_LEFT, 
					textPos_y[i] + SELECTOR_TOP, 
					text_width[i] + SELECTOR_RIGHT, 
					text_height + SELECTOR_BOT)
	end
end
]]


-- +--------------------------------------------------------------+
-- |                   Commands, Action Updates                   |
-- +--------------------------------------------------------------+

--- Menu Commands ---
--------------------- 

-- go to 'Main Game' 
local function commandPlay()
	menuItemSelected = true
end

local function commandUpgrade()
	print("entered upgrade menu")
end

local function commandSettings()
	print("entered settings menu")
end

local function commandCredits()
	print("entered credits menu")
end

-- Array of commands must be declared after all functions because of local scope.
local menuCommands = {
	commandPlay,
	commandUpgrade,
	commandSettings,
	commandCredits
}


--- Revert Menu Commands ---
----------------------------

local function revertPlay()
	menuItemSelected = false
end 

local function revertUpgrade()

end

local function revertSettings()

end

local function revertCredits()

end

-- Array of commands must be declared after all functions because of local scope.
local revertCommands = {
	revertPlay,
	revertUpgrade,
	revertSettings,
	revertCredits
}


--- Action Updates ---
----------------------

local function actionNull()

end 

local function actionPlay()

	local DRAW_CRANK_UI			<const> = pd.ui.crankIndicator.draw

	-- end condition - if the action bar has reached its 'finished state', then end this updating action.
	if UPDATE_ACTION_BAR() == true then
		print(" -- PLAY CONFIRMED -- ")
		menuItemSelected = false

		-- 'gameScene_init' calls 'gameScene_goToLevel', which then calls 'runTransitionEnd'.
		runTransitionStart( GAMESTATE.maingame, TRANSITION_TYPE.growingCircles, gameScene_init, mainMenu_ClearState )
	end
end 

-- Array of commands must be declared after all functions because of local scope.
local actionUpdate = {
	actionPlay,
	actionNull,
	actionNull,
	actionNull
}



-- +--------------------------------------------------------------+
-- |                            Update                            |
-- +--------------------------------------------------------------+

function updateMainMenu(time)

	-- draw background
	DRAW_IMAGE_STATIC(img_MainMenuBackground, 0, 0)

	-- draw menu options
	DRAW_IMAGE_STATIC(img_MenuOptionText, 0, 0)

	-- determine menu option
	if 		BUTTON_PRESSED(UP) then		menuIndex = UPDATE_BUBBLE_INDEX( max(menuIndex - 1, 1) )
	elseif 	BUTTON_PRESSED(DOWN) then	menuIndex = UPDATE_BUBBLE_INDEX( min(menuIndex + 1, MENU_SIZE) )
	end

	-- draw the selector box around selected menu text
	--drawSelectorBox(time)
	drawSelectionBubble(time, 0, menuItemSelected)

	-- check and call selected menu commands	
	if BUTTON_PRESSED(A_BUTTON) then 
		menuCommands[ menuIndex ]()
	end

	if BUTTON_PRESSED(B_BUTTON) then

		if not menuItemSelected then 
			runTransitionStart( GAMESTATE.startscreen, TRANSITION_TYPE.growingCircles, startMenu_StateStart, mainMenu_ClearState )
		else 
			revertCommands[ menuIndex ]()
		end
	end

	if menuItemSelected then  
		actionUpdate[ menuIndex ](time)
	end

end