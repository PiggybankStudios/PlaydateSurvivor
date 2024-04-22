-- File for miscellanious global variables and funtions.
-- Helps remove how much main needs to pass.


local pd 	<const> = playdate


-- +--------------------------------------------------------------+
-- |                           Globals                            |
-- +--------------------------------------------------------------+


local dt <const> = 1/20
function getDT()
	return dt
end



-- +--------------------------------------------------------------+
-- |                            Timers                            |
-- +--------------------------------------------------------------+


--local resetTime <const> = pd.resetElapsedTime
local getTime <const> = pd.getElapsedTime

local timerWindow = 0
local totalElapseTime = 0
local timeInstances = 0
local TIME_INSTANCE_MAX <const> = 500
local averageTime = 0
local maxTime = 0
local minTime = 1


function resetTime()
	pd.resetElapsedTime()
end


function addTotalTime()
	if timeInstances >= TIME_INSTANCE_MAX then return end

	local elapsed = getTime()
	totalElapseTime += elapsed
	timeInstances += 1

	if elapsed < minTime then 
		minTime = elapsed
	elseif elapsed > maxTime then 
		maxTime = elapsed
	end
end


function printAndClearTotalTime(time, activeNameAsString, activeObject)
	-- avoid divide by 0
	if timeInstances == 0 then return end

	-- time instance check
	if timeInstances < TIME_INSTANCE_MAX then return end 

	-- calc average
	averageTime = totalElapseTime / timeInstances

	local objectName = activeNameAsString or ""
	local object = activeObject or ""

	-- print statistics
	print(	"------------")
	print(	objectName .. ": " .. object ..
			" - total time: " .. totalElapseTime .. 
			" - average time: " .. averageTime .. 
			" - time instances: " .. timeInstances .. 
			" - min: " .. minTime .. 
			" - max: " .. maxTime)

	-- reset values for new data
	totalElapseTime = 0
	averageTime = 0
	timeInstances = 0
	minTime = 1
	maxTime = 0
end



-- +--------------------------------------------------------------+
-- |                          Functions                           |
-- +--------------------------------------------------------------+

local abs <const> = math.abs

function clamp(value, min, max)
	if value > max then
		return max
	elseif value < min then 
		return min
	else
		return value
	end
end


function constrain(value, min, max)
	if value > max then 
		return value - max
	elseif value < min then
		return value + max
	else
		return value
	end
end


local function sign(x)
	if x > 0 then 	return 1
	else 			return -1
	end
end


function moveTowards(current, target, maxDelta)
	if abs(target - current) <= maxDelta then
		return target
	else
		return current + sign(target - current) * maxDelta
	end
end