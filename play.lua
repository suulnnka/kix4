local kix = require("kix")

local function d1_to_d2_hum(num)
  local y = ( num - 1 ) % 9
  local x = ( num - y - 1 ) / 9
  return x*10+y
end

local function d2_to_d1_hum(num)
  local y = num % 10
  local x = ( num - y ) / 10
  return x * 9 + y + 1
end

local function dump_board()
  local board = kix.get_board()
  print( "black: " .. kix.count_table(board,1) .. " white: " .. kix.count_table(board,2) )
  local s = ""
  for i = 11,81 do
    local j = board[i]
    if i % 9 == 1 then
      s = s .. "\n"
    end
    if j == 0 then
      s = s .. "."
    end
    if j == 1 then
      s = s .. "X"
    end
    if j == 2 then
      s = s .. "O"
    end
  end
  print(s)
  print()
end

kix.init()
local moveable = true

while moveable do

  print("input:")
  local cmd = io.read()
  local num = tonumber(cmd)
  if num then
    num = d2_to_d1_hum(num)
    if kix.check(num) then
      kix.turn(num)
      dump_board()
    end
  elseif cmd == "c" then
    local num,score = kix.search()
    print( d1_to_d2_hum(num).."    "..score )
    kix.turn(num)
    dump_board()
  elseif cmd == "d" then
    dump_board()
  elseif cmd == "h" then
    print("--[[")
    print("  input num : put chessman")
    print("  input 'c' : computer put")
    print("  input 'd' : draw board")
    print("  input 'h' : print help")
    print("--]]")    
  end

  if not kix.can_move() then
    kix.change_color()
    if not kix.can_move() then
      moveable = false
    end
  end

end

print("game over")
local board = kix.get_board()
local black = kix.count_table(board,1)
local white = kix.count_table(board,2)
if white == black then
  print("draw")
elseif white > black then
  print("white win")
else
  print("black win")
end
