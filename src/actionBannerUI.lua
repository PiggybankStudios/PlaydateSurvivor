local pd 	<const> = playdate
local gfx 	<const> = pd.graphics

-- time
local GET_TIME 				<const> = pd.getCurrentTimeMilliseconds

-- table
local CONCAT 				<const> = table.concat
local UNPACK 				<const> = table.unpack

-- math
local dt 					<const> = getDT()
local random 				<const> = math.random
local max 					<const> = math.max
local min 					<const> = math.min
local sin 					<const> = math.sin
local pi 					<const> = math.pi
local sqrt 					<const> = math.sqrt

-- drawing
local DRAW_IMAGE_STATIC		<const> = gfx.image.drawIgnoringOffset
local GET_SIZE_AT_PATH 		<const> = gfx.imageSizeAtPath
local GET_SIZE 				<const> = gfx.image.getSize
local NEW_IMAGE 			<const> = gfx.image.new
local NEW_IMAGE_TABLE 		<const> = gfx.imagetable.new
local SET_MASK 				<const> = gfx.image.setMaskImage

local LOCK_FOCUS 			<const> = gfx.lockFocus
local UNLOCK_FOCUS 			<const> = gfx.unlockFocus
local SET_COLOR 			<const> = gfx.setColor
local COLOR_WHITE 			<const> = gfx.kColorWhite
local COLOR_BLACK 			<const> = gfx.kColorBlack
local COLOR_CLEAR			<const> = gfx.kColorClear
local FILL_RECT 			<const> = gfx.fillRect
local DRAW_POLYGON 			<const> = gfx.drawPolygon
local FILL_POLYGON			<const> = gfx.fillPolygon
local CLEAR_IMAGE 			<const> = gfx.image.clear

local SET_FONT				<const> = gfx.setFont
local DRAW_TEXT 			<const> = gfx.drawText
local GET_GLYPH		 		<const> = gfx.font.getGlyph
local GET_TEXT_HEIGHT 		<const> = gfx.font.getHeight
local GET_TEXT_WIDTH		<const> = gfx.font.getTextWidth
local SET_DRAW_MODE 		<const> = gfx.setImageDrawMode
local DRAW_MODE_FILL_WHITE	<const> = gfx.kDrawModeFillWhite
local DRAW_MODE_COPY 		<const> = gfx.kDrawModeCopy

local SCREEN_WIDTH_HALF 	<const> = 200

local GET_DRAW_OFFSET 		<const> = gfx.getDrawOffset

-- animation
local IN_OUT_QUAD			<const> = pd.easingFunctions.inOutQuad
local OUT_QUAD 				<const> = pd.easingFunctions.outQuad



-- +--------------------------------------------------------------+
-- |                            Render                            |
-- +--------------------------------------------------------------+

-- fonts
local font_banner = font_FullCircle_12

-- banner
local img_uiBanner 	= nil
local path_uiBanner = 'Resources/Sprites/UIBanner'
local UI_BANNER_WIDTH <const>, UI_BANNER_HEIGHT <const> = GET_SIZE_AT_PATH(path_uiBanner)
local UI_BANNER_HEIGHT_HALF <const>	= UI_BANNER_HEIGHT // 2

-- banner text
local img_levelText = nil 
local LEVEL_TEXT_WIDTH 		<const> = 100
local LEVEL_TEXT_HEIGHT 	<const> = GET_TEXT_HEIGHT( font_banner )
local LEVEL_TEXT_X 			<const> = 101
local LEVEL_TEXT_Y 			<const> = 10

-- exp bar, fill, end cap
local img_expBarBorder = nil 
local img_expBarFill = nil
local path_expBarBorder = 'Resources/Sheets/ActionBanner/expBar'
local EXP_BAR_WIDTH <const>, EXP_BAR_HEIGHT <const> = GET_SIZE_AT_PATH(path_expBarBorder)
local EXP_BAR_WIDTH_HALF 	<const> = EXP_BAR_WIDTH // 2
local FILL_WIDTH 			<const> = EXP_BAR_WIDTH - 4
local FILL_WIDTH_HALF 		<const> = FILL_WIDTH // 2

local img_endCap = nil 
local path_endCap = 'Resources/Sheets/ActionBanner/expBarEndCap'
local END_CAP_WIDTH 		<const> = GET_SIZE_AT_PATH(path_endCap)
local END_CAP_WIDTH_HALF 	<const> = END_CAP_WIDTH // 2

