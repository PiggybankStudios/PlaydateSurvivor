local pd 	<const> = playdate
local gfx 	<const> = pd.graphics

-- math
local min 		<const> = math.min  
local max 		<const> = math.max
local sin 		<const> = math.sin
local rad 		<const> = math.rad
local floor 	<const> = math.floor

-- time
local GET_TIME 	<const> = pd.getCurrentTimeMilliseconds

-- garbage collector
local COLLECT_GARBAGE 		<const> = collectgarbage

-- drawing
local LOCK_FOCUS 			<const> = gfx.lockFocus
local UNLOCK_FOCUS 			<const> = gfx.unlockFocus

local SET_DRAW_OFFSET	 	<const> = gfx.setDrawOffset
local CLEAR_SCREEN			<const> = gfx.clear

local NEW_IMAGE 			<const> = gfx.image.new
local CLEAR_IMAGE 			<const> = gfx.image.clear
local SET_IMAGE_DRAW_MODE 	<const> = gfx.setImageDrawMode
local DRAW_MODE_FILL_WHITE	<const> = gfx.kDrawModeFillWhite
local DRAW_MODE_COPY 		<const> = gfx.kDrawModeCopy
local DRAW_TEXT 			<const> = gfx.drawText
local SET_FONT				<const> = gfx.setFont

local DRAW_IMAGE_STATIC		<const> = gfx.image.drawIgnoringOffset
local GET_SIZE_AT_PATH 		<const> = gfx.imageSizeAtPath
local COLOR_CLEAR 			<const> = gfx.kColorClear

local SCREEN_WIDTH 			<const> = pd.display.getWidth()
local SCREEN_HEIGHT 		<const> = pd.display.getHeight()
local SCREEN_HALF_WIDTH 	<const> = SCREEN_WIDTH // 2
local SCREEN_HALF_HEIGHT 	<const> = SCREEN_HEIGHT // 2

-- animation
local OUT_CUBIC 			<const> = pd.easingFunctions.outCubic

-- input
local GET_CRANK_CHANGE 		<const> = pd.getCrankChange
local BUTTON_PRESSED 		<const> = pd.buttonJustPressed
local UP 					<const> = pd.kButtonUp
local DOWN 					<const> = pd.kButtonDown
local LEFT 					<const> = pd.kButtonLeft
local RIGHT 				<const> = pd.kButtonRight
local A_BUTTON 				<const> = pd.kButtonA
local B_BUTTON 				<const> = pd.kButtonB

-- playdate ui
local IS_CRANK_DOCKED 		<const> = pd.isCrankDocked
local CRANK_UI 				<const> = pd.ui.crankIndicator
local DRAW_CRANK_UI			<const> = pd.ui.crankIndicator.draw

-- Selection Bubble
local SETUP_BUBBLE_SELECTOR 			<const> = setupBubbleSelector
local CLEAR_BUBBLE_SELECTOR 			<const> = clearBubbleSelector
local UPDATE_BUBBLE_INDEX 				<const> = updateBubbleIndex
local UPDATE_VERTICAL_DITHER_GRADIENT	<const> = updateVerticalDitherGradient
local UPDATE_ACTION_BAR 				<const> = updateActionBar
local APPLY_SELECTION_BUMP_FORCE 		<const> = applySelectionBumpForce
local DRAW_SELECTION_BUBBLE				<const> = drawSelectionBubble



-- +--------------------------------------------------------------+
-- |                            Render                            |
-- +--------------------------------------------------------------+

-- title card
local img_TitleCard_Background = nil
local path_TitleCard_Background <const> = 'Resources/Sprites/menu/StartScreen/TitleCard_Background'
local _, STARTSCREEN_HEIGHT <const> = GET_SIZE_AT_PATH( path_TitleCard_Background )

local img_TitleCard_Moon = nil
local path_TitleCard_Moon <const> = 'Resources/Sprites/menu/StartScreen/TitleCard_Moon'
local MOON_WIDTH, MOON_HEIGHT <const> = GET_SIZE_AT_PATH( path_TitleCard_Moon )
local MOON_HALF_WIDTH, MOON_HALF_HEIGHT <const> = MOON_WIDTH // 2, MOON_HEIGHT // 2
local MOON_X <const> = SCREEN_HALF_WIDTH - MOON_HALF_WIDTH
local MOON_Y <const> = 10

