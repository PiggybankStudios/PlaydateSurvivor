
local pd <const> = playdate
local gfx <const> = pd.graphics

local NEW_IMAGE_TABLE 		<const> = gfx.imagetable.new
local LOAD_IMAGE_TABLE 		<const> = gfx.imagetable.load
local GET_DRAW_OFFSET 		<const> = gfx.getDrawOffset
local SET_COLOR 			<const> = gfx.setColor
local COLOR_BLACK 			<const> = gfx.kColorBlack
local FILL_RECT 			<const> = gfx.fillRect -- remove
local GET_IMAGE 			<const> = gfx.imagetable.getImage
local GET_LENGTH 			<const> = gfx.imagetable.getLength -- remove
local DRAW_IMAGE_STATIC		<const> = gfx.image.drawIgnoringOffset
local FLIP_XY 				<const> = gfx.kImageFlippedXY

local LOCK_PLAYER_INPUT 	<const> = player_LockInput



-- +--------------------------------------------------------------+
-- |                           Variables                          |
-- +--------------------------------------------------------------+

local performTransition = false
local transitionStart = false
local transitionEnd = false

local transition_PassedFunction = 0
local transition_ClearFunction = 0
local transition_nextState = currentState

local TRANSITION_TIME_PER_FRAME_SET <const> = 30
local transition_frameTimer = 0
local transition_index = 0
local transition_anim = 0
local transition_frames = 0
local transition_previousAnimType = 0

local TRANSITION_ANIM_PATHS = {
	'Resources/Sheets/Transitions/Transition_GrowingCircles_v2'
}


-- +--------------------------------------------------------------+
-- |                         Initialization                       |
-- +--------------------------------------------------------------+

function transitions_initialize_data()

	print("")
	print(" -- Initializing Transitions --")
	local currentTask = 1
	local totalTasks = 1

	coroutine.yield(currentTask, totalTasks, "Transitions: Loading Animation")
	transition_anim = NEW_IMAGE_TABLE(TRANSITION_ANIM_PATHS[1])
	transition_frames = #transition_anim
	transition_previousAnimType = transition_anim
end


-- +--------------------------------------------------------------+
-- |                         Transitioning                        |
-- +--------------------------------------------------------------+

-- fades screen TO black
-- The passedFunction needs to have 'runTransitionEnd' called by it.
function runTransitionStart(nextState, animType, passedFunction, clearFunction, override)

	-- If a transition was already started, then abort. We don't want to restart it.
	-- BUT if this transition is overriding the previous, then allow the new transition.
	if performTransition and not override then return end 		

	performTransition = true
	transitionStart = true
	transitionEnd = false
	LOCK_PLAYER_INPUT(true) -- need to prevent all input during action game while transitioning to prevent other possible transitions.

	transition_nextState = nextState
	if passedFunction ~= nil then
		transition_PassedFunction = passedFunction
	else
		transition_PassedFunction = runTransitionEnd -- if no function passed, then just finished the transition animation.
	end

	if clearFunction ~= nil then 
		transition_ClearFunction = clearFunction
	else
		transition_ClearFunction = nil -- if no clear function passed, then do nothing.
	end

	-- Load the transition animation if it's different than the previous.
	if transition_previousAnimType ~= animType then
		LOAD_IMAGE_TABLE(transition_anim, TRANSITION_ANIM_PATHS[animType])
		transition_frames = #transition_anim
		transition_previousAnimType = animType
	end
	
	transition_frameTimer = 0
	transition_index = 0
end


-- fades screen FROM black
function runTransitionEnd(animType)

	-- default animType to what TransitionStart used if nothing passed
	if not animType then animType = transition_previousAnimType end

	performTransition = true 
	transitionStart = false
	transitionEnd = true

	currentState = setGameState(transition_nextState)
	transition_nextState = 0
	transition_PassedFunction = 0

	-- Load the transition animation if it's different than the previous.
	if transition_previousAnimType ~= animType then
		LOAD_IMAGE_TABLE(transition_anim, TRANSITION_ANIM_PATHS[animType])
		transition_frames = #transition_anim
		transition_previousAnimType = animType
	end

	transition_frameTimer = 0
	transition_index = transition_frames
end


-- +--------------------------------------------------------------+
-- |                             Update                           |
-- +--------------------------------------------------------------+

function updateTransitions(time)

	--if performTransition == false then
	--	return
	--end

	if performTransition then

		if transitionStart then 
			-- Increment frame
			if transition_frameTimer < time then 
				transition_frameTimer = time + TRANSITION_TIME_PER_FRAME_SET
				transition_index = transition_index + 1 
			end

			-- Check end condition
			if transition_index > transition_frames then 
				performTransition = false
				transitionStart = false						
				SET_COLOR(COLOR_BLACK)
				local xOffset, yOffset = GET_DRAW_OFFSET()
				FILL_RECT(-xOffset, -yOffset, 400, 240) -- This covers the last frame of the transition.	
				if transition_ClearFunction ~= nil then transition_ClearFunction() end
				transition_PassedFunction() -- at then end of the transition, perform the function that was passed.

			-- Else draw frame
			else
				DRAW_IMAGE_STATIC( GET_IMAGE(transition_anim, transition_index), 0, 0)
				--doTransition_GrowingCircles(timePercent) -- functions for creating animations - comment out after the imageTable is created.
			end

		elseif transitionEnd then 
			-- Decrement frame
			if transition_frameTimer < time then 
				transition_frameTimer = time + TRANSITION_TIME_PER_FRAME_SET
				transition_index = transition_index - 1 
			end

			-- Check end condition
			if transition_index < 1 then 
				performTransition = false 
				transitionEnd = false
				LOCK_PLAYER_INPUT(false)

			-- Else draw frame, flipped on both X and Y.
			else
				DRAW_IMAGE_STATIC( GET_IMAGE(transition_anim, transition_index), 0, 0, FLIP_XY)
			end
		end
	end
end

