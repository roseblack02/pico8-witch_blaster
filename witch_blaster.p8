pico-8 cartridge // http://www.pico-8.com
version 36
__lua__
--main tab
function _init()
	state="game"
	frame=0
	map_x,map_y,camera_x,camera_y,front_tree_x,back_tree_x=0,0,0,0,0,0
	scroll_speed,front_speed,back_speed=0.5,0.3,0.1

	--table of enemies
	enemy_objs={}

	--table of bullets
	bullet_objs={}

	--player object
	player={
		x=0,
		y=0,
		width=10,
		velocity_x=0,
		velocity_y=0,
		hp=0,
		max_hp=0,
		dmg=1,
		e_level=0,
		max_e_level=0,
		points=0,
		powerup="",
		blast=false,
		sprite=1,
		up=false,
		down=false,
		is_hit=false,
		hit_timer=0,
		update=function(self)
			--limit position
			self.x=mid(camera_x+8,self.x,camera_x+120)
			self.y=mid(camera_y+8,self.y,camera_y+120)
			--reset variables
			self.down,self.up=false,false

			--count down hit timer and reset is_hit variable
			self.hit_timer-=1
			self.hit_timer=mid(0,self.hit_timer,30)
			if (self.hit_timer<1) self.is_hit=false

			--movement
			self.velocity_x*=0.85
			self.velocity_y*=0.85

			if (btn(0)) self.velocity_x-=1
			if (btn(1)) self.velocity_x+=1
			if (btn(2)) self.velocity_y-=1 self.down=true
			if (btn(3)) self.velocity_y+=1 self.up=true

			self.velocity_x=mid(-2,self.velocity_x,2)
			self.velocity_y=mid(-2,self.velocity_y,2)

			--collision
			--make player invulnerable when hit
			if not self.is_hit then
				self:check_collision(self)
			end

			--map collision
			local collision=hit_wall(self.x+self.velocity_x,self.y+self.velocity_y,self.width,self.height,4)
			if collision~="none" then
				--no movement
			else
				--applying velocity
				self.x+=self.velocity_x
				self.y+=self.velocity_y
			end

			--bullet
			if (btnp(5) and not (#bullet_objs>20)) make_bullet_obj(self.x,self.y)

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
		end,
		draw=function(self)
			outlined_sprites(self.sprite,12,self.x-8,self.y-8,2,2)

			--hit box
			circ(self.x,self.y,self.width/2,8)
		end,
		check_collision=function(self)
			--enemy collision
			local enemy
			for enemy in all(enemy_objs) do
				if circles_overlapping(self,enemy) then
					self.sprite=5
					self.is_hit=true
					self.hit_timer+=30
				end
			end
		end
	}

	--make enemies temp
	--make_worm(64,64)

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

	frame_counter(60)
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
	player:update()

	camera_x+=scroll_speed
	back_tree_x+=back_speed
	if (camera_x>back_tree_x+127) back_tree_x=camera_x
	front_tree_x+=front_speed
	if (camera_x>front_tree_x+127) front_tree_x=camera_x

	camera(camera_x,camera_y)

	--mouse temp
	mouse_x=stat(32)
	mouse_y=stat(33)
end

function draw_game()
	cls(12)

	--background trees
	back_trees(back_tree_x)
	back_trees(back_tree_x+127)

	front_trees(front_tree_x)
	front_trees(front_tree_x+127)

	--ground
	rectfill(camera_x,96,camera_x+128,128,3)

	--map
	map(map_x,map_y)

	--draw objects
	local enemy
	for enemy in all(enemy_objs)do
		enemy:draw()
	end
	local bullet
	for bullet in all(bullet_objs)do
		bullet:draw()
	end
	player:draw()

	--mouse info temp
	print(mouse_x,0,0,8)
	print(mouse_y,0,8,8)
	pset(mouse_x,mouse_y,8)
end

function update_shop()

end

function draw_shop()

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

					--delete bullet
					del(bullet_objs,bullet)

					--delete self if dead
					if (self.hp<1) del(enemy_objs,self)
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
		update=function(self)
			self:check_collision(self)

			--animate sprite
			if frame>30 then
				self.sprite=30
			else
				self.sprite=14
			end
		end,
		draw=function(self)
			outlined_sprites(self.sprite,8,self.x-8,self.y-2,2,1)

			--hitbox
			circ(self.x,self.y,self.width/2,11)
		end
	})
end

--make bullets
function make_bullet_obj(x,y)
	--create enemy
	local obj={
		x=x,
		y=y,
		width=6,
		velocity_x=0,
		dmg=0,
		update=function(self)
			self.velocity_x+=0.5
			self.x+=self.velocity_x

			--delete self if off screen
			if (self.x>(player.x+128)) del(bullet_objs,self)
		end,
		draw=function(self)
			circfill(self.x,self.y,self.width/2,12)
			circfill(self.x,self.y,(self.width/2)-1,7)
		end
	}
	--add object table to enemies table
	add(bullet_objs,obj)
	return obj
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