local img_TitleCard_Vamp = nil  
local path_TitleCard_Vamp <const> = 'Resources/Sprites/menu/StartScreen/TitleCard_Vamp'
local VAMP_WIDTH, VAMP_HEIGHT <const> = GET_SIZE_AT_PATH( path_TitleCard_Vamp )
local VAMP_HALF_WIDTH, VAMP_HALF_HEIGHT <const> = VAMP_WIDTH // 2, VAMP_HEIGHT // 2 
local VAMP_X <const> = SCREEN_HALF_WIDTH - VAMP_HALF_WIDTH - 20
local VAMP_Y <const> = 30 

local img_TitleCard_Title_Shadow = nil  
local path_TitleCard_Title_Shadow = 'Resources/Sprites/menu/StartScreen/TitleCard_Title_Shadow'
local TITLESHADOW_WIDTH, TITLESHADOW_HEIGHT <const> = GET_SIZE_AT_PATH( path_TitleCard_Title_Shadow )
local TITLESHADOW_HALF_WIDTH, TITLESHADOW_HALF_HEIGHT <const> = TITLESHADOW_WIDTH // 2, TITLESHADOW_HEIGHT // 2
local TITLESHADOW_X <const> = SCREEN_HALF_WIDTH - TITLESHADOW_HALF_WIDTH
local TITLESHADOW_Y <const> = 11

local img_TitleCard_Title = nil  
local path_TitleCard_Title = 'Resources/Sprites/menu/StartScreen/TitleCard_Title'
local TITLE_WIDTH, TITLE_HEIGHT <const> = GET_SIZE_AT_PATH( path_TitleCard_Title )
local TITLE_HALF_WIDTH, TITLE_HALF_HEIGHT <const> = TITLE_WIDTH // 2, TITLE_HEIGHT // 2
local TITLE_X <const> = SCREEN_HALF_WIDTH - TITLE_HALF_WIDTH
local TITLE_Y = 12

-- animated arrow
local img_dropArrow_outer = nil
local img_dropArrow_inner = nil
local path_dropArrow_outer = 'Resources/Sprites/menu/StartScreen/dropArrow_outer'
local path_dropArrow_inner = 'Resources/Sprites/menu/StartScreen/dropArrow_inner'
local ARROW_WIDTH, ARROW_HEIGHT <const> = GET_SIZE_AT_PATH(path_dropArrow_outer)
local ARROW_HALF_WIDTH, ARROW_HALF_HEIGHT <const> = ARROW_WIDTH // 2, ARROW_HEIGHT // 2

-- save file background
local img_SaveFilesBackground = nil
local path_SaveFilesBackground <const> = 'Resources/Sprites/menu/StartScreen/startScreen_SaveFiles_Background_v2'
local _, SAVEBACKGROUND_HEIGHT <const> = GET_SIZE_AT_PATH( path_SaveFilesBackground )

-- save file letter cards
local img_letterCard_A = nil
local img_letterCard_B = nil
local img_letterCard_C = nil
local path_letterCard_A = 'Resources/Sprites/menu/StartScreen/SaveFileLetter_A'
local path_letterCard_B = 'Resources/Sprites/menu/StartScreen/SaveFileLetter_B'
local path_letterCard_C = 'Resources/Sprites/menu/StartScreen/SaveFileLetter_C'
local LETTERCARD_WIDTH, LETTERCARD_HEIGHT <const> = GET_SIZE_AT_PATH(path_letterCard_A)
local LETTERCARD_HALF_WIDTH, LETTERCARD_HALF_HEIGHT <const> = LETTERCARD_WIDTH // 2 + 1, LETTERCARD_HEIGHT // 2

-- text images
local img_MenuOptionText = nil
local img_SaveFileOptionsText = nil

-- fonts
local font_Default = gfx.getFont() -- default system font



-- +--------------------------------------------------------------+
-- |                     Variables and Arrays                     |
-- +--------------------------------------------------------------+

-- Menu movement
local CRANKVALUE_ON_STARTUP <const> = 300
local crankValue = CRANKVALUE_ON_STARTUP -- starts high so title card can ease into position on startup
local HIDE_TITLE_CARD_VALUE 	<const> = -230
local ARROW_HEIGHT_START 		<const> = 212

local saveFileSelected = false
local menuItemSelected = false
local dirInputDetected = false
local returnToTitleCard = false
local allowInput = false

local startTime = 0
local startCrank = 0
local MENU_EASING_DURATION 		<const> = 1000
local TITLECARD_EASING_DURATION <const> = 2200


