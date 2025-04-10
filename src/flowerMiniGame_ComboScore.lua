local pd 	<const> = playdate
local gfx 	<const> = pd.graphics
local geo 	<const> = pd.geometry

-- math
local dt 		<const> = getDT()
local sin 		<const> = math.sin
local max 		<const> = math.max 
local min 		<const> = math.min
local floor 	<const> = math.floor
local ceil 		<const> = math.ceil
local pi 		<const> = math.pi
local rescale 	<const> = rescaleRange_global

-- drawing
local NEW_IMAGE 			<const> = gfx.image.new
local NEW_IMAGE_TABLE		<const> = gfx.imagetable.new
local GET_IMAGE 			<const> = gfx.imagetable.getImage
local GET_SIZE_AT_PATH 		<const> = gfx.imageSizeAtPath
local DRAW_IMAGE_STATIC		<const> = gfx.image.drawIgnoringOffset
local SET_DRAW_MODE 		<const> = gfx.setImageDrawMode
local DRAW_MODE_FILL_WHITE	<const> = gfx.kDrawModeFillWhite
local DRAW_MODE_COPY 		<const> = gfx.kDrawModeCopy
local SET_FONT				<const> = gfx.setFont
local GET_TEXT_WIDTH		<const> = gfx.font.getTextWidth
local DRAW_TEXT 			<const> = gfx.drawText

local LOCK_FOCUS 			<const> = gfx.lockFocus
local UNLOCK_FOCUS 			<const> = gfx.unlockFocus

-- animation
local OUT_SINE				<const> = pd.easingFunctions.outSine
local IN_BACK 				<const> = pd.easingFunctions.inBack
local MOVE_TOWARDS 			<const> = moveTowards_global

-- globals
local PLAYER_GET_MULTIPLIER_TOKENS 	<const> = player_GetPlayerMultiplierTokens


-- +--------------------------------------------------------------+
-- |                            Render                            |
-- +--------------------------------------------------------------+

local font_smallText = font_Roobert_20
local font_largeText = font_Roobert_24 

local img_totalScore_Bkgr = nil 
local path_totalScore_Bkgr = 'Resources/Sprites/menu/FlowerGame/TotalScore_Background'
local TOTALSCORE_WIDTH, TOTALSCORE_HEIGHT <const> = GET_SIZE_AT_PATH(path_totalScore_Bkgr)
local TOTALSCORE_HEIGHT_HALF <const>  = TOTALSCORE_HEIGHT // 2

local imgTable_fireGradient = nil 
local path_fireGradient = 'Resources/Sprites/menu/FlowerGame/fire_CircleGradientList_v3'

local imgTable_fireNoise = nil
local path_fireNoise = 'Resources/Sprites/menu/FlowerGame/perlinNoise_FireLevels'
local img_fireCut = nil
local MAX_FIRE_NOISE_IMG 		<const> = 10
local MAX_FIRE_CUTS 			<const> = 10
local FIRE_CUT_HEIGHT 			<const> = 3 -- height in pixels for each slice of fire perlin images
local FIRE_WIDTH 				<const> = 110
local FIRE_CUT_VERT_OFFSET 		<const> = 45



-- +--------------------------------------------------------------+
-- |                     Variables and Arrays                     |
-- +--------------------------------------------------------------+

local enemyScore = 1
local wordScore = 0
local totalScore = 0

local validWord_Scoring = { 	-- change this list according to MAX_WORD_LENGTH and MIN_WORD_LENGTH
	1, 	--  1 - 3 letter word
	2,  --  2 - 4 letter word
	4,	--  3 - 5 letter word
	8, 	--  4 - 6 letter word
	16, --  5 - 7 letter word
	32, --  6 - 8 letter word
	64, --  7 - 9 letter word
	128 -- 8 - 10 letter word
}

local fireAddAmount = { 		-- each word size adds a set amount to total score fire amount
	0.2,
	0.4,
	0.6,
	1,
	1.5,
	3,
	5,
	9
}

