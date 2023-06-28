pico-8 cartridge // http://www.pico-8.com
version 36
__lua__
--main tab
function _init()
	state="game"
	game_pal="normal"
	frame=0

	--game
	map_x,front_tree_x,back_tree_x=0,0,0
	map_speed,front_speed,back_speed=0.35,0.6,0.4
	blast_text=7
	text_wave=0

	--store
	blink_timer=0
	open,buying,close=true,false,false
	cursor={sprite=7,x=48,y=34}
	hp_upgrades,dmg_upgrades,blast_upgrades,magic_upgrades=1,1,1,1

	--get level info from text file
	#include levels.txt
	levels={level1,level2,level3,level4,level5}
	level=1
	level_timer=0
	wave1,wave2,wave3=true,false,false
	level_clear=false

	--particle effects
	blast_particle={}
	hit_particle={}

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
		hp=3,
		max_hp=3,
		lives=3,
		shot_speed=2,
		dmg=1,
		mag_level=0,
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
		mag_gained=3,
		update=function(self)
			--reset variables
			self.down,self.up=false,false

			--count down hit timer
			if (self.hit_timer>0) self.hit_timer-=1 screen_shake(0.05)
			--reset is_hit variable and camera
			if (self.hit_timer<1) self.is_hit=false camera(0,0)

			--count down powerup timer
			self.powerup_timer-=1
			self.powerup_timer=mid(0,self.powerup_timer,180)

			if (self.powerup=="shot speed up") self.shot_speed_mod=4 else self.shot_speed_mod=0
			if (self.powerup=="double shot") self.double=true else self.double=false

			--reset powerup
			if (self.powerup_timer<1) self.powerup=""

			--movement
			self.velocity_x*=0.85
			self.velocity_y*=0.85

			if (btn(0)) self.velocity_x-=1
			if (btn(1)) self.velocity_x+=1
			if (btn(2)) self.velocity_y-=1 self.down=true
			if (btn(3)) self.velocity_y+=1 self.up=true

			self.velocity_x=mid(-2,self.velocity_x,2)
			self.velocity_y=mid(-2,self.velocity_y,2)

			--applying velocity
			self.x+=self.velocity_x
			self.y+=self.velocity_y

			--limit position
			self.x=mid(8,self.x,120)
			self.y=mid(10,self.y,120)

			--bullet
			if btnp(5) then
				if (self.double) make_bullet_obj(self.x,self.y-4,self.shot_speed+self.shot_speed_mod,{false,true,false,false}) make_bullet_obj(self.x,self.y+4,self.shot_speed+self.shot_speed_mod,{false,true,false,false}) else make_bullet_obj(self.x,self.y,self.shot_speed+self.shot_speed_mod,{false,true,false,false})
				sfx(2)
			end

			if btnp(4) then
				if level_clear then
					--end level
					state="shop"
					level_clear=false
					self.points=0
					sfx(5)
				else
					--blast
					if (self.mag_level==116) self.blast=true explosion(blast_particle,self.x+2,self.y-10) sfx(3)
				end
			end

			if (self.blast) self.mag_level-=self.blast_dur make_bullet_obj(self.x,self.y,6,{false,true,false,false})

			--end blast
			if (self.mag_level<1) self.blast=false

			--burst
			if self.burst then
				make_bullet_obj(self.x,self.y,self.shot_speed+self.shot_speed_mod,{true,true,false,false})
				make_bullet_obj(self.x,self.y,self.shot_speed+self.shot_speed_mod,{false,true,true,false})
				make_bullet_obj(self.x,self.y,self.shot_speed+self.shot_speed_mod,{false,false,true,true})
				make_bullet_obj(self.x,self.y,self.shot_speed+self.shot_speed_mod,{true,false,false,true})
				self.burst=false
				sfx(2)
			end

			--limit e level
			self.mag_level=mid(0,self.mag_level,116)

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
			--make player invulnerable when hit
			if not self.is_hit then
				self:check_collision(self)
			end

			--limit hp
			self.hp=mid(0,self.hp,self.max_hp)

			--check if player has lost a life
			if (self.hp<1 and self.lives>0) self.x=25 self.y=64 self.lives-=1 self.hp=self.max_hp

			--check if player is dead
			if (self.hp<1 and self.lives<1) state="end"
		end,
		draw=function(self)
			outlined_sprites(self.sprite,12,self.x-8,self.y-8,2,2)
		end,
		check_collision=function(self)
			--enemy collision
			local enemy
			for enemy in all(enemy_objs) do
				if circles_overlapping(self,enemy) then
					--hit effect
					self.sprite=5
					self.is_hit=true
					self.hit_timer+=60
					explosion(hit_particle,self.x-2,self.y-10)
					sfx(1)

					--take damage
					self.hp-=1
				end
			end
		end
	}

	--mouse temp
	poke(0x5f2d, 1)