local EXP_BAR_X <const> = SCREEN_WIDTH_HALF - EXP_BAR_WIDTH_HALF
local EXP_BAR_Y <const> = 3

-- petals
local img_petalList = setmetatable({}, {__mode = 'k'})
local imgTable_petals = nil 
local path_petals = 'Resources/Sheets/ActionBanner/Petals'
local PETAL_X_MIN 	<const> = 15 
local PETAL_X_MAX 	<const> = 105 
local PETAL_Y 		<const> = 0
local PETAL_WIDTH_HALF 	<const> = 9 	-- manually set since this is from an imageTable
local PETAL_HEIGHT_HALF	<const> = 12

-- Multiplier Tokens
local img_multiplierToken = nil 
local path_multiplierToken = 'Resources/Sheets/ActionBanner/MultiplierToken'
local MULTIPLIER_TOKEN_WIDTH 	<const> = GET_SIZE_AT_PATH(path_multiplierToken)
local MULTIPLIER_TOKEN_START_X 	<const> = 410
local MULTIPLIER_TOKEN_END_X 	<const> = 155
local MULTIPLIER_TOKEN_Y 		<const> = 11



-- +--------------------------------------------------------------+
-- |                     Variables and Arrays                     |
-- +--------------------------------------------------------------+

local expPercent = 0
local currentLevel = 0

-- Exp Bar
local bar_time = 0 
local allowBarUpdate = false 
local oldPercent = 0
local currentPercent = 0
local newPercent = 0
local BAR_TIME_SET 	<const> = 500

-- Petals
local collectedPetals = 0
local petals_x = {}
local petals_y = {}
local petalWidth = 0
local petalHeight = 0
local petalHalfWidth = 0
local petalHalfHeight = 0

local perform_petal_bar_anims = false
local allow_petal_anim_updates = false
local petal_progress = 0
local PETAL_ANIM_SPEED 					<const> = 2 * dt
local PETAL_WOBBLE_SPEED 				<const> = 1.4 * dt 
local PETAL_VERTICAL_WOBBLE_FREQUENCY 	<const> = 6
local PETAL_VERTICAL_WOBBLE_AMPLITUDE 	<const> = 7
local PETAL_VERTICAL_WOBBLE_OFFSET 		<const> = 0.1
local petal_wobble_progress = {}
local start_x 	= {}
local start_y 	= {}
local end_x 	= {}
local end_y 	= {}
local pickup_x 	= {}
local pickup_y 	= {}
local petal_magnet_time = {}
local petal_magnet_perform = {}
local petal_arc_amount = {}

local MAGNET_TIME_SET 					<const> = 700
local ARC_DISTANCE_MIN 					<const> = 20
local ARC_DISTANCE_MAX 					<const> = 90

-- Collected Item Paths
local itemPathsCount = 0
local itemPathsUpdateTracker = 0
local itemPaths_x = {}
local itemPaths_y = {}
local itemPaths_arc_x = {}
local itemPaths_arc_y = {}
local itemPaths_progress = {}
local itemPaths_polygon = {}
local ITEM_PATHS_LENGTH		<const> = 8
local ITEM_PATHS_MAX_WIDTH 	<const> = 10

-- Multiplier Tokens
local totalTokens = 0
local allowTokenUpdate = false
local token_x 		= {}
local token_time 	= {}
local TOKEN_TIME_SET 					<const> = 1000


-- +--------------------------------------------------------------+
-- |                         Create, Clear                        |
-- +--------------------------------------------------------------+

function create_ActionBannerUI()
	-- banner
	img_uiBanner = NEW_IMAGE(path_uiBanner)
	img_levelText = NEW_IMAGE(LEVEL_TEXT_WIDTH, LEVEL_TEXT_HEIGHT)

	-- exp bar
	oldPercent, currentPercent, newPercent = 0, 0, 0
	img_expBarBorder = NEW_IMAGE(path_expBarBorder)
	img_expBarFill = NEW_IMAGE(EXP_BAR_WIDTH, EXP_BAR_HEIGHT)
	img_endCap = NEW_IMAGE(path_endCap)
	currentLevel = -1
	banner_UpdateActionBanner(0, player_GetPlayerLevel(), true)

	-- petals
	imgTable_petals = NEW_IMAGE_TABLE(path_petals)
	collectedPetals = 0
	petalWidth, petalHeight = GET_SIZE(imgTable_petals[1])
	petalHalfWidth = petalWidth // 2
	petalHalfHeight = petalHeight // 2

	perform_petal_bar_anims = false
	allow_petal_anim_updates = false
	petal_progress = 0

	-- item paths - need to initialize polygon table since indices are updated from the center out.
	itemPathsCount = 0
	local totalPoints = (ITEM_PATHS_LENGTH * 2 - 2) * 2 -- tail and head are single points, all others are pairs.
	for i = 1, totalPoints do
		itemPaths_polygon[i] = 0
	end

	-- tokens
	img_multiplierToken = NEW_IMAGE(path_multiplierToken)
	totalTokens = 0
	allowTokenUpdate = false 
