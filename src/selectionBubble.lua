--[[
	- This selection bubble file just handles the vertices and forces around a given point, and 
	drawing a polygon and various effects within this shape. 

	- The selection bubble can have a vertical, pre-rendered dot-dither applied to it.

	- The selection bubble can also have a horizontal 'action bar' that is filled via turning the crank any direction.
		- Once filled, the action bar returns a 'true' bool.

	- Menu navigation is expected to be done outside of this file.

	- This selector bubble is expected to its 'setup' and 'clear' functions called outside of this file.
]]


local pd 	<const> = playdate
local gfx 	<const> = pd.graphics

-- math
local min 		<const> = math.min  
local max 		<const> = math.max
local sin 		<const> = math.sin
local cos 		<const> = math.cos
local rad 		<const> = math.rad
local sqrt 		<const> = math.sqrt
local abs 		<const> = math.abs
local floor 	<const> = math.floor
local random 	<const> = math.random

-- table
local UNPACK 	<const> = table.unpack

-- drawing
local LOCK_FOCUS 			<const> = gfx.lockFocus
local UNLOCK_FOCUS 			<const> = gfx.unlockFocus

local NEW_IMAGE 			<const> = gfx.image.new
local NEW_IMAGE_TABLE 		<const> = gfx.imagetable.new
local GET_IMAGE 			<const> = gfx.imagetable.getImage
local GET_LENGTH 			<const> = gfx.imagetable.getLength
local CLEAR_IMAGE 			<const> = gfx.image.clear
local SET_MASK 				<const> = gfx.image.setMaskImage
local SET_IMAGE_DRAW_MODE 	<const> = gfx.setImageDrawMode
local DRAW_MODE_XOR 		<const> = gfx.kDrawModeXOR
local DRAW_MODE_COPY 		<const> = gfx.kDrawModeCopy

local DRAW_IMAGE_STATIC		<const> = gfx.image.drawIgnoringOffset
local FILL_RECT 			<const> = gfx.fillRect
local DRAW_POLYGON 			<const> = gfx.drawPolygon
local FILL_POLYGON 			<const> = gfx.fillPolygon
local SET_LINE_WIDTH		<const> = gfx.setLineWidth
local SET_COLOR 			<const> = gfx.setColor
local COLOR_WHITE 			<const> = gfx.kColorWhite
local COLOR_BLACK 			<const> = gfx.kColorBlack
local COLOR_CLEAR 			<const> = gfx.kColorClear
local SET_DITHER_PATTERN 	<const> = gfx.setDitherPattern
local DITHER_DIAGONAL 		<const> = gfx.image.kDitherTypeDiagonalLine

local SCREEN_WIDTH 			<const> = pd.display.getWidth()
local SCREEN_HEIGHT 		<const> = pd.display.getHeight()

-- animation
local MOVE_TOWARDS 			<const> = moveTowards_global

-- input
local GET_CRANK_CHANGE 		<const> = pd.getCrankChange



-- +--------------------------------------------------------------+
-- |                            Render                            |
-- +--------------------------------------------------------------+

-- bubble selector
local img_bubble = nil

-- action bar
local img_ActionBar = nil
local mask_ActionBar = nil

-- dither dot pattern - used as vertical action bar gradient
local imgTable_ditherDotPattern = nil
local path_ditherDotPattern <const> = 'Resources/Sheets/Transitions/Transition_GrowingCircles_v2'
local ditherDot_Length = 0



-- +--------------------------------------------------------------+
-- |                     Variables and Arrays                     |
-- +--------------------------------------------------------------+

-- Selection Bubble
local bubble_index = 1

local bubble_target_x = {}
local bubble_target_y = {}
local bubble_target_w = {}
local bubble_target_h = {}

local bubble_x, bubble_y = 0, 0
local bubble_rotation = 0
local bubble_vertice_pos = {} 		-- has both x and y values: x are odd, y are even - needed b/c using Draw_Polygon function
local bubble_vertice_velocity = {} 	-- same as position, so we can keep it in the same loops
local bubble_vertice_dampen = {} 	-- same as position

local BUBBLE_VERTICE_COUNT 		<const> = 7
local BUBBLE_VERT_DATA_TOTAL	<const> = BUBBLE_VERTICE_COUNT * 2
local BUBBLE_ROTATE_SPEED 		<const> = 1
local BUBBLE_WIGGLE_AMOUNT 		<const> = 5

local SPRING_CONSTANT 	<const> = 0.4
local SPRING_DAMPEN_MIN	<const> = 4 -- will end up being a min of 0.4
local SPRING_DAMPEN_MAX	<const> = 6 -- will end up being a max of 0.6

