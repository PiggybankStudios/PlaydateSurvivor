local pd 	<const> = playdate
local gfx 	<const> = pd.graphics

-- math
local sin 		<const> = math.sin
local cos 		<const> = math.cos
local rad 		<const> = math.rad
local ceil 		<const> = math.ceil
local max 		<const> = math.max 

-- time
local GET_TIME 	<const> = pd.getCurrentTimeMilliseconds

-- table
local UNPACK 	<const> = table.unpack

-- drawing
local LOCK_FOCUS 			<const> = gfx.lockFocus
local UNLOCK_FOCUS 			<const> = gfx.unlockFocus
local NEW_IMAGE 			<const> = gfx.image.new
local DRAW_IMAGE_STATIC		<const> = gfx.image.drawIgnoringOffset
local CLEAR_IMAGE 			<const> = gfx.image.clear
local COLOR_CLEAR 			<const> = gfx.kColorClear

local SET_DRAW_MODE 		<const> = gfx.setImageDrawMode
local DRAW_MODE_NXOR 		<const> = gfx.kDrawModeNXOR
local DRAW_MODE_COPY 		<const> = gfx.kDrawModeCopy

local SET_FONT				<const> = gfx.setFont
local DRAW_TEXT 			<const> = gfx.drawText
local GET_TEXT_SIZE 		<const> = gfx.getTextSize

local FILL_CIRCLE 			<const> = gfx.fillCircleAtPoint
local DRAW_CIRCLE 			<const> = gfx.drawCircleAtPoint
local FILL_POLYGON 			<const> = gfx.fillPolygon
local SET_COLOR 			<const> = gfx.setColor
local COLOR_BLACK 			<const> = gfx.kColorBlack
local COLOR_WHITE 			<const> = gfx.kColorWhite



-- +--------------------------------------------------------------+
-- |                            Render                            |
-- +--------------------------------------------------------------+

local font_FlowerLetters = font_Roobert_24
local img_countdownTimer = nil 



-- +--------------------------------------------------------------+
-- |                     Variables and Arrays                     |
-- +--------------------------------------------------------------+

-- Countdown Timer
local countdownTimer = 0
local countdownTimer_seconds = 15
local countdownTimer_set = 0
local CD_TIMER_SET_MILL			<const> = 1000

local CD_TIMER_X 				<const> = 8 
local CD_TIMER_Y 				<const> = 88
local CD_TIMER_RADIUS 			<const> = 40 
local CD_TIMER_RADIUS_DOUBLE 	<const> = CD_TIMER_RADIUS * 2

local cdTimer_maskPoints = {}
local CD_TIMER_MASKPOINTS_MAX 	<const> = 9
local CD_TIMER_VERTICE_COUNT 	<const> = CD_TIMER_MASKPOINTS_MAX * 2

local allowEndOfTimerNotification = true



-- +--------------------------------------------------------------+
-- |                         Create, Clear                        |
-- +--------------------------------------------------------------+

function create_CountdownTimer()

	allowEndOfTimerNotification = true

	img_countdownTimer = NEW_IMAGE(CD_TIMER_RADIUS_DOUBLE, CD_TIMER_RADIUS_DOUBLE)
	countdownTimer_set = CD_TIMER_SET_MILL * countdownTimer_seconds
	countdownTimer = countdownTimer_set + GET_TIME()

	-- set all the mask points in the center of the countdown circle
	for i = 1, CD_TIMER_VERTICE_COUNT do
		cdTimer_maskPoints[i] = CD_TIMER_RADIUS
	end
	local angle = rad(0 - 90)
	cdTimer_maskPoints[3] = CD_TIMER_RADIUS_DOUBLE * cos(angle) + CD_TIMER_RADIUS
	cdTimer_maskPoints[4] = CD_TIMER_RADIUS_DOUBLE * sin(angle) + CD_TIMER_RADIUS
end


function clear_CountdownTimer()
	img_countdownTimer = nil
end


-- +--------------------------------------------------------------+
-- |                             Draw                             |
-- +--------------------------------------------------------------+

function draw_CountdownTimer(time)
	
	local timePercent = (countdownTimer - time) / countdownTimer_set
	
	-- Draw Timer w/ elapsed time
	if timePercent > 0 then
		CLEAR_IMAGE(img_countdownTimer, COLOR_CLEAR)
		LOCK_FOCUS(img_countdownTimer)

			-- draw circle
			SET_COLOR(COLOR_WHITE)
			FILL_CIRCLE(CD_TIMER_RADIUS, CD_TIMER_RADIUS, CD_TIMER_RADIUS)

			-- draw polygon overlay
			local circlePercent = 1 - timePercent
			local i = ceil((CD_TIMER_MASKPOINTS_MAX - 2) * circlePercent) * 2 + 3	
			local angle = rad(360 * circlePercent - 90)
			cdTimer_maskPoints[i] 	= CD_TIMER_RADIUS_DOUBLE * cos(angle) + CD_TIMER_RADIUS
			cdTimer_maskPoints[i+1] = CD_TIMER_RADIUS_DOUBLE * sin(angle) + CD_TIMER_RADIUS
			SET_COLOR(COLOR_BLACK)
			FILL_POLYGON( UNPACK(cdTimer_maskPoints) )

			-- draw countdown numbers w/ invert drawing
			SET_FONT(font_FlowerLetters)
			local timeInt = (countdownTimer - time) // 1000 + 1
			local numberWidth, numberHeight = GET_TEXT_SIZE(timeInt)
			numberWidth = CD_TIMER_RADIUS - (numberWidth // 2)
			numberHeight = CD_TIMER_RADIUS - (numberHeight // 2) + 2
			SET_DRAW_MODE(DRAW_MODE_NXOR)
			DRAW_TEXT(timeInt, numberWidth, numberHeight)

			-- draw circle border
			SET_COLOR(COLOR_WHITE)
			DRAW_CIRCLE(CD_TIMER_RADIUS, CD_TIMER_RADIUS, CD_TIMER_RADIUS)

		UNLOCK_FOCUS()
	
	-- Draw fully elapsed timer w/ 0
	else
		CLEAR_IMAGE(img_countdownTimer, COLOR_CLEAR)
		LOCK_FOCUS(img_countdownTimer)

			-- draw countdown numbers w/ invert drawing
			SET_FONT(font_FlowerLetters)
			local timeInt = 0
			local numberWidth, numberHeight = GET_TEXT_SIZE(timeInt)
			numberWidth = CD_TIMER_RADIUS - (numberWidth // 2)
			numberHeight = CD_TIMER_RADIUS - (numberHeight // 2) + 2
			SET_DRAW_MODE(DRAW_MODE_NXOR)
			DRAW_TEXT(timeInt, numberWidth, numberHeight)

			-- draw circle border
			SET_COLOR(COLOR_WHITE)
			DRAW_CIRCLE(CD_TIMER_RADIUS, CD_TIMER_RADIUS, CD_TIMER_RADIUS)
		UNLOCK_FOCUS()

		-- send flag to flowerMiniGame that the timer has fully elapsed.
		if allowEndOfTimerNotification then
			flowerGame_TimerHasElapsed(time)
			allowEndOfTimerNotification = false
		end
	end

	-- draw timer circle
	DRAW_IMAGE_STATIC(img_countdownTimer, CD_TIMER_X, CD_TIMER_Y)
end