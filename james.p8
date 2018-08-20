pico-8 cartridge // http://www.pico-8.com
version 16
__lua__
-- main
-- global props
fishes= {}
weeds = {}
weed_heights={0.6,1.0,0.8}
frame =0
hook  ={x=0,y=0,r=3}
crsr  ={x=0,y=6,dx=0,dy=0}
player_score=0
player_score_pending=0
particles={}
timers={}

-- casting, fishing, reeling
-- scoring
state = nil

-- title, game, gameover
metastate="game"

-- debug flags
debug=true
debug_collision=true and debug

-- game data
fish_data={
 {spd=1,spr=0, pts=100,chance=0.6},
 {spd=2,spr=16,pts=200,chance=0.3},
 {spd=3,spr=32,pts=800,chance=0.1}
}


-- core functions

function _init ()
  palt(0,false)
  palt(14,true)
  timers.level=new_timer(60*30)
  start_level()
end

function start_level ()
  hook.y=64
  hook.x=64
  crsr.x=64
  crsr.y=64
  metastate="game"
		state="casting" 

  make_weed(30, 3)
  make_weed(75, 2)
  make_weed(90, 4)

  start_timer(timers.level)

  fishes={}
  
  for i=1,10,1 do
   make_fish()
  end
end

function _update()
 frame=frame+1
 for n,t in pairs(timers) do
  update_timer(t)
 end

 if (metastate=="game")     update_game()
 if (metastate=="gameover") update_gameover()
  
 foreach(particles,sim_particle)
end