--map collision 
function check_tile(x,y,flag)
	local tile_x=x/8
 	local tile_y=y/8
 	local tile=mget(tile_x,tile_y)
 	return fget(tile,flag)
end

--map collision 
function hit_wall(x,y,width,height,indent)
 	if (check_tile(x+indent,y,0)) and (check_tile(x+width-indent,y,0)) then
 		return "top"
 	elseif (check_tile(x+indent,y,0)) and (check_tile(x+width-indent,y,0)) then
 		return "bottom"
 	elseif (check_tile(x,y+indent,0)) and (check_tile(x,y+height-indent,0)) then
 		return "left"
 	elseif (check_tile(x,y+indent,0)) and (check_tile(x+width,y+height-indent,0)) then
 		return "right"
 	else
 		return "none"
 	end
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
	pal({1,2,3,4,5,6,7,8,9,10,-5},1)
	spr(sprite,x,y,width,height,flip_x,flip_y)
end

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

--count up frames
function frame_counter(limit)
	frame+=1
	if (frame>limit) frame=0
end

__gfx__
00000000000000001110000000000000000000000000000077700000000000000000000000000000000000000000000000000000111100000000000000000000
00000000000000001c11100000000000000000000000000078777000000000000000000000000000001111100001111100000011167100000000000111111000
007007000000000011cc110000000000111110000000000077887700000000000000000000000000011666110011777100000116771101110000001122ee1100
000770000000000011ccc110000000001ccc11000000000077888770000000000000000000000000116677711117777100111167771111710111111222eee110
00077000000000011ccccc100000000011ccc110000000077888887000000000000000000000000018577771185566111117c7777777771111eeeee222eeee11
0070070000000001ceeff110000000011ccccc100000000788888770000000000000000000000000155511111555111119977777777771111e2eeee2211eeee1
00000000000000011efff10000000001ceeff1100000000778888700000000000000000000000000111110001111100011111111111111101eeeeee11111eee1
0000000001111011ccc11100000000011efff1000777707788877700000000000000000000000000000000000000000000000000000000001111111100011111
011111101144111eeeeef11100111011ccc111007788777888888777000000000000000000000000000000000111110000000000000000000111100111111000
11cccc111444444eee4444411114111eeeeef11178888888888888870000000000000000000000000000000001777111000000000000011111ee111122ee1100
1dccccc1111411cee11111111444444eee4444417778778887777777000000000000000000000000000000001171717100111111111111711e2ee11222eee110
1dcdccc1001111c111000000114411cee1111111007777877700000030000000000000000000000000000000199777711117c777777777111eeeee2222eeee11
1dcddcc10000011100000000011111c1110000000000077700000000b3000000000000000000000000000000118777711997777777777110111eeee2211eeee1
1dccccc1000000000000000000000111000000000000000000000000bb3000000000000000000000000000000118771111111167771111000011eeee1111eee1
11dddd11000000000000000000000000000000000000000000000000bb30000000000000000000000000000000111110000001167771000000011ee110011ee1
01111110000000000000000000000000000000000000000000000000bbb330000000000000000000000000000000000000000011111100000000111100001111
1111111100111100011111102442244422444442244224420244442222444442bbbbb30033000000000000000000000000000001111100001111110011111000
188118810018810011aaaa112444224424444220024424420024444224444420bbbbb300bb30000000000000000000000000001124f110001333310114441100
188888811118811119aaaaa10244442444442000002444420002444424444200bbbbbb30bbb30000000000000000000000000112444f10001313311444444100
188888811888888119a99aa10024444444420000002444420002444444442000bbbbbb30bbbb300000000000000000000000112444ff10001333332444444110
188888811888888119aa9aa10002444444200000002444200002444444442000bbbbbb303bbb30000000000000000000000112444ff110001113333244442211
118888111118811119aaaaa10002444442000000002444200000244444420000bbbbbb30bbbbb330011111111111000001112444ff1100000011333322222331
0118811000188100119999110002444442000000002444200000244444420000b3bbbbb3bbb3bbb3114444444441111111444444444111110001133333333331
00111100001111000111111000024444420000000024442000002444444200003b3bbbb3bbbbbbb31f0044444444fff11f0044444444fff10000111111111111
1111111100111110011100003333333333333333333333330000333300000000003bbbbbbbbbbbbb1f2f444444f4f1111f2f44444444f1110111111011111000
100110010118881101c1110033b333333b33b333333333330003bbbb00000000003bbbbbbbbbbbbb1fff424444ff11001fff4444444f11000133331114441100
1000000101811181011cc1103b3b333333b3b333333b3333033bbbbb0000000003bbbbbbbbbbbbbb19f4424444ff100019f44444441110000131331444444111
1000000101811181011ccc1133b3333333333333333333333bbbbbbb0000000303bbbb3bbbbbbbbb11112244444f000011111111241100000133332444442331
100000010111881111ccccc133333333333333333b333b33bbbbb3bb0000003b3bbbbbb3bbbbbbbb0001122444f1000000000001129100000113333244442331
11000011000111101ceeff1133333b33333b33b33333b3b3bbbbbbbb000003bb3bbbbbbbbbbbbbbb000011222211000000000000111100000011333322223331
011001100001810011efff10333333b333b3b33333333b33bbbbbbbb000003bb3bbbbbbbbbbbbbbb000001111110000000000000000000000001133333333331
001111000001110011111110333333333333333333333333bbbbbbbb00033bbb3bbbbbbbbbbbbbbb000000000000000000000000000000000000111111111111
000000011111111000000000001fffffffffffff0000000111111110000000007ccccccc00000000000000000000000000000000000000000000000000000000
00000011ffffff1100000000011fffffffffffff00000111cccccc111000000077cccccc00000000000000000000000000000000000000000000000000000000
0000011ffffffff11000000001ffffffffffffff000011cccccccccc1100000077cccccc00000000000000000000000000000000000000000000000000000000
000011ffffffffff1100000001ffffffffffffff00001cccccccccccc10000007774c4cc00000000000000000000000000000000000000000000000000000000
00001ffffffffffff100000011ffffffffffffff00011cccccccccccc1100000777c4ccc00000000000000000000000000000000000000000000000000000000
00011ffffffffffff11000001fff1ff1ffff1ff10001cccccccccccccc1000007777cccc00000000000000000000000000000000000000000000000000000000
0001ffffffffffffff1000001ffff11ffffff11f0001cccccccccccccc1000007777cccc00000000000000000000000000000000000000000000000000000000
0011ffffffffffffff1100001fffffffffffffff00117777cccccccccc100000e777cccc00000000000000000000000000000000000000000000000000000000
001fffffffffffffff210000001fffffffffffff001777777ccc4ccccc1100000000000000000000000000000000000000000000000000000000000000000000
011fffffffffffffff211000011fffffffffffff0017777777c474ccccc100000000000000000000000000000000000000000000000000000000000000000000
01ffffffffffffffff22100001ffffffffffffff0017777777c404ccccc100000000000000000000000000000000000000000000000000000000000000000000
01ff1ffffffffff1ff22100001ff1ffffffffff101177777777404ccccc100000000000000000000000000000000000000000000000000000000000000000000
11fff1ffffffff1fff22110011fff1ffffffff1f01777777777c4cccccc100000000000000000000000000000000000000000000000000000000000000000000
1ffff11ffffff11fff2221001fffff1ffffff1ff017eeee77777ccccccc100000000000000000000000000000000000000000000000000000000000000000000
1ffff171ffff171fff2221001ffffff1ffff1fff01eeeeee7777ccccccc110000000000000000000000000000000000000000000000000000000000000000000
1ffff17ffffff71ff22221001fffffffffffffff01eeeeeee777cccccccc10000000000000000000000000000000000000000000000000000000000000000000
1fffff1ffffff1fff2222100ff2100001111111001eeeeeee7777ccccccc10000000000000000000000000000000000000000000000000000000000000000000
1ffffffffffffffff2222100ff211000ff1fff1101e7777eee777ccccccc10000000000000000000000000000000000000000000000000000000000000000000
1ffffffff11fffff222221001f221000ff1ffff101777777ee777ccc1ccc10000000000000000000000000000000000000000000000000000000000000000000
1fffffff1221ffff222221001f221000fff1ffff01777777ee777cc1cccc10000000000000000000000000000000000000000000000000000000000000000000
1fffffff1221fff222222100f1211100fff1ffff11777777e777771ccccc10000000000000000000000000000000000000000000000000000000000000000000
1ffffffff11fff2222222100f1122100ff1f1fff17777777777777cccccc10000000000000000000000000000000000000000000000000000000000000000000
1ffffffffffff222222221001f222100f1fff1ff17777777777777cccccc10000000000000000000000000000000000000000000000000000000000000000000
1fffffffffff222222222100f2222100ffffff1f17777777777777cccccc10000000000000000000000000000000000000000000000000000000000000000000
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
0000000000000000003717000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000003828000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000373629000037363939290000371700000037362900003717000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0034000000000000350000330000003400003400003300003500000000000000003300000035000000003500003400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
3300350034350000000000343500000000003300000000000000003434003400000000000033330035003400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000003435000033000000003500000000330034353500000000000000003534000000003300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0033000034000000340000000000350000330000000035000000330000003300000000000000003500000035000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
