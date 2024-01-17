-- savefile
local saveData = {
	0, --coins
	0, --start health
	0, --start damage
	0, --start speed
	0, --start luck
	0, --start magnet
	0, --start dodge
	0, --start heal bonus
	0, --start exp bonus
	0, --start difficulty (10)
	0, --high score 1
	0, --high score 2
	0, --high score 3
	0, --high score 4
	0, --high score 5
	0, --high score 6
	0, --high score 7
	0, --high score 8
	0, --high score 9
	0, --current char (20)
	0, --unlock char 1
	0, --unlock char 2
	0, --unlock char 3
	0, --unlock char 4
	0, --unlock char 5
	0, --unlock char 6
	0, --unlock char 7
	0, --unlock char 8
	0, --unlock char 9
	0, --unlock map (30)
	0, --unlock compass
	0, --unlock charm slot 1
	0, --unlock charm slot 2
	0, --unlock charm slot 3
	0, --unlock charm slot 4
	0, --unlock relic slot 1
	0, --unlock relic slot 2
	0, --unlock relic slot 3
	0, --unlock relic slot 4
	0, --current wave (40)
	0, --current gun 1
	0, --current gun 2
	0, --current gun 3
	0, --current gun 4
	0, --current gun tier 1
	0, --current gun tier 2
	0, --current gun tier 3
	0, --current gun tier 4
	0, --current charm 1-1
	0, --current charm 1-2 (50)
	0, --current charm 1-3
	0, --current charm 1-4
	0, --current charm tier 1-1
	0, --current charm tier 1-2
	0, --current charm tier 1-3
	0, --current charm tier 1-4
	0, --current charm 2-1
	0, --current charm 2-2
	0, --current charm 2-3
	0, --current charm 2-4 (60)
	0, --current charm tier 2-1
	0, --current charm tier 2-2
	0, --current charm tier 2-3
	0, --current charm tier 2-4
	0, --current charm 3-1
	0, --current charm 3-2
	0, --current charm 3-3
	0, --current charm 3-4
	0, --current charm tier 3-1
	0, --current charm tier 3-2 (70)
	0, --current charm tier 3-3
	0, --current charm tier 3-4
	0, --current charm 4-1
	0, --current charm 4-2
	0, --current charm 4-3
	0, --current charm 4-4
	0, --current charm tier 4-1
	0, --current charm tier 4-2
	0, --current charm tier 4-3
	0, --current charm tier 4-4 (80)
	0, --current relic 1
	0, --current relic 2
	0, --current relic 3
	0, --current relic 4
	0, --current location x
	0, --current location y
	0, --current rotation
	0, --current coins
	0, --current level
	0, --current exp (90)
	0, --current health
	0, --current max health
	0, --current speed
	0, --current att rate
	0, --current magnet
	0, --current damage
	0, --current reflect
	0, --current exp bonus
	0, --current luck
	0, --current bullet speed (100)
	0, --current armor
	0, --current dodge
	0, --current heal bonus
	0, --current vampire
	0, --current stun
	0, --current difficulty
	0, --current total exp
	0, --current damage dealt
	0, --current shots fired
	0, --current enemies killed (110)
	0, --current max combo
	0, --current damage taken
	0, --current items grabbed
	0, --current time survived
	0, --current queued level ups
	0, --current queued weapons
	0, --current queued charms
	0, --current queued relics
}

function writeSaveFile()
	playdate.datastore.write(saveData, "save")
	print("save data stored")
end

function readSaveFile()
	saveData = playdate.datastore.read("save")
	print("save data read")
	--for ind, data in pairs(saveData) do
	--	print(tostring(data))
	--end
end