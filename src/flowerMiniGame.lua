local pd 	<const> = playdate
local gfx 	<const> = pd.graphics

-- math
local dt 		<const> = getDT()
local sin 		<const> = math.sin
local cos 		<const> = math.cos
local rad 		<const> = math.rad
local floor 	<const> = math.floor
local ceil 		<const> = math.ceil
local max 		<const> = math.max 
local min 		<const> = math.min
local random 	<const> = math.random
local pi 		<const> = math.pi

-- time
local GET_TIME 	<const> = pd.getCurrentTimeMilliseconds

-- table
local concat 	<const> = table.concat
local UNPACK 	<const> = table.unpack

-- string
local GET_CHAR 	<const> = string.sub

-- garbage collector
local COLLECT_GARBAGE 		<const> = collectgarbage

-- drawing
local LOCK_FOCUS 			<const> = gfx.lockFocus
local UNLOCK_FOCUS 			<const> = gfx.unlockFocus

local SET_DRAW_OFFSET	 	<const> = gfx.setDrawOffset
local CLEAR_SCREEN			<const> = gfx.clear

local NEW_IMAGE 			<const> = gfx.image.new
local NEW_ROTATED_IMAGE 	<const> = gfx.image.rotatedImage
local NEW_IMAGE_TABLE 		<const> = gfx.imagetable.new
local GET_IMAGE 			<const> = gfx.imagetable.getImage
local SET_MASK 				<const> = gfx.image.setMaskImage
local DRAW_IMAGE_STATIC		<const> = gfx.image.drawIgnoringOffset
local DRAW_IMAGE_SCALED		<const> = gfx.image.drawScaled
local DRAW_IMAGE_FADED 		<const> = gfx.image.drawFaded
local GET_IMAGE_ROTATED		<const> = gfx.image.rotatedImage
local GET_SIZE 				<const> = gfx.image.getSize
local GET_SIZE_AT_PATH 		<const> = gfx.imageSizeAtPath
local CLEAR_IMAGE 			<const> = gfx.image.clear
local COLOR_CLEAR 			<const> = gfx.kColorClear

local SET_DRAW_MODE 	<const> = gfx.setImageDrawMode
local DRAW_MODE_FILL_WHITE	<const> = gfx.kDrawModeFillWhite
local DRAW_MODE_NXOR 		<const> = gfx.kDrawModeNXOR
local DRAW_MODE_COPY 		<const> = gfx.kDrawModeCopy

local NEW_FONT 				<const> = gfx.font.new
local SET_FONT				<const> = gfx.setFont
local DRAW_TEXT 			<const> = gfx.drawText
local GET_GLYPH		 		<const> = gfx.font.getGlyph
local GET_TEXT_HEIGHT 		<const> = gfx.font.getHeight
local GET_TEXT_WIDTH		<const> = gfx.font.getTextWidth

local FILL_RECT 			<const> = gfx.fillRect
local FILL_CIRCLE 			<const> = gfx.fillCircleAtPoint
local DRAW_CIRCLE 			<const> = gfx.drawCircleAtPoint
local FILL_POLYGON 			<const> = gfx.fillPolygon
local SET_COLOR 			<const> = gfx.setColor
local COLOR_BLACK 			<const> = gfx.kColorBlack
local COLOR_WHITE 			<const> = gfx.kColorWhite
local DITHER_BAYER_4X4		<const> = gfx.image.kDitherTypeBayer4x4

local SCREEN_WIDTH 			<const> = pd.display.getWidth()
local SCREEN_HEIGHT 		<const> = pd.display.getHeight()

-- input
local GET_CRANK_POSITION	<const>	= pd.getCrankPosition
local GET_CRANK_CHANGE 		<const> = pd.getCrankChange
local BUTTON_PRESSED 		<const> = pd.buttonJustPressed
local UP 					<const> = pd.kButtonUp
local DOWN 					<const> = pd.kButtonDown
local LEFT 					<const> = pd.kButtonLeft
local RIGHT 				<const> = pd.kButtonRight
--local A_BUTTON 				<const> = pd.kButtonA
local B_BUTTON 				<const> = pd.kButtonB

-- animation
local IN_OUT_CUBIC 			<const> = pd.easingFunctions.inOutCubic
local OUT_IN_BACK 				<const> = pd.easingFunctions.outInBack
local OUT_IN_EXPO 				<const> = pd.easingFunctions.outInExpo
local IN_QUAD				<const> = pd.easingFunctions.inQuad
local MOVE_TOWARDS			<const> = moveTowards_global

