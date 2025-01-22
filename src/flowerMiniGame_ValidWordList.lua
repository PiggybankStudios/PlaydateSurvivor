local pd 	<const> = playdate
local gfx 	<const> = pd.graphics

-- math
local dt 		<const> = getDT()
local max 		<const> = math.max 
local min 		<const> = math.min
local floor 	<const> = math.floor

-- time
local GET_TIME 	<const> = pd.getCurrentTimeMilliseconds

-- table
local concat 	<const> = table.concat

-- file
local FILE_OPEN 	<const> = pd.file.open
local FILE_CLOSE 	<const> = pd.file.file.close
local FILE_READ 	<const> = pd.file.file.read

-- string
local TEXT_BYTE 	<const> = string.byte
local TEXT_CHAR 	<const> = string.char
local UPPER_CASE 	<const> = string.upper

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
local COLOR_BLACK 			<const> = gfx.kColorBlack

-- animation
local IN_QUAD			<const> = pd.easingFunctions.inQuad
local MOVE_TOWARDS			<const> = moveTowards_global

-- temp
local DRAW_RECT 			<const> = gfx.drawRect



-- +--------------------------------------------------------------+
-- |                            Render                            |
-- +--------------------------------------------------------------+

local font_ValidWords = font_FullCircle_12
local VALID_WORD_HEIGHT 		<const> = GET_TEXT_HEIGHT( font_ValidWords )
local VALID_WORD_HEIGHT_HALF	<const> = VALID_WORD_HEIGHT // 2

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
local VALID_WORD_MOVE_SPEED 	<const> = 4

-- Need to make a new WORDLIST_HEIGHT that allows for 15 words to be drawn to the word list
local WORDLIST_DRAW_HEIGHT 	<const> = WORDLIST_HEIGHT + VALID_WORD_HEIGHT * 3


-- +--------------------------------------------------------------+
-- |                          Dictionary                          |
-- +--------------------------------------------------------------+

local DICTIONARY_FILE_SIZE 	<const> = 50000
local BYTE_SPACE 			<const> = 10

local wordFilePaths = {
	'Resources/Dictionaries/common_words3.txt',
	'Resources/Dictionaries/common_words4.txt',
	'Resources/Dictionaries/common_words5.txt',
	'Resources/Dictionaries/common_words6.txt',
	'Resources/Dictionaries/common_words7.txt'
}
local NUMBER_OF_TEXT_FILES 	<const> = #wordFilePaths
local dictionary = {}
local dictionary_LastTime = 0

local submittedWordIDs = {}
local charIDs = { 
	A = 1,  B = 2,  C = 3,  D = 4,  E = 5,  F = 6,  G = 7,  H = 8,  I = 9,  J = 10, K = 11, L = 12, M = 13,
	N = 14, O = 15, P = 16, Q = 17, R = 18, S = 19, T = 20, U = 21, V = 22, W = 23, X = 24, Y = 25, Z = 26
}


local function dictionary_checkLetter(text, list, charIndex)

	local charByte = TEXT_BYTE(text, charIndex)
	local charLetter = UPPER_CASE( TEXT_CHAR(charByte) )

	-- If this char is a 'space', then don't return a deeper list - skip back to the dictionary.
	if charByte == BYTE_SPACE then 
		return dictionary
	end

	-- Check all the letters in the given list for a potential match.
	local listLength = #list
	for i = 1, listLength do
		if charLetter == list[i].letter then
			return list[i].nextLetters -- found a matching letter, end the search and traverse down next list.
		end
	end

	-- No match found, so add letter to end of this list and return the new node.
	-- If the next text character is a 'space' then mark this letter as a complete word.
	local completeWordBool = TEXT_BYTE(text, charIndex+1) == BYTE_SPACE and true or false
	--local completeWordBool = false
	local newSize = #list + 1
	list[newSize] = { letter = charLetter, completeWord = completeWordBool, nextLetters = {} }
	return list[newSize].nextLetters
end