local WIGGLE_TIMER_SET 	<const> = 100
local WIGGLE_MAX_RANGE 	<const> = 6
local WIGGLE_FORCE 		<const> = 3
local wiggleTimer = 0
local wiggleFirstHalfOfVertices = true

local selection_bump_force = false


-- Action Crank Indicator
local actionCrankValue = 0
local AC_MAX  			<const> = 100
local AC_MIN 			<const> = 0 

local actionBarProgress = 0
local ACTION_BAR_CONFIRM_VALUE 	<const> = 1
local ACTION_BAR_SUBTRACT_SPEED <const> = 4




-- +--------------------------------------------------------------+
-- |                          Setup, Clear                        |
-- +--------------------------------------------------------------+


-- Set up the the starting data in order to draw the bubble selector
function setupBubbleSelector(	xList, yList, wList, hList,
								bubble_image_height
								)

	-- menu navigation and details
	bubble_target_x = xList
	bubble_target_y = yList
	bubble_target_w = wList
	bubble_target_h = hList
	if not bubble_image_height then bubble_image_height = 240 end

	-- image creation
	img_bubble 		= NEW_IMAGE(SCREEN_WIDTH, bubble_image_height)
	img_ActionBar	= NEW_IMAGE(SCREEN_WIDTH, bubble_image_height)
	mask_ActionBar 	= NEW_IMAGE(SCREEN_WIDTH, bubble_image_height)

	imgTable_ditherDotPattern = NEW_IMAGE_TABLE(path_ditherDotPattern)
	ditherDot_Length = GET_LENGTH(imgTable_ditherDotPattern)

	-- bubble data setup
	local i = 1
	local vertIndex = 1
	local angle = 360 / BUBBLE_VERTICE_COUNT
	while vertIndex <= BUBBLE_VERTICE_COUNT do
		-- vertice starting positions		
		local rad = rad(angle * vertIndex)	
		bubble_vertice_pos[i] 	= bubble_target_w[bubble_index] * cos(rad) + bubble_target_x[bubble_index]
		bubble_vertice_pos[i+1]	= bubble_target_h[bubble_index] * sin(rad) + bubble_target_y[bubble_index]

		-- indexing increments
		i += 2
		vertIndex += 1
	end

	-- set up selection bubble vertice velocity and dampening - x values are ODD, y values are EVEN
	for j = 1, BUBBLE_VERT_DATA_TOTAL do
		-- velocity and dampen sets
		bubble_vertice_velocity[j] = 0
		bubble_vertice_dampen[j] = (random(SPRING_DAMPEN_MIN, SPRING_DAMPEN_MAX) + random()) * 0.1
	end

	-- action bar setup
	actionCrankValue = 0
	actionBarProgress = 0

	-- global draw variables
	SET_LINE_WIDTH(2)
end


-- clears bubble data for garbageCollector, for when menu navigation is not needed.
-- garbageCollector is expected to be called from a DIFFERENT file, not this one.
function clearBubbleSelector()

	img_bubble 		= nil	
	img_ActionBar	= nil 
	mask_ActionBar	= nil
	imgTable_ditherDotPattern = nil 
	ditherDot_Length = nil 

	bubble_target_x = nil
	bubble_target_y = nil
	bubble_target_w = nil
	bubble_target_h = nil
	bubble_image_height = nil

	-- reset global drawing values
	SET_LINE_WIDTH(1)
end


-- +--------------------------------------------------------------+
-- |                          Interaction                         |
-- +--------------------------------------------------------------+


function updateBubbleIndex(value)
	bubble_index = value
	return bubble_index
end


function updateActionBarProgress(value)
	actionBarProgress = value
	return actionBarProgress
end


function applySelectionBumpForce()
	selection_bump_force = true
end


-- +--------------------------------------------------------------+
-- |                            Drawing                           |
-- +--------------------------------------------------------------+