local animProgress = 1
local ANIM_PROGRESS_SPEED 		<const> = 1.2 --0.65

local UPPER_TEXT_FREQUENCY 		<const> = 2 
local UPPER_TEXT_AMPLITUDE		<const> = 15

local TOTAL_SCORE_FREQUENCY 	<const> = 7 
local TOTAL_SCORE_AMPLITUDE 	<const> = 10

local enemyScore_progress = 0
local multText_progress = 0
local wordScore_progress = 0
local moneyText_progress = 0
local totalScore_progress = 0

local wordScore_textChange = false

local enemyScore_x = 0
local multText_x = 0
local wordScore_x = 0
local moneyText_x = 0
local totalScore_x = 0

local enemyScore_width = 0

local ENEMY_SCORE_DEFAULT_X		<const> = 5 
local MULT_TEXT_DEFAULT_X 		<const> = 10
local WORD_SCORE_DEFAULT_X 		<const> = 32
local MONEY_TEXT_DEFUALT_X 		<const> = 14
local TOTAL_SCORE_DEFAULT_X 	<const> = 36

local UPPER_TEXT_Y 				<const> = 3
local LOWER_TEXT_Y 				<const> = 45

-- Total Score Fire Anim
local fire_y = 0
local fireAmount = 0
local fireAmount_Target = 0
local fireGradientIndex = 1
local fireGradientTimer = 0
local fireAddAmountTimer = 0

local FIRE_GRADIENT_TIMER_SET 	<const> = 300
local FIRE_ADD_AMOUNT_TIMER_SET <const> = 3000
local FIRE_SPEED 				<const> = -60
local FIRE_INCREASE_RATE 		<const> = 3 * dt
local FIRE_DECREASE_RATE 		<const> = 0.8 * dt
local FIRE_AMOUNT_MIN 			<const> = -6
local FIRE_AMOUNT_MAX 			<const> = 4



-- +--------------------------------------------------------------+
-- |                        Helper Functions                      |
-- +--------------------------------------------------------------+

function getTotalScorePosition()
	return TOTAL_SCORE_DEFAULT_X, LOWER_TEXT_Y
end

function getTotalScore()
	return totalScore
end


-- +--------------------------------------------------------------+
-- |                      Init, Start, Clear                      |
-- +--------------------------------------------------------------+

function create_ComboScore()
	
	img_totalScore_Bkgr = NEW_IMAGE(path_totalScore_Bkgr)
	imgTable_fireGradient = NEW_IMAGE_TABLE(path_fireGradient)
	img_fireCut = NEW_IMAGE(FIRE_WIDTH, FIRE_CUT_HEIGHT)
	imgTable_fireNoise = NEW_IMAGE_TABLE(path_fireNoise)

	enemyScore = PLAYER_GET_MULTIPLIER_TOKENS()
	wordScore = 0
	totalScore = 0

	enemyScoreWidth = GET_TEXT_WIDTH(font_smallText, enemyScore) + ENEMY_SCORE_DEFAULT_X

	animProgress = 1
	enemyScore_progress = 0
	multText_progress = 0
	wordScore_progress = 0
	moneyText_progress = 0
	totalScore_progress = 0

	wordScore_textChange = false
	wordScore_newText = 0
	totalScore_textChange = false
	totalScore_newText = 0

	enemyScore_x = ENEMY_SCORE_DEFAULT_X
	multText_x = enemyScoreWidth + MULT_TEXT_DEFAULT_X
	wordScore_x = enemyScoreWidth + WORD_SCORE_DEFAULT_X
	moneyText_x = MONEY_TEXT_DEFUALT_X
	totalScore_x = TOTAL_SCORE_DEFAULT_X

	fireAmount = FIRE_AMOUNT_MIN
	fireAmount_Target = FIRE_AMOUNT_MIN
	fireGradientIndex = 1

	fireAddAmountTimer = 0
