local pd 	<const> = playdate
local gfx 	<const> = pd.graphics

-- math
local dt 		<const> = getDT()
local pi 		<const> = math.pi
local sin 		<const> = math.sin
local max 		<const> = math.max 
local min 		<const> = math.min
local random 	<const> = math.random

-- drawing
local NEW_IMAGE 			<const> = gfx.image.new
local NEW_IMAGE_TABLE		<const> = gfx.imagetable.new
local GET_IMAGE 			<const> = gfx.imagetable.getImage
local GET_SIZE_AT_PATH 		<const> = gfx.imageSizeAtPath
local DRAW_IMAGE_STATIC		<const> = gfx.image.drawIgnoringOffset
local CLEAR_IMAGE 			<const> = gfx.image.clear
local SET_MASK 				<const> = gfx.image.setMaskImage
local SET_FONT				<const> = gfx.setFont
local GET_TEXT_WIDTH		<const> = gfx.font.getTextWidth
local GET_TEXT_HEIGHT 		<const> = gfx.font.getHeight
local GET_FONT_TRACKING		<const> = gfx.font.getTracking

local DRAW_TEXT 			<const> = gfx.drawText
local FILL_RECT 			<const> = gfx.fillRect
local FILL_CIRCLE 			<const> = gfx.fillCircleAtPoint

local COLOR_BLACK 			<const> = gfx.kColorBlack
local COLOR_WHITE 			<const> = gfx.kColorWhite
local COLOR_CLEAR 			<const> = gfx.kColorClear
local SET_COLOR 			<const> = gfx.setColor
local SET_DITHER_PATTERN 	<const> = gfx.setDitherPattern
local DITHER_BAYER_4X4		<const> = gfx.image.kDitherTypeBayer4x4

local SCREEN_WIDTH 			<const> = pd.display.getWidth()
local SCREEN_HEIGHT 		<const> = pd.display.getHeight()

local LOCK_FOCUS 			<const> = gfx.lockFocus
local UNLOCK_FOCUS 			<const> = gfx.unlockFocus

local IN_EXPO 				<const> = pd.easingFunctions.inExpo
local OUT_QUART				<const> = pd.easingFunctions.outQuart

-- money
local GET_RUN_MONEY 		<const> = player_GetRunMoney
local ADD_TO_RUN_MONEY 		<const> = player_AddToRunMoney


-- +--------------------------------------------------------------+
-- |                            Render                            |
-- +--------------------------------------------------------------+

-- Fonts
local font_FlowerLetters 		= font_Roobert_24 
local FONT_FLOWER_LETTERS_HEIGHT 	<const> = GET_TEXT_HEIGHT(font_FlowerLetters)

-- White Out Mask
local img_whiteOut = nil 
local mask_whiteOut = nil

