local pd 	<const> = playdate
local gfx 	<const> = pd.graphics

local GET_IMAGE 			<const> = gfx.imagetable.getImage
local DRAW_IMAGE_STATIC		<const> = gfx.image.drawIgnoringOffset



-- +--------------------------------------------------------------+
-- |                            Render                            |
-- +--------------------------------------------------------------+

local imgTable_LevelModifiers_TitleCard = gfx.imagetable.new('Resources/Sheets/Menu_LevelModifiers/levelModifiersTitleCard_Wobble')

local TITLECARD_FRAMES <const> = #imgTable_LevelModifiers_TitleCard


-- +--------------------------------------------------------------+
-- |                     Variables and Arrays                     |
-- +--------------------------------------------------------------+

local TITLECARD_WOBBLE_TIMER_SET <const> = 150
local titleCardWobbleTimer = 0
local titleCardIndex = 1


-- +--------------------------------------------------------------+
-- |                       Init, State Start                      |
-- +--------------------------------------------------------------+

function levelModifierMenu_StateStart()


	-- Run the 'End Transition' animation
	runTransitionEnd()

end



-- +--------------------------------------------------------------+
-- |                            Update                            |
-- +--------------------------------------------------------------+

function updateLevelModifierMenu(time)

	if titleCardWobbleTimer < time then 
		titleCardWobbleTimer = time + TITLECARD_WOBBLE_TIMER_SET
		titleCardIndex = titleCardIndex % TITLECARD_FRAMES + 1
	end

	local image = GET_IMAGE(imgTable_LevelModifiers_TitleCard, titleCardIndex)
	DRAW_IMAGE_STATIC(image, 0, 0)


	-- go back to the main game
	if pd.buttonJustPressed(pd.kButtonB) then 
		runTransitionStart( GAMESTATE.maingame, TRANSITION_TYPE.growingCircles, gameScene_NextLevel )
	end

end