-- temp
local DRAW_RECT 			<const> = gfx.drawRect

-- +--------------------------------------------------------------+
-- |                            Render                            |
-- +--------------------------------------------------------------+

local imgTable_FlowerMiniGame_TitleCard = gfx.imagetable.new('Resources/Sheets/Menu_FlowerGame/flowerTitleCard_Wobble')

local TITLECARD_FRAMES <const> = #imgTable_FlowerMiniGame_TitleCard


-- Fonts
local font_FlowerLetters 	= font_Roobert_24 
local font_ValidWords 		= font_Roobert_20 
local font_InputText 		= font_Onyx_9 

-- Input Icons, Input Text
local imgTable_InputIcons = nil 
local path_InputIcons = 'Resources/Sprites/menu/FlowerGame/FlowerGame_UI'

local img_InputText = nil
local img_InputText_Toggled = nil
local INPUTTEXT_WIDTH 		<const> = SCREEN_WIDTH
local INPUTTEXT_HEIGHT 		<const> = 16
local INPUTTEXT_Y 			<const> = 224
local INPUTTEXT_DRAWTEXT_Y 	<const> = 4

-- Flower Letters
local img_PetalArt = nil
local path_Petal = 'Resources/Sprites/menu/FlowerGame/Petal'
local img_PetalList = setmetatable({}, {__mode = 'k'})
local petalHalfWidth = {}
local petalHalfHeight = {}
local img_LetterList = setmetatable({}, {__mode = 'k'})
local letterHalfWidth = {}
local letterHalfHeight = {}

-- Selected Letters
local img_word = nil
local WORD_WIDTH 		<const> = 400
local WORD_WIDTH_HALF 	<const> = WORD_WIDTH // 2
local WORD_HEIGHT 		<const> = 100
local WORD_HEIGHT_HALF 	<const> = WORD_HEIGHT // 2

local img_underline = nil
local FLOWERTEXT_HEIGHT 		<const> = GET_TEXT_HEIGHT(font_FlowerLetters)
local FLOWERTEXT_HEIGHT_HALF 	<const> = FLOWERTEXT_HEIGHT // 2

-- Combo Score
local img_totalScore_Bkgr = nil 
local path_totalScore_Bkgr = 'Resources/Sprites/menu/FlowerGame/TotalScore_Background'
local TOTALSCORE_WIDTH, TOTALSCORE_HEIGHT <const> = GET_SIZE_AT_PATH(path_totalScore_Bkgr)
local TOTALSCORE_HEIGHT_HALF <const>  = TOTALSCORE_HEIGHT // 2


-- +--------------------------------------------------------------+
-- |                     Variables and Arrays                     |
-- +--------------------------------------------------------------+

local TITLECARD_WOBBLE_TIMER_SET <const> = 150
local titleCardWobbleTimer = 0
local titleCardIndex = 1

-- Letter Selector
local selector_index = 1
--local selector_x = 0
--local selector_y = 0

-- Letter Petals
local numLetters = 5

local letterList = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
local flowerLetters = {}

local flowerCenter_x = 0
local flowerCenter_y = 0
local petal_x = {}
local petal_y = {}
local letter_x = {}
local letter_y = {}

local FLOWER_CENTER_START_X <const> = 180
local FLOWER_CENTER_START_Y <const> = 85 

local petal_progress = {}
local petal_distance = {}
local petal_scale = {}

local PETAL_DISTANCE_CLOSE 	<const> = 50
local PETAL_DISTANCE_FAR	<const> = 60
local LETTER_DISTANCE_ADD	<const> = 6
local PETAL_MAX_SCALE 		<const> = 1.4

local PETAL_PROGRESS_SPEED_GROW 	<const> = 0.12
local PETAL_PROGRESS_SPEED_SHRINK 	<const> = -0.04

-- Selected Letters
local activeLetters = 0
local selectedLetters = {} -- a table of img_LetterList indices - only ints

local selectedLetter_x = {}
local selectedLetter_y = {}
local selectedLetter_progress = {}
local selectedLetter_startX = {}
local selectedLetter_targetX = {}
local selectedLetter_rotation = {}
local selectedLetter_rotationDir = {}
local selectedLetter_velX = {}
local selectedLetter_velY = {}
local selectedLetter_fade = {}
local selectedLetter_allowFade = {}

local underline_progress = 0
local underline_x = 0
local underline_startX = 0