end


function clear_ActionBannerUI()
	img_uiBanner = nil
	img_levelText = nil

	img_expBarBorder = nil
	img_expBarFill = nil
	img_endCap = nil	

	imgTable_petals = nil
	for i = 1, #img_petalList do
		img_petalList[i] = nil
	end

	img_multiplierToken = nil 
end


-- +--------------------------------------------------------------+
-- |                           EXP Bar                            |
-- +--------------------------------------------------------------+

local function updateExpBar(time)

	if allowBarUpdate then
		if bar_time > time then 
			local timePercent = 1 - ((bar_time - time) / BAR_TIME_SET)
			local finish = newPercent - oldPercent
			currentPercent = OUT_QUAD(timePercent, oldPercent, finish, 1)

		else
			allowBarUpdate = false 
			currentPercent = newPercent
		end

		LOCK_FOCUS(img_expBarFill)	
			CLEAR_IMAGE(img_expBarFill, COLOR_CLEAR)	
			local width = FILL_WIDTH * (1 - currentPercent)
			local endX = EXP_BAR_WIDTH_HALF + FILL_WIDTH_HALF
			local endCap_x = endX - width

			-- empty fill
			width -= END_CAP_WIDTH_HALF
			SET_COLOR(COLOR_WHITE)
			FILL_RECT(endX, 0, -width, EXP_BAR_HEIGHT)

			-- end cap
			DRAW_IMAGE_STATIC(img_endCap, endCap_x, 0)
		UNLOCK_FOCUS()
	end

	DRAW_IMAGE_STATIC(img_expBarFill, EXP_BAR_X, EXP_BAR_Y)
	DRAW_IMAGE_STATIC(img_expBarBorder, EXP_BAR_X, EXP_BAR_Y)
end


-- +--------------------------------------------------------------+
-- |                          Item Paths                          |
-- +--------------------------------------------------------------+

local function createItemPath(startX, startY)

	for i = 1, ITEM_PATHS_LENGTH do
		local index = itemPathsCount + i
		itemPaths_x[index] = startX
		itemPaths_y[index] = startY
		itemPaths_progress[index] = 1
		itemPaths_arc_x[index] = 0
		itemPaths_arc_y[index] = 0
	end
	itemPathsCount += ITEM_PATHS_LENGTH
end 


-- overwrite the to-be-deleted itemPath with the itemPath at the end
local function deleteItemPath(headIndex)

	-- increment backwards, overwriting itemPath from tail to head.
	for k = ITEM_PATHS_LENGTH - 1, 0, -1 do
		local deletingPoint = headIndex + k
		local keepingPoint = itemPathsCount - (ITEM_PATHS_LENGTH - 1 - k)

		itemPaths_x[deletingPoint] = itemPaths_x[keepingPoint]
		itemPaths_y[deletingPoint] = itemPaths_y[keepingPoint]
		itemPaths_progress[deletingPoint] = itemPaths_progress[keepingPoint]
		itemPaths_arc_x[deletingPoint] = itemPaths_arc_x[keepingPoint]
		itemPaths_arc_y[deletingPoint] = itemPaths_arc_y[keepingPoint]
	end

	itemPathsCount -= ITEM_PATHS_LENGTH
end


local function updateSingleItemPath(newX, newY, progress, directionX, directionY)

	-- Whenever this function is called, we need to update the NEXT itemPath.
	-- This can be called from petals OR and picked-up items, and we can't use those indices for which itemPath to update.
	-- This tracker is reset on every drawItemPaths() call.
	-- Only updates the head of an itemPath, so increment needs to be by tail length.
	
	local i = itemPathsUpdateTracker

	itemPaths_x[i] = newX
	itemPaths_y[i] = newY
	itemPaths_progress[i] = progress

	if directionX and directionY then 
		itemPaths_arc_x[i] = directionX
		itemPaths_arc_y[i] = directionY
	end

	itemPathsUpdateTracker += ITEM_PATHS_LENGTH
