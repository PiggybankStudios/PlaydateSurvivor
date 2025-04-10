
TAGS = {
	walls = 1,
	player = 2,
	weapon = 3,
	enemy = 4,
	damage = 5,
	breakable = 6
}

--[[
ZINDEX = {	
	uidetails = 510,
	ui = 500,
	uibanner = 490,	
	healthbar = 480,
	player = 200,
	weapon = 150,
	enemy = 140,
	item = 135,
	particle = 130,
	default = 100,
	map = 50
}
]]

CAMERA_SHAKE_STRENGTH = {
	tiny = 2,
	small = 4, 
	medium = 10,
	large = 24,
	massive = 48
}

LEVEL_DIFFICULTY = {
	breezy = 	1,
	easy = 		2,  
	medium = 	3, 
	hard = 		5, 
	intense = 	6
}

ITEM_TYPE = {
	health 			= 1,
	weapon 			= 2, 
	shield 			= 3,  
	absorbAll 		= 4, 
	exp1 			= 5, 
	exp2 			= 6,  
	exp3 			= 7,  
	exp6 			= 8,  
	exp9 			= 9,
	exp16 			= 10,
	luck 			= 11,
	mun2 			= 12,
	mun10 			= 13,
	mun50 			= 14,
	petal 			= 15,
	multiplierToken = 16
}


OBJECT_TYPE = {
	teleporter = 1,
	spikeball = 2,
	enemySpawner = 3
}

ENEMY_TYPE = {
	fastBall = 1,
	normalSquare = 2,
	bat = 3,
	medic = 4,
	bulletBill = 5,
	chunkyArms = 6,
	munBag = 7,
	enemy_A = 8
}

ENEMY_SPAWN_RATE = {
	sluggish = 1600,
	verySlow = 1400,
	slow = 1200,
	medium = 1000,
	fast = 800,
	veryFast = 600,
	swift = 400
}


TRANSITION_TYPE = {
	growingCircles = 1
}


GAMESTATE = {
	maingame 			= 1,
	pauseMenu 			= 2,
	flowerMinigame		= 3,
	newWeaponMenu 		= 4,
	playerUpgradeMenu	= 5,
	levelModifierMenu 	= 6,
	deathscreen 		= 7,
	startscreen 		= 8,
	mainmenu 			= 9,
	loadGame 			= 10
}

--[[
GAMESTATE = {
	nothing = 0,
	startscreen = 1,
	maingame = 2,
	pausemenu = 3,
	levelupmenu = 4,
	newweaponmenu = 5,
	deathscreen = 6,
	mainmenu = 7,
	unpaused = 8,
	wavescreen = 9
}
]]


PLAYER_STATS = {
	armor = 1,
	attackRate = 2,
	bulletSpeed = 3,
	gunDamage = 4,
	dodge = 5,
	expBonus = 6,
	healBonus = 7,
	maxHealth = 8,
	luck = 9,
	itemMagnet = 10,
	reflectDamage = 11,
	moveSpeed = 12,
	vampire = 13,
	stunChance = 14
}


GUN_NAMES = {
	"pistol", 				-- 1
	"cannon", 				-- 2
	"minigun", 				-- 3
	"shotgun", 				-- 4
	"burst rifle", 			-- 5
	"grenade launcher",		-- 6
	"boomerang",			-- 7
	"wave gun"				-- 8
}


PARTICLE_TYPE = {
	playerImpact = 1,
	enemyTrail = 2
}


-- configfile
CONFIG_REF = {
	Default_Save = "save 1",
	run_mode = 0,
	pause_time = 3,
	No_Screen_Shake = 0,
	No_Screen_Flash  = 0,
	invincible  = 0,
	Infinite_Money  = 0,
	one_hit_kill  = 0,
	Unlock_All  = 0,
	Ironman_Mode  = 0
}


-- savefile
SAVE_REF = {
	mun = 0,
	hiscore_0 = 0,
	hiscore_1 = 0,
	hiscore_2 = 0,
	hiscore_3 = 0,
	hiscore_4 = 0,
	hiscore_5 = 0,
	hiscore_6 = 0,
	hiscore_7 = 0,
	hiscore_8 = 0,
	hiscore_9 = 0,
	health = 75,
	damage = 5,
	exp_bonus = 0,
	speed = 50,
	waveNumber = 1,
	level_up_list = 0,
	weapons_grabbed_list = 0,
	playerMun = 0
}