end


function clear_ComboScore()
	img_totalScore_Bkgr = nil
	imgTable_fireGradient = nil
	img_fireCut = nil
	imgTable_fireNoise = nil
end


-- +--------------------------------------------------------------+
-- |                             Draw                             |
-- +--------------------------------------------------------------+

function comboScore_applyNewWordScore(numLetters, time)

	-- if passed score is 0 then word is NOT valid, return false.
	if numLetters < 1 then return false end

	-- else word must be valid, so reset anims, apply new score and return true.
	animProgress = 0
	enemyScore_progress = 0
	multText_progress = 0
	wordScore_progress = 0
	moneyText_progress = 0
	totalScore_progress = 0

	wordScore_newText = wordScore + validWord_Scoring[numLetters]
	wordScore_textChange = false
	
	totalScore_newText = enemyScore * wordScore_newText
	totalScore_textChange = false

	-- add to total score fire amount
	if fireAmount_Target < fireAmount then 
		fireAmount_Target = fireAmount + fireAddAmount[numLetters]
	else
		fireAmount_Target += fireAddAmount[numLetters]
	end
	fireAmount_Target = min( max(fireAmount_Target, FIRE_AMOUNT_MIN), FIRE_AMOUNT_MAX )

	-- reset the 'add to fire amount' timer, which allows build-up of fire to happen
	fireAddAmountTimer = time + FIRE_ADD_AMOUNT_TIMER_SET

	return true
end


-- Fire change amount: increase and decrease
-- Small words add a small amount to target total; large words add large amount.
-- Lots of small words vs few large words will have same effect, so fire should be seen regularly.	
local function draw_FireAnimation(time)
	
	if fireAmount < fireAmount_Target then 
		fireAmount += FIRE_INCREASE_RATE

	-- Every time a word is submitted, the timer for the fire-decrease rate is reset, so that small words
	-- can slowly build up a fire over time.
	elseif fireAddAmountTimer < time and fireAmount > FIRE_AMOUNT_MIN then
		fireAmount_Target = FIRE_AMOUNT_MIN - 1
		fireAmount = fireAmount < FIRE_AMOUNT_MIN and FIRE_AMOUNT_MIN or max(fireAmount - FIRE_DECREASE_RATE, FIRE_AMOUNT_MIN)
	end

	-- pan noise upwards
	fire_y = fire_y + ((FIRE_SPEED - (fireAmount*4)) * dt)
	if fire_y < -128 then fire_y += 128	end

	-- Fire VFX - draw multiple cuts of different fire noises, depending on intensity of flames
	if fireAmount > FIRE_AMOUNT_MIN then
	local i = MAX_FIRE_CUTS
		while i > 0 do
			local index = i + floor(fireAmount)
			LOCK_FOCUS(img_fireCut)
				local slice_y = i * FIRE_CUT_HEIGHT + 40
				local noise_y = fire_y - slice_y + FIRE_CUT_VERT_OFFSET + 2
				index = min( max(index, 1), MAX_FIRE_NOISE_IMG)				
				DRAW_IMAGE_STATIC( GET_IMAGE(imgTable_fireNoise, index), 0, noise_y)
			UNLOCK_FOCUS()
			DRAW_IMAGE_STATIC(img_fireCut, -4, slice_y - 33) -- drawing 1 slice of fire
			i -= 1
		end
	end

	-- Draw circle gradient over fire
	-- This animates frame-by-frame via 'fireGradientTimer', which is a slow 4 frame animation.
	-- Helps round off the right edge of the fire, making it look more natural.
	if fireGradientTimer < time then 
		fireGradientTimer = time + FIRE_GRADIENT_TIMER_SET 
		fireGradientIndex = (fireGradientIndex < 4) and (fireGradientIndex + 1) or 1
	end
	DRAW_IMAGE_STATIC( GET_IMAGE(imgTable_fireGradient, fireGradientIndex), -4, 10) -- drawing gradient over fire