end


local function drawItemPaths()

	if itemPathsCount < 1 then 
		return 
	end

	-- reset trackers on every draw call
	itemPathsUpdateTracker = 1

	-- set up polygon vertex tracking
	local polygonVertexIndex = 0
	local polygonSide = { left = 1, right = 2}
	local halfVertice = ITEM_PATHS_LENGTH * 2 -- getting the halfway vertice index (for x and y) is double the total path segments.
	
	local function addPolygonVertex(x, y, side)
		if side == polygonSide.left then 
			itemPaths_polygon[halfVertice - polygonVertexIndex - 1] = x
			itemPaths_polygon[halfVertice - polygonVertexIndex] = y
		else
			itemPaths_polygon[halfVertice + polygonVertexIndex - 1] = x 
			itemPaths_polygon[halfVertice + polygonVertexIndex] = y 
		end	
	end

	-- find each vertex position and put both X and Y into a single list for drawing the polygon shape
	local drawOffsetX, drawOffsetY = GET_DRAW_OFFSET()
	local i = 1
	while i < itemPathsCount do

		-- if progress is 0, then delete this path.
		-- don't increment i after deleting, b/c the swapped data needs to be drawn still.
		if itemPaths_progress[i] <= 0 then
			deleteItemPath(i)

		-- else, draw polygon
		else
	
			-- update path tail, from tail to head, but DO NOT update head
			local lastPoint = i + ITEM_PATHS_LENGTH - 1
			for k = lastPoint, i+1, -1 do
				itemPaths_x[k] = itemPaths_x[k-1]
				itemPaths_y[k] = itemPaths_y[k-1]
				itemPaths_arc_x[k] = itemPaths_arc_x[k-1]
				itemPaths_arc_y[k] = itemPaths_arc_y[k-1]

				local x = itemPaths_x[k] - drawOffsetX + PETAL_WIDTH_HALF
				local y = itemPaths_y[k] - drawOffsetY + PETAL_HEIGHT_HALF

				-- range for tracker needs to start at 0 for mod to work properly
				local tailIndex = ITEM_PATHS_LENGTH - ((k-1) % ITEM_PATHS_LENGTH)
				local width = tailIndex / ITEM_PATHS_LENGTH * ITEM_PATHS_MAX_WIDTH

				addPolygonVertex(	x - (itemPaths_arc_x[k] * width), 
									y - (itemPaths_arc_y[k] * width), 
									polygonSide.left)

				-- end of tail is only 1 point
				if k ~= lastPoint then 
					addPolygonVertex(	x + (itemPaths_arc_x[k] * width), 
										y + (itemPaths_arc_y[k] * width), 
										polygonSide.right)
				end

				-- increment to the next pair of vertex indices.
				polygonVertexIndex += 2 -- update index per X and Y	
			end

			-- path head
			addPolygonVertex(	itemPaths_x[i] - drawOffsetX + PETAL_WIDTH_HALF, 
								itemPaths_y[i] - drawOffsetY + PETAL_HEIGHT_HALF, 
								polygonSide.left)

			-- with polygon table constructed, draw polygon
			SET_COLOR(COLOR_BLACK)
			FILL_POLYGON( UNPACK(itemPaths_polygon) )
			SET_COLOR(COLOR_WHITE)
			DRAW_POLYGON( UNPACK(itemPaths_polygon) )

			-- increment to next path group and reset polygon vertex tracker
			i += ITEM_PATHS_LENGTH
			polygonVertexIndex = 0
		end
	end
end


-- +--------------------------------------------------------------+
-- |                            Petals                            |
-- +--------------------------------------------------------------+

local function resetAllPetalWobbleVerticalProgress()
	for i = 1, collectedPetals do
		petal_wobble_progress[i] = -(i - 1) * PETAL_VERTICAL_WOBBLE_OFFSET
	end
end


local function petalWobbleVertical(progress)
	local progress = min( max(progress, 0), 1 )
	return sin(progress * PETAL_VERTICAL_WOBBLE_FREQUENCY * pi ) * PETAL_VERTICAL_WOBBLE_AMPLITUDE * (1 - progress)
end