-- Updates the action bar with a pre-rendered vertical dither, based on an interpolate value, with a start and end range.
function updateVerticalDitherGradient(interpolateValue, ditherStart, ditherEnd, ditherEndOffset)

	-- if dither range not provided, report error and abort.
	if not ditherStart or not ditherEnd then  
		print("function: 'updateActionBar' - for vertical dither, either ditherStart or ditherEnd wasn't passed. Cannot create dither.")
		return
	end

	-- if interpolator not within range, skip.
	if interpolateValue < ditherStart or interpolateValue >= ditherEnd then return end


	-- calculate dither image index
	local i = bubble_index
	local width = bubble_target_w[i]
	local height = bubble_target_h[i]
	local x = bubble_x - width
	local y = bubble_y - height
	
	if not ditherEndOffset then ditherEndOffset = 0 end -- if an end offset wasn't given, set to 0.
	interpolateValue = interpolateValue - ditherStart  	-- offset the interpolation by the start value
	local heightProgress = interpolateValue / (ditherEnd + ditherEndOffset) -- get the percent from the offset end value
	heightProgress = max( min(heightProgress, 1), 0)	-- finally clamp the interpolation between 0 and 1

	local index = max( ditherDot_Length - floor( ditherDot_Length * heightProgress ), 1)

	-- Draw vertical dither
	CLEAR_IMAGE(img_ActionBar, COLOR_CLEAR)
	LOCK_FOCUS(img_ActionBar)
		-- main bar - white
		SET_COLOR(COLOR_WHITE)	
		FILL_RECT(x, y, width * 2, height * 2)

		-- dither dot pattern - black
		DRAW_IMAGE_STATIC( GET_IMAGE(imgTable_ditherDotPattern, index), x, y)
	UNLOCK_FOCUS()
end


-- Updates the masked 'Progress Bar' inside the selection bubble, using the crank at high speeds to make progress.
function updateActionBar()

	-- calculating progress based on crank amount
	local subtractValue = ACTION_BAR_SUBTRACT_SPEED * actionBarProgress
	actionCrankValue = abs( GET_CRANK_CHANGE() ) * 0.1 + actionCrankValue - subtractValue
	actionCrankValue = min( max( actionCrankValue, AC_MIN), AC_MAX )
	actionBarProgress = actionCrankValue / AC_MAX

	-- drawing the action bar width with a dithered right end
	local i = bubble_index
	local width = bubble_target_w[i] * 2 * actionBarProgress
	local height = bubble_target_h[i] * 2
	local x = bubble_x - bubble_target_w[i]
	local y = bubble_y - bubble_target_h[i]

	CLEAR_IMAGE(img_ActionBar, COLOR_CLEAR)
	LOCK_FOCUS(img_ActionBar)
		-- main bar
		SET_COLOR(COLOR_WHITE)	
		FILL_RECT(x, y, width, height)

		-- dithered edge
		SET_DITHER_PATTERN(0.8, DITHER_DIAGONAL)
		FILL_RECT(x + width, y, 15, height)
	UNLOCK_FOCUS()

	-- If bar progress is completed, then reset values and exit via 'true' bool
	if actionBarProgress >= ACTION_BAR_CONFIRM_VALUE then 
		finishedState = true
		actionBarProgress = 0
		actionCrankValue = 0
		return true
	end

	return false
end