-- Circle Gradient
local img_circleGradient = nil 
local path_circleGradient = 'Resources/Sprites/menu/FlowerGame/CircleGradient'
local CIRCLE_GRADIENT_WIDTH <const>, CIRCLE_GRADIENT_HEIGHT <const> = GET_SIZE_AT_PATH(path_circleGradient)
local CIRCLE_GRADIENT_X <const> = (SCREEN_WIDTH//2) - (CIRCLE_GRADIENT_WIDTH//2)
local CIRCLE_GRADIENT_Y <const> = (SCREEN_HEIGHT//2) - (CIRCLE_GRADIENT_HEIGHT//2)

-- Drops Image
local img_drops = nil


-- +--------------------------------------------------------------+
-- |                     Variables and Arrays                     |
-- +--------------------------------------------------------------+

-- White Out States
whiteOutStates = {
	inactive = 1,
	whiteOutAnim = 2,
	numberAnim = 3,
	complete = 4
}
currentWhiteOutState = whiteOutStates.inactive

-- Countdown Timer Flag
local timerElapsed = false
local transitionToNextPhase = false
local transitionTimer = 0
local TRANSITION_TIMER_SET 	<const> = 1000

-- Final Score Screen White Out
local whiteOutMaskFinished = false
local whiteOutTimer = 0
local WHITE_OUT_TIMER_SET 			<const> = 1000
local WHITE_OUT_CIRCLE_RADIUS_MAX 	<const> = 400

local whiteOut_circle_one_x = 0 	-- randomly set at timer end
local WHITE_OUT_CIRCLE_ONE_Y 		<const> = 260
local WHITE_OUT_CIRCLE_TWO_X 		<const> = 440
local whiteOut_circle_two_y = 0 	-- randomly set at timer end

local totalScore = 0
local TOTAL_SCORE_START_X <const>, TOTAL_SCORE_START_Y <const> = getTotalScorePosition()
local totalScore_x = 0
local totalScore_y = 0
local totalScore_timer = 0
local TOTALSCORE_TIMER_SET 		<const> = 1000

local runMoney = 0
local runMoney_start_x = 0
local runMoney_start_y = 0
local runMoney_wobble = 0
local start_runMoney_wobble = false
local runMoneyDigits = {}
local digits_offset_x = {}
local digits_wobble_progress = {}
local numberOfDigits = 0

local DIGIT_WOBBLE_SPEED 				<const> = 0.8 * dt 
local DIGIT_VERTICAL_WOBBLE_FREQUENCY 	<const> = 7
local DIGIT_VERTICAL_WOBBLE_AMPLITUDE 	<const> = 15
local DIGIT_VERTICAL_WOBBLE_OFFSET 		<const> = 0.05

-- Circle Drops
local drops_count = 0
local drops_x = {}
local drops_y = {}
local drops_max_size = {}
local drops_progress = {}
local drops_radius_offset = {}

local DROPS_COUNT_MIN 			<const> = 1
local DROPS_COUNT_MAX 			<const> = 5
local DROPS_SIZE_MIN 			<const> = 50
local DROPS_SIZE_MAX 			<const> = 250
local DROPS_RADIUS_OFFSET_MIN	<const> = 2
local DROPS_RADIUS_OFFSET_MAX	<const> = 8
local DROPS_PROGRESS_OFFSET		<const> = 0.1
local DROPS_PROGRESS_SPEED 		<const> = 0.5 * dt


-- +--------------------------------------------------------------+
-- |                      Init, Start, Clear                      |
-- +--------------------------------------------------------------+

function create_WhiteOut()
	currentWhiteOutState = whiteOutStates.inactive
	timerElapsed = false
	transitionTimer = 0
	transitionToNextPhase = false
	whiteOutMaskFinished = false
	start_runMoney_wobble = false
	numberOfDigits = 0

	drops_count = 0

	img_whiteOut = NEW_IMAGE(SCREEN_WIDTH, SCREEN_HEIGHT)
	mask_whiteOut = NEW_IMAGE(SCREEN_WIDTH, SCREEN_HEIGHT, COLOR_BLACK)
	img_circleGradient = NEW_IMAGE(path_circleGradient)
	img_drops = NEW_IMAGE(SCREEN_WIDTH, SCREEN_HEIGHT, COLOR_CLEAR)
end


function clear_WhiteOut()
	img_whiteOut = nil
	mask_whiteOut = nil
	img_circleGradient = nil
	img_drops = nil
	for i = 1, numberOfDigits do
		runMoneyDigits[i] = nil
		digits_wobble_progress[i] = 0
	end
end


-- +--------------------------------------------------------------+
-- |                          Circle Drops                        |
-- +--------------------------------------------------------------+

local function createCircleDrops()

	drops_count = random(DROPS_COUNT_MIN, DROPS_COUNT_MAX)

	for i = 1, drops_count do
		drops_x[i] = random(0, SCREEN_WIDTH)
		drops_y[i] = random(0, SCREEN_HEIGHT)
		drops_max_size[i] = random(DROPS_SIZE_MIN, DROPS_SIZE_MAX)
		drops_radius_offset[i] = random(DROPS_RADIUS_OFFSET_MIN, DROPS_RADIUS_OFFSET_MAX)
		drops_progress[i] = -(i - 1) * DROPS_PROGRESS_OFFSET
	end
end


local function drawCircleDrops()
	
	for i = 1, drops_count do
		drops_progress[i] += DROPS_PROGRESS_SPEED
		local progress = min( max(drops_progress[i], 0), 1 )
		local radius = drops_max_size[i] * OUT_QUART(progress, 0, 1, 1)

		LOCK_FOCUS(img_drops)
			CLEAR_IMAGE(img_drops, COLOR_CLEAR)
			SET_COLOR(COLOR_BLACK)
			SET_DITHER_PATTERN(progress, DITHER_BAYER_4X4)
			FILL_CIRCLE(drops_x[i], drops_y[i], radius)
			SET_COLOR(COLOR_CLEAR)
			FILL_CIRCLE(drops_x[i], drops_y[i], radius - drops_radius_offset[i])

		LOCK_FOCUS(img_whiteOut)
			DRAW_IMAGE_STATIC(img_drops, 0, 0)
	end
	--UNLOCK_FOCUS() -- focus is unlocked in main draw function. The last focus here redirects back to img_whiteOut.
end


-- +--------------------------------------------------------------+
-- |                            Digits                            |
-- +--------------------------------------------------------------+

local function updateDigitImages()

	SET_FONT(font_FlowerLetters)

	runMoney = "$" .. tostring(GET_RUN_MONEY())
	numberOfDigits = #runMoney
	runMoney_start_x = (SCREEN_WIDTH // 2) - (GET_TEXT_WIDTH(font_FlowerLetters, runMoney) // 2)
	runMoney_start_y = (SCREEN_HEIGHT // 2) - (FONT_FLOWER_LETTERS_HEIGHT // 2)

	local fontTracking = GET_FONT_TRACKING(font_FlowerLetters)
	local previousWidth = 0
	for i = 1, numberOfDigits do
		local letter = string.sub(runMoney, i, i)
		local letterWidth = GET_TEXT_WIDTH(font_FlowerLetters, letter) + fontTracking
		digits_offset_x[i] = previousWidth
		previousWidth += letterWidth
		digits_wobble_progress[i] = -(i - 1) * DIGIT_VERTICAL_WOBBLE_OFFSET
		runMoneyDigits[i] = NEW_IMAGE(letterWidth, FONT_FLOWER_LETTERS_HEIGHT)
		LOCK_FOCUS(runMoneyDigits[i])
			DRAW_TEXT(letter, 0, 0)
	end
	UNLOCK_FOCUS()
end


local function singleDigitVerticalWobble(progress)
	local progress = min( max(progress, 0), 1 )
	return sin(progress * DIGIT_VERTICAL_WOBBLE_FREQUENCY * pi ) * DIGIT_VERTICAL_WOBBLE_AMPLITUDE * (1 - progress)
end


-- +--------------------------------------------------------------+
-- |                        Helper Functions                      |
-- +--------------------------------------------------------------+

function flowerGame_TimerHasElapsed(time, score)

	-- set whiteOut state
	currentWhiteOutState = whiteOutStates.whiteOutAnim

	-- set whiteOut mask
	timerElapsed = true
	whiteOutTimer = WHITE_OUT_TIMER_SET + time
	whiteOut_circle_one_x = random(40, SCREEN_WIDTH)
	whiteOut_circle_two_y = random(20, SCREEN_HEIGHT)
	SET_MASK(img_whiteOut, mask_whiteOut)
	
	-- set money text values and positions	
	updateDigitImages()
	totalScore = getTotalScore()
	totalScore_x = TOTAL_SCORE_START_X
	totalScore_y = TOTAL_SCORE_START_Y

	-- draw money text to whiteOut image
	LOCK_FOCUS(img_whiteOut)		
		SET_COLOR(COLOR_WHITE)
		FILL_RECT(0, 0, SCREEN_WIDTH, SCREEN_HEIGHT)		
		DRAW_TEXT(totalScore, totalScore_x, totalScore_y)
		for i = 1, numberOfDigits do
			DRAW_IMAGE_STATIC(runMoneyDigits[i], runMoney_start_x + digits_offset_x[i], runMoney_start_y)
		end
	UNLOCK_FOCUS()
end


-- +--------------------------------------------------------------+
-- |                            Update                            |
-- +--------------------------------------------------------------+

--- End of Timer Score
function draw_whiteOut(time)

	-- GUARD -- don't do anything if timer has not elapsed yet.
	if timerElapsed == false then
		return whiteOutStates.inactive
	end

	
	-- lerp 'White Out' mask to cover entire screen
	if whiteOutMaskFinished == false then
		local whiteOutPercent = 1 - max( (whiteOutTimer - time) / WHITE_OUT_TIMER_SET, 0)
		LOCK_FOCUS(mask_whiteOut)
			SET_COLOR(COLOR_WHITE)
			if whiteOutPercent < 1 then
				FILL_CIRCLE(whiteOut_circle_one_x, WHITE_OUT_CIRCLE_ONE_Y, WHITE_OUT_CIRCLE_RADIUS_MAX * whiteOutPercent)
				FILL_CIRCLE(WHITE_OUT_CIRCLE_TWO_X, whiteOut_circle_two_y, WHITE_OUT_CIRCLE_RADIUS_MAX * whiteOutPercent)
			else
				whiteOutMaskFinished = true
				currentWhiteOutState = whiteOutStates.numberAnim
				FILL_RECT(0, 0, SCREEN_WIDTH, SCREEN_HEIGHT)
				totalScore_timer = time + TOTALSCORE_TIMER_SET
			end
		UNLOCK_FOCUS()
		SET_MASK(img_whiteOut, mask_whiteOut)
		DRAW_IMAGE_STATIC(img_whiteOut, 0, 0)
		return currentWhiteOutState
	
	-- once whiteOut is fully visible, animate text positions
	else
		CLEAR_IMAGE(img_whiteOut, COLOR_WHITE)

		-- lerp 'TotalScore' into 'Current Money', with white circular gradient around 'Current Money'
		local totalScore_progress = 1 - max( (totalScore_timer - time) / TOTALSCORE_TIMER_SET, 0)
		totalScore_end_x = runMoney_start_x - TOTAL_SCORE_START_X
		totalScore_end_y = runMoney_start_y - TOTAL_SCORE_START_Y
		totalScore_x = IN_EXPO(totalScore_progress, TOTAL_SCORE_START_X, totalScore_end_x, 1)
		totalScore_y = IN_EXPO(totalScore_progress, TOTAL_SCORE_START_Y, totalScore_end_y, 1)

		-- increase 'Current Money' to new added amount and start runMoney digit wobble
		if totalScore_progress >= 0.95 and start_runMoney_wobble == false and transitionToNextPhase == false then
			start_runMoney_wobble = true
			runMoney = ADD_TO_RUN_MONEY(totalScore)
			updateDigitImages()
			createCircleDrops(time)
		end

		-- draw money text to whiteOut image
		LOCK_FOCUS(img_whiteOut)	
			SET_FONT(font_FlowerLetters)
			DRAW_TEXT(totalScore, totalScore_x, totalScore_y)
			drawCircleDrops(time)
			DRAW_IMAGE_STATIC(img_circleGradient, CIRCLE_GRADIENT_X, CIRCLE_GRADIENT_Y)			
			for i = 1, numberOfDigits do
				local runMoney_x = runMoney_start_x + digits_offset_x[i]
				local runMoney_y
				if start_runMoney_wobble then
					digits_wobble_progress[i] += DIGIT_WOBBLE_SPEED
					runMoney_y = runMoney_start_y + singleDigitVerticalWobble(digits_wobble_progress[i])
				else
					runMoney_y = runMoney_start_y
				end
				DRAW_IMAGE_STATIC(runMoneyDigits[i], runMoney_x, runMoney_y)
			end
		UNLOCK_FOCUS()

		-- once the last digit finishes its anims, then end all anim calcs AND return 'True' to start transition to next phase.
		if digits_wobble_progress[numberOfDigits] > 1 and transitionToNextPhase == false then
			start_runMoney_wobble = false 
			transitionToNextPhase = true
			transitionTimer = time + TRANSITION_TIMER_SET
		end

		DRAW_IMAGE_STATIC(img_whiteOut, 0, 0)
	end


	-- Once all animations are complete AND transition timer has passed, proceed to the next phase
	if transitionToNextPhase == true then
		if transitionTimer < time then
			currentWhiteOutState = whiteOutStates.complete
		end
	end

	return currentWhiteOutState
end