-- Save file letter cards
local LETTERCARD_UNSELECTED_Y	<const> = 263 
local LETTERCARD_SELECTED_Y 	<const> = 205
local letterCard_index = 0
local letterCard_startTime = 0
local aCardY, bCardY, cCardY = LETTERCARD_UNSELECTED_Y, LETTERCARD_UNSELECTED_Y, LETTERCARD_UNSELECTED_Y
local aCardStartY, bCardStartY, cCardStartY = 0, 0, 0


-- Save file text
--local text_images = {}
--local textPos_x = {}
--local textPos_y = {}
--local text_width = {}
--local text_height = 0

local TEXT_START_POS_Y 		<const> = SCREEN_HALF_HEIGHT - 10
local NEW_LINE_DISTANCE 	<const> = 30

local saveFileOptions = {	
	"Save File 1", 
	"Save File 2",
	"Save File 3"
}

--local MENU_SIZE <const> = #saveFileOptions



-- Save file options text
local SAVEFILE_OPTIONSTEXT_NEWLINE <const> = 25
local OPTION_TEXT_OFFSET <const> = -20

local BUBBLE_LEFT_X <const> = 80
local BUBBLE_MIDL_X <const> = 200
local BUBBLE_RGHT_X <const> = 320

local BUBBLE_SAVE_Y <const> = 405
local BUBBLE_DLTE_Y <const> = 282
local BUBBLE_COPY_Y <const> = BUBBLE_DLTE_Y + SAVEFILE_OPTIONSTEXT_NEWLINE
local BUBBLE_PLAY_Y <const> = 465

local SAVEFILE_WIDTH 	<const> = 70
local SAVEFILE_HEIGHT 	<const> = 95 
local DELETE_WIDTH 		<const> = 35
local DELETE_HEIGHT 	<const> = 16
local COPY_WIDTH 		<const> = 24 
local COPY_HEIGHT 		<const> = 16 
local PLAY_WIDTH 		<const> = 30
local PLAY_HEIGHT 		<const> = 16

local DLTE_DRAW_HEIGHT 	<const> = 12
local COPY_DRAW_HEIGHT 	<const> = DLTE_DRAW_HEIGHT + SAVEFILE_OPTIONSTEXT_NEWLINE 
local PLAY_DRAW_HEIGHT 	<const> = 195 

local saveFileOptionsText_x = { BUBBLE_LEFT_X + OPTION_TEXT_OFFSET, 
								BUBBLE_MIDL_X + OPTION_TEXT_OFFSET, 
								BUBBLE_RGHT_X + OPTION_TEXT_OFFSET }
local SAVEFILE_OPTIONS_TEXT_DRAW_Y <const> = STARTSCREEN_HEIGHT + SAVEBACKGROUND_HEIGHT - SCREEN_HEIGHT


-- Bubble Selector - menu data 
local BUBBLE_IMAGE_HEIGHT 		<const> = STARTSCREEN_HEIGHT + SAVEBACKGROUND_HEIGHT
local MENU_BOTTOM_SCREEN_VALUE	<const> = -SAVEBACKGROUND_HEIGHT -- screen height to indicate menu navigation is okay

local bubble_index = 1

local bubble_target_x = { 
	BUBBLE_LEFT_X, BUBBLE_MIDL_X, BUBBLE_RGHT_X, 
	BUBBLE_LEFT_X, BUBBLE_MIDL_X, BUBBLE_RGHT_X,
	BUBBLE_LEFT_X, BUBBLE_MIDL_X, BUBBLE_RGHT_X,
	BUBBLE_LEFT_X, BUBBLE_MIDL_X, BUBBLE_RGHT_X 
}
local bubble_target_y = {
	BUBBLE_DLTE_Y, BUBBLE_DLTE_Y, BUBBLE_DLTE_Y,
	BUBBLE_COPY_Y, BUBBLE_COPY_Y, BUBBLE_COPY_Y,
	BUBBLE_SAVE_Y, BUBBLE_SAVE_Y, BUBBLE_SAVE_Y,
	BUBBLE_PLAY_Y, BUBBLE_PLAY_Y, BUBBLE_PLAY_Y
}
local bubble_target_w = {
	DELETE_WIDTH, DELETE_WIDTH, DELETE_WIDTH,
	COPY_WIDTH, COPY_WIDTH, COPY_WIDTH, 
	SAVEFILE_WIDTH, SAVEFILE_WIDTH, SAVEFILE_WIDTH, 
	PLAY_WIDTH, PLAY_WIDTH, PLAY_WIDTH,
}
local bubble_target_h = {
	DELETE_HEIGHT, DELETE_HEIGHT, DELETE_HEIGHT,
	COPY_HEIGHT, COPY_HEIGHT, COPY_HEIGHT, 
	SAVEFILE_HEIGHT, SAVEFILE_HEIGHT, SAVEFILE_HEIGHT, 
	PLAY_HEIGHT, PLAY_HEIGHT, PLAY_HEIGHT
}