-- NEED TO INITIALIZE IN COROUTINE - done on first load in 'main.lua'
function flowerMiniGame_initialize_dictionary()

	print("")
	print(" -- Initializing dictionary --")

	local checkingList = dictionary

	for i = 1, NUMBER_OF_TEXT_FILES do
		-- open this file and set the text
		local file = pd.file.open( wordFilePaths[i] )
		local text = file:read(DICTIONARY_FILE_SIZE)
		local textLength = #text 

		-- loop over the text and add to the dictionary list
		for charIndex = 1, textLength do
			checkingList = dictionary_checkLetter(text, checkingList, charIndex)
		end

		-- after this file's text has been added to the dictionary, close this file.
		file:close()

		-- print amount of time it took to finish this file's process.
		local finishTime = GET_TIME()
		local timeToComplete = finishTime - dictionary_LastTime
		print("- " .. wordFilePaths[i] .. " :: added to dictionary -- time to complete: " .. timeToComplete)
		dictionary_LastTime = finishTime

		-- yield(currentTaskCompleted, totalNumberOfTasks, loadDescription)
		coroutine.yield(i, NUMBER_OF_TEXT_FILES, "Initializing Dictionary")
	end

	print(" -- Dictionary Initialization Complete --")
	print("")
end


-- Printing Dictionary is used for debugging only