local MAX_WORD_LENGTH 		<const> = 20
local WORD_DRAW_X 			<const> = 180
local WORD_DRAW_Y 			<const> = 180
local LETTER_SPACING 		<const> = 5
local LETTER_DRAW_Y 		<const> = (WORD_HEIGHT - FLOWERTEXT_HEIGHT) // 2
local LETTER_HIDE_Y 		<const> = 0
local LETTER_PROGRESS_SPEED <const> = 2 * dt
local LETTER_FADE_SPEED 	<const> = 1 * dt
local LETTER_ROTATE_HIDE	<const> = 30
local LETTER_ROTATE_SHOW	<const> = 0

-- Clear Word
local performClearWord = false
local UPWARD_FORCE_LOW 		<const> = 70
local UPWARD_FORCE_HIGH 	<const> = 110 
local LEFT_FORCE_LOW 		<const> = 30
local LEFT_FORCE_HIGH		<const> = 60 
local CLEAR_ROTATE_LOW 		<const> = 1 
local CLEAR_ROTATE_HIGH 	<const> = 3

local MAX_FALL_SPEED 		<const> = dt * 50
local GRAVITY 				<const> = dt * 9.8
local LETTER_OFFSCREEN_Y 	<const> = 120

-- Submit Word
local performWordSubmit = false
local wordIsValid = false
local ACCEPT_SLIDE_DISTANCE		<const> = 120
local REJECT_WOBBLE_FREQUENCY 	<const> = 8
local REJECT_WOBBLE_AMPLITUDE	<const> = 6

-- Minigame Scoring
local enemyScore = 0
local wordScore = 0
local totalScore = 0


-- Countdown Timer
local CREATE_COUNTDOWN_TIMER 	<const> = create_CountdownTimer
local CLEAR_COUNTDOWN_TIMER		<const> = clear_CountdownTimer
local DRAW_COUNTDOWN_TIMER 		<const> = draw_CountdownTimer


-- Valid Word List
local scrollValidWords = false
local CREATE_VALIDWORDLIST 		<const> = create_ValidWordList
local CLEAR_VALIDWORDLIST		<const> = clear_ValidWordList
local ADD_VALID_WORD		 	<const> = addValidWord
local DRAW_VALIDWORDLIST 		<const> = draw_ValidWordList



-- +--------------------------------------------------------------+
-- |                        Helper Functions                      |
-- +--------------------------------------------------------------+