local function updatePetals(time)

	-- petal magnet AND bar anims
	if allow_petal_anim_updates then 

		petal_progress = min(petal_progress + PETAL_ANIM_SPEED, 1) -- anim for ALL petals on the banner

		for i = 1, collectedPetals do
			--- perform petal magnet ---		
			if petal_magnet_perform[i] then 

				local percentToEnd = min( (petal_magnet_time[i] - time) / MAGNET_TIME_SET, 1)
				if percentToEnd > 0 then 
					-- this petal's path from pickup location to end location on banner
					local pickup_vector_x = end_x[i] - pickup_x[i]
					local pickup_vector_y = end_y[i] - pickup_y[i]
					local lerpToEnd_x = end_x[i] - (pickup_vector_x * percentToEnd)
					local lerpToEnd_y = end_y[i] - (pickup_vector_y * percentToEnd)				

					-- perpendicular vector to give this petal an arc in its travel to the banner
					local magnitude = 1 / sqrt(pickup_vector_x * pickup_vector_x + pickup_vector_y * pickup_vector_y)
					local perpendicularVector_x = -pickup_vector_y * magnitude
					local perpendicularVector_y = pickup_vector_x * magnitude

					local arcAmount = petal_arc_amount[i]
					local arc_x = sin(percentToEnd * pi) * perpendicularVector_x * arcAmount
					local arc_y = sin(percentToEnd * pi) * perpendicularVector_y * arcAmount
					petals_x[i] = lerpToEnd_x - arc_x
					petals_y[i] = lerpToEnd_y - arc_y

					-- update item paths for petals moving along arc			
					updateSingleItemPath(petals_x[i], petals_y[i], percentToEnd, perpendicularVector_x, perpendicularVector_y)

				else
					petal_magnet_perform[i] = false
					resetAllPetalWobbleVerticalProgress()		
					updateSingleItemPath(petals_x[i], petals_y[i], percentToEnd) -- last call to item paths with progress to delete path
				end

			--- else perform bar anims ---
			else
				-- anim for ALL petals - horizontal
				local start_x = start_x[i]
				local finish_x = end_x[i] - start_x
				petals_x[i] = IN_OUT_QUAD( min(petal_progress, 1) , start_x, finish_x, 1)

				-- anim for INDIVIDUAL petals - vertical
				petal_wobble_progress[i] += PETAL_WOBBLE_SPEED 
				if petal_wobble_progress[i] <= 1 then 
					petals_y[i] = petalWobbleVertical(petal_wobble_progress[i])
				end
			end

			DRAW_IMAGE_STATIC(img_petalList[i], petals_x[i], petals_y[i])
		end

		-- once the last petal finishes its anims, then end all anim calcs.
		if petal_wobble_progress[collectedPetals] > 1 then  
			allow_petal_anim_updates = false
		end
	end
end


local function drawPetals()
	for i = 1, collectedPetals do
		DRAW_IMAGE_STATIC(img_petalList[i], petals_x[i], petals_y[i])
	end
end