-- Action Bar Dither Range
local CRANK_DITHER_DOT_START	<const> = 110
local CRANK_DITHER_DOT_OFFSET 	<const> = -80
local CRANK_DITHER_DOT_END		<const> = 260



-- +--------------------------------------------------------------+
-- |                Init, State Start, Clear, Drawing             |
-- +--------------------------------------------------------------+

--[[
-- Draws the descriptive text of each save file inside each save file section
local function createSaveFileText()

	CLEAR_IMAGE(font_SaveFileOptions, COLOR_CLEAR)

	SET_IMAGE_DRAW_MODE(DRAW_MODE_FILL_WHITE) -- draw text white
	SET_FONT(font_SaveFileOptions)
	
	for i = 1, MENU_SIZE do 
		text_images[i] = gfx.image.new(SCREEN_WIDTH, SCREEN_HEIGHT)
		LOCK_FOCUS(text_images[i])
			local width, height = DRAW_TEXT(saveFileOptions[i], 0, 0)
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
]]


-- Draw the text options for the 3 save files: Delete and Copy
local function createSaveFileOptionText()

	CLEAR_IMAGE(img_SaveFileOptionsText, COLOR_CLEAR)

	SET_IMAGE_DRAW_MODE(DRAW_MODE_FILL_WHITE) -- draw text white
	SET_FONT(font_Default)

	LOCK_FOCUS(img_SaveFileOptionsText)		
		for i = 1, 3 do
			DRAW_TEXT("Play", 	saveFileOptionsText_x[i] + 6, PLAY_DRAW_HEIGHT)
			DRAW_TEXT("Copy", 	saveFileOptionsText_x[i] + 4, COPY_DRAW_HEIGHT)
			DRAW_TEXT("Delete", saveFileOptionsText_x[i], DLTE_DRAW_HEIGHT)
		end
	UNLOCK_FOCUS()

	SET_IMAGE_DRAW_MODE(DRAW_MODE_COPY)		-- reset drawing mode
end


-- Prepares the start screen to be drawn
-- Global - needs to be called outside this file to initialize data
function startMenu_StateStart()

	-- reset the draw offset so the selector boxes are drawn correctly
	SET_DRAW_OFFSET(0, 0)

	-- set crank and menu selection values
	crankValue = CRANKVALUE_ON_STARTUP 	-- so title card can ease into position
	startTime = GET_TIME() 				-- setting up duration for title card easing animation
	saveFileSelected = false
	menuItemSelected = false
	dirInputDetected = false
	allowInput = false

	letterCard_index, letterCard_startTime = 0, 0
	aCardY, bCardY, cCardY = LETTERCARD_UNSELECTED_Y, LETTERCARD_UNSELECTED_Y, LETTERCARD_UNSELECTED_Y
	aCardStartY, bCardStartY, cCardStartY = 0, 0, 0

	-- Create background images
	img_TitleCard_Background = NEW_IMAGE(path_TitleCard_Background)
	img_TitleCard_Moon = NEW_IMAGE(path_TitleCard_Moon)
	img_TitleCard_Vamp = NEW_IMAGE(path_TitleCard_Vamp)
	img_TitleCard_Title_Shadow = NEW_IMAGE(path_TitleCard_Title_Shadow)
	img_TitleCard_Title = NEW_IMAGE(path_TitleCard_Title)
	img_dropArrow_outer = NEW_IMAGE(path_dropArrow_outer)
	img_dropArrow_inner = NEW_IMAGE(path_dropArrow_inner)

	img_SaveFilesBackground = NEW_IMAGE(path_SaveFilesBackground)	
	img_letterCard_A = NEW_IMAGE(path_letterCard_A) 
	img_letterCard_B = NEW_IMAGE(path_letterCard_B)  
	img_letterCard_C = NEW_IMAGE(path_letterCard_C)

	img_MenuOptionText = NEW_IMAGE(SCREEN_WIDTH, SCREEN_HEIGHT)
	img_SaveFileOptionsText = NEW_IMAGE(SCREEN_WIDTH, SCREEN_HEIGHT)

	-- draw to all of the images and set up the bubble selector data
	--createSaveFileText()
	createSaveFileOptionText()

	bubble_index = UPDATE_BUBBLE_INDEX(7) -- starts on first save select
	SETUP_BUBBLE_SELECTOR(	bubble_target_x, bubble_target_y, 
							bubble_target_w, bubble_target_h,
							BUBBLE_IMAGE_HEIGHT
							)

	-- Run the 'End Transition' animation
	runTransitionEnd()
