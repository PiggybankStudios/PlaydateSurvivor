local pi <const> = math.pi


-- +--------------------------------------------------------------+
-- |                             Misc                             |
-- +--------------------------------------------------------------+


function sign(x)
	if x < 0 then
		return -1
	elseif x > 0 then
		return 1
	else
		return 0
	end
end


-- Keeps a value within range, allowing overflow
function constrain(value, min, max)
	if value > max then
		value -= max
	elseif value < min then
		value += max
	end
	
	return value
end


-- Keeps a value within range, ignoring overflow
function clamp(value, min, max)
	if value > max then
		return max
	elseif value < min then 
		return min
	else
		return value
	end
end


function distance(vec1, vec2)
	x = vec1.x - vec2.x
	y = vec1.y - vec2.y
	return math.sqrt((x * x) + (y * y))
end

-- +--------------------------------------------------------------+
-- |                        Interpolation                         |
-- +--------------------------------------------------------------+


function moveTowards(current, target, maxDelta)
	if math.abs(target - current) <= maxDelta then
		return target
	else
		return current + sign(target - current) * maxDelta
	end
end


-- Expects 0 to 1
function easeInOutCubic(x)
	if x < 0.5 then
		return 4 * x * x * x
	else
		return 1 - math.pow(-2 * x + 2, 3) / 2
	end
end