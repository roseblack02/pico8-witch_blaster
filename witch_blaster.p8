pico-8 cartridge // http://www.pico-8.com
version 36
__lua__
--main tab

--[[todo
	maybe an extra level or 2? 
	
	refine tutorial level
	refine final boss level
	
	game music
	end screen music
	at least 1 boss song ideally 2
]]--

function _init()
	state="menu"
	frame=0
	music(2)
	--menu
	witch_y,blaster_x=-20,-100
	game_pal="original"
	music_on="on"
	option=1
	menu_colour={7,7,7}
	text_flash=7

	--intro
	intro_x,intro_y,intro_size_x,intro_size_y=32,64,58,48
	intro_angle=0
	intro_state,intro_text=1,{{"dark forces lurk in this","forest, sapping my magical","energy..."},{"i need to smoke these evil","spirits and free myself from ","their clutches!"}}

	--game
	map_x,front_tree_x,back_tree_x=0,0,0
	map_speed,front_speed,back_speed=0.35,0.6,0.4
	text_wave=0

	--get level info from text file
	#include levels.lua
	levels={level1,level2,level3,level4,level5,level6,level7}
	level=1
	level_timer=0
	wave1,wave2,wave3=true,false,false
	level_clear=false
	death_colour={7,7}
	message=""

	--tutorial info
	pause,tutorial_state,tutorial_text=false,1,{{"⬇️⬆️⬅️➡️ to move","❎/x to shoot","🅾️/z to continue"},{"your energy is","always draining","watch the bar below","enemies and orbs fill it up","🅾️/z to continue"},{"enemies drop orbs,","magic, coins, and","random powerups","🅾️/z to continue"},{"blast using 🅾️/z","when magic is at 100%","🅾️/z to continue"}}

	--final boss animation
	boss_dead=false
	circle_size=0
	end_x,end_y,end_size_x,end_size_y=64,94,0,0
	fade_timer=0
	end_state,end_text=1,{{"at last i have defeated the","evil spirits and regained my","energy..."},{"im finally free!","",""}}

	--store
	blink_timer=0
	open,buying,close=true,false,false
	cursor={sprite=7,x=64,y=34}
	e_upgrades,drain_upgrades,dmg_upgrades,blast_upgrades,magic_upgrades=1,1,1,1

	--particle effects
	blast_particle={}
	hit_particle={}
	trail_particle={}

	--table of enemies
	enemy_objs={}

	--table of bullets
	bullet_objs={}

	--table of pickups
	pickup_objs={}

	--player object
	player={
		x=25,
		y=64,
		width=8,
		velocity_x=0,
		velocity_y=0,
		e_level=116,
		e_gained=5,
		e_drain=0.15,
		lives=3,
		shot_speed=2,
		dmg=1,
		mag_level=0,
		current_mag=0,
		blast=false,
		blast_dur=2,
		coins=0,
		powerup="",
		powerup_timer=0,
		points=0,
		sprite=1,
		up=false,
		down=false,
		is_hit=false,
		hit_timer=0,
		shot_speed_mod=0,
		burst=false,
		double=false,
		shield=false,
		bullet_colour=7,
		dead=false,
		update=function(self)
			--count down powerup timer
			self.powerup_timer-=1
			self.powerup_timer=mid(0,self.powerup_timer,300)

			if (self.powerup=="shot speed up") self.shot_speed_mod=4 else self.shot_speed_mod=0
			if (self.powerup=="double shot") self.double=true else self.double=false
			if (self.powerup=="burst") self.burst=true else self.burst=false
			if (self.powerup=="shield") self.shield=true else self.shield=false

			--reset powerup
			if (self.powerup_timer<1) self.powerup=""

			--reset movement variables
			self.down,self.up=false,false

			--movement
			self.velocity_x*=0.85
			self.velocity_y*=0.85

			if (btn(0)) self.velocity_x-=0.75
			if (btn(1)) self.velocity_x+=0.75
			if (btn(2)) self.velocity_y-=0.75 self.down=true
			if (btn(3)) self.velocity_y+=0.75 self.up=true

			self.velocity_x=mid(-2,self.velocity_x,2)
			self.velocity_y=mid(-2,self.velocity_y,2)

			--applying velocity
			self.x+=self.velocity_x
			self.y+=self.velocity_y

			--limit position
			self.x=mid(8,self.x,120)
			self.y=mid(10,self.y,120)

			--bullet
			if btnp(5) and not self.blast and not self.dead then
				if (self.double) make_bullet_obj(self.x,self.y-4,self.shot_speed+self.shot_speed_mod,{false,true,false,false}) make_bullet_obj(self.x,self.y+4,self.shot_speed+self.shot_speed_mod,{false,true,false,false}) else make_bullet_obj(self.x,self.y,self.shot_speed+self.shot_speed_mod,{false,true,false,false})
				sfx(2)
			end

			if btnp(4) then
				if level_clear then
					--end level
					state="shop"
					level_clear=false
					sfx(5)
					if(music_on=="on")music(0)
				else
					--blast
					if (self.mag_level==100) self.blast=true explosion(blast_particle,self.x+2,self.y-10) sfx(3)
				end
			end

			--change bullet colour duting blast as mag_level drains
			if(self.mag_level>self.current_mag) self.current_mag=self.mag_level

			local colour={12,14,7,14,12}
			for i=5,1,-1 do
				if(self.mag_level<self.current_mag*(i/5)) self.bullet_colour=colour[i]
			end

			if (self.blast) self.mag_level-=self.blast_dur make_bullet_obj(self.x,self.y,6,{false,true,false,false},self.bullet_colour)

			--end blast
			if (self.mag_level<1) self.blast=false

			--burst
			if self.burst then
				make_bullet_obj(self.x,self.y,self.shot_speed+self.shot_speed_mod,{true,true,false,false})
				make_bullet_obj(self.x,self.y,self.shot_speed+self.shot_speed_mod,{false,true,true,false})
				make_bullet_obj(self.x,self.y,self.shot_speed+self.shot_speed_mod,{false,false,true,true})
				make_bullet_obj(self.x,self.y,self.shot_speed+self.shot_speed_mod,{true,false,false,true})
				self.powerup=""
				sfx(2)
			end

			--limit mag_level
			self.mag_level=mid(0,self.mag_level,100)

			--animate sprite
			if not self.is_hit then
				if frame>30 then
					self.sprite=1
				else
					self.sprite=3
				end

				--change sprite if moving up or down
				if (self.up) self.sprite=1
				if (self.down) self.sprite=3
			end

			--collision
			--count down hit timer
			if (self.hit_timer>0) self.hit_timer-=1 screen_shake(0.05)
			--reset is_hit variable and camera
			if (self.hit_timer<1) self.is_hit=false camera(0,0)

			--make player invulnerable when hit
			if not self.is_hit and not self.dead then
				self:check_collision(self)
			end

			--contstantly drain players e_level
			if not level_clear then
				--slow down draining for tutorial
				if (level==1) self.e_level-= 0.025 else self.e_level-=self.e_drain
			end

			--limit e_level
			self.e_level=mid(0,self.e_level,116)

			--check if player has lost a life
			if (self.e_level<1 and self.lives>0) self.x=25 self.y=64 self.lives-=1 self.e_level=116 self:hit_effect(self)

			--check if player is dead
			if (self.e_level<1 and self.lives<1) self.dead=true 
		end,
		draw=function(self)
			outlined_sprites(self.sprite,12,self.x-8,self.y-8,2,2)

			--shield
			if self.shield then
				circ(self.x,self.y-1,10,12)
				circ(self.x+1,self.y,10,12)
				circ(self.x,self.y+1,10,12)
				circ(self.x-1,self.y,10,12)
				circ(self.x,self.y,10,7)
			end
		end,
		check_collision=function(self)
			--enemy collision
			local enemy
			for enemy in all(enemy_objs) do
				if circles_overlapping(self,enemy) and not self.shield then
					self:hit_effect(self)
					--take damage
					self.e_level-=20
				end
			end
		end,
		hit_effect=function(self)
			--hit effect
			self.sprite=5
			self.is_hit=true
			self.hit_timer+=60
			explosion(hit_particle,self.x-2,self.y-10)
			sfx(1)

		end
	}
end

function _update60()
	if state=="menu" then
		update_menu()
	elseif state=="intro" then
		update_intro()
	elseif state=="game" then
		update_game()
	elseif state=="shop" then
		update_shop()
	elseif state=="end" then
		update_end()
	end

	--count frames
	frame+=1
	if (frame>60) frame=0
end

function _draw()
	if state=="menu" then
		draw_menu()
	elseif state=="intro" then
		draw_intro()
	elseif state=="game" then
		draw_game()
	elseif state=="shop" then
		draw_shop()
	elseif state=="end" then
		draw_end()
	end
end

--game states
function update_menu()
	if(witch_y<15) witch_y+=1
	if(blaster_x<40 and witch_y>7) blaster_x+=2

	--choose option
	if(btnp(2)) option-=1
	if(btnp(3)) option+=1
	option=mid(1,option,3)

	if (option==1 and btnp(5)) state="intro" sfx(7) intro_state=1

	if option==2 then
		if btnp(1) or btnp(0) then
			if(music_on=="on") music_on="off" music(-1) else music_on="on" music(2)
			sfx(8)
		end
	end

	if option==3 then
		if btnp(1) or btnp(0) then
			if(game_pal=="full") game_pal="original" else game_pal="full"
			sfx(8)
		end
	end

	--flash button prompts
	if(frame>30) text_flash=7 else text_flash=12

	--change menu option colour if player has selected it
	for c=1,#menu_colour do
		menu_colour[c]=7
	end

	menu_colour[option]=12

	--set song
	track=0
end