end


-- Removes start screen data from memory - set everything to 0 and call the garbageCollector.
-- Local - only called from this file to clear data
local function startMenu_ClearState()

	-- background images
	img_TitleCard_Background = nil
	img_TitleCard_Moon = nil
	img_TitleCard_Vamp = nil
	img_TitleCard_Title_Shadow = nil
	img_TitleCard_Title = nil
	img_dropArrow_outer = nil
	img_dropArrow_inner = nil

	img_SaveFilesBackground = nil	
	img_letterCard_A = nil 
	img_letterCard_B = nil  
	img_letterCard_C = nil

	img_MenuOptionText = nil
	img_SaveFileOptionsText = nil

	CLEAR_BUBBLE_SELECTOR()

	print("start state cleared")

	-- Clean up all the data that was disconnected via being set to nil
	COLLECT_GARBAGE()
end


-- Draw the art for the title card w/ animated effects
local function drawTitleCard(time)
	if 	crankValue > HIDE_TITLE_CARD_VALUE then

		-- Title Card
		DRAW_IMAGE_STATIC(img_TitleCard_Background, 	0, min(crankValue, 0))
		DRAW_IMAGE_STATIC(img_TitleCard_Moon, 			MOON_X, crankValue*1.2 + MOON_Y)
		DRAW_IMAGE_STATIC(img_TitleCard_Vamp, 			VAMP_X, crankValue*1.5 + VAMP_Y)
		DRAW_IMAGE_STATIC(img_TitleCard_Title_Shadow, 	TITLESHADOW_X, crankValue*1.8 + TITLESHADOW_Y)
		DRAW_IMAGE_STATIC(img_TitleCard_Title, 			TITLE_X, crankValue*2.1 + TITLE_Y)

		-- Drop Arrows
		local arrowOuter_y = crankValue + ARROW_HEIGHT_START + sin(rad(time) * 0.5) * 4
		local arrowInner_y = crankValue + ARROW_HEIGHT_START + sin(rad(time) * 0.5 + 0.4) * 4
		DRAW_IMAGE_STATIC(img_dropArrow_outer, SCREEN_HALF_WIDTH - ARROW_HALF_WIDTH, arrowOuter_y)
		DRAW_IMAGE_STATIC(img_dropArrow_inner, SCREEN_HALF_WIDTH - ARROW_HALF_WIDTH, arrowInner_y)
	end
end


-- Draw the Letter Cards above each save file w/ animated effects
local function drawSaveFileLetterCards(time, crank)

	local function easeCardHeight(cardY, index, startY)
		-- card selected - slide up
		if letterCard_index == index then
			if cardY > LETTERCARD_SELECTED_Y then
				local elapsedTime = (time - letterCard_startTime)
				cardY = floor( OUT_CUBIC(elapsedTime, startY, LETTERCARD_SELECTED_Y - startY, MENU_EASING_DURATION) )
			else 
				cardY = LETTERCARD_SELECTED_Y
			end

		-- card NOT selected - slide down
		else
			if cardY < LETTERCARD_UNSELECTED_Y and startY ~= 0 then 
				local elapsedTime = (time - letterCard_startTime)
				cardY = floor( OUT_CUBIC(elapsedTime, startY, LETTERCARD_UNSELECTED_Y - startY, MENU_EASING_DURATION) )
			else 
				cardY = LETTERCARD_UNSELECTED_Y
				startY = 0 -- tracking this 0 stops flickering w/ subtle crank changes
			end

		end
		return cardY, startY
	end

	aCardY, aCardStartY = easeCardHeight(aCardY, 1, aCardStartY)
	bCardY, bCardStartY = easeCardHeight(bCardY, 2, bCardStartY)
	cCardY, cCardStartY = easeCardHeight(cCardY, 3, cCardStartY)

	DRAW_IMAGE_STATIC(img_letterCard_A, BUBBLE_LEFT_X - LETTERCARD_HALF_WIDTH, aCardY + crank)
	DRAW_IMAGE_STATIC(img_letterCard_B, BUBBLE_MIDL_X - LETTERCARD_HALF_WIDTH, bCardY + crank)
	DRAW_IMAGE_STATIC(img_letterCard_C, BUBBLE_RGHT_X - LETTERCARD_HALF_WIDTH, cCardY + crank)