local function getRandomLetter()
	local randLetter = math.random(1, #letterList)
	return GET_CHAR(letterList, randLetter, randLetter)
end



-- +--------------------------------------------------------------+
-- |                      Init, Start, Clear                      |
-- +--------------------------------------------------------------+

local function create_InputText()

	img_InputText = NEW_IMAGE(INPUTTEXT_WIDTH, INPUTTEXT_HEIGHT)
	img_InputText_Toggled = NEW_IMAGE(INPUTTEXT_WIDTH, INPUTTEXT_HEIGHT)
	imgTable_InputIcons = NEW_IMAGE_TABLE( path_InputIcons )

	LOCK_FOCUS(img_InputText)

		SET_FONT(font_InputText)
		SET_COLOR(COLOR_WHITE)
		FILL_RECT(0, 0, INPUTTEXT_WIDTH, INPUTTEXT_HEIGHT)

		DRAW_IMAGE_STATIC( GET_IMAGE(imgTable_InputIcons, 6), 10, 3)
		DRAW_TEXT("Toggle Scroll", 	25, INPUTTEXT_DRAWTEXT_Y)

		DRAW_IMAGE_STATIC( GET_IMAGE(imgTable_InputIcons, 5), 110, 3)
		DRAW_TEXT("Scroll", 		125,  INPUTTEXT_DRAWTEXT_Y)

		DRAW_IMAGE_STATIC( GET_IMAGE(imgTable_InputIcons, 4), 170, 3)
		DRAW_TEXT("Clear", 			185, INPUTTEXT_DRAWTEXT_Y)
	
		DRAW_IMAGE_STATIC( GET_IMAGE(imgTable_InputIcons, 1), 225, 3)
		DRAW_TEXT("Add", 			240, INPUTTEXT_DRAWTEXT_Y)
		
		DRAW_IMAGE_STATIC( GET_IMAGE(imgTable_InputIcons, 2), 270, 3)
		DRAW_TEXT("Remove", 		285, INPUTTEXT_DRAWTEXT_Y)

		DRAW_IMAGE_STATIC( GET_IMAGE(imgTable_InputIcons, 3), 335, 3)
		DRAW_TEXT("Submit", 		350, INPUTTEXT_DRAWTEXT_Y)


	LOCK_FOCUS(img_InputText_Toggled)
		SET_FONT(font_InputText)
		SET_COLOR(COLOR_WHITE)
		FILL_RECT(0, 0, INPUTTEXT_WIDTH, INPUTTEXT_HEIGHT)

		DRAW_IMAGE_STATIC( GET_IMAGE(imgTable_InputIcons, 6), 80, 3)
		DRAW_TEXT("Toggle Scroll", 95, INPUTTEXT_DRAWTEXT_Y)

		DRAW_IMAGE_STATIC( GET_IMAGE(imgTable_InputIcons, 5), 210, 3)
		DRAW_TEXT("Scroll Word List", 225, INPUTTEXT_DRAWTEXT_Y)


	UNLOCK_FOCUS()
end


local function create_FlowerLetters()

	img_PetalArt = NEW_IMAGE( path_Petal )

	-- set the flower center
	flowerCenter_x = FLOWER_CENTER_START_X
	flowerCenter_y = FLOWER_CENTER_START_Y

	-- init all petal lists, and...
	-- set the starting position for each petal, around the flower center
	local angle = 360 / numLetters
	local width, height
	for i = 1, numLetters do
	
		-- create the new, rotated, petal image
		img_PetalList[i] = NEW_ROTATED_IMAGE( img_PetalArt, angle * i - 90)
		width, height = GET_SIZE(img_PetalList[i])
		petalHalfWidth[i], petalHalfHeight[i] = width // 2, height // 2

		-- set the default values for this petal
		petal_progress[i] = 0
		petal_distance[i] = PETAL_DISTANCE_CLOSE
		petal_scale[i] = 1

		-- set the position of this petal
		local rad = rad(angle * i)
		local circleX = cos(rad)
		local circleY = sin(rad)
		petal_x[i] = PETAL_DISTANCE_CLOSE * circleX + flowerCenter_x
		petal_y[i] = PETAL_DISTANCE_CLOSE * circleY + flowerCenter_y
		letter_x[i] = PETAL_DISTANCE_CLOSE + LETTER_DISTANCE_ADD * circleX + flowerCenter_x
		letter_y[i] = PETAL_DISTANCE_CLOSE + LETTER_DISTANCE_ADD * circleY + flowerCenter_y

		-- select and setup the letters for this minigame
		local font = font_FlowerLetters
		flowerLetters[i] = getRandomLetter()
		img_LetterList[i] = GET_GLYPH(font, flowerLetters[i])
		letterHalfWidth[i] = GET_TEXT_WIDTH(font, flowerLetters[i]) // 2 -- GET_SIZE won't get true letter width
		letterHalfHeight[i] = GET_TEXT_HEIGHT(font) // 2
		
	end
end


local function create_SelectedLetters()

	activeLetters = 0

	for i = 0, MAX_WORD_LENGTH do
		selectedLetters[i] = 0
		selectedLetter_x[i] = WORD_WIDTH_HALF
		selectedLetter_y[i] = 0

		selectedLetter_startX[i] = WORD_WIDTH_HALF
		selectedLetter_targetX[i] = 0
		selectedLetter_rotation[i] = 0 
		selectedLetter_rotationDir[i] = 1

		selectedLetter_progress[i] = 0
		selectedLetter_fade[i] = 0
		selectedLetter_allowFade[i] = false

		selectedLetter_velX[i] = 0
		selectedLetter_velY[i] = 0

		underline_progress = 0
		underline_x = 0
		underline_startX = 0
	end

	img_underline = GET_GLYPH(font_FlowerLetters, "_")
	img_word = NEW_IMAGE(WORD_WIDTH, WORD_HEIGHT)
end


local function create_ComboScore()
	
	img_totalScore_Bkgr = NEW_IMAGE(path_totalScore_Bkgr)

	enemyScore = 0
	wordScore = 0
	totalScore = 0
end


function flowerMiniGame_StateStart()

	-- reset the draw offset so the selector boxes are drawn correctly
	SET_DRAW_OFFSET(0, 0)

	-- Created Images
	create_InputText()
	create_FlowerLetters()
	create_SelectedLetters()
	create_ComboScore()
	CREATE_COUNTDOWN_TIMER()
	CREATE_VALIDWORDLIST()

	-- Run the 'End Transition' animation
	runTransitionEnd()
end


local function flowerMiniGame_ClearState()

	-- Input Images
	img_InputText = nil
	img_InputText_Toggled = nil
	imgTable_InputIcons = nil

	-- Flower Images
	img_PetalArt = nil
	for i = 1, numLetters do 
		img_PetalList[i] = nil
		img_LetterList[i] = nil
	end

	-- Selected Letters
	img_word = nil 
	img_underline = nil

	-- Combo Score
	img_totalScore_Bkgr = nil

	-- Countdown Timer
	CLEAR_COUNTDOWN_TIMER()

	-- Valid Word List
	CLEAR_VALIDWORDLIST()


	print("flower minigame state cleared")

	-- Clean up all the data that was disconnected via being set to nil
	COLLECT_GARBAGE()
end



-- +--------------------------------------------------------------+
-- |                             Draw                             |
-- +--------------------------------------------------------------+

--- Flower Petals
-- move and draw each petal, around the flower center, with highlight and selection animations.
local function draw_FlowerLetters(crank, scrollWordList)

	local angle = 360 / numLetters
	local halfAngle = angle // 2

	-- Selector Index
	local adjustedCrank = crank - 90 - halfAngle
	if 		adjustedCrank > 360 then adjustedCrank -= 360
	elseif 	adjustedCrank < 0 then adjustedCrank += 360
	end
	local index = adjustedCrank // angle + 1

	for i = 1, numLetters do
		local rad = rad(angle * i)
		local circleX = cos(rad)
		local circleY = sin(rad)	

		-- Petal Animations
		local allowFocus = index == i and scrollWordList == false
		local change = allowFocus and PETAL_PROGRESS_SPEED_GROW or PETAL_PROGRESS_SPEED_SHRINK  -- a ? b : c
		local progress = max( min(petal_progress[i] + change, 1), 0)
		petal_progress[i] = progress
		if 0 < progress or progress < 1 then 
			petal_distance[i] = IN_OUT_CUBIC(progress, PETAL_DISTANCE_CLOSE, PETAL_DISTANCE_FAR - PETAL_DISTANCE_CLOSE, 1)
			petal_scale[i] = IN_OUT_CUBIC(progress, 1, PETAL_MAX_SCALE - 1, 1)
		end

		-- Petal
		local distance = petal_distance[i]
		local scale = petal_scale[i]
		petal_x[i] = (distance * circleX) + flowerCenter_x - (petalHalfWidth[i] * scale)
		petal_y[i] = (distance * circleY) + flowerCenter_y - (petalHalfHeight[i] * scale)
		if scale > 1 then
			DRAW_IMAGE_SCALED(img_PetalList[i], petal_x[i], petal_y[i], scale)
		else
			DRAW_IMAGE_STATIC(img_PetalList[i], petal_x[i], petal_y[i])
		end

		-- Letter
		letter_x[i] = ((distance + LETTER_DISTANCE_ADD) * circleX) + flowerCenter_x - letterHalfWidth[i]
		letter_y[i] = ((distance + LETTER_DISTANCE_ADD) * circleY) + flowerCenter_y - letterHalfHeight[i] + 3
		DRAW_IMAGE_STATIC(img_LetterList[i], letter_x[i], letter_y[i])
	end

	-- draw letter selector
	--SET_COLOR(COLOR_BLACK)
	--FILL_CIRCLE(selector_x, selector_y, 4)
	--SET_COLOR(COLOR_WHITE)
	--FILL_CIRCLE(selector_x, selector_y, 3)

	return index
end


--- Selected Letters
local function selectedLetters_updateMoveProgress()

	-- adjust progress for each letter, based on if it's active or not
	for i = 1, MAX_WORD_LENGTH do

		--if i <= activeLetters then
		if selectedLetter_progress[i] < 1 then
			selectedLetter_progress[i] = min(selectedLetter_progress[i] + LETTER_PROGRESS_SPEED, 1)
		end
	end

	-- adjust progress for the underline char
	underline_progress = min( underline_progress + LETTER_PROGRESS_SPEED, 1)
end


local function selectedLetters_resetMoveProgress(fadeOut)

	-- allow all letters to lerp to their new positions
	for i = 1, MAX_WORD_LENGTH do
		selectedLetter_progress[i] = 0
		selectedLetter_startX[i] = selectedLetter_x[i]
		if fadeOut == nil then  
			selectedLetter_startX[i] = WORD_WIDTH_HALF
			selectedLetter_fade[i] = 0
		end
	end
	underline_progress = 0
	underline_startX = underline_x

	-- clear any action bools
	performWordSubmit = false

	-- if no fadeOut is passed, skip.
	if fadeOut == nil then return end

	if fadeOut == true then
		selectedLetter_allowFade[activeLetters] = true 		-- if no fade index, then fade IN the last active letter
		selectedLetter_fade[activeLetters] = 0.05	
		selectedLetter_rotationDir[activeLetters] = random(0, 1) * 2 - 1 -- either -1 or 1, randomly chosen
	else 				
		selectedLetter_allowFade[activeLetters + 1] = true  -- fade OUT the letter after the active
		selectedLetter_fade[activeLetters + 1] = 0.95
		selectedLetter_rotationDir[activeLetters + 1] = random(0, 1) * 2 - 1
	end
end


local function selectedLetters_prepareWordSubmit()
	for i = 1, MAX_WORD_LENGTH do
		selectedLetter_progress[i] = 0
		selectedLetter_startX[i] = selectedLetter_x[i]
	end
	--underline_progress = 0
	--underline_startX = underline_x
end


local function selectedLetters_startClearWord()
	local x, y, rot
	for i = 1, activeLetters do
		x = random(LEFT_FORCE_LOW, LEFT_FORCE_HIGH)
		y = random(UPWARD_FORCE_LOW, UPWARD_FORCE_HIGH)
		selectedLetter_velX[i] = -x * dt
		selectedLetter_velY[i] = -y * dt
		selectedLetter_y[i] = LETTER_DRAW_Y

		rot = random(CLEAR_ROTATE_LOW, CLEAR_ROTATE_HIGH)
		selectedLetter_rotation[i] = 0
		selectedLetter_rotationDir[i] = (random(0, 1) * 2 - 1) * rot
	end
end


local function selectedLetters_getFinalLetterList()

	local finalLetterList = {}
	for i = 1, activeLetters do
		finalLetterList[i] = flowerLetters[ selectedLetters[i] ]
	end
	return finalLetterList
end


-- move and draw the letters that have been selected from the flower, below the flower 
local function draw_SelectedLetters()

	local letterX = 0

	CLEAR_IMAGE(img_word, COLOR_CLEAR)
	SET_DRAW_MODE(DRAW_MODE_FILL_WHITE) -- draw text white

	selectedLetters_updateMoveProgress()

	-- combine all selected letters into the word image
	LOCK_FOCUS(img_word)

		--SET_COLOR(COLOR_WHITE)
		--gfx.drawRect(0, 0, WORD_WIDTH, WORD_HEIGHT)

		-- Calculate the positions for all letters in the first loop, b/c letter widths are different
		for i = 1, activeLetters do
			local index = selectedLetters[i]
			selectedLetter_targetX[i] = WORD_WIDTH_HALF + letterX	
			letterX = (letterHalfWidth[index] * 2) + LETTER_SPACING + letterX
		end

		-- Draw all the letters, with calcluated total length of all characters, offset positions by half total length.
			-- adjust letter positions after target is calced, so all letters can lerp into new positions.
		local halfTotal = letterX // 2
		local lastLetterHeight = 500

		for i = 1, MAX_WORD_LENGTH do
		
			-- Clear Entire Word - knock letters up and leftwards, falling towards bottom of screen.
			if performClearWord then
				if i <= activeLetters then
					-- velocity
					local velX = selectedLetter_velX[i]
					local velY = selectedLetter_velY[i] + GRAVITY -- downward direction is positive, so need to add grav instead of subtract.
					selectedLetter_velX[i] = velX 
					selectedLetter_velY[i] = velY

					-- position
					local posX = selectedLetter_x[i] + velX 
					local posY = selectedLetter_y[i] + velY
					selectedLetter_x[i] = posX 
					selectedLetter_y[i] = posY

					-- rotation
					local rot = selectedLetter_rotation[i]
					rot = selectedLetter_rotationDir[i] + rot 
					selectedLetter_rotation[i] = rot

					-- once last letter is out of sight, then stop clearing word.
					if lastLetterHeight > posY then lastLetterHeight = posY end
					if lastLetterHeight > LETTER_OFFSCREEN_Y then 
						performClearWord = false
						activeLetters = 0
						underline_startX = underline_x
						underline_progress = 0
					end

					-- reset x position once offscreen
					if posY > LETTER_OFFSCREEN_Y then 
						selectedLetter_x[i] = WORD_WIDTH_HALF
					end

					local index = selectedLetters[i]
					DRAW_IMAGE_STATIC( GET_IMAGE_ROTATED(img_LetterList[index], rot), posX, posY) -- getting rotated keeps image at same center
				end

			-- Draw Faded Letter
			elseif selectedLetter_allowFade[i] == true then
				-- move letter to new position
				local progress = selectedLetter_progress[i]
				local start = selectedLetter_startX[i]
				local target = selectedLetter_targetX[i] - halfTotal
				local x = IN_OUT_CUBIC(progress, start, target - start, 1)
				selectedLetter_x[i] = x

				-- adjust fade value and vertical position
				local fadeTarget = i <= activeLetters and 1 or -1  -- a ? b : c
				local fadeProgress = (LETTER_FADE_SPEED * fadeTarget) + selectedLetter_fade[i]
				fadeProgress = min( max(fadeProgress, 0), 1 )
				selectedLetter_fade[i] = fadeProgress
				local y = IN_OUT_CUBIC(fadeProgress, LETTER_HIDE_Y, LETTER_DRAW_Y, 1)

				-- when fade is at either extreme, stop allowing fade.
				if fadeProgress <= 0 or fadeProgress >= 1 then 
					selectedLetter_allowFade[i] = false					
				end

				-- adjust letter rotation
				local hide = LETTER_ROTATE_HIDE * selectedLetter_rotationDir[i]
				local show = LETTER_ROTATE_SHOW - hide
				selectedLetter_rotation[i] = IN_OUT_CUBIC(fadeProgress, hide, show, 1)
				
				-- draw faded letter with rotation
				local index = selectedLetters[i]
				local rotatedLetter = GET_IMAGE_ROTATED(img_LetterList[index], selectedLetter_rotation[i])
				DRAW_IMAGE_FADED(rotatedLetter, x, y, fadeProgress, DITHER_BAYER_4X4)		

			-- Submit Word
			elseif performWordSubmit then

				if activeLetters < 1 then
					performWordSubmit = false

				elseif i <= activeLetters then
					local index = selectedLetters[i]
					local progress = selectedLetter_progress[i]
					local animX

					-- word is valid - slide right towards word list and fade away
					if wordIsValid == true then 
						local start = selectedLetter_startX[i]
						local finish = selectedLetter_startX[i] + ACCEPT_SLIDE_DISTANCE - start
						animX = IN_QUAD(progress, start, finish, 1)
						DRAW_IMAGE_FADED(img_LetterList[index], animX, LETTER_DRAW_Y, (1-progress), DITHER_BAYER_4X4)

					-- invalid word - calculate wobble	
					else 				
						local amplitude = sin((0.5* pi * progress) + (0.5 * pi)) * REJECT_WOBBLE_AMPLITUDE
						animX = sin(REJECT_WOBBLE_FREQUENCY * pi * progress) * amplitude + selectedLetter_x[i]
						DRAW_IMAGE_STATIC(img_LetterList[index], animX, LETTER_DRAW_Y)
					end

					-- Once progress is completed, exit word wobble
					if progress >= 1 then
						performWordSubmit = false
						if wordIsValid == true then activeLetters = 0 end -- if word is accepted, then clear all letters.
					end
				end

			-- Draw Solid Letter
			elseif i <= activeLetters then
				-- move letter to new position
				local progress = selectedLetter_progress[i]
				local start = selectedLetter_startX[i]
				local target = selectedLetter_targetX[i] - halfTotal
				local x = IN_OUT_CUBIC(progress, start, target - start, 1)
				selectedLetter_x[i] = x

				-- draw letter
				local index = selectedLetters[i]
				DRAW_IMAGE_STATIC(img_LetterList[index], x, LETTER_DRAW_Y)

			end
		end

		-- always draw underline after selected letters
		if activeLetters < MAX_WORD_LENGTH then
			local target = halfTotal + WORD_WIDTH_HALF - underline_startX
			underline_x = IN_OUT_CUBIC(underline_progress, underline_startX, target, 1)
			DRAW_IMAGE_STATIC(img_underline, underline_x, LETTER_DRAW_Y)
		end

	UNLOCK_FOCUS()
	SET_DRAW_MODE(DRAW_MODE_COPY)

	-- draw the word image
	local wordY = WORD_DRAW_Y - LETTER_DRAW_Y
	DRAW_IMAGE_STATIC(img_word, 0, wordY)
end


--- Combo Scoring
local function draw_ComboScore()

	SET_DRAW_MODE(DRAW_MODE_FILL_WHITE) -- draw text white
	SET_FONT(font_ValidWords)
	local comboString = {enemyScore, " x ", wordScore}
	DRAW_TEXT(concat(comboString), 6, 3)

	SET_DRAW_MODE(DRAW_MODE_COPY) -- draw text black
	DRAW_IMAGE_STATIC(img_totalScore_Bkgr, -3, 35)
	SET_FONT(font_FlowerLetters)
	DRAW_TEXT("$", 4, 40)
	DRAW_TEXT(totalScore, 24, 40)
end



-- +--------------------------------------------------------------+
-- |                            Update                            |
-- +--------------------------------------------------------------+

function updateFlowerMinigame(time)

	-- clear the screen before any drawing
	CLEAR_SCREEN()

	--- CRANKING ---
	-- move letter selector	
	local crank = GET_CRANK_POSITION()
	local crankChange = GET_CRANK_CHANGE()
	--selector_x = cos(rad(crank-90)) * PETAL_DISTANCE_CLOSE + flowerCenter_x
	--selector_y = sin(rad(crank-90)) * PETAL_DISTANCE_CLOSE + flowerCenter_y


	--- DRAWING ---
	---------------
	-- Title Card Wobble
	--if titleCardWobbleTimer < time then 
	--	titleCardWobbleTimer = time + TITLECARD_WOBBLE_TIMER_SET
	--	titleCardIndex = titleCardIndex % TITLECARD_FRAMES + 1
	--end

	--local image = GET_IMAGE(imgTable_FlowerMiniGame_TitleCard, titleCardIndex)
	--DRAW_IMAGE_STATIC(image, 0, 0)

	-- Combo Score
	draw_ComboScore()

	-- Countdown Timer
	DRAW_COUNTDOWN_TIMER(time)

	-- Valid Word List
	DRAW_VALIDWORDLIST(crankChange, scrollValidWords)

	-- Flower Letters
	local letterIndex = draw_FlowerLetters(crank, scrollValidWords)

	-- Selected Letters
	draw_SelectedLetters()


	--- INTERACTION ---
	-------------------
	-- Scroll Word List --
	if scrollValidWords then
		DRAW_IMAGE_STATIC(img_InputText_Toggled, 0, INPUTTEXT_Y) -- draw instructions

		-- toggle TO selecting flower letters
		if BUTTON_PRESSED(B_BUTTON) then
			scrollValidWords = not scrollValidWords
		end

	-- Select Letters --
	else
		DRAW_IMAGE_STATIC(img_InputText, 0, INPUTTEXT_Y) -- draw instructions

		if not performClearWord and not performWordSubmit then

			-- select letter
			if BUTTON_PRESSED(DOWN) then 
				activeLetters = min(activeLetters + 1, MAX_WORD_LENGTH)
				selectedLetters[activeLetters] = letterIndex
				selectedLetters_resetMoveProgress(true) 	-- fade in the last letter
			end

			-- remove letter
			if BUTTON_PRESSED(UP) and activeLetters > 0 then
				activeLetters = max(activeLetters - 1, 0) -- only need to reduce index - letters will overwrite on new selection
				selectedLetters_resetMoveProgress(false) -- fade out the letter after last active
			end

			-- submit word
			if BUTTON_PRESSED(RIGHT) then 
				--selectedLetters_resetMoveProgress() -- skip letter fading, so no param
				selectedLetters_prepareWordSubmit()
				performWordSubmit = true 			-- setting action bool AFTER reset, b/c reset sets all action bools to false
				wordIsValid = ADD_VALID_WORD( selectedLetters_getFinalLetterList(), LETTER_PROGRESS_SPEED )
			end

			-- clear word
			if BUTTON_PRESSED(LEFT) and activeLetters > 0 then
				selectedLetters_resetMoveProgress()
				selectedLetters_startClearWord()
				performClearWord = true
			end

		end

		-- toggle TO scrolling word list
		if BUTTON_PRESSED(B_BUTTON) then
			scrollValidWords = not scrollValidWords
		end

		-- skip to 'New Weapon' menu
		if pd.buttonJustPressed(pd.kButtonA) then 
			runTransitionStart( GAMESTATE.newWeaponMenu, TRANSITION_TYPE.growingCircles, newWeaponMenu_StateStart, flowerMiniGame_ClearState )
		end
	end

end