-- savefile order
SAVE_REF_ORDER = {
	"mun",
	"start_health",
	"start_damage",
	"start_speed",
	"start_luck",
	"start_magnet",
	"start_dodge",
	"start_heal_bonus",
	"start_exp_bonus",
	"start_difficulty",
	"start_gun",
	"start_charm",
	"hiscore_0",
	"hiscore_1",
	"hiscore_2",
	"hiscore_3",
	"hiscore_4",
	"hiscore_5",
	"hiscore_6",
	"hiscore_7",
	"hiscore_8",
	"hiscore_9",
	"hiscore_char_0",
	"hiscore_char_1",
	"hiscore_char_2",
	"hiscore_char_3",
	"hiscore_char_4",
	"hiscore_char_5",
	"hiscore_char_6",
	"hiscore_char_7",
	"hiscore_char_8",
	"hiscore_char_9",
	"unlock_char_1",
	"unlock_char_2",
	"unlock_char_3",
	"unlock_char_4",
	"unlock_char_5",
	"unlock_char_6",
	"unlock_char_7",
	"unlock_char_8",
	"unlock_char_9",
	"max_wave_char_0",
	"max_wave_char_1",
	"max_wave_char_2",
	"max_wave_char_3",
	"max_wave_char_4",
	"max_wave_char_5",
	"max_wave_char_6",
	"max_wave_char_7",
	"max_wave_char_8",
	"max_wave_char_9",
	"unlock_map",
	"unlock_compass",
	"unlock_charm_1",
	"unlock_charm_2",
	"unlock_charm_3",
	"unlock_charm_4",
	"unlock_relic_1",
	"unlock_relic_2",
	"unlock_relic_3",
	"unlock_relic_4",
	"run_char",
	"run_wave",
	"run_gun_1",
	"run_gun_2",
	"run_gun_3",
	"run_gun_4",
	"run_gun_t1",
	"run_gun_t2",
	"run_gun_t3",
	"run_gun_t4",
	"run_charm_11",
	"run_charm_12",
	"run_charm_13",
	"run_charm_14",
	"run_charm_t11",
	"run_charm_t12",
	"run_charm_t13",
	"run_charm_t14",
	"run_charm_21",
	"run_charm_22",
	"run_charm_23",
	"run_charm_24",
	"run_charm_t21",
	"run_charm_t22",
	"run_charm_t23",
	"run_charm_t24",
	"run_charm_31",
	"run_charm_32",
	"run_charm_33",
	"run_charm_34",
	"run_charm_t31",
	"run_charm_t32",
	"run_charm_t33",
	"run_charm_t34",
	"run_charm_41",
	"run_charm_42",
	"run_charm_43",
	"run_charm_44",
	"run_charm_t41",
	"run_charm_t42",
	"run_charm_t43",
	"run_charm_t44",
	"run_relic_1",
	"run_relic_2",
	"run_relic_3",
	"run_relic_4",
	"run_location_x",
	"run_location_y",
	"run_rotation",
	"run_mun",
	"run_level",
	"run_slots",
	"run_exp",
	"run_health",
	"run_health_max",
	"run_speed",
	"run_att_rate",
	"run_magnet",
	"run_damage",
	"run_reflect",
	"run_exp_bonus",
	"run_luck",
	"run_bullet_speed",
	"run_armor",
	"run_dodge",
	"run_heal_bonus",
	"run_vampire",
	"run_stun",
	"run_difficulty",
	"run_exp_total",
	"run_damage_dealt",
	"run_shots_fired",
	"run_enemies_killed",
	"run_max_combo",
	"run_damage_taken",
	"run_items_grabbed",
	"run_time_survived",
	"run_queued_level_ups",
	"run_queued_weapons",
	"run_queued_charms",
	"run_queued_relics",
	"save_file_number",
	"save_file_gameInProgress"
}
