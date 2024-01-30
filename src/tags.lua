
TAGS = {
	walls = 1,
	player = 2,
	weapon = 3,
	enemy = 4,
}


GROUPS = {
	walls = 1,
	player = 2,
	weapon = 3,
	enemy = 4,
	item = 5,
	itemAbsorber = 6
}


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
	default = 100
}


GAMESTATE = {
	nothing = 0,
	startscreen = 1,
	maingame = 2,
	pausemenu = 3,
	levelupmenu = 4,
	newweaponmenu = 5,
	deathscreen = 6
}


CAMERA_SHAKE_STRENGTH = {
	tiny = 2,
	small = 4, 
	medium = 10,
	large = 24,
	massive = 48
}


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
	"NONE",					-- 1
	"pistol", 				-- 2
	"cannon", 				-- 3
	"minigun", 				-- 4
	"shotgun", 				-- 5
	"burst rifle", 			-- 6
	"grenade launcher",		-- 7
	"boomerang",			-- 8
	"wave gun"				-- 9
}


ITEM_TYPE = {
	none = 1,
	health = 2,
	weapon = 3, 
	shield = 4, 
	absorbAll = 5,
	exp1 = 6, 
	exp2 = 7, 
	exp3 = 8, 
	exp6 = 9, 
	exp9 = 10, 
	exp16 = 11, 
	luck = 12 
}


PARTICLE_TYPE = {
	none = 1,
	playerImpact = 2,
	enemyTrail = 3
}