function drawSelectionBubble(time, crank, menuItemSelected, drawDitherDot)

	-- Gaurds
	if not crank then crank = 0 end
	if not drawDitherDot then drawDitherDot = false end

	--- Data Handling ---
	-- selector movement between targets
	local i = bubble_index
	local xDiff, yDiff = bubble_target_x[i] - bubble_x, bubble_target_y[i] - bubble_y
	local moveSpeed = sqrt(xDiff * xDiff + yDiff * yDiff) * 0.25
	bubble_x = MOVE_TOWARDS(bubble_x, bubble_target_x[i], moveSpeed)
	bubble_y = MOVE_TOWARDS(bubble_y, bubble_target_y[i], moveSpeed)

	-- Create selection bubble via vertice data plugged into fill_polygon
	bubble_rotation += BUBBLE_ROTATE_SPEED
	if bubble_rotation > 359 then bubble_rotation -= 359 end
	local j = 1
	local vertIndex = 1

	-- Allow smaller 'wiggle' force to half of the vertices based on a timer
	local performWiggle = false
	--if wiggleTimer < time then 
	--	wiggleTimer = random(1, WIGGLE_MAX_RANGE) * WIGGLE_TIMER_SET + time
	--	performWiggle = true
	--	wiggleFirstHalfOfVertices = not wiggleFirstHalfOfVertices
	--end


	-- Calculate all polygon vertices for the selection bubble
	while j <= BUBBLE_VERT_DATA_TOTAL do 

		-- angle of vertice to area center
		local angle = 360 / BUBBLE_VERTICE_COUNT
		local rad = rad(angle * vertIndex + bubble_rotation)	

		-- vertice positions, current and target
		local posX = bubble_vertice_pos[j]
		local posY = bubble_vertice_pos[j+1]
		local targetX = bubble_target_w[bubble_index] * cos(rad) + bubble_x
		local targetY = bubble_target_h[bubble_index] * sin(rad) + bubble_y
		
		-- add a selection force (small bump towards center) to all vertices, if a selection happened
		local selectBumpX, selectBumpY = 0, 0
		if selection_bump_force then 		
			local forceX = bubble_x - posX
			local forceY = bubble_y - posY
			local mag = sqrt(forceX * forceX + forceY * forceY)
			selectBumpX = forceX / mag + (forceX * 0.5)
			selectBumpY = forceY / mag + (forceY * 0.5)
		end

		-- add wiggle force
		local wiggleX, wiggleY = 0, 0
		if performWiggle then 

			local function calculateWiggle()
				local randX = random() * 2 - 1
				local randY = random() * 2 - 1
				local mag = randX * randX + randY * randY
				wiggleX = randX / mag * WIGGLE_FORCE
				wiggleY = randY / mag * WIGGLE_FORCE
			end

			if wiggleFirstHalfOfVertices then
				if vertIndex % 2 == 0 then
					calculateWiggle()
				end
			else
				if vertIndex % 2 == 1 then
					calculateWiggle()
				end
			end
		end

		-- velocity for each vertice, added to position
		local forceX = (targetX - posX) * SPRING_CONSTANT
		local forceY = (targetY - posY) * SPRING_CONSTANT
		local velX = (bubble_vertice_velocity[j]   + forceX + wiggleX + selectBumpX) * bubble_vertice_dampen[j]
		local velY = (bubble_vertice_velocity[j+1] + forceY + wiggleY + selectBumpY) * bubble_vertice_dampen[j+1]
		posX = posX + velX
		posY = posY + velY

		-- reassign array values
		bubble_vertice_pos[j] 			= posX 
		bubble_vertice_pos[j+1] 		= posY
		bubble_vertice_velocity[j] 		= velX
		bubble_vertice_velocity[j+1] 	= velY

		-- incrementing data index and vertice index
		j += 2
		vertIndex += 1
	end

	selection_bump_force = false

	
	--- Drawing ---
	CLEAR_IMAGE(img_bubble, COLOR_CLEAR)

	-- If a button is selected, then draw the polygon outline with an adjusting center
	if menuItemSelected and bubble_index < 10 then 

		-- bubble selector
		SET_COLOR(COLOR_WHITE)
		LOCK_FOCUS(img_bubble)
			DRAW_POLYGON( UNPACK(bubble_vertice_pos) )
		UNLOCK_FOCUS()

		-- action bar mask
		LOCK_FOCUS(mask_ActionBar)
			CLEAR_IMAGE(mask_ActionBar, COLOR_BLACK)
			FILL_POLYGON( UNPACK(bubble_vertice_pos) )
		UNLOCK_FOCUS()
		SET_MASK(img_ActionBar, mask_ActionBar)

		-- drawing action bar
		SET_IMAGE_DRAW_MODE(DRAW_MODE_XOR)
			DRAW_IMAGE_STATIC(img_ActionBar, 0, crank)
		SET_IMAGE_DRAW_MODE(DRAW_MODE_COPY)

		-- drawing bubble outline
		DRAW_IMAGE_STATIC(img_bubble, 0, crank)

	-- if the crank is above the ShowGradientHeight, draw the full bubble image WITH an imageTable mask.
	elseif drawDitherDot then

		-- draw only the action bar with dither dot mask - no outline
		SET_COLOR(COLOR_WHITE)
		LOCK_FOCUS(mask_ActionBar)
			CLEAR_IMAGE(mask_ActionBar, COLOR_BLACK)
			FILL_POLYGON( UNPACK(bubble_vertice_pos) )
		UNLOCK_FOCUS()
		SET_MASK(img_ActionBar, mask_ActionBar)

		-- drawing action bar
		SET_IMAGE_DRAW_MODE(DRAW_MODE_XOR)
			DRAW_IMAGE_STATIC(img_ActionBar, 0, crank)
		SET_IMAGE_DRAW_MODE(DRAW_MODE_COPY)
	
	-- Else only draw the filled polygon to the bubble image.
	else
		SET_COLOR(COLOR_WHITE)
		LOCK_FOCUS(img_bubble)
			FILL_POLYGON( UNPACK(bubble_vertice_pos) )
		UNLOCK_FOCUS()

		-- Draw the bubble selection image with a draw mode, so we can see what's underneath it
		SET_IMAGE_DRAW_MODE(DRAW_MODE_XOR)
			DRAW_IMAGE_STATIC(img_bubble, 0, crank)
		SET_IMAGE_DRAW_MODE(DRAW_MODE_COPY)
	end
end