end

function _update60()
	if state=="menu" then
		update_menu()
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

	--mouse temp
	mouse_x=stat(32)
	mouse_y=stat(33)
end

function _draw()
	if state=="menu" then
		draw_menu()
	elseif state=="game" then
		draw_game()
	elseif state=="shop" then
		draw_shop()
	elseif state=="end" then
		draw_end()
	end

	--debug info
	print("mx:"..mouse_x,0,113,8)
	print("my:"..mouse_y,0,121,8)
	pset(mouse_x,mouse_y,8)

	print("px:"..flr(player.x),25,113,2)
	print("py:"..flr(player.y),25,121,2)
end

--game states
function update_menu()

end

function draw_menu()

end

--prep next level
function start_game()

end

function update_game()
	--update objects
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
	player:update()

	--side scrolling
	map_x+=map_speed
	if (map_x>60) map_x=0
	back_tree_x-=back_speed
	if (back_tree_x<-127) back_tree_x=0
	front_tree_x-=front_speed
	if (front_tree_x<-127) front_tree_x=0

	--load waves
	--count level timer
	level_timer+=(1/60)

	--load wave based on timer
	if not level_clear then
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
		elseif level_timer>30 and level_timer<45 and wave3 then
			load_wave(levels[level].wave3)
			wave3=false
		--end level based on timer and on if there are no enemies
		elseif level_timer>45 and #enemy_objs<1 then
			level_clear=true
			level_timer=0
		end 
	end

	--wave text counter
	if (text_wave>59) text_wave=0
	text_wave+=1

	--flash text
	if frame>30 then
		blast_text=7
	else
		blast_text=12
	end
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

	--draw objects
	local enemy
	for enemy in all(enemy_objs)do
		enemy:draw()
	end
	local bullet
	for bullet in all(bullet_objs)do
		bullet:draw()
	end
	local pickup
	for pickup in all(pickup_objs)do
		pickup:draw()
	end
	player:draw()

	--explosions
	draw_explosion(hit_particle,{7,8,8,2})
	draw_explosion(blast_particle,{1,12,12,7})

	--hud
	--hp
	for hearts=1,player.max_hp do
		local sprite=48
		if (hearts<=player.hp) sprite=32

		spr(sprite,(hearts*9)-8,1)
	end

	--score
	outlined_text(player.points,64-(#tostr(player.points)*2)-1,2,7,1)

	--powerup
	outlined_text(player.powerup,64-(#player.powerup*2)-1,12,7,1)

	--lives
	outlined_text(player.lives,109,2,7,1)
	spr(50,119,1)

	--coins
	outlined_text(player.coins,109,12,7,1)
	spr(34,119,11)

	--e level
	circfill(4,123,7,7)
	rectfill(7,119,127,126,7)
	rectfill(8,120,126,125,13)
	rect(8,120,126,125,1)
	spr(16,1,119)
	rectfill(9,121,9+(player.mag_level),124,12)

	--blast prompt
	if (player.mag_level==116) outlined_text("blast 🅾️",48,112,blast_text,1)

	--level clear screen
	if level_clear then
		waving_text("level cleared!",33,15,7,1)
		rectfill(35,27,92,49,1)
		rectfill(36,28,91,48,14)
		outlined_text("score : ",40,31,7,1)
		outlined_text(player.points,72,31,12,1)
		outlined_text("continue 🅾️",42,41,blast_text,1)
	end
end

function update_shop()
	--blink timer
	if (blink_timer>30) blink_timer=0
	blink_timer+=1/60

	--player controls
	if btnp(5) then
		
	end

	if (open and btnp(5)) open=false buying=true

	if buying and btnp(4) then	
		if(cursor.y==34 and player.coins>6 and hp_upgrades<3) player.coins-=3 player.max_hp+=1 player.hp=player.max_hp hp_upgrades+=1 sfx(6)
		if(cursor.y==42 and player.coins>6 and dmg_upgrades<3) player.coins-=5 player.dmg+=0.5 dmg_upgrades+=1 sfx(6)
		if(cursor.y==50 and player.coins>14) player.coins-=5 player.lives+=1 sfx(6)
		if(cursor.y==58 and player.coins>9 and blast_upgrades<5) player.coins-=7 player.blast_dur-=0.2 blast_upgrades+=1 sfx(6)
		if(cursor.y==66 and player.coins>9 and magic_upgrades<5) player.coins-=7 player.mag_gained+=2 magic_upgrades+=1 sfx(6)
		if(cursor.y==74) buying=false close=true sfx(5)
	end

	if (close and btnp(5)) close=false open=true state="game" level+=1 wave1=true

	if (btnp(2)) cursor.y-=8
	if (btnp(3)) cursor.y+=8

	cursor.y=mid(34,cursor.y,74)
end

function draw_shop()
	cls(12)
	--background
	back_trees(back_tree_x)
	front_trees(front_tree_x)
	rectfill(0,96,128,128,3)
	map(map_x,0)

	--blahaj
	sspr(40,32,24,32,64,24,48,64)
	--blink
	if (blink_timer>29.5) sspr(64,32,8,8,80,40,16,16)

	--stand
	rectfill(4,20,12,88,4)
	rect(3,20,13,88,1)

	rectfill(116,20,124,88,4)
	rect(115,20,125,88,1)

	rectfill(0,87,128,128,4)
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
	rectfill(6,30,60,84,1)
	outlined_text("▶",59,57,7,1)
	rectfill(8,32,58,82,7)

	--speech
	if open then
		print("what are ya",10,34,1)
		print("buyin?",10,40,1)
		print("❎",50,76,1)
	end

	if buying then
		print("hp $7",10,34,1)
		print("dmg $7",10,42,1)
		print("lives $15",10,50,1)
		print("blast $10",10,58,1)
		print("magic $10",10,66,1)
		print("leave",10,74,1)
		spr(cursor.sprite,cursor.x,cursor.y)

		if(cursor.y==34) outlined_text("increase maximum hp "..hp_upgrades.."/3",8,91,7,1) outlined_text("🅾️ to purchase",8,99,7,1)

		if(cursor.y==42) outlined_text("increase damage "..dmg_upgrades.."/3",8,91,7,1) outlined_text("🅾️ to purchase",8,99,7,1)

		if(cursor.y==50) outlined_text("purchase extra lives",8,91,7,1) outlined_text("🅾️ to purchase",8,99,7,1)

		if(cursor.y==58) outlined_text("increase blast duration "..blast_upgrades.."/5",8,91,7,1) outlined_text("🅾️ to purchase",8,99,7,1)

		if(cursor.y==66) outlined_text("increase magic gained "..magic_upgrades.."/5",8,91,7,1) outlined_text("🅾️ to purchase",8,99,7,1)

		if(cursor.y==74) outlined_text("leave shop",8,91,7,1) outlined_text("🅾️ to leave",8,99,7,1)
	end

	if close then
		print("come back",10,34,1)
		print("any time!",10,40,1)
		print("❎",50,76,1)
	end

	--hud
	--hp
	for hearts=1,player.max_hp do
		local sprite=48
		if (hearts<=player.hp) sprite=32

		spr(sprite,(hearts*9)-8,1)
	end

	--lives
	outlined_text(player.lives,109,2,7,1)
	spr(50,119,1)

	--coins
	outlined_text(player.coins,109,12,7,1)
	spr(34,119,11)
end

function update_end()

end

function draw_end()

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
					if self.hp<1 then 
						del(enemy_objs,self) 
						player.points+=self.points
						--randomly drop a pickup
						local rand=flr(rnd(15))+1

						if (rand==1) make_powerup(self.x,self.y)
						if (rand==2) make_health(self.x,self.y)
						if (rand==3) make_life(self.x,self.y)
						if (rand>3 and rand<7) make_magic(self.x,self.y)
						if (rand>6) make_coin(self.x,self.y)

						--give player magic
						player.mag_level+=player.mag_gained
					end
				else
					self.is_hit=false
				end
			end
			
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

			--delete self if off screen
			if (self.x<(player.x-128)) del(enemy_objs,self)
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

			--shoot at player
			self.shoot_timer+=1
			if (self.shoot_timer>180) self.shoot_timer=0

			if (self.x<(player.x+128) and self.shoot_timer==179) make_enemy_bullet(self.x,self.y)

			--delete self if off screen
			if (self.x<(player.x-128)) del(enemy_objs,self)
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

			--delete self if off screen
			if (self.x<(player.x-128)) del(enemy_objs,self)
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
     		self.angle+=0.015

			self:check_collision(self)

			--animate sprite
			if frame>30 then
				self.sprite=28
			else
				self.sprite=12
			end

			--delete self if off screen
			if (self.x<(player.x-128)) del(enemy_objs,self)
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
		shoot_timer=0,
		update=function(self)
			self.x-=0.4

			self:check_collision(self)

			--animate sprite
			if frame>30 then
				self.sprite=27
			else
				self.sprite=11
			end

			--shoot at player
			self.shoot_timer+=1
			if (self.shoot_timer>150) self.shoot_timer=0

			if (self.x<(player.x+128) and self.shoot_timer==149) make_enemy_bullet(self.x,self.y)

			--delete self if off screen
			if (self.x<(player.x-128)) del(enemy_objs,self)
		end,
		draw=function(self)
			outlined_sprites(self.sprite,8,self.x-2,self.y-2,1,1)
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
			self.x-=0.2

			self:check_collision(self)

			--delete self if off screen
			if (self.x<(player.x-128)) del(enemy_objs,self)
		end,
		draw=function(self)
			outlined_sprites(self.sprite,8,self.x-4,self.y-4,1,1)
		end
	})
end

function make_enemy_bullet(x,y)
	return make_enemy_obj("enemy_bullet",x,y,{
		width=4,
		update=function(self)
			self.x-=0.8
			--delete self if off screen
			if (self.x<(player.x-128)) del(enemy_objs,self)
		end,
		draw=function(self)
			circfill(self.x,self.y,self.width/2,8)
			circfill(self.x,self.y,(self.width/2)-1,7)
		end
	})
end

--make bullets
function make_bullet_obj(x,y,speed,direction)
	--create bullet
	local obj={
		x=x,
		y=y,
		width=6,
		update=function(self)
			--choose which direction (clockwise bool) to shoot and apply speed
			if (direction[1]) self.y-=speed
			if (direction[2]) self.x+=speed
			if (direction[3]) self.y+=speed
			if (direction[4]) self.x-=speed

			--delete self if off screen
			if (self.x>(player.x+128) or self.x<player.x-128 or self.y>(player.y+128) or self.y<player.y-128) del(bullet_objs,self)
		end,
		draw=function(self)
			circfill(self.x,self.y,self.width/2,12)
			circfill(self.x,self.y,(self.width/2)-1,7)
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

--health pickup
function make_health(x,y)
	return make_pickup_obj("health",x,y,{
		update=function(self)
			self.x-=0.25

			--player pickup
			if circles_overlapping(self,player) then
				--add hp
				player.hp+=1

				sfx(4)

				--delete self
				del(pickup_objs,self)
			end

			--delete self if off screen
			if (self.x<(player.x-128)) del(pickup_objs,self)
		end,
		draw=function(self)
			outlined_sprites(33,12,self.x-4,self.y-4,1,1)
		end
	})
end

function make_life(x,y)
	return make_pickup_obj("life",x,y,{
		update=function(self)
			self.x-=0.25

			--player pickup
			if circles_overlapping(self,player) then
				--add lives
				player.lives+=1

				--limit lives
				player.lives=mid(0,player.lives,99)

				sfx(4)

				--delete self
				del(pickup_objs,self)
			end

			--delete self if off screen
			if (self.x<(player.x-128)) del(pickup_objs,self)
		end,
		draw=function(self)
			outlined_sprites(50,12,self.x-4,self.y-4,1,1)
		end
	})
end

function make_coin(x,y)
	return make_pickup_obj("coin",x,y,{
		update=function(self)
			self.x-=0.25

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

			--delete self if off screen
			if (self.x<(player.x-128)) del(pickup_objs,self)
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

			--player pickup
			if circles_overlapping(self,player) then
				--add to powerup timer
				player.powerup_timer+=180

				--select random powerup
				local rand=flr(rnd(3))+1

				if (rand==1) player.powerup="shot speed up"
				if (rand==2) player.powerup="double shot"
				if (rand==3) player.burst=true

				sfx(4)

				--delete self
				del(pickup_objs,self)
			end

			--delete self if off screen
			if (self.x<(player.x-128)) del(pickup_objs,self)
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

			--player pickup
			if circles_overlapping(self,player) then
				--add e
				player.mag_level+=12

				sfx(4)

				--delete self
				del(pickup_objs,self)
			end

			--delete self if off screen
			if (self.x<(player.x-128)) del(pickup_objs,self)
		end,
		draw=function(self)
			outlined_sprites(16,12,self.x-4,self.y-4,1,1)
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
end

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

	if game_pal=="trans" then
		pal({-15,-14,2,-3,-4,6,7,-8,12,14,-3,12,13,14,6},1)
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
		local my_particle={}
		my_particle.x=x 
		my_particle.y=y 
		my_particle.sx=rnd()*25-3
		my_particle.sy=rnd()*25-3
		my_particle.size=rnd(3)+1
		my_particle.age=rnd(2)
		my_particle.max_age=10+rnd(10)

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
__gfx__
00000000000000001110000000000000000000000000000077700000001110000000000000000000011111000000000000000000111100000000000000000000
00000000000000001c11100000000000000000000000000078777000011810000000000000000000017771110001111100000011167100000000000111111000
007007000000000011cc110000000000111110000000000077887700118811110000000000000000117171710011777100000116771101110000001122ee1100
000770000000000011ccc110000000001ccc11000000000077888770188888810000000000000000199777711117777100111167771111710111111222eee110
00077000000000011ccccc100000000011ccc110000000077888887011881111000000000000000011877771185566111117c7777777771111eeeee222eeee11
0070070000000001ceeff110000000011ccccc100000000788888770011810000000000000000000011877111555111119977777777771111e2eeee2211eeee1
00000000000000011efff10000000001ceeff1100000000778888700001110000000000000000000001111101111100011111111111111101eeeeee11111eee1
0000000001111011ccc11100000000011efff1000777707788877700000000000000000000000000000000000000000000000000000000001111111100011111
011111101144111eeeeef11100111011ccc111007788777888888777000000000000000000000000000000000000000000000000000000000111100111111000
11c7c7111444444eee4444411114111eeeeef11178888888888888870000000000000000000000000000000000111110000000000000011111ee111122ee1100
1dcccc71111411cee11111111444444eee4444417778778887777777000000000000000000000000000000000116661100111111111111711e2ee11222eee110
1dcccc71001111c111000000114411cee1111111007777877700000000000000000000000000000000000000116677711117c777777777111eeeee2222eeee11
1ddcccc10000011100000000011111c111000000000007770000000000000000000000000000000000000000185777711997777777777110111eeee2211eeee1
1dddccc1000000000000000000000111000000000000000000000000000000000000000000000000000000001555111111111167771111000011eeee1111eee1
11dddd110000000000000000000000000000000000000000000000000000000000000000000000000000000011111000000001167771000000011ee110011ee1
01111110000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000011111100000000111100001111
111111110011110001111110244224442244444224422442024444222244444200000000bbbbb300000000000000000000000001111100001111110011111000
188118810018810011aaaa11244422442444422002442442002444422444442000000000bbbbb30000000000000000000000001124f110001333310114441100
188888811118811119aaaaa1024444244444200000244442000244442444420000000000bbbbbb30000000000000000000000112444f10001313311444444100
188888811888888119a99aa1002444444442000000244442000244444444200030000000bbbbbb3000000000000000000000112444ff10001333332444444110
188888811888888119aa9aa10002444444200000002444200002444444442000b3000000bbbbbb300000000000000000000112444ff110001113333244442211
118888111118811119aaaaa10002444442000000002444200000244444420000bb300000bbbbbb30011111111111000001112444ff1100000011333322222331
0118811000188100119999110002444442000000002444200000244444420000bb300000b3bbbbb3114444444441111111444444444111110001133333333331
0011110000111100011111100002444442000000002444200000244444420000bbb330003b3bbbb31f1144444444fff11f1144444444fff10000111111111111
11111111001111100111000033333333333333330000333300000000003bbbbbbbbbbbbb330000001f2f444444f4f1111f2f44444444f1110111111011111000
1dd11dd10118881101c1110033b333333b33b3330003bbbb00000000003bbbbbbbbbbbbbbb3000001fff424444ff11001fff4444444f11000133331114441100
1dddddd101811181011cc1103b3b333333b3b333033bbbbb0000000003bbbbbbbbbbbbbbbbb3000019f4424444ff100019f44444441110000131331444444111
1dddddd101811181011ccc1133b33333333333333bbbbbbb0000000303bbbb3bbbbbbbbbbbbb300011112244444f000011111111241100000133332444442331
1dddddd10111881111ccccc13333333333333333bbbbb3bb0000003b3bbbbbb3bbbbbbbb3bbb30000001122444f1000000000001129100000113333244442331
11dddd11000111101ceeff1133333b33333b33b3bbbbbbbb000003bb3bbbbbbbbbbbbbbbbbbbb330000011222211000000000000111100000011333322223331
011dd1100001810011efff10333333b333b3b333bbbbbbbb000003bb3bbbbbbbbbbbbbbbbbb3bbb3000001111110000000000000000000000001133333333331
0011110000011100011111103333333333333333bbbbbbbb00033bbb3bbbbbbbbbbbbbbbbbbbbbb3000000000000000000000000000000000000111111111111
000000011111111000000000001fffffffffffff0000000111111110000000007ccccccc00000000000001110000000000000000000000000000000000000000
00000011ffffff1100000000011fffffffffffff00000111cccccc111000000077cccccc00000000000011c11110000000000000000000000000000000000000
0000011ffffffff11000000001ffffffffffffff000011cccccccccc1100000077cccccc0000000000001d1ccc11000000000000000000000000000000000000
000011ffffffffff1100000001ffffffffffffff00001cccccccccccc10000007774c4cc0000000000001111dcc1100000000000000000000000000000000000
00001ffffffffffff100000011ffffffffffffff00011cccccccccccc1100000777c4ccc0000000000000011dccc111110000000000000000000000000000000
00011ffffffffffff11000001fff1ff1ffff1ff10001cccccccccccccc1000007777cccc000000000011111dcccccccc10000000000000000000000000000000
0001ffffffffffffff1000001ffff11ffffff11f0001cccccccccccccc1000007777cccc00000000001ddddcceef111110000000000000000000000000000000
0011ffffffffffffff1100001fffffffffffffff00117777cccccccccc100000e777cccc00000000001111eeee1f100000000000000000000000000000000000
001fffffffffffffff210000001fffffffffffff001777777ccc4ccccc110000000000000000000000011eeeefff100000000000000000000000000000000000
011fffffffffffffff211000011fffffffffffff0017777777c474ccccc1000000000000000000000001eeccccc1100000000000000000000000000000000000
01ff1ffffffffff1ff22100001ffffffffffffff0017777777c414ccccc10000000000000000000000011ceeeec1100000000000000000000000000000000000
01fff1ffffffff1fff22100001ff1ffffffffff101177777777414ccccc10000000000000000000000011eeeeeec100000000000000000000000000000000000
11fff11ffffff11fff22110011fff1ffffffff1f01777777777c4cccccc1000000000000000000000011eeeeeeee111111111000000000000000000000000000
1ffff171ffff171fff2221001fffff1ffffff1ff017eeee77777ccccccc100000000000000000000001eeee2eeeeeeff14441000000000000000000000000000
1ffff17ffffff71fff2221001ffffff1ffff1fff01eeeeee7777ccccccc1100000000000000000000012eeee2eeeeef441111000000000000000000000000000
1fffff1ffffff1fff22221001fffffffffffffff01eeeeeee777cccccccc100000000000000000000012eeeee2eeee1111000000000000000000000000000000
1ffffffffffffffff2222100ff2100001111111001eeeeeee7777ccccccc1000000000000111100000112eeeee222e1000000000000000000000000000000000
1ffffffffffffffff2222100ff211000ff1fff1101e7777eee777ccccccc10000000000001441111111442eeeeeee11000000000000000000000000000000000
1ffffffff11fffff222221001f221000ff1ffff101777777ee777ccc1ccc10000000000001144441444112eeeeeee10000000000000000000000000000000000
1fffffff1221ffff222221001f221000fff1ffff01777777ee777cc1cccc1000000000001144442411112eeee221110000000000000000000000000000000000
1fffffff1221fff222222100f1211100fff1ffff11777777e777771ccccc100000000000124422111122eeee2211000000000000000000000000000000000000
1ffffffff11fff2222222100f1122100ff1f1fff17777777777777cccccc10000000000011221110012eeeeedd10000000000000000000000000000000000000
1ffffffffffff222222221001f222100f1fff1ff17777777777777cccccc1000000000001211100001111cc11110000000000000000000000000000000000000
1fffffffffff222222222100f2222100ffffff1f17777777777777cccccc10000000000011100000000011110000000000000000000000000000000000000000
11fffffffff222222222110011ffff1f1ff2212217777777777777cc1ccc10000000000000000000000000000000000000000000000000000000000000000000
01ffffffff2222222222100001f11f1ff122122217777777777777c1cccc11000000000000000000000000000000000000000000000000000000000000000000
011fffff2222222222211000011ff1f122121222177777777777771cccccc1000000000000000000000000000000000000000000000000000000000000000000
0011f22222222222221100000011f2212221222217777777777777ccccccc1000000000000000000000000000000000000000000000000000000000000000000
000112222222222221100000000112222221222217777777777777ccccccc1000000000000000000000000000000000000000000000000000000000000000000
000011222222222211000000000011222212222217777777777777ccccccc1000000000000000000000000000000000000000000000000000000000000000000
000001122222222110000000000001122212222117777777777777ccccccc1000000000000000000000000000000000000000000000000000000000000000000
000000111111111100000000000000111111111117777777777777ccccccc1000000000000000000000000000000000000000000000000000000000000000000
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
000300000f050160501d0502505000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
110a00002575326753287532775328753257532475326753007000070000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
010500000f45315450194500040022453284503145000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
