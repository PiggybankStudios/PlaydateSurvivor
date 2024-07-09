

-- +--------------------------------------------------------------+
-- |                Shared Constants and Variables                |
-- +--------------------------------------------------------------+

-- extensions
local pd <const> = playdate
local gfx <const> = pd.graphics

-- drawing
local GET_DRAW_OFFSET 		<const> = gfx.getDrawOffset
local SET_COLOR 			<const> = gfx.setColor
local COLOR_WHITE 			<const> = gfx.kColorWhite
local COLOR_BLACK 			<const> = gfx.kColorBlack
local FILL_CIRCLE 			<const> = gfx.fillCircleAtPoint
local FILL_RECT 			<const> = gfx.fillRect



-- +--------------------------------------------------------------+
-- |                       Growing Circles                        |
-- +--------------------------------------------------------------+

local TRANSITION_NUM_ROWS 						<const> = 50
local TRANSITION_CIRCLES_IN_ROW 				<const> = 40

local TRANSITION_CIRCLE_WIDTH_OFFSET 			<const> = 400 / TRANSITION_CIRCLES_IN_ROW

local TRANSITION_CIRCLE_ROW_OFFSET 				<const> = 600 / TRANSITION_NUM_ROWS
local TRANSITION_CIRCLE_HEIGHT_OFFSET_IN_ROW	<const> = TRANSITION_CIRCLE_ROW_OFFSET / TRANSITION_CIRCLES_IN_ROW
local TRANSITION_CIRCLE_OFFSET_ALL_ROWS 		<const> = 100

local TRANSITION_CIRCLE_SCALE_WINDOW 			<const> = 1 / TRANSITION_NUM_ROWS
local TRANSITION_MAX_CIRCLE_SIZE 				<const> = 10
local TRANSITION_CIRCLE_RANGE_OFFSET 			<const> = TRANSITION_CIRCLE_SCALE_WINDOW * 8
	

function doTransition_GrowingCircles(timePercent)

	local xOffset, yOffset = GET_DRAW_OFFSET()

	SET_COLOR(COLOR_WHITE)
	FILL_RECT(-xOffset, -yOffset, 400, 240)

	SET_COLOR(COLOR_BLACK)
	for j = 0, TRANSITION_NUM_ROWS do
		for i = 0, TRANSITION_CIRCLES_IN_ROW do

			local scaleTimeRangeStart 	= j * TRANSITION_CIRCLE_SCALE_WINDOW - TRANSITION_CIRCLE_RANGE_OFFSET
			local scaleTimeRangeEnd 	= j * TRANSITION_CIRCLE_SCALE_WINDOW + TRANSITION_CIRCLE_RANGE_OFFSET

			local timePercentPerRow = (timePercent - scaleTimeRangeStart) / (scaleTimeRangeEnd - scaleTimeRangeStart)
			local circleR = (1 - timePercentPerRow) * TRANSITION_MAX_CIRCLE_SIZE

			if 0 < circleR then 
				local xOffset, yOffset = GET_DRAW_OFFSET()
				local circleX = i * TRANSITION_CIRCLE_WIDTH_OFFSET - xOffset
				local circleY = 	(j * TRANSITION_CIRCLE_ROW_OFFSET) 
									- (i * TRANSITION_CIRCLE_HEIGHT_OFFSET_IN_ROW) 											
									- TRANSITION_CIRCLE_OFFSET_ALL_ROWS
									- yOffset	

				FILL_CIRCLE(circleX, circleY, circleR)
			end
		end
	end

end