end


local function prepareLetterCardEasing(newIndex, time)
	letterCard_index = newIndex
	letterCard_startTime = time

	aCardStartY = aCardY
	bCardStartY = bCardY
	cCardStartY = cCardY
end


local function prepareCrankValueEasing(time, dirInput)
	if dirInput then 	dirInputDetected = true 
	else 				dirInputDetected = false
	end

	startTime = time
	startCrank = -floor(crankValue)
	returnToTitleCard = false
end


-- Allow cranking if nothing is selected, OR if there is any input, tween crankValue to startMenu height value.
local function handleCrankValue(time, crank)
	
	-- crank on startup
	if crank > 0 then
		local elapsedTime = time - startTime
		crankValue = floor( OUT_CUBIC(elapsedTime, CRANKVALUE_ON_STARTUP, 0 - CRANKVALUE_ON_STARTUP, TITLECARD_EASING_DURATION) )

		if crankValue == 0 then allowInput = true end -- allow input after title art is done moving into screen.

		return crankValue
	end


	-- crank for everything else
	local bkgrHeight = -SAVEBACKGROUND_HEIGHT

	-- if nothing is selected, but B-Button pressed, then move screen to the title card.
	if returnToTitleCard then 
		local elapsedTime = time - startTime
		crankValue = -floor( OUT_CUBIC(elapsedTime, startCrank, 0 - startCrank, MENU_EASING_DURATION) ) -- '0 - startCrank' = 'endV - startV'
		UPDATE_VERTICAL_DITHER_GRADIENT(-crankValue, CRANK_DITHER_DOT_START, CRANK_DITHER_DOT_END, CRANK_DITHER_DOT_OFFSET)

	-- if something is selected, but the menu isn't at the bottom, then move the screen to the bottom position for menu selection.
	elseif dirInputDetected and crank > bkgrHeight then 		
		local elapsedTime = time - startTime
		crankValue = -floor( OUT_CUBIC(elapsedTime, startCrank, SAVEBACKGROUND_HEIGHT - startCrank, MENU_EASING_DURATION) )
		if not menuItemSelected then
			UPDATE_VERTICAL_DITHER_GRADIENT(-crankValue, CRANK_DITHER_DOT_START, CRANK_DITHER_DOT_END, CRANK_DITHER_DOT_OFFSET)
		end

	-- allow cranking if no other input is detected
	elseif not menuItemSelected and not saveFileSelected then
		local crankChange = GET_CRANK_CHANGE()
		crank = crank - (crankChange * 0.3)
		crankValue = max( min(crank, 0), bkgrHeight)
		UPDATE_VERTICAL_DITHER_GRADIENT(-crankValue, CRANK_DITHER_DOT_START, CRANK_DITHER_DOT_END, CRANK_DITHER_DOT_OFFSET) 

	end

	if crankValue <= bkgrHeight then dirInputDetected = false end 	-- end of moving screen to menu
	if crankValue >= 0 then returnToTitleCard = false end 			-- end of moving screen to title card

	return crankValue
end