function draw_menu()
	cls(12)
	--background
	static_background()

	--title text
	outlined_sprites(192,1,24,witch_y,8,2)
	outlined_sprites(224,1,blaster_x,35,8,2)


	--menu options
	if blaster_x>18 then 
		outlined_text("start",54,71,menu_colour[1],1) 
		outlined_text("music: "..music_on,49-(#music_on*2),81,menu_colour[2],1) 
		outlined_text("palette: "..game_pal,45-(#game_pal*2),91,menu_colour[3],1)

		--button prompts
		if(option==1) outlined_text("❎",76,71,text_flash,1)
		if(option==2) outlined_text("⬅️",39-(#music_on*2),81,text_flash,1) outlined_text("➡️",80+(#music_on*2),81,text_flash,1)
		if(option==3) outlined_text("⬅️",35-(#game_pal*2),91,text_flash,1) outlined_text("➡️",84+(#game_pal*2),91,text_flash,1)
	end
end

function update_intro()
	--scroll background
	map_x+=map_speed
	if (map_x>60) map_x=0
	back_tree_x-=back_speed
	if (back_tree_x<-127) back_tree_x=0
	front_tree_x-=front_speed
	if (front_tree_x<-127) front_tree_x=0

	--bob character
	if intro_state<3 then
		intro_y+=sin(intro_angle)*1
		if(intro_angle>10)intro_angle=0
	    intro_angle+=0.01
	end

    --shrink character
    if intro_state>2 then
		if(intro_size_x>16)intro_size_x-=58/35
		if(intro_size_y>15)intro_size_y-=48/35

		--move character down
		if(intro_y>64)intro_y-=1
		if(intro_y<64)intro_y+=1
	end

    --advance dialogue
    if(btnp(5) and intro_state<3) sfx(7) intro_state+=1

    --start game
    if intro_size_x<18 then
    	reset_info() 
    	if(music_on=="on")music(6,0,7)
    end
end

function draw_intro()
	cls(12)
	--background trees
	back_trees(back_tree_x)
	back_trees(back_tree_x+127)
	front_trees(front_tree_x)
	front_trees(front_tree_x+127)
	rectfill(0,96,128,128,3)
	map(map_x,0)

	--draw character 29:24 ratio for x:y
	sspr(72,32,29,24,intro_x,intro_y-(intro_size_y/2),intro_size_x,intro_size_y)

	if intro_state<3 then
		--text bubble
		rectfill(0,0,128,36,1)
		outlined_text("◆",40,33,7,1)
		rectfill(0,0,128,34,7)

		--text
		for i=1,3 do
			if(intro_state)print(intro_text[intro_state][i],2,-6+(i*8),1)
		end
		print("❎",119,28,1)
	end
end

function update_game()
	--update objects
	--dont update if paused during tutorial
	if not pause then
		local enemy
		for enemy in all(enemy_objs)do
			enemy:update()
		end
		local bullet
		for bullet in all(bullet_objs)do
			bullet:update()
		end
		local pickup
		for pickup in all(pickup_objs)do
			pickup:update()
		end

		if(not player.dead and not boss_dead)player:update()
	end

	--side scrolling
	map_x+=map_speed
	if (map_x>60) map_x=0
	back_tree_x-=back_speed
	if (back_tree_x<-127) back_tree_x=0
	front_tree_x-=front_speed
	if (front_tree_x<-127) front_tree_x=0

	--tutorial
	if level==1 then
		--pause game and set which tutorial text to display
		if(level_timer==0 or (level_timer>9 and level_timer<9+(1/60)) or (level_timer>22 and level_timer<22+(1/60)) or (level_timer>39 and level_timer<39+(1/60))) pause=true

		if(pause and btnp(4)) pause=false tutorial_state+=1
	end

	--load waves
	--load wave based on timer
	if not level_clear then
		--count level timer
		if(not pause)level_timer+=(1/60)

		if level_timer<15 and wave1 then
			--spawn
			load_wave(levels[level].wave1)
			--end spawn
			wave1=false
			--start next wave
			wave2=true
		elseif level_timer>15 and level_timer<30 and wave2 then
			load_wave(levels[level].wave2)
			wave2=false
			wave3=true
		elseif level_timer>30 and wave3 then
			load_wave(levels[level].wave3)
			wave3=false
		--end level based on timer and on if there are no enemies
		elseif level_timer>30 and #enemy_objs<1 then
			level_clear=true
		end 
	end

	--wave text counter
	if (text_wave>59) text_wave=0
	text_wave+=1

	--controls for death screen
	if player.dead then
		if(btnp(2)) option=1
		if(btnp(3)) option=2

		if btnp(4) then
			if option==1 then 
				state="menu"
				if(music_on=="on")music(2)
				sfx(8)
			end

			if(option==2)reset_info()
		end
	end

	--death menu
	--flash button prompts
	if(frame>30) text_flash=7 else text_flash=12

	--change menu option colour if player has selected it
	for c=1,#death_colour do
		death_colour[c]=7
	end

	menu_colour[option]=12
end

function draw_game()
	cls(12)

	--background trees
	back_trees(back_tree_x)
	back_trees(back_tree_x+127)

	front_trees(front_tree_x)
	front_trees(front_tree_x+127)

	--ground
	rectfill(0,96,128,128,3)

	--map
	map(map_x,0)

	--trail effect
	draw_trail(7)

	--draw objects
	local pickup
	for pickup in all(pickup_objs)do
		pickup:draw()
	end
	if(not player.dead)player:draw()
	local enemy
	for enemy in all(enemy_objs)do
		enemy:draw()
	end
	local bullet
	for bullet in all(bullet_objs)do
		bullet:draw()
	end

	--explosions
	draw_explosion(hit_particle,{7,8,8,2})
	draw_explosion(blast_particle,{1,12,12,7})

	--hud
	--mag level
	outlined_text("★ "..flr(player.mag_level).."%",2,2,7,1)

	--blast prompt
	if (player.mag_level==100) outlined_text("blast 🅾️",48,112,text_flash,1)

	--score
	outlined_text(player.points,64-(#tostr(player.points)*2)-1,2,7,1)

	--powerup
	--dont show powerup text during tutorial
	if(not pause) outlined_text(player.powerup,63-(#player.powerup*2),12,7,1)

	--lives
	outlined_text(player.lives,109,2,7,1)
	spr(50,119,1)

	--coins
	outlined_text(player.coins,109,12,7,1)
	spr(34,119,11)

	--e level
	circfill(4,122,4,7)
	circfill(4,123,4,7)
	rectfill(7,119,127,126,7)
	rectfill(8,120,126,125,13)
	rect(8,120,126,125,1)
	spr(33,1,119)
	rectfill(9,121,9+(player.e_level),124,12)

	--bar on left :/
	--[[spr(33,1,10)
	rectfill(1,16,8,126,1)
	rectfill(2,17,7,125,13)
	rectfill(7,125,2,125-player.e_level,12)]]--

	--level clear screen
	if level_clear then
		--display level cleared or special boss cleared message
		if(level==4 or level==7) waving_text(message,61-((#message)*2),40,7,1) else waving_text("level cleared!",33,40,7,1)
		rectfill(35,52,92,74,1)
		rectfill(36,53,91,73,14)
		outlined_text("score : ",40,56,7,1)
		outlined_text(player.points,72,56,12,1)
		outlined_text("continue 🅾️",42,66,text_flash,1)
	end

	--death screen
	if player.dead then
		waving_text("you died",45,40,7,1)
		rectfill(35,52,92,84,1)
		rectfill(36,53,91,83,14)
		outlined_text("score : ",40,56,7,1)
		outlined_text(player.points,72,56,12,1)
		outlined_text("menu",56,66,death_colour[1],1)
		outlined_text("replay",52,76,death_colour[2],1)

		--button prompts
		if(option==1) outlined_text("🅾️",76,66,text_flash,1)
		if(option==2) outlined_text("🅾️",80,76,text_flash,1)
	end

	--tutorial text
	if pause then
		--loop through lines of tutorial text and display them
		for i=1,#tutorial_text[tutorial_state] do
			--offset used due to multiple symbols in the first line of the first text
			local offset=0
			if(i==1 and tutorial_state==1) offset=6 else offset=0
			--change colour of last line
			local colour=7
			if(i==#tutorial_text[tutorial_state]) colour=12 else colour=7
			outlined_text(tutorial_text[tutorial_state][i],63-offset-(#tutorial_text[tutorial_state][i]*2),4+i*8,colour,1)
		end

		--arrows
		if(tutorial_state==2)sspr(56,0,16,16,48,85,32,32)
		if(tutorial_state==4)spr(7,1,10,2,2,false,true)
	end

	--final boss animation
	if boss_dead then
		circfill(104,64,circle_size,7)
	end
end

function update_shop()
	--blink timer
	if (blink_timer>30) blink_timer=0
	blink_timer+=1/60

	--player controls
	--open dialogue
	if (open and btnp(5)) open=false buying=true sfx(5)

	--buy options
	if buying and btnp(4) then	
		if(cursor.y==34 and player.coins>9 and e_upgrades<3) player.coins-=10 player.e_gained+=2.5 e_upgrades+=1 sfx(6)
		if(cursor.y==42 and player.coins>14 and drain_upgrades<5) player.coins-=15 player.e_drain-=0.025 drain_upgrades+=1 sfx(6)
		if(cursor.y==50 and player.coins>17 and dmg_upgrades<5) player.coins-=18 player.dmg+=0.25 dmg_upgrades+=1 sfx(6)
		if(cursor.y==58 and player.coins>19) player.coins-=20 player.lives+=1 sfx(6)
		if(cursor.y==66 and player.coins>14 and blast_upgrades<3) player.coins-=15 player.blast_dur-=0.2 blast_upgrades+=1 sfx(6)
		if(cursor.y==74) buying=false close=true sfx(5)
	end

	--leaving dialogue
	if close and btnp(5) then
		close,open=false,true
		level+=1 
		sfx(5) 
		reset_info() 
		if(music_on=="on")music(6,0,7)
	end

	--move cursor
	if (btnp(2)) cursor.y-=8
	if (btnp(3)) cursor.y+=8

	--bob cursor
	if(frame==60) cursor.x-=1
	if(frame==30) cursor.x+=1

	cursor.y=mid(34,cursor.y,74)
end

function draw_shop()
	cls(12)
	--background
	static_background()

	--blahaj
	sspr(40,32,24,32,64,24,48,64)
	--blink
	if (blink_timer>29.5) sspr(64,32,8,8,80,40,16,16)

	--stand
	rectfill(4,20,12,88,4)
	rect(3,20,13,88,1)
	circfill(8,28,4,2)

	rectfill(116,20,124,88,4)
	rect(115,20,125,88,1)
	circfill(120,28,4,2)

	rectfill(0,87,128,128,4)
	rectfill(0,87,128,90,2)
	line(0,87,128,87,1)
	--tent stripes
	--outline
	for i=0,16 do
		circfill((i*8)+4,22,5,1)
	end
	local stripe=7
	for i=0,16 do
		--alterante stripe colour
		if (i%2==0) stripe=12 else stripe=7
		rectfill(i*8,0,(i*8)+8,22,stripe)
		circfill((i*8)+4,22,4,stripe)
	end

	--speech bubble
	rectfill(1,30,62,84,1)
	outlined_text("▶",61,57,7,1)
	rectfill(3,32,60,82,7)

	--speech
	if (open) print("what are ya",5,34,1) print("buyin?",5,40,1) outlined_text("❎ to continue",3,91,7,1)
	

	if buying then
		print("e gained $10",5,34,1)
		print("e draining $15",5,42,1)
		print("dmg $18",5,50,1)
		print("lives $20",5,58,1)
		print("blast $15",5,66,1)
		print("leave",5,74,1)

		if(cursor.y==34) outlined_text("increase energy gained ",3,91,7,1) outlined_text("from enemies "..e_upgrades.."/3",3,99,7,1) outlined_text("🅾️ to purchase",3,107,7,1)
		if(cursor.y==42) outlined_text("slows down the draining ",3,91,7,1) outlined_text("of energy "..drain_upgrades.."/5",3,99,7,1) outlined_text("🅾️ to purchase",3,107,7,1)
		if(cursor.y==50) outlined_text("increase damage dealt "..dmg_upgrades.."/5",3,91,7,1) outlined_text("🅾️ to purchase",3,99,7,1)
		if(cursor.y==58) outlined_text("purchase extra lives ",3,91,7,1) outlined_text("🅾️ to purchase",3,99,7,1)
		if(cursor.y==66) outlined_text("increase blast duration "..blast_upgrades.."/3",3,91,7,1) outlined_text("🅾️ to purchase",3,99,7,1)
		if(cursor.y==74) outlined_text("leave shop",3,91,7,1) outlined_text("🅾️ to leave",3,99,7,1)

		--spr(cursor.sprite,cursor.x,cursor.y)
		outlined_text("◀",cursor.x,cursor.y,8,1)
	end

	if (close) print("come back any",5,34,1) print("time!",5,40,1) outlined_text("❎ to continue",3,91,7,1)

	--hud
	--lives
	outlined_text(player.lives,109,2,7,1)
	spr(50,119,1)

	--coins
	outlined_text(player.coins,109,12,7,1)
	spr(34,119,11)
end

function update_end()
	--scroll background
	map_x+=map_speed
	if (map_x>60) map_x=0
	back_tree_x-=back_speed
	if (back_tree_x<-127) back_tree_x=0
	front_tree_x-=front_speed
	if (front_tree_x<-127) front_tree_x=0

	--bob character
	end_y+=sin(intro_angle)*1
	if(intro_angle>10)intro_angle=0
    intro_angle+=0.01

    --fade timer to fade out of white
    fade_timer+=1
    fade_timer=mid(0,fade_timer,241)

    if fade_timer>90 then
		if(end_size_x<64)end_size_x+=4/18
		if(end_size_y<112)end_size_y+=7/18
	end

     --advance dialogue
    if(btnp(5) and end_size_x>64) sfx(7) end_state+=1

    --start game
    if end_state>2 then
    	state="menu"
    	if(music_on=="on")music(2)

    	--reset things for intro and ending animation
    	intro_x,intro_y,intro_size_x,intro_size_y=32,64,58,48
		circle_size=0
		end_x,end_y,end_size_x,end_size_y=64,94,0,0
		fade_timer=0
		boss_dead=false
    end
end

function draw_end()
	cls(12)
	--background trees
	back_trees(back_tree_x)
	back_trees(back_tree_x+127)
	front_trees(front_tree_x)
	front_trees(front_tree_x+127)
	rectfill(0,96,128,128,3)
	map(map_x,0)

	--bring in character 
	--use fillp to fade out of white
	if(fade_timer>60)fillp(▒) 
	if(fade_timer>120)fillp(░)
	if(fade_timer>180)fillp(…)
	if(fade_timer<240)rectfill(0,0,128,128,7)
	fillp()

	--draw character 4:7 ratio for x:y
	sspr(96,64,32,56,end_x-(end_size_x/2),end_y-(end_size_y/2),end_size_x,end_size_y)

	if end_size_x>64 then
		--text bubble
		rectfill(0,0,128,36,1)
		outlined_text("◆",40,33,7,1)
		rectfill(0,0,128,34,7)

		--text
		for i=1,3 do
			print(end_text[end_state][i],2,-6+(i*8),1)
		end
		print("❎",119,28,1)
	end
end
-->8
--objects
--object creation from bridgs tutorial
--make enemies
function make_enemy_obj(name,x,y,props)
	--create enemy
	local obj={
		name=name,
		x=x,
		y=y,
		width=0,
		velocity_x=0,
		velocity_y=0,
		hp=0,
		dmg=0,
		sprite=0,
		is_hit=false,
		points=0,
		shoot_timer=0,
		update=function(self)
		end,
		draw=function(self)
		end,
		check_collision=function(self)
			--bullet collision
			local bullet
			for bullet in all(bullet_objs) do
				if circles_overlapping(self,bullet) then
					--take damage
					self.hp-=player.dmg
					sfx(0)

					--hit effect
					explosion(hit_particle,self.x-6,self.y-10)
					self.is_hit=true

					--delete bullet
					del(bullet_objs,bullet)

					--delete self if dead
					if self.hp<1 and not self.final_boss then 
						del(enemy_objs,self) 
						player.points+=self.points
						--randomly drop a pickup
						local rand=flr(rnd(9))+1

						if (rand==1) make_powerup(self.x,self.y)
						if (rand>1 and rand<4) make_energy(self.x,self.y)
						if (rand>3 and rand<5) make_magic(self.x,self.y)
						if (rand>4) make_coin(self.x,self.y)

						--give player e
						player.e_level+=player.e_gained

						--check if boss and give coins and randomly choose a message for player to say
						if (self.boss) player.coins+=20 message=rnd({"get smoked b)","foe vanquished","enemy felled","foe smoked"})
					end
				else
					self.is_hit=false
				end
			end
		end,
		shoot_player=function(self,offset,speed)
			--set offset to 0 and speed to 1 if not specified
			offset=0 or offset
			speed=1 or speed

			--shoot at player
			self.shoot_timer+=speed
			if (self.shoot_timer>180+offset) self.shoot_timer=0

			if (self.x<200 and self.shoot_timer==179+offset) make_enemy_bullet(self.x,self.y)
		end,
		despawn=function(self)
			--delete self if off screen
			if (self.x<-20) del(enemy_objs,self)
		end
	}
	--loop through properties and assign it to the obj table
	local k,v
	for k,v in pairs(props) do
		obj[k]=v
	end
	--add object table to enemies table
	add(enemy_objs,obj)
	return obj
end

function make_worm(x,y)
	return make_enemy_obj("worm",x,y,{
		width=12,
		hp=5,
		sprite=14,
		points=100,
		update=function(self)
			self.x-=0.25

			self:check_collision(self)

			--animate sprite
			if frame>30 then
				self.sprite=30
			else
				self.sprite=14
			end

			self:despawn(self)
		end,
		draw=function(self)
			outlined_sprites(self.sprite,8,self.x-8,self.y-2,2,1)

		end
	})
end

function make_owl(x,y)
	return make_enemy_obj("owl",x,y,{
		width=16,
		hp=8,
		sprite=42,
		points=250,
		update=function(self)
			self.x-=0.5

			self:check_collision(self)

			--animate sprite
			if frame>30 then
				self.sprite=42
			else
				self.sprite=44
			end

			self:shoot_player(self)

			self:despawn(self)
		end,
		draw=function(self)
			outlined_sprites(self.sprite,8,self.x-8,self.y-8,2,2)
		end
	})
end

function make_snail(x,y)
	return make_enemy_obj("snail",x,y,{
		width=12,
		hp=10,
		sprite=46,
		points=200,
		update=function(self)
			self.x-=0.1

			self:check_collision(self)

			--animate sprite
			if frame>30 then
				self.sprite=62
			else
				self.sprite=46
			end

			self:despawn(self)
		end,
		draw=function(self)
			outlined_sprites(self.sprite,8,self.x-8,self.y-2,2,1)
		end
	})
end

function make_gull(x,y)
	return make_enemy_obj("gull",x,y,{
		width=12,
		hp=5,
		sprite=12,
		points=150,
		angle=0,
		update=function(self)
			self.x-=0.5

			--move up and down in sin wave
			self.y+=sin(self.angle)*2
			if(self.angle>10)self.angle=0
     		self.angle+=0.015

			self:check_collision(self)

			--animate sprite
			if frame>30 then
				self.sprite=28
			else
				self.sprite=12
			end

			self:despawn(self)
		end,
		draw=function(self)
			outlined_sprites(self.sprite,8,self.x-8,self.y-2,2,1)
		end
	})
end

function make_fly(x,y)
	return make_enemy_obj("fly",x,y,{
		width=8,
		hp=2,
		sprite=11,
		points=50,
		update=function(self)
			self.x-=0.4

			self:check_collision(self)

			--animate sprite
			if frame>30 then
				self.sprite=27
			else
				self.sprite=11
			end

			self:shoot_player(self,0,2)

			self:despawn(self)
		end,
		draw=function(self)
			outlined_sprites(self.sprite,8,self.x-2,self.y-2,1,1)
		end
	})
end

function make_wizard(x,y)
	return make_enemy_obj("wizard",x,y,{
		width=28,
		hp=150,
		sprite=77,
		points=2000,
		angle=0,
		boss=true,
		spawn_count=0,
		update=function(self)
			--move forward then stop when in on the right side of the screen
			if(self.x>104) self.x-=0.4

			--move up and down in sin wave
			self.y+=sin(self.angle)*1.2
			if(self.angle>10)self.angle=0
     		self.angle+=0.007

			self:check_collision(self)

			--shoot multiple times with random time offsets
			for i=0,3 do
				self:shoot_player(self,flr(rnd(20)+10),5)
			end

			--spawn flies at top and bottom of screen
			if (self.spawn_count>100) self.spawn_count=0
			self.spawn_count+=1
			if(self.spawn_count==100) make_fly(138,14) make_fly(138,94)

			trail(self.x-10,self.y-6,{false,false,false,true})

			trail(self.x+10,self.y-6,{false,false,false,true})

			self:despawn(self)
		end,
		draw=function(self)
			outlined_sprites(self.sprite,8,self.x-12,self.y-16,3,4)
		end
	})
end

function make_chicken(x,y)
	return make_enemy_obj("chicken",x,y,{
		width=8,
		hp=3,
		sprite=10,
		points=50,
		update=function(self)
			self.x-=0.45

			self:check_collision(self)

			self:despawn(self)
		end,
		draw=function(self)
			outlined_sprites(self.sprite,8,self.x-4,self.y-4,1,1)
		end
	})
end

function make_egg(x,y)
	return make_enemy_obj("egg",x,y,{
		width=28,
		hp=260,
		sprite=64,
		points=2000,
		angle=0,
		boss=true,
		final_boss=true,
		spawn_count=0,
		move_timer=0,
		angle=0,
		update=function(self)
			if not boss_dead then
				--move forward then stop when in on the right side of the screen
				if(self.x>104) self.x-=0.4

	     		--move up and down
	     		if(self.move_timer>900)self.move_timer=0
	     		self.move_timer+=1

	     		if(self.move_timer<300)self.y-=1 self.y=mid(34,self.y,94)
	     		if(self.move_timer>300 and self.move_timer<600)self.y+=1 self.y=mid(34,self.y,64)
	     		if(self.move_timer>600)self.y+=1 self.y=mid(34,self.y,94)

				for i=0,1 do
					self:shoot_player(self,0,8)
				end

				--spawn chickens
				if (self.spawn_count>300) self.spawn_count=0
				self.spawn_count+=1
				if self.spawn_count==100 then
					--spawn in a circle around boss
					for i=1,6 do
						self.angle+=60
						make_chicken(self.x+20*cos(self.angle/360),self.y+20*sin(self.angle/360))
					end
				else
					self.angle=0
				end

				self:despawn(self)
				self:check_collision(self)

				--death animation
				if self.hp<1 then
					boss_dead=true
				end
			else
				--stop music
				music(-1)

				--move boss to center
				if(self.y<64)self.y+=0.5
				if(self.y>64)self.y-=0.5

				--grow circle
				if(self.y==64)circle_size+=0.35 circle_size=mid(0,circle_size,128,7) sfx(9)

				--screen shake when circle is growing then stop and go to end state
				if circle_size>126  then 
					camera(0,0) 
					state="end" 
					if(music_on=="on")music(2)
					end_state=1 
					fade_timer=0 
				else 
					screen_shake(0.05)
				end 
			end
		end,
		draw=function(self)
			outlined_sprites(self.sprite,8,self.x-12,self.y-16,3,4)

			--blink
			if(self.spawn_count>70 and self.spawn_count<100)spr(83,self.x-12,self.y-8,2,1)

			--show cracks
			if(self.hp<175)spr(99,self.x+4,self.y-8)
			if(self.hp<125)spr(100,self.x-4,self.y-16)
			if(self.hp<75)spr(115,self.x-12,self.y+8)
			if(self.hp<25)spr(116,self.x-4,self.y+8)
		end
	})
end

function make_enemy_bullet(x,y)
	return make_enemy_obj("enemy_bullet",x,y,{
		width=4,
		update=function(self)
			self.x-=0.95
			--delete self if off screen
			if (self.x<-6) del(enemy_objs,self)
		end,
		draw=function(self)
			circfill(self.x,self.y,self.width/2,8)
			circfill(self.x,self.y,(self.width/2)-1,7)
		end
	})
end

--make bullets
function make_bullet_obj(x,y,speed,direction,colour)
	--create bullet
	local obj={
		x=x,
		y=y,
		width=6,
		colour=colour or 7,
		update=function(self)
			--choose which direction (clockwise bool) to shoot and apply speed
			if (direction[1]) self.y-=speed
			if (direction[2]) self.x+=speed
			if (direction[3]) self.y+=speed
			if (direction[4]) self.x-=speed

			--delete self if off screen
			if (self.x>134 or self.x<-6 or self.y>134 or self.y<-6) del(bullet_objs,self)
		end,
		draw=function(self)
			circfill(self.x,self.y,self.width/2,12)
			circfill(self.x,self.y,(self.width/2)-1,self.colour)
		end
	}
	--add object table to bullet table
	add(bullet_objs,obj)
	return obj
end

--make pickups
function make_pickup_obj(name,x,y,props)
	--create pickup
	local obj={
		name=name,
		x=x,
		y=y,
		width=10,
		update=function(self)
		end,
		draw=function(self)
		end,
		despawn=function(self)
			--delete self if off screen
			if (self.x<-6) del(pickup_objs,self)
		end
	}
	--loop through properties and assign it to the obj table
	local k,v
	for k,v in pairs(props) do
		obj[k]=v
	end
	--add object table to pickup table
	add(pickup_objs,obj)
	return obj
end

--e pickup
function make_energy(x,y)
	return make_pickup_obj("health",x,y,{
		update=function(self)
			self.x-=0.25
			self:despawn(self)

			--player pickup
			if circles_overlapping(self,player) then
				--add hp
				player.e_level+=15

				sfx(4)

				--delete self
				del(pickup_objs,self)
			end
		end,
		draw=function(self)
			outlined_sprites(33,12,self.x-4,self.y-4,1,1)
		end
	})
end

function make_coin(x,y)
	return make_pickup_obj("coin",x,y,{
		update=function(self)
			self.x-=0.25
			self:despawn(self)

			--player pickup
			if circles_overlapping(self,player) then
				--add coins
				player.coins+=1

				--limit coins
				player.coins=mid(0,player.coins,99)

				sfx(4)

				--delete self
				del(pickup_objs,self)
			end
		end,
		draw=function(self)
			outlined_sprites(34,12,self.x-4,self.y-4,1,1)
		end
	})
end

function make_powerup(x,y)
	return make_pickup_obj("powerup",x,y,{
		update=function(self)
			self.x-=0.25
			self:despawn(self)

			--player pickup
			if circles_overlapping(self,player) and player.powerup=="" then
				--add to powerup timer
				player.powerup_timer=300

				--select random powerup
				player.powerup=rnd({"shot speed up","double shot","burst","shield"})

				sfx(4)

				--delete self
				del(pickup_objs,self)
			end
		end,
		draw=function(self)
			outlined_sprites(49,12,self.x-4,self.y-4,1,1)
		end
	})
end

--e pickup
function make_magic(x,y)
	return make_pickup_obj("magic",x,y,{
		update=function(self)
			self.x-=0.25
			
			trail(self.x,self.y,{false,false,false,true})

			self:despawn(self)

			--player pickup
			if circles_overlapping(self,player) then
				--add magic
				player.mag_level+=25

				sfx(4)

				--delete self
				del(pickup_objs,self)
			end
		end,
		draw=function(self)
			outlined_text("★",self.x-4,self.y-3,7,12)
		end
	})
end

--iterates through an object of a specified type and call a specified function
function for_each_object(type,name,callback)
	local obj
	for obj in all(type) do
		if obj.name==name then
			callback(obj)
		end
	end
end
-->8
--collision
--circle based collision from bridgs tutorial
function circles_overlapping(obj1,obj2)
	--horizontal distance
	local dist_x=mid(-100,obj2.x-obj1.x,100)
	--vertical distance
	local dist_y=mid(-100,obj2.y-obj1.y,100)
	--real distance using using pythagoras
	local dist=sqrt(dist_x*dist_x+dist_y*dist_y)
	--return true if distance is less than the radiuses combined
	return dist<(obj1.width/2)+(obj2.width/2)
end

-->8
--functions
-- remove all items from a list
function remove(list)
	local i
	for i=1,#list do
		del(list, list[1])
	end
end

--reset game info for next level
function reset_info()
	--remove old bullets
	remove(bullet_objs)

	--remove old pickups
	remove(pickup_objs)

	--remove old enemies
	remove(enemy_objs)

	--reset level info
	level_timer=0
	level_clear,wave1=false,true

	--reset player position, points, and powerup for next level
	player.x,player.y,player.powerup,player.points,player.e_level,player.dead,player.hit_timer=25,64,"",0,116,false,0

	--reset more stats if starting from intro screen
	if state=="intro" then 
		player.lives,player.dmg,player.mag_level,player.blast_dur,player.e_gained,player.e_drain,player.coins=3,1,0,2,5,0.15,0
		e_upgrades,drain_upgrades,dmg_upgrades,blast_upgrades,magic_upgrades=1,1,1,1

		level,tutorial_state=1,1
	end

	--change to game
	state="game" 
end

--load wave from level file
function load_wave(wave)
	--check if there are any specified enemies for the chosen wave
	if wave.flies then
		for fly in all(wave.flies) do
			make_fly(fly[1],fly[2])
		end
	end

	if wave.gulls then
		for gull in all(wave.gulls) do
			make_gull(gull[1],gull[2])
		end
	end

	if wave.owls then
		for owl in all(wave.owls) do
			make_owl(owl[1],owl[2])
		end
	end

	if wave.worms then
		for worm in all(wave.worms) do
			make_worm(worm[1],worm[2])
		end
	end

	if wave.snails then
		for snail in all(wave.snails) do
			make_snail(snail[1],snail[2])
		end
	end

	if wave.chickens then
		for chicken in all(wave.chickens) do
			make_chicken(chicken[1],chicken[2])
		end
	end

	if wave.wizards then
		for wizard in all(wave.wizards) do
			make_wizard(wizard[1],wizard[2])
		end
	end

	if wave.eggs then
		for egg in all(wave.eggs) do
			make_egg(egg[1],egg[2])
		end
	end
end

-->8
--visual effect function
--draw srites with an outline
function outlined_sprites(sprite,colour,x,y,width,height,flip_x,flip_y)
	--set all colours in palette to outline colour
	for i=1,15 do
		pal(i,colour)
	end

	--draw outline of sprite
	spr(sprite,x,y+1,width,height,flip_x,flip_y)
	spr(sprite,x+1,y,width,height,flip_x,flip_y)
	spr(sprite,x,y-1,width,height,flip_x,flip_y)
	spr(sprite,x-1,y,width,height,flip_x,flip_y)

	--reset palette and draw sprite
	pal()

	if game_pal=="original" then
		pal({-15,-14,2,-3,-4,6,7,-8,6,7,-3,12,13,14,6},1)
	else
		pal({1,2,3,4,5,6,7,8,9,10,-5},1)
	end

	spr(sprite,x,y,width,height,flip_x,flip_y)
end

--print text with an outline
function outlined_text(text,x,y,colour,outline)
	--outline of text
	print(text,x,y-1,outline)
	print(text,x+1,y-1,outline)
	print(text,x+1,y,outline)
	print(text,x+1,y+1,outline)
	print(text,x,y+1,outline)
	print(text,x-1,y+1,outline)
	print(text,x-1,y,outline)
	print(text,x-1,y-1,outline)

	--text
	print(text,x,y,colour)
end

--waving text with outline
function waving_text(text,x,y,colour,outline)
	for i=0,#text,1 do
	  	outlined_text(sub(text,i,i),x+(i*4),y+sin((text_wave+i)/60)*5,colour,outline)
	end
end

--create explosion particles
function explosion(type,x,y)
	for i=1,10 do
		local my_particle={
			x=x,
			y=y,
			sx=rnd()*25-3,
			sy=rnd()*25-3,
			size=rnd(3)+1,
			age=rnd(2),
			max_age=10+rnd(10)
		}

		add(type,my_particle)
	end
end

--draw explosion
function draw_explosion(type,colours)
	for my_particle in all(type) do
		--change colour based on time
		local colour=colours[1]
		if my_particle.age>5 then
			colour=colours[1]
		end
		if my_particle.age>7 then
			colour=colours[2]
		end
		if my_particle.age>12 then
			colour=colours[3]
		end
		if my_particle.age>15 then
			colour=colours[4]
		end 

		--draw explosion particles
		circfill(my_particle.x,my_particle.y,my_particle.size,colour)

		--move particles
		my_particle.x+=my_particle.sx
		my_particle.y+=my_particle.sy

		my_particle.sx*=0.5
		my_particle.sy*=0.5

		--count up age
		my_particle.age+=1

		--decrease size
		if my_particle.age>my_particle.max_age then
			my_particle.size-=0.5
			if my_particle.size<0 then
				del(type,my_particle)
			end
		end
	end
end

--trail effect
function trail(x,y,direction)
	for i=1,3 do
		local my_particle={
			x=x+(flr(rnd(6)-3)),
			y=y+(flr(rnd(6)-3)),
			direction=direction,
			time=flr(rnd(10))+10
		}
		add(trail_particle,my_particle)
	end
end

--draw the trail
function draw_trail(colour)
	for my_particle in all(trail_particle) do
		--move particle based on direction of the object theyre trailing (clockwise)
		if (my_particle.direction[1]) my_particle.y+=1 
		if (my_particle.direction[2]) my_particle.x-=1
		if (my_particle.direction[3]) my_particle.y-=1
		if (my_particle.direction[4]) my_particle.x+=1   

		--tick down time
		my_particle.time-=1
		if(my_particle.time<0) del(trail_particle,my_particle)

		pset(my_particle.x,my_particle.y,colour)
	end
end

--screen shake
function screen_shake(intesity)
	local shakex,shakey=16-rnd(32),16-rnd(32)
	camera(shakex*intesity,shakey*intesity)
end

-->8
--background
--draw background trees
function front_trees(x)
	rect(11+x,35,17+x,99,2)
	rectfill(12+x,35,16+x,99,4)
	spr(35,8+x,29,2,1)

	rect(34+x,35,41+x,99,2)
	rectfill(35+x,35,40+x,99,4)
	spr(38,30+x,29,2,1)

	rect(56+x,35,62+x,99,2)
	rectfill(57+x,35,61+x,99,4)
	spr(35,53+x,29,2,1)

	rect(78+x,35,85+x,99,2)
	rectfill(79+x,35,84+x,99,4)
	spr(38,74+x,34,2,1)

	rect(98+x,35,102+x,99,2)
	rectfill(99+x,35,101+x,99,4)
	spr(37,96+x,33)

	rect(118+x,35,125+x,99,2)
	rectfill(119+x,35,124+x,99,4)
	spr(38,114+x,27,2,1)

	leaves(x,0,0,3)
	leaves(x,0,-1,11)

	rectfill(-3+x,2,5+x,26,11)
end

function back_trees(x)
	rectfill(5+x,51,13+x,99,2)
	rectfill(26+x,51,32+x,99,2)
	rectfill(41+x,51,46+x,99,2)
	rectfill(58+x,51,66+x,99,2)
	rectfill(72+x,51,78+x,99,2)
	rectfill(84+x,51,90+x,99,2)
	rectfill(110+x,51,117+x,99,2)

	leaves(x,25,7,3)
end

function leaves(x,y,width,colour)
	circfill(12+x,15+y,15+width,colour)
	circfill(28+x,28+y,7+width,colour)
	circfill(38+x,14+y,16+width,colour)
	circfill(52+x,17+y,14+width,colour)
	circfill(72+x,15+y,20+width,colour)
	circfill(89+x,31+y,7+width,colour)
	circfill(101+x,15+y,17+width,colour)
	circfill(121+x,13+y,16+width,colour)
end

function static_background()
	back_trees(0)
	front_trees(0)
	rectfill(0,96,128,128,3)
	map(0,0)
end
__gfx__
00000000000000001110000000000000000000000000000077700000000001111110000000000000011111000000000000000000111100000000000000000000
00000000000000001c11100000000000000000000000000078777000000001888810000000000000017771110001111100000011167100000000000111111000
007007000000000011cc110000000000111110000000000077887700000001888810000000000000117171710011777100000116771101110000001122ee1100
000770000000000011ccc110000000001ccc11000000000077888770000001888810000000000000199777711117777100111167771111710111111222eee110
00077000000000011ccccc100000000011ccc110000000077888887000000188881000000000000011877771185566111117c7777777771111eeeee222eeee11
0070070000000001ceeff110000000011ccccc100000000788888770000001888810000000000000011877111555111119977777777771111e2eeee2211eeee1
00000000000000011efff10000000001ceeff1100000000778888700000001888810000000000000001111101111100011111111111111101eeeeee11111eee1
0000000001111011ccc11100000000011efff1000777707788877700000001888810000000000000000000000000000000000000000000001111111100011111
000000001144111eeeeef11100111011ccc111007788777888888777111111888811111100000000000000000000000000000000000000000111100111111000
000000001444444eee4444411114111eeeeef11178888888888888871188888888888811000000000000000000111110000000000000011111ee111122ee1100
00000000111411cee11111111444444eee4444417778778887777777011888888888811000000000000000000116661100111111111111711e2ee11222eee110
00000000001111c111000000114411cee1111111007777877700000000118888888811000000000000000000116677711117c777777777111eeeee2222eeee11
000000000000011100000000011111c111000000000007770000000000011888888110000000000000000000185777711997777777777110111eeee2211eeee1
00000000000000000000000000000111000000000000000000000000000011888811000000000000000000001555111111111167771111000011eeee1111eee1
000000000000000000000000000000000000000000000000000000000000011881100000000000000000000011111000000001167771000000011ee110011ee1
00000000000000000000000000000000000000000000000000000000000000111100000000000000000000000000000000000011111100000000111100001111
000000000000000001111110244224442244444224422442024444222244444200000000bbbbb300000000000000000000000001111100001111110011111000
000000000111111011aaaa11244422442444422002442442002444422444442000000000bbbbb30000000000000000000000001124f110001333310114441100
0000000011cccc1119aaaaa1024444244444200000244442000244442444420000000000bbbbbb30000000000000000000000112444f10001313311444444100
000000001dcddcc119a99aa1002444444442000000244442000244444444200030000000bbbbbb3000000000000000000000112444ff10001333332444444110
000000001dccccc119aa9aa10002444444200000002444200002444444442000b3000000bbbbbb300000000000000000000112444ff110001113333244442211
0000000011dddd1119aaaaa10002444442000000002444200000244444420000bb300000bbbbbb30011111111111000001112444ff1100000011333322222331
0000000001111110119999110002444442000000002444200000244444420000bb300000b3bbbbb3114444444441111111444444444111110001133333333331
0000000000000000011111100002444442000000002444200000244444420000bbb330003b3bbbb31f1144444444fff11f1144444444fff10000111111111111
00000000001111100111000033333333333333330000333300000000003bbbbbbbbbbbbb330000001f2f444444f4f1111f2f44444444f1110111111011111000
000000000118881101c1110033b333333b33b3330003bbbb00000000003bbbbbbbbbbbbbbb3000001fff424444ff11001fff4444444f11000133331114441100
0000000001811181011cc1103b3b333333b3b333033bbbbb0000000003bbbbbbbbbbbbbbbbb3000019f4424444ff100019f44444441110000131331444444111
0000000001811181011ccc1133b33333333333333bbbbbbb0000000303bbbb3bbbbbbbbbbbbb300011112244444f000011111111241100000133332444442331
000000000111881111ccccc13333333333333333bbbbb3bb0000003b3bbbbbb3bbbbbbbb3bbb30000001122444f1000000000001129100000113333244442331
00000000000111101ceeff1133333b33333b33b3bbbbbbbb000003bb3bbbbbbbbbbbbbbbbbbbb330000011222211000000000000111100000011333322223331
000000000001810011efff10333333b333b3b333bbbbbbbb000003bb3bbbbbbbbbbbbbbbbbb3bbb3000001111110000000000000000000000001133333333331
0000000000011100011111103333333333333333bbbbbbbb00033bbb3bbbbbbbbbbbbbbbbbbbbbb3000000000000000000000000000000000000111111111111
000000011111111000000000001fffffffffffff0000000111111110000000007ccccccc00000000000001111000000000000000000000000000011110000000
00000011ffffff1100000000011fffffffffffff00000111cccccc111000000077cccccc00000000000011cc1110000000000000000000000001118811000000
0000011ffffffff11000000001ffffffffffffff000011cccccccccc1100000077cccccc0000000000001d1dcc11000000000000000000000011888881100000
000011ffffffffff1100000001ffffffffffffff00001cccccccccccc10000007774c4cc000000000000111ddcc1100000000000000000000118888288100000
00001ffffffffffff100000011ffffffffffffff00011cccccccccccc1100000777c4ccc0000000000000011dccc111110000000000000000188888828100000
00011ffffffffffff11000001fff1ff1ffff1ff10001cccccccccccccc1000007777cccc000000000011111dcccccccc10000000000000000188288822100000
0001ffffffffffffff1000001ffff11ffffff11f0001cccccccccccccc1000007777cccc00000000001ddddcceef111110000000000000001182228821100000
0011ffffffffffffff1100001fffffffffffffff00117777cccccccccc100000e777cccc00000000001111eeee1f100000000000000000001822222821000000
001fffffffffffffff210000001fffffffffffff001777777ccc4ccccc110000000000000000000000011eeeefff100000000000008000001812212821000800
011fffffffffffffff211000011fffffffffffff0017777777c474ccccc1000000000000000000000001eeccccc1100000000000087800001822222821008780
01ff1ffffffffff1ff22100001ffffffffffffff0017777777c414ccccc10000000000000000000000011ceeeec1100000000000111110001822222821011111
01fff1ffffffff1fff22100001ff1ffffffffff101177777777414ccccc10000000000000000000000011eeeeeec1000000000001fff1110188222882111fff1
11fff11ffffff11fff22110011fff1ffffffff1f01777777777c4cccccc1000000000000000000000011eeeeeeee11111111100011f288111888288821182f11
1ffff171ffff171fff2221001fffff1ffffff1ff017eeee77777ccccccc100000000000000000000001eeee2eeeeeeff14441000011128888828882888822110
1ffff17ffffff71fff2221001ffffff1ffff1fff01eeeeee7777ccccccc1100000000000000000000012eeee2eeeeef441111000000118888882228888821100
1fffff1ffffff1fff22221001fffffffffffffff01eeeeeee777cccccccc100000000000000000000012eeeee2eeee1111000000000018888888888888821000
1ffffffffffffffff2222100ff2100001111111001eeeeeee7777ccccccc1000000000000111100000112eeeee222e1000000000000018888888888888821000
1ffffffffffffffff2222100ff211000ff1fff1101e7777eee777ccccccc10000000000001441111111442eeeeeee11000000000000012888888888888821000
1ffffffff11fffff222221001f221000ff1ffff101777777ee777ccc1ccc10000000000001144441444112eeeeeee10000000000000011288888888888211000
1fffffff1221ffff222221001f221000fff1ffff01777777ee777cc1cccc1000000000001144442411112eeee221110000000000000001128888888888210000
1fffffff1221fff222222100f1211100fff1ffff11777777e777771ccccc100000000000124422111122eeee2211000000000000000000188888888882210000
1ffffffff11fff2222222100f1122100ff1f1fff17777777777777cccccc10000000000011221110012eeeeedd10000000000000000001188888888821110000
1ffffffffffff222222221001f222100f1fff1ff17777777777777cccccc1000000000001211100001111cc11110000000000000000011888888888821000000
1fffffffffff222222222100f2222100ffffff1f17777777777777cccccc10000000000011100000000011110000000000000000000118888888888821000000
11fffffffff222222222110011ffff1f1ff2212217777777777777cc1ccc10000000000000000000000000000000000000000000000188888888888821000000
01ffffffff2222222222100001f11f1ff122122217777777777777c1cccc11000000000000000000000000000000000000000000000111111222888221000000
011fffff2222222222211000011ff1f122121222177777777777771cccccc1000000000000000000000000000000000000000000000000001111282221000000
0011f22222222222221100000011f2212221222217777777777777ccccccc1000000000000000000000000000000000000000000000000000001122221000000
000112222222222221100000000112222221222217777777777777ccccccc1000000000000000000000000000000000000000000000000000000122221000000
000011222222222211000000000011222212222217777777777777ccccccc1000000000000000000000000000000000000000000000000000000112211000000
000001122222222110000000000001122212222117777777777777ccccccc1000000000000000000000000000000000000000000000000000000012110000000
000000111111111100000000000000111111111117777777777777ccccccc1000000000000000000000000000000000000000000000000000000011100000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000077700000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000711177000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000071d111700000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000711dc1170000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000711dc117000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000071dcc11700000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000007711dddc1170000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000077111dccccc117770000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000007111ddddccccc11117000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000071ddddd2efeccccc17000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000007111112effee111117000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000077771ef1f1e177770000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000007112ffffe117000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000071222ff22e17000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000007122cccc2217000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000007117ccc7c117000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000711ec7c7cee11700000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000071eeec7ceeee1700000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000711eee7c7eeee1700000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000071eeeee7eeeee1170000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000071eeeee7eeeeee170000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000711eeeee7eeeeee170000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000071eeeeee7eeeeee170000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000071eeeeeeeeeeeee117000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000071eeeeeeeeeeeeee17000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000711eeeeeeeeeeeeee17000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000712eeeeeeeeeeeeee17000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000712eeeeeeeeeeeeee17000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000712eeeeeeeeeeeeee17000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000071f2eeeeeeeeeeeee17000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000071ffeeeeeeeeeeeef17000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000711f2eeeeeeeeeeff17000000
00000eeeeeeeeeeee00000e00000e0000000000000000000000000000000000000000000000000000000000000000000000000007112eeeeeeeee2f117000000
0000eeeeeeeeeeeee0000ee0000ee00000000000000000000000000000000000b0000000000000000000000000000000000000000712eeeeeeeee21170000000
000eeeeeeeeeeeeee000eee000eee00000000000000000000000000000000000b0000000000000000000000000000000000000000712eeeeeeeee21700000000
00e11111111111eee001eee001eee00000000000000000000000000000000000b0000000000000000000000000000000000000000712eeeeeeeee21700000000
0e00000e000001eee001eee001eee00000000000000000000000000000e0000000000000000000000000000000000000000000000712eeeeeeeeee1700000000
1e00e01e000001eee001eee001eee00000000e0000e000000000000001e0000000000000000000000000000000000000000000000712eeeeeeeee21700000000
11ee00eee00001eee001eee001eee000000010000e0000000eee00000e00000000000000000000000000000000000000000000000712eeeeeeeeee1700000000
01100eeeee0001eee001eee001eee000000e00eee000000ee111e0001e00000000000000000000000000000000000000000000000712eeeeeeeeee1700000000
000011eee00001eee001eee001eee000001e011e1ee000ee00011e00ee0eee00000000000000000000000000000000000000000007122eeeeeeeee1700000000
0000011e000001eee001eee001eee00000e000e011000e1e0000100e1ee111e0000000000000000000000000000000000000000007122eeeeeeeee1700000000
0000001e000001eeee01eeee01eeee0001e00ee00000e1e00000001e1e000e000000000000000000000000000000000000000000071222eeeeeee11700000000
0000001e0000e1eeeee1eeeee1eeeee00e00e1e0000e01e0000000e0e0001e0000000000000000000000000000000000000000000712222eeee2117000000000
0000001e00011e1eeeee1eeeee1eeeee1e0e01e0001e01e000000e01e000e00e000000000000000000000000000000000000000007122222222d170000000000
0000001e00001011eee011eee011eee01e1e01e000e0011e0000e00e0001e0e000000000000000000000000000000000000000000712222211dc170000000000
0000001e000000011e00011e00011e0011e0011eee000011eeee001e00011e0000000000000000000000000000000000000000000711222d11cc170000000000
00000010000000001000001000001000010000111000000111100010000010000000000000000000000000000000000000000000007111dc1111170000000000
00000eeeeee00000000000000000000000000000000000000000000000000000000000000000000000000000b000000000000000000771cc1777700000000000
0000eeeeeee000000000000000000000000000000000000000000000e0000000000000000000000000000000b000000000000000000071111700000000000000
000eeeeeeee000000000000000000000000000000000000000000001e00000000000000000000000000000000000000000000000000007777000000000000000
001eee11ee0000000e0000000000000000000000000000000000000eee0000000000000000000000000000000000000000000000000000000000000000000000
001eee01e0000000e0000000000000000000000000000000000000eeeee000000000000000000000000000000000000000000000000000000000000000000000
001eee0e0000000e000000000000000000000000e00000000000011eee0000000000000000000000000000000000000000000000000000000000000000000000
001eeeeeeeee001e00000000000000000000000e0000000000000011e00000000000000000000000000000000000000000000000000000000000000000000000
001eeeeeeeee00e000000ee0000000000000eee000000ee000000001e00000000000000000000000000000000000000000000000000000000000000000000000
001eeeeeeeee01e00000e11e00000eee00011e1ee000e11e00000001e000e0000000000000000000000000000000000000000000000000000000000000000000
001eee111eee0e00000e001e0000e111e00ee0110001e01e00e00001e001e0000000000000000000000000000000000000000000000000000000000000000000
001eeee01eee1e0000e0001e000e0001e0e1e000000e00e00ee00001000e00000000000000000000000000000000000000000000000000000000000000000000
0e1eeeee1eee1e000e0000e000e00eeeee01e000001e0e00e11e0000001e00000000000000000000000000000000000000000000000000000000000000000000
11e1eeeeeee01e00ee000ee00e00e11e1001e00000eee00e0011e00000e000000000000000000000000000000000000000000000000000000000000000000000
01011eeeee001e0e1e00e1e0e00e00e00001e000ee11e0e000011eeeee0000000000000000000000000000000000000000000000000000000000000000000000
000011eee00011e011ee011e0011ee0000011eee10011e0000001111100000000000000000000000000000000000000000000000000000000000000000000000
00000111000001000110001000011000000011100000100000000000000000000000000000000000000000000000000000000000000000000000000000000000
__label__
ccccccccc2222222cccccccccccccc22ttttttttttttt22cccccccccccc2ttttttttttttttttttttttttt2ccccccc22ttttttttttttt22cc2ttttttttttttttt
cccccc222ttttttt222cccccccccc2ttttttttttttttttt2cccccccccc2ttttttttttttttttttttttttttt2cccc22ttttttttttttttttt22tttttttttttttttt
ttttttttttttttttttt22cccccc22ttttttttttttttttttt22ccccccc2ttttttttttttttttttttttttttttt2cc22tttttttttttttttttttttttttttttttttttt
tttttttttttttttttttt22cccc22ttttttttttttttttttttt22222222ttttttttttttttttttttttttttttttt22tttttttttttttttttttttttttttttttttttttt
tttttttttttttttttttttt2ccc2ttttttttttttttttttttttttttttt2ttttttttttttttttttttttttttttttt2ttttttttttttttttttttttttttttttttttttttt
ttttttttttttttttttttttt2c2tttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttt
tttttttttttttttttttttttt2ttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttt
tttttttttttttttttttttttt2ttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttt
tttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttt
tttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttt
tttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttt
tttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttt
tttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttt
tttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttt
ttttttttttttttttttttttttttttthhhhhhhhhhhhttttthttttthttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttt
ttttttttttttttttttttttttttttheeeeeeeeeeeehttthehttthehtttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttt
tttttttttttttttttttttttttttheeeeeeeeeeeeehttheehttheehtttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttt
ttttttttttttttttttttttttttheeeeeeeeeeeeeehtheeehtheeehtttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttttt
ttttttttttttttttttttttttthehhhhhhhhhhheeehhheeehhheeehtttttttttttttttttttttttttttthttttttttttttttttttttttttttttttttttttttttttttt
tttttttttttttttttttttttthehhhhhehhhhhheeehhheeehhheeehttttttthtttthtttttttttttttthehtttttttttttttttttttttttttttttttttttttttttttt
ttttttttttttttttttttttthhehhehhehttthheeehhheeehhheeehtttttthehtthehttttthhhtttthhehtttttttttttttttttttttttttttttttttttttttttttt
ttttttttttttttttttttttthhheehheeehtthheeehhheeehhheeehttttthhhhhhehtttthheeehttthehttttttttttttttttttttttttttttttttttttttttttttt
tttttttttttttttttttttttthhhhheeeeehthheeehhheeehhheeehtttthehheeehhtttheehhhehthhehhhhtttttttttttttttttttttttttttttttttttttttttt
tttttttttttttttttttttttt2hhhhheeehtthheeehhheeehhheeehttthhehhheheehtheehhhhhehheeheeehttttttttttttttttttttttttttttttttttttttttt
tttttttttttttttttttttttttttthhhehttthheeehhheeehhheeehttthehthehhhhthehehtthhhheheehhhehtttttttttttttttttttttttttttttttttttttttt
ttttttttttttttttttttttttttttthhehttthheeeehheeeehheeeehthhehheehhhthehehtttthhhehehhhehttttttttttttttttttttttttttttttttttttttttt
ttttttttttttttttttttttttttttthhehttheheeeeeheeeeeheeeeehhehhehehtthehhehttttthehehthhehhtttttttttttttttttttttttttttttttttttttttt
22222ttttttttttttttt22ttttttthhehthhheheeeeeheeeeeheeeeehehehhehthhehhehtttthehhehthehhehtttttttttttttttttttttttt22ttttttttttttt
222222ttttttttttttt222ttttttthhehtthhhhheeehhheeehhheeehhehehhehhhehhhhehhhhehhehthhehehttttttttttttttttttttttt2222222ttttttt222
222222222ttttttt222tt2ttttttthhehttththhheh2hhhehthhhehhhhehhhheeehtthhheeeehhhehthhhehttttttttttttttttttttttt2222222i2222222tti
22222222i2222222itttt2ttttttthhhttt2222hhhttihhh2tthhhtthhh2thhhhhtttthhhhhhthhhttthhhtttttttttttttttttttttt222222222itttttttti2
222222222ittttittttti22ttttttthttt2tttithtti22h22222h222thti22hhhtttttthhhhttthttttthttttttttttt22ttttttt222222222222itttttttti2
2222222222itttttttti2222ttttttttt22ttttttti222222222222ittttt22ttttttttttttttttttt2ttttttttttttt2222222222222222222222itttttti22
22222222222itttttti222222ttttttt22tttttttti2222222222222itttttt22ttttttttttttttt222ttttttttttttt2ttiitti22222222222222itttttti22
22222222222ittttti22222222ttttt222itttttti222hhhhhh22222ittttti22222ttttttttt222iii2ttttttttttt22ittitti22222222222222itttttti22
22222222222ittttti2222222222222222itttttti22heeeeeeh2222ittttti22222222222222ttttii22ttttttttt22h2itttti22222222222222itttttti22
22222222222ittttti2222222222222222itttttti2heeeeeeeh2222ittttti22222222222222ittttit22ttttttt22hehitttti22222222222222itttttti22
22222222222ittttti2222222222222222ittttttiheeeeeeeeh2222ihtttti22222222222222ittttttt22ttttt22hhehittti222222222222222itttttti22
22222222222ittttti2222222222222222itttttthheeehheeh22222hehttti22222222222222itttttttti2222222heeehttti222222222222222itttttti22
22222222222ittttti2222222222222222itttttthheeehheh22222hehtttti222222222222222ithtttti2222222heeeeehtti222222222222222itttttti22
22222222222ittttti2222222222222222itttttthheeehehhhh22hehttttti222222222222222ihehttti222222hhheeehttti222222222222222itttttti22
22222222222ittttti2222222222222222itttttthheeeeeeeeehhhehtttthh2222222222222hhhehtttthh222222hhhehittti222222222222222itttttti22
22222222222ittttti2222222222222222itttttthheeeeeeeeehhehitttheeh22222hhh222heeehhtttheeh222222hhehithti222222222222222itttttti22
22222222222ittttti2222222222222222itttttthheeeeeeeeehhehitthehheh222heeeh2hhheheehthehheh2h222hhehihehi222222222222222itttttti22
22222222222ittttti2222222222222222itttttthheeehhheeeheh2ithehhheh22hehhhehheehhhhthhehhehheh22hhehhhehi222222222222222itttttti22
22222222222ittttti2222222222222222itttttthheeeehheeeheh2ihehthheh2hehhhhehehehhhtthehhehheeh22hhh2hehti222222222222222itttttti22
22222222222ittttti2222222222222222itttttheheeeeeheeeheh2hehttheh2hehheeeeehhehitthhehehhehheh22h2hhehti222222222222222itttttti22
22222222222ittttti2222222222222222itttthhheheeeeeeehhehheehtheehhehhehhehhhhehithheeehhehhhhehhhhhehtti222222222222222itttttti22
22222222222ittttti2222222222222222ittttthhhhheeeeehhhehehehhehehehhehhehh2hhehhheehheheh22hhheeeeehttti222222222222222itttttti22
22222222222ittttti2222222222222222itttttth2hhheeeh2hhhehhheehhhehhhheeh222hhheeehhhhheh2222hhhhhhhittti222222222222222itttttti22
22222222222ittttti2222222222222222itttttti22hhhhh222hhh2hhhhthhh22hhhh22222hhhhhhtthhh222222hhhhh2ittti222222222222222itttttti22
22222222222ittttti2222222222222222itttttti222hhh22222h22ihhttth2222hh2222222hhhttttthi222222222222ittti222222222222222itttttti22
22222222222ittttti2222222222222222itttttti22222222222222ittttti222222222222222itttttti222222222222ittti222222222222222itttttti22
22222222222ittttti2222222222222222itttttti22222222222222ittttti222222222222222itttttti222222222222ittti222222222222222itttttti22
22222222222ittttti2222222222222222itttttti22222222222222ittttti222222222222222itttttti222222222222ittti222222222222222itttttti22
22222222222ittttti2222222222222222itttttti22222222222222ittttti222222222222222itttttti222222222222ittti222222222222222itttttti22
22222222222ittttti2222222222222222itttttti22222222222222ittttti222222222222222itttttti222222222222ittti222222222222222itttttti22
22222222222ittttti2222222222222222itttttti22222222222222ittttti222222222222222itttttti222222222222ittti222222222222222itttttti22
22222222222ittttti2222222222222222itttttti22222222222222ittttti222222222222222itttttti222222222222ittti222222222222222itttttti22
c2222222222ittttti2222222222222222itttttti22222222222222ittttti222222222222222itttttti222222222222ittti222222222222222itttttti22
cc222222222ittttti2222222222222222itttttti22222222222222ittttti222222222222222itttttti222222222222ittti222222222222222itttttti22
ccccc222222ittttti2222222222222222itttttti22222222222222ittttti222222222222222itttttti222222222222ittti22222222222iii2itttttticc
ccccciii222ittttti2222222222222222itttttti2ii22222222222ittttti222222222222222itttttti222222222222ittti222222222iiiiiiitttttticc
ccccciiiiiiittttti2222222222222222ittttttiiiiiic22222222ittttti222222222222222itttttti222222222222ittti2222222iiiiiiiiitttttticc
ccccciiiiiiitttttic222222222222222ittttttiiiiiicccccccccittttti222222222222222itttttti222222222222ittti222cccciiiiiiiiitttttticc
ccccciiiiiiittttticcc2222222222222ittttttiiiiiicccccccccittttti222222222222222itttttti222222222222ittticcccccciiiiiiiiitttttticc
ccccciiiiiiittttticccc222222222222ittttttiiiiiicccccccccitttttii22222222222222itttttti222222222222ittticcccccciiiiiiiiitttttticc
ccccciiiiiiittttticcccccc2222222icittttttiiiiiicccccccccitttttiiiii22222222222itttttti222222222222ittticcccccciiiiiiiiitttttticc
ccccciiiiiiittttticccccccciiiiiiicittttttiiiiiicccccccccitttttiiiiiccccciiiiiiitttttti22222222222cittticcccccciiiiiiiiitttttticc
ccccciiiiiiittttticccccccciiiiiiicittttttiiiiiicccccccccitttttiiiiiccccciiiiiiitttttti2222222222ccittticcccccciiiiiiiiitttttticc
ccccciiiiiiittttticccccccciiiiiiicittttttiiiiiiccccccchhhhhhhhhhhhhhhhhhhhiihhhhhhhtti2222222cccccittticcccccciiiiiiiiitttttticc
ccccciiiiiiittttticccccccciiiiiiicittttttiiiiiicccccchhcchccchccchccchccchihh77777hhtiiiiiicccccccittticcccccciiiiiiiiitttttticc
ccccciiiiiiittttticccccccciiiiiiicittttttiiiiiicccccchchhhhchhchchchchhchhih77h7h77htiiiiiicccccccittticcccccciiiiiiiiitttttticc
ccccciiiiiiittttticccccccciiiiiiicittttttiiiiiicccccchccchhchhccchcchhhchiih777h777htiiiiiicccccccittticcccccciiiiiiiiitttttticc
ccccciiiiiiittttticccccccciiiiiiicittttttiiiiiicccccchhhchhchhchchchchhchiih77h7h77htiiiiiicccccccittticcccccciiiiiiiiitttttticc
ccccciiiiiiittttticccccccciiiiiiicittttttiiiiiicccccchcchhhchhchchchchhchiihh77777hhtiiiiiicccccccittticcccccciiiiiiiiitttttticc
ccccciiiiiiittttticccccccciiiiiiicittttttiiiiiicccccchhhhthhhhhhhhhhhhhhhiiihhhhhhhttiiiiiicccccccittticcccccciiiiiiiiitttttticc
ccccciiiiiiittttticccccccciiiiiiicittttttiiiiiicccccccccitttttiiiiiccccciiiiiiittttttiiiiiicccccccittticcccccciiiiiiiiitttttticc
ccccciiiiiiittttticccccccciiiiiiicittttttiiiiiicccccccccitttttiiiiiccccciiiiiiittttttiiiiiicccccccittticcccccciiiiiiiiitttttticc
ccccciiiiiiittttticccccccciiiiiiicittttttiiiiiicccccccccitttttiiiiiccccciiiiiiittttttiiiiiicccccccittticcccccciiiiiiiiitttttticc
ccccciiiiiiittttticccccccciiiiiiicittttttiiihhhhhhhhhhhhhhhhhhhhhiicccccihhhhhhhtttttiiiiiicccccccittticcccccciiiiiiiiitttttticc
ccccciiiiiiittttticccccccciiiiiiicittttttiiih777h7h7hh77h777hh77hhhhcccchh77h77hhttttiiiiiicccccccittticcccccciiiiiiiiitttttticc
ccccciiiiiiittttticccccccciiiiiiicittttttiiih777h7h7h7hhhh7hh7hhhh7hcccch7h7h7h7httttiiiiiicccccccittticcccccciiiiiiiiitttttticc
ccccciiiiiiittt22icccccccciiiiiiicittttttiiih7h7h7h7h777hh7hh7hiihhhcccch7h7h7h7httttiiiiiicccccccittticcccccciiiiiiiiitttttticc
ccccciiiiiiitt2tt2cccccccciiiiiiicittttttiiih7h7h7h7hhh7hh7hh7hhhh7hcccch7h7h7h7httttiiiiiicccccccittticcccccciiiiiiiiitttttticc
ccccciiiiiiit2tttt2ccccccciiiiiiicittttttiiih7h7hh77h77hh777hh77hhhhcccch77hh7h7httttiiiiiicccccccittticcccccciiiiiiiiitttttticc
ccccciiiiiiit2tttt2ccccccciiiiiiicittttttiiihhhhhhhhhhhhhhhhhhhhhiiccccchhhhhhhhhttttiiiiiicccccccittticcccccciiiiiiiiitttttticc
ccccciiiiii22tttttt22ccccciiiiiiicittttttiiiiiicccccccccitttttiiiiiccccciiiiiiittttttiiiiiicccccccittticcccccciiiiiiiiitttttticc
ccccciiiii2tttttttttt2cccciiiiiiicittttttiiiiiicccccccccitttttiiiiiccccciiiiiiittttttiiiiiic222222ittticcccccciiiiiiiiitttttticc
ccccciiiii2tttttttttt2cccciiiiiiicittttttiiiiiicccccccccitttttiiiiiccccciiiiiiittttttiiiiii2tttttt2ttticcccccciiiiiiiiitttttticc
ccccciiii2tttttttttttt2ccciihhhhhhhhhhhthhhhhhhhhhhhhhhhhtttttiiihhhhhhhhhhhhhhhhhhhhhhhhhhhhhhtttt2tticcccccciiiiiiiiitttttticc
ccccciiii2tttt2ttttttt2ccciih777h777h7hth777h777h777h777hhhhttiihh77h777h777hh77h777h77hh777h7httttt2ticcccccciiiiiiiiitttttticc
ccccciii2tttttt2tttttt2ccciih7h7h7h7h7hth7hhhh7hhh7hh7hhhh7httiih7h7h7h7hh7hh7hhhh7hh7h7h7h7h7ht2ttt2ticcccccciiiiiiiiitttttticc
ccccciii2ttttttttttttt2ccciih777h777h7hth77hih7hch7hh77hihhhttiih7h7h77hhh7hh7hhhh7hh7h7h777h7htttttt22ccccccciiiiiiiiitttttticc
ccccciii2tttttttt2ttttt2cciih7hhh7h7h7hhh7hhhh7hch7hh7hhhh7httiih7h7h7h7hh7hh7h7hh7hh7h7h7h7h7hhhtt2ttt2cccccciiiiiiiiitttttticc
ccccciii2ttttttt2t2tttt2cciih7hih7h7h777h777hh7hch7hh777hhhhttiih77hh7h7h777h777h777h7h7h7h7h777htttttt2cccccciiiiiiiiitttttticc
2222222222222222222222222222hhh2hhhhhhhhhhhhhhhh2hhhhhhhh2222222hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh2222222222222222222222222222222
222222222t22t2222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222
2222222222t2t2222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222
22222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222
22222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222
22222222222t22t22222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222
2222222222t2t2222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222
22222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222
22222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222
22t222222222222222222222222222222t22t22222222222222222222222222222222222222222222222222222222222222222222t22t2222222222222222222
2t2t222222222222222222222222222222t2t222222222222222222222222222222222222222222222222222222222222222222222t2t2222222222222222222
22t22222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222
22222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222
22222t22222222222222222222222222222t22t22222222222222222222222222222222222222222222222222222222222222222222t22t22222222222222222
222222t222222222222222222222222222t2t222222222222222222222222222222222222222222222222222222222222222222222t2t2222222222222222222
22222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222
22222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222
222222222222222222222222222222222222222222222222222222222t22t2222222222222222222222222222222222222t22222222222222222222222222222
2222222222222222222222222222222222222222222222222222222222t2t222222222222222222222222222222222222t2t2222222222222222222222222222
22222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222t22222222222222222222222222222
22222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222
22222222222222222222222222222222222222222222222222222222222t22t22222222222222222222222222222222222222t22222222222222222222222222
2222222222222222222222222222222222222222222222222222222222t2t22222222222222222222222222222222222222222t2222222222222222222222222
22222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222
22222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222
2222222222t2222222222222222222222t22t22222222222222222222222222222222222222222222t22t2222222222222222222222222222222222222222222
222222222t2t2222222222222222222222t2t222222222222222222222222222222222222222222222t2t2222222222222222222222222222222222222222222
2222222222t222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222
22222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222
2222222222222t222222222222222222222t22t22222222222222222222222222222222222222222222t22t22222222222222222222222222222222222222222
22222222222222t2222222222222222222t2t222222222222222222222222222222222222222222222t2t2222222222222222222222222222222222222222222
22222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222222

__map__
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000362800000000000000000000003628000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0036280000000000000000000000000000003628000000000000000000372900003628000000000000003729000000000000000000362800000000000036280000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0037290000000000000036353900000000003729362800000000003635383839003729000000000036353838390000000000003628372900000000000037290000000000000036353900000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0034000000000000000000000000000000000000000000000000000000330000000000000000000000000000003300000000000000000000000000000034000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3300000034000000000000000034000034000000000033000000330000000000000000340000000034003400000000000000003300000033330000343300000034000000000000000034000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000034000000003300000000003400000000003300000033003400000000000033000000000000000000000000000034000000003300000000000000000034000000003300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0033000034000000000034000000000000000000003300000000000000000000000033000000000000000000330033000000340000000000000000000033000034000000000034000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__sfx__
0303000024053240531a6501b6501d6502065022650266502a6502d65028000126001160011600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
030300001205315450174501545022650206501e6501c6501b6501a65019650186501765000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
130300002305322550205501c5501a550165501355500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1b0300002f5532f550256501e6501a65018650156501465014650146501565017650196501a6501a6501a650196501765016650186501a6501b65017650156501665019650196501865018650186501a65019655
010300000f050160501d0502505000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010300000d553125501355000000195531e5501f55000000195531e5501f550000000d5531255013550000000d553125501355000000195531e5501f550000000d553125501355000000255002b5000000000000
110500000f55015550195500050022550285502e55000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
01030000195531e5501f55000000255532a5502b55000000255532a5502b55000000195531e5501f55000000195531e5501f55000000255532a5502b55000000195531e5501f55000000255002b5000000000000
000400000a5530d550115501655000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
070c000009650086500b6500b65008600086000860004600036000860009600086000760000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
191000000c1500c1500c1500c1400c1400c1400c1300c1300c1300c1200c1200c1200c1100c1150c1000c1000e1500e1500e1500e1400e1400e1400e1300e1300e1300e1200e1200e1200e1100e1150c1000c100
191000001b5501b5501b5501b5401b5401b5401b5301b5301b5301b5201b5201b5201b5101b51518000180001d5501d5501d5501d5401d5401d5401d5301d5301d5301d5201d5201d5201d5101d5151800000000
191000002275422750227502274022740227402273022730227302272022720227202271022715187001870024754247502475024740247402474024730247302473024720247202472024710247151870000700
19100000091500915009150091400914009140091300913009130091200912009120091100911500100001000b1500b1500b1500b1400b1400b1400b1300b1300b1300b1200b1200b1200b1100b1150010000100
19100000185501855018550185401854018540185301853018530185201852018520185101851518000180001a5501a5501a5501a5401a5401a5401a5301a5301a5301a5201a5201a5201a5101a5151800000000
191000001f7541f7501f7501f7401f7401f7401f7301f7301f7301f7201f7201f7201f7101f715187001870021754217502175021740217402174021730217302173021720217202172021710217151870000700
0110000030564000040000432565000040000434564000043056400004000042d5650000400004325640000432564000040000400004365650000400004000043956400004000040000434565000000000000000
011000002d56400004000042f565000040000431564000042d56400004000042a56500004000042f564000042f564000040000400004335650000400004000043656036530365203651036510365150000000000
011000000a1540a1500a1500a1500a1400a1400a1400a1400a1300a1300a1300a1300a12500100091000910009154091500915009150091400914009140091400913009130091300913009125001000010000000
01100000217542175021750217502174021740217402174021730217302173021730217250070009700097002b7542b7502b7502b7502b7402b7402b7402b7402b7302b7302b7302b7302b725007000070000700
011000002d5542d5502d5402d5402d5302d5302d5202d52500000000002b554000003055430545325543254534544345453553434534345303452034520345203451034510345150000030554305453255400000
011000000815408150081500815008140081400814008140081300813008130081300812500100091000910007154071450910005154051450910009154091450910007154071450910010154001001015400100
011000002b7542b7502b7502b7502b7402b7402b7402b7402b7302b7302b7302b7302b7250010009100091002975429745097002675426745097002b7542b745097002875428745097002d754007002e75400000
011000003755437550375503754037540375403753037530375303752035525300003a5543a545385540000035554355450000032554325450000034554345450000035554355450000037554000003455400000
011000000815408150081500815008140081400814008140081300813008130081300812500100091000910007154071500715007150071400714007140071400713007130071300713007125001000010000000
011000002b7542b7502b7502b7502b7402b7402b7402b7402b7302b7302b7302b7302b72500700097000970029754297502975029750297402974029740297402973029730297302973029725007000010000000
011000003755437550375503754037540375403753037530375303752035525300003a5543a54538554000003254432545335343253432530325203252032520325103251032515000002e5542e5453055400000
000f00002376423760237602376023760237602375023750237502375023750237502374023740237402374023740237402373023730237302373023730237302372023720237202372023720237202371023715
000f0000245540000000000000000000000000000000000028554000000000000000000000000000000000002b554000000000000000000000000000000000002f55400000000000000000000000000000000000
000f00001c050000001c0501c0401c0401c0301c0301c0201805018050180301803018040180401f0501f0501f0501f0501f0401f0401f0401f0401f0301f0301f0301f0301f0201f0201c0501c0401c0301c020
000f00001d7641d7601d7601d7501d7501d7501d7401d7401d7401d7301d7301d7301d7201d7201d7201d72520764207602075020750207402074020730207302072020720207102071526764267502674026735
000f00001f55400000000000000000000000000000000000225540000000000000000000000000000000000022554000000000000000000000000025554000000000000000000000000028554000000000000000
000f00001a0601a0501a0401a0301606016060160501605016050160401604016040160301603016030160201d0601d0501d0401d03019060190601904019040190301903019020190201f0601f0501f0401f020
000f00001c7641c7601c7601c7501c7501c7501c7401c7401c7401c7301c7301c7301c7301c7201c7201c7251e7641e7601e7601e7601e7501e7501e7501e7501e7401e7401e7401e7401e7301e7301e7301e735
000f00001d5540000000000000000000000000000000000021554000000000000000000000000000000000001f554000000000000000000000000000000000002355400000000000000000000000000000000000
000f00001806018050180401803015060000001506015050150401503015020150101c0601c0501c0401c0301a0601a0501a0401a03017060000001706017050170401703017020170101e0601e0501e0401e030
000f00001d7641d7601d7601d7501d7501d7501d7401d7401d7401d7401d7301d7301d7301d7301d7201d72520764207602075020750207402074020730207302072020720207202072528764287502874028725
000f00001f55400000000000000000000000000000000000225540000000000000000000000000000000000022554000000000000000000000000025554000000000000000000000000029554000000000000000
000f00001a0601a0501a0401a0301606016060160501605016040160401603016030160201602016010160101d0601d0501d0401d030190601906019040190401905019050190301903021060210502104021030
000f00001e7641e7601e7601e7501e7501e7501e7401e7401e7401e7301e7301e7301e7201e7201e7201e72524764247602476024750247502475024740247402474024730247302473024720247202472024725
000f19001f55400000000000000000000000000000000000235540000000000000000000000000000000000026554000000000000000000000000000000000002955401400014000140001400014000140001400
000f00001706017050170401703013060000001306013050130401303013020130201a0601a0501a0401a0301d0601d0501d0401d0301a060000001a0601a0501a0401a0301a0201a02021060210502104021030
000f00002376423760237602376023760237602375023750237502375023750237502374023740237402374023740237402373023730237302373023730237302372023720237202372023720237202371023715
000f00001c060000001c0601c0601c0501c0501c0501c0401804018040180301803018030180201f0601f0601f0601f0501f0501f0501f0401f0401f0401f0401f0301f0301f0301f0301c0601c0501c0401c030
000f00001d7641d7601d7601d7501d7501d7501d7501d7401d7401d7401d7401d7301d7301d7301d7201d72520764207602075020750207402074020730207302072020720207102071526764267502674026735
__music__
01 0a0b0c10
02 0d0e0f11
01 12131459
00 18191a59
00 12131459
02 15161759
01 2a1c2b40
00 2c1f2040
00 2a1c2b40
00 21222340
00 2a1c2b40
00 24252640
00 2a1c2b40
02 27282940