function _draw()
  cls(1)
  
  -- ground/water
  for i=0,128,8 do
    spr(48,i,120)
    
    for j=0,112,8 do
    		spr(49+j/8,i,j)  
    end
  end
  
  foreach(weeds, draw_weed)
  foreach(fishes, draw_fish)
  
  if debug then
  circfill(crsr.x,crsr.y,hook.r,8)
  end
  line(hook.x,-1,hook.x,hook.y-4,6)
  spr(15,hook.x-2,hook.y-4)

  local score="score:"..player_score
  local score_offset = (128-#score * 4) -1
  
  print(score, score_offset, 1, 7)
  cprint(""..flr((timers.level.dur-timers.level.t)/30),1,7)

  foreach(particles,draw_particle)

  -- debug shit
  print(state, 1, 1, 7)
	 --print(timers.level.p,1,7,8)
  print("",1,40,8)
  for fish in all(fishes) do
   local c=12
   if (fish.hooked) c=8
   color(c)
   print("["..fish.tp.."] "..fish.x..","..fish.y)
  end
end

-->8
-- state logic

-- fishing
function state_fishing()
 hook.x=lerp(hook.x,0.5,crsr.x)
 hook.y=lerp(hook.y,0.5,crsr.y)
end

-- casting
function state_casting()
 hook.x=lerp(hook.x,0.5,crsr.x)
 hook.y+=2
   
 if hook.y>crsr.y then
  state="fishing"
 end
end

-- reeling
function state_reeling()
 if hook.y<-hook.r then
  
  state="scoring"
  for i=#fishes,1,-1 do
   local fish=fishes[i]
   if fish.hooked then
    player_score_pending+=fish.score
    del(fishes,fish)
    make_fish()
   end
  end
    
 else
  
  hook.y-=4
 
  for fish in all(fishes) do
   if not fish.hooked then
    if collide(hook,fish) then
     fish.hooked=true
     make_bubbles(
      fish.x,
      fish.y,
      5+rnd(5)
     )
    end
   end
  end
 end
end

-- scoring
function state_scoring()
 
end


-- main game metastate
function update_game ()

  if timers.level.elf then
   metastate="gameover"
   return
  end

  if (btn(⬅️)) crsr.dx-=1
  if (btn(➡️)) crsr.dx+=1
  if (btn(⬆️)) crsr.dy-=1
  if (btn(⬇️)) crsr.dy+=1

  if btnp(❎) and state == "fishing" then
    state = "reeling"
  end
  
  if btnp(❎) and state == "scoring" then
    state = "casting"
  end
  
  crsr.dx=mid(-5,crsr.dx,5)
  crsr.dy=mid(-5,crsr.dy,5)
  crsr.dx*=0.9
  crsr.dy*=0.9
  crsr.x+=crsr.dx
  crsr.y+=crsr.dy
  crsr.x=mid(0,crsr.x,127)
  crsr.y=mid(0,crsr.y,120)

  -- update fishies
  for fish in all(fishes) do

   -- not hooked fish   
   if not fish.hooked then
    
    if fish.x>=128+fish.r then
  	  del(fishes,fish)
  	  make_fish()
    end
    
    if fish.wait_time<=0 and fish.tgt.x == nil then  
     -- regenerate target
     fish.tgt.x = rir(fish.x,fish.x+60)
     fish.tgt.y = rir(fish.y-10,fish.y+10)
    elseif fish.wait_time<=0 then
     
     fish.x=lerp(fish.x,0.1,fish.tgt.x)
     fish.y=lerp(fish.y,0.1,fish.tgt.y)
     
     local prox=hyp(fish.x,fish.y,fish.tgt.x,fish.tgt.y)
     
     if prox <= 1 then
      fish.x=fish.tgt.x
      fish.y=fish.tgt.y
      
      fish.tgt.x=nil
      fish.tgt.y=nil
      
      fish.wait_time=rir(0,10)
     end
    else
      fish.wait_time-=1    
    end
    
    -- random chance of fish-farts
    --if rnd(500) < 1 then -- 0.2% chance per frame
    -- make_bubbles(fish.x, fish.y, 1)
    --end

   -- hooked fish 
   else
    --fish.x=hook.x
    fish.y=hook.y
   end
  end

  -- update pending score modificatons 
  if player_score < player_score_pending then
   player_score+=25
   sfx(1)
  end
 
  -- dispatch update for current state
  if (state=="fishing") state_fishing()
  if (state=="casting") state_casting()
  if (state=="reeling") state_reeling()
  if (state=="scoring") state_scoring()
end

-- game over metastate updater
function update_gameover ()
 if (btnp(❎)) start_level()
end

-->8
-- particles
function make_bubbles (x,y,n)
 sfx(0)
 for i=0,n do
  local ang=rnd(1)
  local mag=rnd(5)
  
  add(particles,{
   x=x,y=y,
   s=1+rnd(3),
   dx=mag*sin(ang),
   dy=mag*cos(ang),
   type=1
  })
 end
end

function sim_particle (p)
 p.dx*=0.8
 p.dy*=0.8
 p.x+=p.dx
 p.y+=p.dy

 if p.type==1 then
  p.y-=1
  p.x+=rnd(2)-1
 end
end

function draw_particle (p)
 if p.type==1 then
  circ(p.x,p.y,p.s,7)
 end
end
-->8
-- makers and drawers


function make_weed(x,h)
  local w={x=x,h=h}
  add(weeds, w)
  return w
end


function draw_weed(w)
  for i=1,3 do
    local h=weed_heights[i]*w.h*8
    local x=w.x-(i-2)*3
    
    for j=1,6 do
      local y=120-h+j*h/6
      local x_dist=sin(frame/51+j/3)
      local fat=1
      if (j==1) fat=0
      
      rectfill(
        x+x_dist,
        y,
        x+x_dist+fat,
        y+h/6,
        3
      )
    end
  end
end


function make_fish ()
 local tp=rnd(1)
 local z=0
 local fd=nil
 
 for i=1,#fish_data do
  fd=fish_data[i]
  z+=fd.chance
  if (tp<z) then
   tp=i
   break
  end
 end

 local fish={
  x=flr(rnd(64)-128),
  y=flr(rnd(120)),
  r=4,
  w=8,
  h=8,
  tp=tp,
  hooked=false,
  spd   =fd.spd,
  score =fd.pts,
  sprite=fd.spr,
  tgt={x,y},
  wait_time=rir(0,30),
 }
    
 add(fishes,fish)
 return fish
end

function draw_fish (fish)
 local anim=(frame/2)%3
 spr(fish.sprite+anim,fish.x-fish.r,fish.y-fish.r)

 if debug_collision then
  local c=7
  if (fish.hooked) c=8
  circ(fish.x%128,fish.y,fish.r,c)
 end
end


-->8
-- utils
function lerp (a,t,b)
 return a+(b-a)*t
end


function hyp (x1,y1,x2,y2)
 local dx=x2-x1
 local dy=y2-y1
 return sqrt(dx*dx + dy*dy)
end

function collide (a,b)
 local dist=hyp(a.x,a.y,b.x,b.y)
 return dist <= a.r+b.r
end 

function cprint (str,y,c)
 local w=#str*4
 print(str,64-w/2,y,c)
end

function rir(a,b) 
  return a+rnd(b-a)
end
-->8
-- timers

timers={}

function new_timer (dur)
 return {
  t=0,
  p=0,
  dur=dur,
  active=false,
  elapsed=false,
  elf=false
 }
end

function update_timer (t)
 if (not t.active) return
 t.t+=1
 t.p=t.t/t.dur
 t.elf=false
 local elapsed=t.t>=t.dur
 if not t.elapsed and elapsed then
  t.elf=true
 end 
 t.elapsed=elapsed 
end

function start_timer (t)
 t.t=0
 t.p=0
 t.elapsed=false
 t.elf=false
 t.active=true
end

__gfx__
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000ee5eeeee
3eeeaaee3eeeaaeeeeeeaaeeeeeeaaee0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000ee5eeeee
3ee9aaae3ee9aaae3ee9aaae3ee9aaae0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000e5eeeeee
c39aa0aac39aa0aa339aa0aa339aa0aa0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000e5eeeeee
33aaaaa733aaaaa7c3aaaaa7c3aaaaa700000000000000000000000000000000000000000000000000000000000000000000000000000000000000005eeeeeee
33a33aaa33a33aaa33aa3aaa33a33aaa00000000000000000000000000000000000000000000000000000000000000000000000000000000000000005eee5eee
3eea3aae3eeaaaae3eea3aae3eeaaaae00000000000000000000000000000000000000000000000000000000000000000000000000000000000000005eee5eee
eeeeaaeeeeeeaaee3eeeaaee3eeeaaee0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000e555eeee
ee11eeeeee11eeeeee11eeeeee11eeee000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
eee11eeeeee11eeeeee11eeeeee11eee000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
cee888eecee888ee1ee888ee1ee888ee000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1c88808e1c89808ecc88808ecc89808e000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1c88888ccc88888c1c88888ccc88888c000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
cee81eee1ee81eeecee81eee1ee81eee000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
eee1eeeeeee1eeeeeee1eeeeeee1eeee000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
eeebeeeeeeebeeeeeeebeeeeeeebeeee000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
eee3beeeeee3beeeeee3beeeeee3beee000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
9ee33bee9ee33beeaee33bee9ee33bee000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
9a3303bea93303be9a3303be993303be000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
a93333be9a3333bea93333be993333be000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
9ae99bee9aee9bee9ae99bee9ae99bee000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
aee3beeeaee39eeeaee39eeeaee3beee000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
44444444111111110111011101010111010101010101010101010101010101010101010100010001000000010000000000000000000000000000000000000000
44444444111111111111111111111111111111111011111110111011101010101010101010101010101010101010101000101010001000100000000000000000
45444494111111111101111111011101010111010101110101010101010101010101010101000101010001000000010000000000000000000000000000000000
44444444111111111111111111111111111111111111111111101110101011101010101010101010101010101010101010101010100010000000100000000000
44444444111101110111011101110101010101010101010101010101010101010101000100010001000100000000000000000000000000000000000000000000
44944444111111111111111111111111111111111011101110111011101010101010101010101010101010101010101000100010001000100000000000000000
44444494111111111111110111011101010101010101010101010101010101010101010101010100010001000000000000000000000000000000000000000000
54445444111111111111111111111111111111111111111011101110111010101010101010101010101010101010101010101000100010001000000000000000
__sfx__
00020000050600a0600f060080500d050110500b0400c0400e04010040130400b0300c0300c0300d0301003014030190300e0200e0200f0201002013020160201b0201f0201301014010170101a0102101026010
010300001052523734005040050400504005040050400504005040050400504005040050400504005040050400504005040050400504005040050400504005040050400504005040050400504005040050400504
000200003a6100c31031610072202b6201333027230113300f6300f330256200e6200f3200d1100c3100a11007010050100402002010010100101001010010000160002600026000260002600016000160001600
011000000c153000033c61300003006530000300003000030c1530000300003000030c6530000300003000030c1530000300003000030c6530000300003000030c1530000300003000030c653000030000300003
0110050c0c0540f05113051180511e0511e0521e0521e0521e0521e0521e0521e0520000000000000000000000000000000000000000290000000000000000000000000000000000000000000000000000000000
011000003085030850308503085030850308503085030850000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__music__
01 01020344
02 01020344