function banner_CollectNewPetal(time, letter, worldX, worldY)

	collectedPetals += 1 
	allow_petal_anim_updates = true
	petal_magnet_time[collectedPetals] = time + MAGNET_TIME_SET
	petal_progress = 0

	-- draw the new petal image into the petal list
	local newPetal = NEW_IMAGE(petalWidth, petalHeight)
	LOCK_FOCUS(newPetal)
		local glyph = GET_GLYPH(font_banner, letter)
		local letterHalfWidth = GET_TEXT_WIDTH(font_banner, letter) // 2
		local letterHalfHeight = LEVEL_TEXT_HEIGHT // 2 
		local x = petalHalfWidth - letterHalfWidth
		local y = petalHalfHeight - letterHalfHeight - 2
		local index = random(1, #imgTable_petals)
		DRAW_IMAGE_STATIC(imgTable_petals[index], 0, 0)
		SET_FONT(font_banner)
		DRAW_TEXT(letter, x, y)
	UNLOCK_FOCUS()
	img_petalList[collectedPetals] = newPetal

	-- evenly space out all petals IN PETAL AREA along x-axis
	for i = 1, collectedPetals do 
		local xSpace = PETAL_X_MAX - PETAL_X_MIN
		local position = xSpace / (collectedPetals + 1)
		start_x[i] = petals_x[i]
		start_y[i] = petals_y[i]
		end_x[i] = position * i
		end_y[i] = PETAL_Y
		petal_wobble_progress[i] = 1
	end

	-- set starting position for new petal, since it could be nil
	start_x[collectedPetals] = PETAL_X_MAX - petalHalfWidth - petalHalfWidth
	start_y[collectedPetals] = PETAL_Y

	-- get screen position of petal on moment of player pick-up, and have petal 'fall' into it's starting position
	local drawOffsetX, drawOffsetY = GET_DRAW_OFFSET()
	pickup_x[collectedPetals] = worldX + drawOffsetX
	pickup_y[collectedPetals] = worldY + drawOffsetY

	petal_magnet_perform[collectedPetals] = true
	petal_arc_amount[collectedPetals] = random(ARC_DISTANCE_MIN, ARC_DISTANCE_MAX)

	-- create itemPath at petal's location
	createItemPath(pickup_x[collectedPetals], pickup_y[collectedPetals])
end


-- +--------------------------------------------------------------+
-- |                      Multiplier Tokens                       |
-- +--------------------------------------------------------------+


local function updateMultiplierTokens(time)

	if allowTokenUpdate then
		for i = 1, totalTokens do

			-- lerp the token toward its final position
			local currentTokenTime = token_time[i]
			if currentTokenTime > time then 
				local progress = (currentTokenTime - time) / TOKEN_TIME_SET
				local calculatedEndX = MULTIPLIER_TOKEN_END_X + MULTIPLIER_TOKEN_WIDTH * (i - 1)
				local finish = calculatedEndX - MULTIPLIER_TOKEN_START_X
				token_x[i] = IN_OUT_QUAD(1 - progress, MULTIPLIER_TOKEN_START_X, finish, 1)

			-- token progress is finished, set its position at its adjusted final point
			else
				token_x[i] = MULTIPLIER_TOKEN_END_X + MULTIPLIER_TOKEN_WIDTH * (i - 1)
				allowTokenUpdate = i < totalTokens and true or false -- stop updating tokens after last is at end point
			end

			DRAW_IMAGE_STATIC(img_multiplierToken, token_x[i], MULTIPLIER_TOKEN_Y)			
		end

	else
		for i = 1, totalTokens do
			DRAW_IMAGE_STATIC(img_multiplierToken, token_x[i], MULTIPLIER_TOKEN_Y)
		end
	end
end


function banner_CollectNewMultiplierToken(newTokenCount, time)
	totalTokens = newTokenCount 
	allowTokenUpdate = true 
	token_time[totalTokens] = TOKEN_TIME_SET + time
end


-- +--------------------------------------------------------------+
-- |                      Action Banner Data                      |
-- +--------------------------------------------------------------+

function banner_UpdateActionBanner(percentIn, newLevel, setupText)

	-- Exp Bar
	local time = GET_TIME()
	bar_time = time + BAR_TIME_SET
	oldPercent = currentPercent
	newPercent = percentIn
	allowBarUpdate = true

	-- Level Text
	if newLevel == currentLevel then return end 	-- if the level hasn't changed, don't do anything.

	currentLevel = newLevel
	LOCK_FOCUS(img_levelText)

		CLEAR_IMAGE(img_levelText, COLOR_CLEAR)
		local LV = "Lv. "
		local levelTextWidth = GET_TEXT_WIDTH(font_banner, LV)

		SET_FONT(font_banner)
		SET_DRAW_MODE(DRAW_MODE_FILL_WHITE)
		DRAW_TEXT(LV, 0, 0)
		DRAW_TEXT(newLevel, levelTextWidth, 0)
		SET_DRAW_MODE(DRAW_MODE_COPY)

	UNLOCK_FOCUS()	

	-- Multiplier Tokens
	if setupText == true then return end 		-- if only setting up the text, don't add any multiplier tokens.
	totalTokens += 1 
	allowTokenUpdate = true 
	token_time[totalTokens] = TOKEN_TIME_SET + time

end


function getBannerHeight()
	return UI_BANNER_HEIGHT
end


function getPauseTime_ActionBanner(pauseTime)

	bar_time += pauseTime

	for i = 1, collectedPetals do
		petal_magnet_time[i] += pauseTime
	end

	for i = 1, totalTokens do
		token_time[i] += pauseTime
	end
end


-- +--------------------------------------------------------------+
-- |                            Update                            |
-- +--------------------------------------------------------------+

function updateActionBanner(time)

	DRAW_IMAGE_STATIC(img_uiBanner, 0, 0)
	DRAW_IMAGE_STATIC(img_levelText, LEVEL_TEXT_X, LEVEL_TEXT_Y)

	updateExpBar(time)
	
	updatePetals(time)

	drawItemPaths()
	drawPetals()

	updateMultiplierTokens(time)
end