local function manageMenuInput(time)
	
	-- If a menu item was selected, or if input isn't allowed, then don't allow movement
	if menuItemSelected or not allowInput then 
		return
	end

	-- navigation
	if 		BUTTON_PRESSED(LEFT) then 
		prepareCrankValueEasing(time, true)
		if bubble_index == 8 or bubble_index == 9 then 
			bubble_index = UPDATE_BUBBLE_INDEX(bubble_index - 1)	
		end

	elseif 	BUTTON_PRESSED(RIGHT) then
		prepareCrankValueEasing(time, true)
		if bubble_index == 7 or bubble_index == 8 then 
			bubble_index = UPDATE_BUBBLE_INDEX(bubble_index + 1)
		end

	elseif 	BUTTON_PRESSED(UP) then
		prepareCrankValueEasing(time, true)
		if saveFileSelected then 			
			if bubble_index > 9 then 		-- Play -> Copy
				bubble_index = UPDATE_BUBBLE_INDEX(bubble_index - 6)
			elseif bubble_index > 3 then	-- Copy -> Delete
				bubble_index = UPDATE_BUBBLE_INDEX(bubble_index - 3)
			end
		end

	elseif 	BUTTON_PRESSED(DOWN) then
		prepareCrankValueEasing(time, true)
		if saveFileSelected then 			
			if bubble_index < 4 then 		-- Delete -> Copy
				bubble_index = UPDATE_BUBBLE_INDEX(bubble_index + 3)
			elseif bubble_index < 7 then	-- Copy -> Play
				bubble_index = UPDATE_BUBBLE_INDEX(bubble_index + 6)
			end
		end

	end
end


local function revertToSaveFileSelection()
	-- save slot 1
	if bubble_index == 1 or bubble_index == 4 or bubble_index == 10 then
		bubble_index = UPDATE_BUBBLE_INDEX(7)
		return
	end

	-- save slot 2
	if bubble_index == 2 or bubble_index == 5 or bubble_index == 11 then
		bubble_index = UPDATE_BUBBLE_INDEX(8)
		return
	end

	-- save slot 3
	if bubble_index == 3 or bubble_index == 6 or bubble_index == 12 then
		bubble_index = UPDATE_BUBBLE_INDEX(9)
		return
	end
end



-- +--------------------------------------------------------------+
-- |                   Commands, Action Updates                   |
-- +--------------------------------------------------------------+

--- Menu Commands ---
--------------------- 

-- Select a save file to play
local function commandSelectSaveFile(time)
	prepareLetterCardEasing(bubble_index - 6, time)
	bubble_index = UPDATE_BUBBLE_INDEX(bubble_index + 3) -- starts on first save select
	saveFileSelected = true
end

-- Play the associated save file
local function commandPlay()
	menuItemSelected = true
	runTransitionStart( GAMESTATE.mainmenu, TRANSITION_TYPE.growingCircles, mainMenu_StateStart, startMenu_ClearState )
	print("Playing save file: " .. "#")
end

-- Copy the associated save file to an empty save slot
local function commandCopy()
	menuItemSelected = true
end

-- Delete the associated save file
local function commandDelete()
	menuItemSelected = true
end


-- Array of commands when a menu item is selected.
-- Must be declared after all functions because of local scope.
local menuCommands = {
	commandDelete, commandDelete, commandDelete,
	commandCopy, commandCopy, commandCopy,
	commandSelectSaveFile, commandSelectSaveFile, commandSelectSaveFile,
	commandPlay, commandPlay, commandPlay	
}


--- Revert Menu Commands ---
----------------------------

local function revertSelect()
	returnToTitleCard = true -- nothing in menu selected, but cancel is requested - lerp back to title card
end

local function revertPlay(time)
	saveFileSelected = false
	prepareLetterCardEasing(0, time)
	revertToSaveFileSelection()
end

local function revertCopy(time)
	-- If inside the button (waiting for crank confirmation), then exit button selection, not save file selection.
	if menuItemSelected == true then 
		menuItemSelected = false
	
	-- Else exit the save file selection.
	else
		saveFileSelected = false
		prepareLetterCardEasing(0, time)
		revertToSaveFileSelection()
	end
end

local function revertDelete(time)
	-- If inside the button (waiting for crank confirmation), then exit button selection, not save file selection.
	if menuItemSelected == true then 
		menuItemSelected = false
	
	-- Else exit the save file selection.
	else
		saveFileSelected = false
		prepareLetterCardEasing(0, time)
		revertToSaveFileSelection()
	end
end


-- Array of commands when exiting from a menu item.
local revertCommands = {
	revertDelete, revertDelete, revertDelete,
	revertCopy, revertCopy, revertCopy,
	revertSelect, revertSelect, revertSelect,
	revertPlay, revertPlay, revertPlay	
}


--- Action Updates ---
----------------------

local function actionNull()

end

local function actionCopy(time)

	DRAW_CRANK_UI(CRANK_UI)

	-- end condition - if the action bar has reached its 'finished state', then end this updating action.
	if UPDATE_ACTION_BAR() == true then
		print(" -- COPY CONFIRMED -- ")
		APPLY_SELECTION_BUMP_FORCE()
		menuItemSelected = false
		saveFileSelected = false
		prepareLetterCardEasing(0, time)
		revertToSaveFileSelection()
	end
