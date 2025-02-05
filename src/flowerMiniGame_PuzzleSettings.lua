
-- +--------------------------------------------------------------+
-- |                        Level Variables                       |
-- +--------------------------------------------------------------+

-- Enemy Types
local FAST_BALL		<const> = ENEMY_TYPE.fastBall
local NORMAL_SQUARE <const> = ENEMY_TYPE.normalSquare
local BAT 			<const> = ENEMY_TYPE.bat
local MEDIC 		<const> = ENEMY_TYPE.medic
local BULLET_BILL 	<const> = ENEMY_TYPE.bulletBill
local CHUNKY_ARMS 	<const> = ENEMY_TYPE.chunkyArms
local MUN_BAG 		<const> = ENEMY_TYPE.munBag
local ENEMY_A 		<const> = ENEMY_TYPE.enemy_A

-- Enemy Spawn Rates
local SLUGGISH 	<const> = ENEMY_SPAWN_RATE.sluggish
local VERY_SLOW <const> = ENEMY_SPAWN_RATE.verySlow
local SLOW 		<const> = ENEMY_SPAWN_RATE.slow
local MEDIUM 	<const> = ENEMY_SPAWN_RATE.medium
local FAST 		<const> = ENEMY_SPAWN_RATE.fast 
local VERY_FAST <const> = ENEMY_SPAWN_RATE.veryFast
local SWIFT 	<const> = ENEMY_SPAWN_RATE.swift


-- +--------------------------------------------------------------+
-- |                          Level Data                          |
-- +--------------------------------------------------------------+

-- All puzzles need to be made with these details:
	-- Only use UPPER CASE letters for collecting letters - lower case causes problems, they won't work here.

local flowerGame_Puzzles = {

	-- TEST - 1 - Starting Area
	{	name 			= "Level_3",											-- Level to be loaded
		difficulty 		= LEVEL_DIFFICULTY.breezy,								-- Difficulty
		letters 		= { "A", "B", "C", "D" },								-- Letters to be collected
		spawners 		= {	{ type = FAST_BALL, 	rate = SWIFT 		},		-- Spawner details
							{ type = FAST_BALL, 	rate = SLUGGISH 	},
							{ type = NORMAL_SQUARE, rate = SLOW 		},
							{ type = BAT, 			rate = MEDIUM 		}	}
		-- Level Goal?
		-- Level Modifier?
		-- Next Levels?
	},

	-- 2 - Big Room
	{	name 			= "Level_0",
		difficulty 		= LEVEL_DIFFICULTY.easy,
		letters 		= { "R", "O", "B", "M", "E" },
		spawners 		= {	{ type = FAST_BALL, 	rate = FAST 		},
							{ type = NORMAL_SQUARE, rate = SLOW 		},
							{ type = BAT, 			rate = SLOW 		},
							{ type = MEDIC, 		rate = MEDIUM 		},
							{ type = BULLET_BILL, 	rate = SLUGGISH 	}	}
	}
}


-- +--------------------------------------------------------------+
-- |                     Functions and Access                     |
-- +--------------------------------------------------------------+


function get_Level_Data(value)
	return flowerGame_Puzzles[value]
end


function flowerGame_puzzleCount()
	return #flowerGame_Puzzles
end


function puzzleData_GetSpawnerList(level_index)
	return flowerGame_Puzzles[level_index].spawners
end


function puzzleData_GetSpawnerTypeAndRate(level_index, spawnerID)
	local enemyType = flowerGame_Puzzles[level_index].spawners[spawnerID]
	local spawnRate = flowerGame_Puzzles[level_index].spawnRate[spawnerID]
	return enemyType, spawnRate
end