local function print_tree(node, previousLettersList, depthFromRoot)

	-- print this letter, it's depth from the root, and how many letters it's linked to.
	local list = node.nextLetters
	local listLength = #list

	-- increase the indentation to the line we're printing on based on this node's depth from the root
	local spaces = ""
	for i = 1, depthFromRoot do
		spaces = spaces .. "- "
	end

	-- make the string for previous letters
	local previousLetters = ""
	if #previousLettersList > 0 then
		previousLetters = "~" .. concat(previousLettersList, ", ") .. "~ "
	end

	-- create a new previousLetters list for all linked nodes
	local newList = {}
	for i = 1, #previousLettersList do
		newList[i] = previousLettersList[i]
	end
	newList[#newList+1] = node.letter 

	-- print this node's information
	if listLength == 0 then
		print(spaces .. previousLetters .. "[" .. node.letter .. "]" .. " **valid: " .. tostring(node.completeWord))
	else
		-- create a single string of the linked letters and print in a single line	
		local nextLettersTable = {}
		for i = 1, listLength do
			nextLettersTable[i] = node.nextLetters[i].letter
		end
		print(spaces .. previousLetters .. "[" .. node.letter .. "]" .. " : " .. concat(nextLettersTable, ", ") .. " **valid: " .. tostring(node.completeWord))
	end

	-- iterate over all of the letters this node is linked to, and print their information.
	for _, node in ipairs(node.nextLetters) do
		print_tree(node, newList, depthFromRoot+1)
	end
end


function print_dictionary()
	print("")
	print("-- print the dictionary --")

	print("dictionary length: " .. #dictionary)
	
	for i = 1, #dictionary do
		local node = dictionary[i]
		local depthFromRoot = 0
		print_tree(node, {}, depthFromRoot)
	end
end




-- +--------------------------------------------------------------+
-- |                         Create, Clear                        |
-- +--------------------------------------------------------------+

function create_ValidWordList()
	img_wordListAll = NEW_IMAGE(WORDLIST_WIDTH, WORDLIST_HEIGHT)
	img_wordListAllMask = NEW_IMAGE(path_wordListMask)
	validWordCount = 0

	submittedWordIDs = {} -- resetting the saved wordID list to be used again after being cleared by garbage collector.
end


function clear_ValidWordList()
	img_wordListMask = nil 
	for i = 1, #img_wordList do
		img_wordList[i] = nil
	end

	submittedWordIDs = nil

end



-- +--------------------------------------------------------------+
-- |                        List Functions                        |
-- +--------------------------------------------------------------+

-- Creates a unique numerical ID for the passed word, by combining all char alphabet positions into a string, then to a number.
-- No math is used, literally making a number from the given digits.
local function createWordID(letterList)

	local wordID = {}

	for i = 1, #letterList do
		local letter = letterList[i]
		wordID[i] = charIDs[letter]
	end

	return tonumber( concat(wordID) )
end


-- Determines if word has already been submitted by comparing wordID to the saved list.
local function checkIfSubmitted(wordID)

	for i = 1, #submittedWordIDs do
		print("wordID: " .. wordID .. " =? " .. submittedWordIDs[i])
		if wordID == submittedWordIDs[i] then
			print(" !! MATCH FOUND !!")
			return true
		end
	end

	return false
end


-- Determines if the word is in dictionaries.
local function confirmValidWord(letterList)
	print("Checking word: " .. concat(letterList))
	local list = dictionary

	-- loop through every letter in the passed letterList
	for i = 1, #letterList do
		local letter = letterList[i]
		local letterFound = false

		-- attempt to find a matching letter in the dictionary
		for k = 1, #list do

			print("::finding match for: " .. letter .. " - checking list letter: " .. list[k].letter ..
					" -- test match: " .. tostring(letter == list[k].letter))

			-- if there's a match...
			if letter == list[k].letter then 

				print(" - letter found: " .. letter)

				-- and this IS the end of the letterList, then return if this is a valid word.
				if i >= #letterList then
					return list[k].completeWord
				end

				-- else go to the next linked list if it exists, and exit this inner loop.
				list = list[k].nextLetters
				letterFound = true
				print("~~ FOUND LETTER, but not end of word. Going to next list. ~~")
				break

			end
		end

		-- After checking every linked letter, if a match was NOT found then this word does not exist in the dictionary. 
		if letterFound == false then
			return false
		end

	end
	
	-- after checking every letter, at this point the word does not exist in the dictionary. 
	return false
end


function addValidWord(letterList, animSpeed, minLetters)

	-- If no letters are passed, abort with 0 length.
	local validWordLength = #letterList - minLetters + 1
	if validWordLength < 1 then return 0 end

	-- check if current selected letters make a valid word
	local wordInDictionary = confirmValidWord(letterList)
	print(" -- wordInDictionary: " .. tostring(wordInDictionary))
	if wordInDictionary == false then 
		print(" ~NOT A VALID WORD~")
		return 0
	end

	-- check if word has already been submitted
	local wordID = createWordID(letterList)
	if checkIfSubmitted(wordID) == true then 
		print(" ~~WORD ALREADY SUBMITTED~~ ")
		return 0
	end

	-- else yes, add to the valid word list
	validWordCount += 1
	submittedWordIDs[validWordCount] = wordID

	local i = validWordCount
	local newWord = concat(letterList)
	local newWord_width = GET_TEXT_WIDTH(font_ValidWords, newWord)
	img_wordList[i] = NEW_IMAGE(newWord_width, VALID_WORD_HEIGHT)
	validWord_x[i] = -newWord_width
	validWord_y[i] = VALID_WORD_START_Y
	validWord_progress[i] = 0
	validWord_progressSpeed = animSpeed
	

	LOCK_FOCUS(img_wordList[i])
		SET_FONT(font_ValidWords)
		SET_DRAW_MODE(DRAW_MODE_FILL_WHITE)
		DRAW_TEXT(newWord, 0, 0)
		SET_DRAW_MODE(DRAW_MODE_COPY)
	UNLOCK_FOCUS()

	-- word is valid, so return number of letters.
	return validWordLength
end



-- +--------------------------------------------------------------+
-- |                             Draw                             |
-- +--------------------------------------------------------------+

function draw_ValidWordList(crankChange, listControl)

	-- loop through all valid words, draw to the mask, then draw the mask over the words. 
	CLEAR_IMAGE(img_wordListAll, COLOR_CLEAR)
	LOCK_FOCUS(img_wordListAll)

		-- If controlling the list, then allow crankChange to scroll through word list. 
		-- Else, return to end of word list when making new words.
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

		-- draw only visible words to the mask
		for i = 1, validWordCount do
		
			-- move word vertically
			local index = validWordCount - i
			local targetY = ((VALID_WORD_HEIGHT + VALID_WORD_GAP) * -1) * index + VALID_WORD_START_Y
			validWord_y[i] = MOVE_TOWARDS(validWord_y[i], targetY, VALID_WORD_MOVE_SPEED)
			local wordY = validWord_y[i] + crank

			-- IF the word can be seen, either moving into or out of view, then calc horizontal movement and draw word.
			if (wordY + VALID_WORD_HEIGHT) > 0 and wordY < WORDLIST_HEIGHT then

				local progress = validWord_progress[i]
				if progress < 1 then
					progress = max( min(progress + validWord_progressSpeed, 1), 0 )
					validWord_progress[i] = progress
					local startX = -GET_SIZE(img_wordList[i])
					local finishX = VALID_WORD_END_X - startX
					validWord_x[i] = IN_QUAD(progress, startX, finishX, 1)
				end
			
				DRAW_IMAGE_STATIC(img_wordList[i], validWord_x[i], validWord_y[i] + crank)
			end
		end

		-- set the mask
		SET_MASK(img_wordListAll, img_wordListAllMask)
	
	UNLOCK_FOCUS()

	DRAW_IMAGE_STATIC(img_wordListAll, WORD_LIST_X, WORD_LIST_Y)
end