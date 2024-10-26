local pd 	<const> = playdate
local gfx 	<const> = pd.graphics

-- math
local dt 		<const> = getDT()
local max 		<const> = math.max 
local min 		<const> = math.min

-- table
local concat 	<const> = table.concat

-- drawing
local LOCK_FOCUS 			<const> = gfx.lockFocus
local UNLOCK_FOCUS 			<const> = gfx.unlockFocus

local NEW_IMAGE 			<const> = gfx.image.new
local SET_MASK 				<const> = gfx.image.setMaskImage
local DRAW_IMAGE_STATIC		<const> = gfx.image.drawIgnoringOffset

local GET_SIZE 				<const> = gfx.image.getSize
local GET_SIZE_AT_PATH 		<const> = gfx.imageSizeAtPath
local CLEAR_IMAGE 			<const> = gfx.image.clear
local COLOR_CLEAR 			<const> = gfx.kColorClear
local SET_DRAW_MODE 		<const> = gfx.setImageDrawMode
local DRAW_MODE_FILL_WHITE	<const> = gfx.kDrawModeFillWhite
local DRAW_MODE_COPY 		<const> = gfx.kDrawModeCopy

local SET_FONT				<const> = gfx.setFont
local DRAW_TEXT 			<const> = gfx.drawText
local GET_TEXT_HEIGHT 		<const> = gfx.font.getHeight
local GET_TEXT_WIDTH		<const> = gfx.font.getTextWidth

local SET_COLOR 			<const> = gfx.setColor
local COLOR_WHITE 			<const> = gfx.kColorWhite

-- animation
local IN_QUAD			<const> = pd.easingFunctions.inQuad
local MOVE_TOWARDS			<const> = moveTowards_global

-- temp
local DRAW_RECT 			<const> = gfx.drawRect



-- +--------------------------------------------------------------+
-- |                            Render                            |
-- +--------------------------------------------------------------+

local font_ValidWords = font_FullCircle_12
local VALID_WORD_HEIGHT <const> = GET_TEXT_HEIGHT( font_ValidWords )

local img_wordListAll = nil
local img_wordListAllMask = nil 
local path_wordListMask = 'Resources/Sprites/menu/FlowerGame/VerticalGradient_wide'
local WORDLIST_WIDTH, WORDLIST_HEIGHT <const> = GET_SIZE_AT_PATH(path_wordListMask)

local img_wordList = setmetatable({}, {__mode = 'k'})



-- +--------------------------------------------------------------+
-- |                     Variables and Arrays                     |
-- +--------------------------------------------------------------+

local validWord_Crank = 0
local validWordCount = 0
local validWord_x = {}
local validWord_y = {}
local validWord_progress = {}
local validWord_progressSpeed = dt

local WORD_LIST_X 				<const> = 400 - WORDLIST_WIDTH
local WORD_LIST_Y				<const> = 0
local VALID_WORD_END_X 			<const> = 12
local VALID_WORD_START_Y 		<const> = WORDLIST_HEIGHT - VALID_WORD_HEIGHT - 6
local VALID_WORD_GAP 			<const> = -2
local VALID_WORD_LETTER_SPACING	<const> = 2
local WORDLIST_DITHER_HEIGHT 	<const> = 10
local WORDLIST_CRANK_SPEED 		<const> = 0.2
local WORDLIST_RETURN_SPEED 	<const> = 10



-- +--------------------------------------------------------------+
-- |                         Create, Clear                        |
-- +--------------------------------------------------------------+

function create_ValidWordList()
	img_wordListAll = NEW_IMAGE(WORDLIST_WIDTH, WORDLIST_HEIGHT)
	img_wordListAllMask = NEW_IMAGE(path_wordListMask)
	validWordCount = 0
end


function clear_ValidWordList()
	img_wordListMask = nil 
	for i = 1, validWordCount do
		img_wordList[i] = nil
	end
end



-- +--------------------------------------------------------------+
-- |                        List Functions                        |
-- +--------------------------------------------------------------+

function addValidWord(letterList, animSpeed)

	-- check if current selected letters make a valid word


	-- if no, reject


	-- else yes, add to the valid word list
	print("word list length: " .. #img_wordList)
	local i = #img_wordList + 1
	--local newWord = concat(selectedLetters)
	local newWord = concat(letterList)
	local newWord_width = GET_TEXT_WIDTH(font_ValidWords, newWord)
	img_wordList[i] = NEW_IMAGE(newWord_width, VALID_WORD_HEIGHT)
	validWord_x[i] = -newWord_width
	validWord_y[i] = VALID_WORD_START_Y
	validWord_progress[i] = 0
	validWord_progressSpeed = animSpeed
	validWordCount += 1

	LOCK_FOCUS(img_wordList[i])
		SET_FONT(font_ValidWords)
		SET_DRAW_MODE(DRAW_MODE_FILL_WHITE)
		DRAW_TEXT(newWord, 0, 0)
		SET_DRAW_MODE(DRAW_MODE_COPY)
	UNLOCK_FOCUS()

	-- word is valid, so return true
	return true
end



-- +--------------------------------------------------------------+
-- |                             Draw                             |
-- +--------------------------------------------------------------+

function draw_ValidWordList(crankChange, listControl)

	-- loop through all valid words, draw to the mask, then draw the mask over the words. 
	CLEAR_IMAGE(img_wordListAll, COLOR_CLEAR)
	LOCK_FOCUS(img_wordListAll)

		if listControl then 
			validWord_Crank += crankChange * WORDLIST_CRANK_SPEED
		else
			validWord_Crank = MOVE_TOWARDS(validWord_Crank, 0, WORDLIST_RETURN_SPEED)
		end

		local wordTotalHeight = validWordCount * VALID_WORD_HEIGHT
		local gapTotal = validWordCount * VALID_WORD_GAP
		local crankMax = max(wordTotalHeight + gapTotal - WORDLIST_HEIGHT + WORDLIST_DITHER_HEIGHT, 0)
		validWord_Crank = max( min(validWord_Crank, crankMax), 0)
		local crank = validWord_Crank
		
		-- draw all the words to the mask
		for i = 1, validWordCount do
			local VALID_WORD_MOVE_SPEED = 4

			-- move horizontal
			local progress = validWord_progress[i]
			if progress < 1 then
				progress = max( min(progress + validWord_progressSpeed, 1), 0 )
				validWord_progress[i] = progress
				local startX = -GET_SIZE(img_wordList[i])
				local finishX = VALID_WORD_END_X - startX
				validWord_x[i] = IN_QUAD(progress, startX, finishX, 1)
			end

			local index = validWordCount - i
			local targetY = ((VALID_WORD_HEIGHT + VALID_WORD_GAP) * -1) * index + VALID_WORD_START_Y
			validWord_y[i] = MOVE_TOWARDS(validWord_y[i], targetY, VALID_WORD_MOVE_SPEED)

			DRAW_IMAGE_STATIC(img_wordList[i], validWord_x[i], validWord_y[i] + crank)
		end

		-- set the mask
		SET_MASK(img_wordListAll, img_wordListAllMask)
		--DRAW_IMAGE_STATIC(img_wordListAllMask, 0, 0)

		-- temp test
		--SET_COLOR(COLOR_WHITE)
		--DRAW_RECT(0, 0, WORDLIST_WIDTH, WORDLIST_HEIGHT)

	UNLOCK_FOCUS()

	DRAW_IMAGE_STATIC(img_wordListAll, WORD_LIST_X, WORD_LIST_Y)
end