end

local function actionDelete(time)

	DRAW_CRANK_UI(CRANK_UI)

	-- end condition - if the action bar has reached its 'finished state', then end this updating action.
	if UPDATE_ACTION_BAR() == true then
		print(" -- DELETE CONFIRMED -- ")
		APPLY_SELECTION_BUMP_FORCE()
		menuItemSelected = false
		saveFileSelected = false
		prepareLetterCardEasing(0, time)
		revertToSaveFileSelection()
	end
end


-- Array of updates while a menu item is selected.
local actionUpdate = {
	actionDelete, actionDelete, actionDelete,
	actionCopy, actionCopy, actionCopy,
	actionNull, actionNull, actionNull,
	actionNull, actionNull, actionNull	
}


-- +--------------------------------------------------------------+
-- |                            Update                            |
-- +--------------------------------------------------------------+


function updateStartScreen(time)

	-- clear the screen before any drawing
	CLEAR_SCREEN()

	--- CRANKING ---
	local crank = handleCrankValue(time, crankValue)

	--- DRAWING ---
	-- Title Card
	drawTitleCard(time)

	-- Save Files
	DRAW_IMAGE_STATIC(img_SaveFilesBackground, 0, STARTSCREEN_HEIGHT + crank)

	-- Save File Options
	DRAW_IMAGE_STATIC(img_SaveFileOptionsText, 0, SAVEFILE_OPTIONS_TEXT_DRAW_Y + crank)

	-- Save File Letter Cards
	drawSaveFileLetterCards(time, crank)

	-- Selection Bubble
	manageMenuInput(time)
	local menuAboveBottom = (crank - 0.1) > MENU_BOTTOM_SCREEN_VALUE
	DRAW_SELECTION_BUBBLE(time, crank, menuItemSelected, menuAboveBottom)

	-- Crank Indicator - Needs to be drawn over the title card.
	if IS_CRANK_DOCKED() and 
		not menuItemSelected and 
		not saveFileSelected and 
		menuAboveBottom then

		DRAW_CRANK_UI(CRANK_UI)
	end


	--- INTERACTION ---
	-- Title Card

	-- Save File Select


	-- Save File Options - play, copy, delete, etc.
	-- go to 'Save Files' state
	if BUTTON_PRESSED(A_BUTTON) and allowInput then 
		-- do save file stuff here
		APPLY_SELECTION_BUMP_FORCE()
		prepareCrankValueEasing(time, true)
		menuCommands[ bubble_index ](time) 	
	end

	-- 'Cancel' button
	if BUTTON_PRESSED(B_BUTTON) and allowInput then
		prepareCrankValueEasing(time)
		revertCommands[ bubble_index ](time)
	end

	-- Action Update
	if menuItemSelected then
		actionUpdate[ bubble_index ](time)
	end

end





--[[
local gfx <const> = playdate.graphics

local screenWidth <const> = playdate.display.getWidth()
local screenHeight <const> = playdate.display.getHeight()
local halfScreenWidth <const> = screenWidth / 2
local halfScreenHeight <const> = screenHeight / 2

local blinking = false
local lastBlink = 0

--setup main menu
local startMenu = gfx.image.new('Resources/Sprites/menu/startMenu')
local startSprite = gfx.sprite.new(startMenu)
startSprite:setIgnoresDrawOffset(true)	-- forces sprite to be draw to screen, not world
--startSprite:setZIndex(ZINDEX.ui)
startSprite:moveTo(halfScreenWidth, halfScreenHeight)

--setup prompt
local promptImage = gfx.image.new('Resources/Sprites/menu/mainPrompt')
local promptSprite = gfx.sprite.new(promptImage)
promptSprite:setIgnoresDrawOffset(true)	-- forces sprite to be draw to screen, not world
--promptSprite:setZIndex(ZINDEX.uidetails)
promptSprite:moveTo(190, 212)


function openStartMenu()
	startSprite:add()
	promptSprite:add()
	blinking = true
	--print("paused")
end

function updateStartManu()
	local theCurrTime = getRunTime()
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

function closeStartMenu()
	startSprite:remove()
	if blinking == true then promptSprite:remove() end
	--print("unpaused")
end
]]