end


-- Score animations on score update, and image drawing
function draw_ComboScore(time)

	-- fire animation over total score
	draw_FireAnimation(time)

	-- animate all score text
	if animProgress < 1 then
		animProgress = min(animProgress + (ANIM_PROGRESS_SPEED * dt), 1)

		-- enemy score anim
		enemyScore_progress = min( rescale(animProgress, 0, 0.5, 0, 1), 1 )
		local decreaseAmp = 1 - enemyScore_progress
		enemyScore_x = (sin(pi * enemyScore_progress * UPPER_TEXT_FREQUENCY) * (UPPER_TEXT_AMPLITUDE * decreaseAmp)) + ENEMY_SCORE_DEFAULT_X

		-- mult 'x' anim
		multText_progress = min( max( rescale(animProgress, 0.1, 0.6, 0, 1), 0), 1 )
		decreaseAmp = 1 - multText_progress
		multText_x = (sin(pi * multText_progress * UPPER_TEXT_FREQUENCY) * (UPPER_TEXT_AMPLITUDE * decreaseAmp)) + MULT_TEXT_DEFAULT_X + enemyScoreWidth

		-- word score anim
		wordScore_progress = min( max( rescale(animProgress, 0.2, 0.7, 0, 1), 0 ), 1)
		decreaseAmp = 1 - wordScore_progress
		wordScore_x = (sin(pi * wordScore_progress * UPPER_TEXT_FREQUENCY) * (UPPER_TEXT_AMPLITUDE * decreaseAmp)) + WORD_SCORE_DEFAULT_X + enemyScoreWidth
		if wordScore_progress > 0 and wordScore_textChange == false then
			wordScore = wordScore_newText
			wordScore_textChange = true
		end

		-- money '$' anim
		moneyText_progress = min( rescale(animProgress, 0, 0.7, 0, 1), 1 )
		if moneyText_progress < 0.75 then
			local START = 0
			local FINISH = -12 - START
			local outProgress = rescale(moneyText_progress, 0, 0.75, 0, 1)
			moneyText_x = OUT_SINE(outProgress, START, FINISH, 1) + MONEY_TEXT_DEFUALT_X
		else
			local START = -12
			local FINISH = 0 - START
			local inProgress = rescale(moneyText_progress, 0.75, 1, 0, 1)
			moneyText_x = IN_BACK(inProgress, START, FINISH, 1) + MONEY_TEXT_DEFUALT_X
		end

		-- total score anim
		totalScore_progress = max( rescale(animProgress, 0.75, 1, 0, 1), 0)
		decreaseAmp = 1 - totalScore_progress
		totalScore_x = (sin(pi * totalScore_progress * TOTAL_SCORE_FREQUENCY) * (TOTAL_SCORE_AMPLITUDE * decreaseAmp)) + TOTAL_SCORE_DEFAULT_X
		if totalScore_progress > 0 and totalScore_textChange == false then 
			totalScore = totalScore_newText
			totalScore_textChange = true
		end
	end

	-- lower text banner
	DRAW_IMAGE_STATIC(img_totalScore_Bkgr, -3, 40)

	-- lower text - draw text black
	SET_FONT(font_largeText)
	DRAW_TEXT("$", 			moneyText_x, 	LOWER_TEXT_Y)
	DRAW_TEXT(totalScore, 	totalScore_x, 	LOWER_TEXT_Y)
	
	-- upper text - draw text white
	SET_DRAW_MODE(DRAW_MODE_FILL_WHITE) 
	SET_FONT(font_smallText)
	DRAW_TEXT(enemyScore, 	enemyScore_x, 	UPPER_TEXT_Y)
	DRAW_TEXT("x", 			multText_x, 	UPPER_TEXT_Y)
	DRAW_TEXT(wordScore, 	wordScore_x, 	UPPER_TEXT_Y)
	SET_DRAW_MODE(DRAW_MODE_COPY) 
end