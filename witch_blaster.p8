pico-8 cartridge // http://www.pico-8.com
version 36
__lua__
--main tab
function _init()
	state="game"

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
		update=function(self)
			--movement
			self.velocity_x*=0.8
			self.velocity_y*=0.8

			if (btn(0)) self.velocity_x-=1
			if (btn(1)) self.velocity_x+=1
			if (btn(2)) self.velocity_y-=1
			if (btn(3)) self.velocity_y+=1

			self.velocity_x=mid(-2,self.velocity_x,2)
			self.velocity_y=mid(-2,self.velocity_y,2)

			self.x+=self.velocity_x
			self.y+=self.velocity_y

			--bullet
			if (btnp(5) and not (#bullet_objs>20)) make_bullet_obj(self.x,self.y)
		end,
		draw=function(self)
			spr(1,self.x-8,self.y-8,2,2)

			--hit box
			circ(self.x,self.y,self.width/2,8)
		end,
		check_collision=function(self)
			
		end
	}

	--enemy
	make_worm(64,64)
end

function _update()
	if state=="menu" then
		update_menu()
	elseif state=="game" then
		update_game()
	elseif state=="shop" then
		update_shop()
	elseif state=="end" then
		update_end()
	end
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
end

function draw_game()
	cls(3)
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
		update=function(self)
		end,
		draw=function(self)
		end,
		check_collision=function(self)
			--player collision
			if circles_overlapping(self,player) then

			end

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
		update=function(self)
			self:check_collision(self)
		end,
		draw=function(self)
			spr(14,self.x-8,self.y-2,2,1)

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
			circfill(self.x,self.y,self.width/2,1)
			circfill(self.x,self.y,(self.width/2)-1,10)
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


__gfx__
00000000000000001110000000000000000000000000000077700000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000001c11100000000000000000000000000078777000000000000000000000000000001111100001111100000000000000000000000111111000
007007000000000011cc110000000000111110000000000077887700000000000000000000000000011666110011777100000000000000000000001122ee1100
000770000000000011ccc110000000001ccc11000000000077888770000000000000000000000000116677711117777100000000000000000111111222eee110
00077000000000011ccccc100000000011ccc11000000007788888700000000000000000000000001857777118556611000000000000000011eeeee222eeee11
0070070000000001ceeff110000000011ccccc100000000788888770000000000000000000000000155511111555111100000000000000001e2eeee2211eeee1
00000000000000011efff10000000001ceeff1100000000778888700000000000000000000000000111110001111100000000000000000001eeeeee11111eee1
0000000001111011ccc11100000000011efff1000777707788877700000000000000000000000000000000000000000000000000000000001111111100011111
011111101144111eeeeef11100111011ccc111007788777888888777000000000000000000000000000000000111110000000000000000000111100111111000
11cccc111444444eee4444411114111eeeeef11178888888888888870000000000000000000000000000000001777111000000000000000011ee111122ee1100
1dccccc1111411cee11111111444444eee4444417778778887777777000000000000000000000000000000001171717100000000000000001e2ee11222eee110
1dcdccc1001111c111000000114411cee11111110077778777000000000000000000000000000000000000001997777100000000000000001eeeee2222eeee11
1dcddcc10000011100000000011111c111000000000007770000000000000000000000000000000000000000118777710000000000000000111eeee2211eeee1
1dccccc1000000000000000000000111000000000000000000000000000000000000000000000000000000000118771100000000000000000011eeee1111eee1
11dddd110000000000000000000000000000000000000000000000000000000000000000000000000000000000111110000000000000000000011ee110011ee1
01111110000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000111100001111
11111111001111000111111000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001111110011111000
188118810018810011aaaa1100000000000000000000000000000000000000000000000000000000000000000000000000000000000000001333310114441100
188888811118811119aaaaa100000000000000000000000000000000000000000000000000000000000000000000000000000000000000001313311444444100
188888811888888119a99aa100000000000000000000000000000000000000000000000000000000000000000000000000000000000000001333332444444110
188888811888888119aa9aa100000000000000000000000000000000000000000000000000000000000000000000000000000000000000001113333244442211
118888111118811119aaaaa100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000011333322222331
01188110001881001199991100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001133333333331
00111100001111000111111000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000111111111111
11111111001111100111000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000111111011111000
100110010118881101c1110000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000133331114441100
1000000101811181011cc11000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000131331444444111
1000000101811181011ccc1100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000133332444442331
100000010111881111ccccc100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000113333244442331
11000011000111101ceeff1100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000011333322223331
011001100001810011efff1000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001133333333331
00111100000111001111111000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000111111111111
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
