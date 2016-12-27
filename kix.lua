-- kix v4
-- 2016-12-11 vv.
-- start

-----------------------TOOLS START-----------------------

local op_depth = 0
local mid_depth = 8
local end_depth = 16

local step = 0.24
local total_diff = 0

local insert = table.insert

math.randomseed(os.time())
-- math.randomseed(0)
math.random()

local update_pos_ptn

local now_book

local function copy(x)
  if type(x) == "table" then
    return {}
  end
  if type(x) == "function" then
    return x()
  end
  return x
end

local function init_array_d1(list,x,init)
  for i = 1, x do
    list[i] = copy(init) or 0
  end
end

local function init_array_d2(list,x,y,init)
  for i = 1, x do
    list[i] = {}
    init_array_d1(list[i],y,init)
  end
end

local function count_table( table, value )
  local count = 0
  for _,v in pairs(table) do
    if v == value then
      count = count + 1
    end
  end
  return count
end

------------------------TOOLS END------------------------

-----------------------BOARD START-----------------------
-- board copy from v2
-- for luajit or lua5.1
-- lua5.3 support 64-bit

-- TODO OR NOT TODO hashtable

local board = {}
local color = 1
local direction = {-10,-9,-8,-1,1,8,9,10}

local black = 2 -- 1
local white = 2 -- 2

local list_top = 0

local function d2_to_d1(x,y)
  return x * 9 + y + 1
end

local function get_board()
  return board
end

local function change_color()
  color = 3 - color
end

local function init()
  for i = 1,91 do
    board[i] = 3
  end
  for i = 1,8 do
  for j = 1,8 do
    board[d2_to_d1(i,j)] = 0
  end
  end
  board[d2_to_d1(4,4)] = 2
  board[d2_to_d1(5,5)] = 2
  board[d2_to_d1(4,5)] = 1
  board[d2_to_d1(5,4)] = 1
  color = 1
  black = 2
  white = 2
  list_top = 0
end

init()

local turn_list = {}
local move_list = {}

-- 1-8 way count
-- 9 where
-- 10 color
-- 11,12 black & white
init_array_d2(turn_list,64,12)
init_array_d2(move_list,64,32)

local function check_way(x,way)
  local count = 0
  local dir = direction[way]
  local now_x = x + dir
  local now = board[now_x]
  while now == 1 or now == 2 do
    if now == color then
      return count
    end
    now_x = now_x + dir
    now = board[now_x]
    count = count + 1
  end
  return 0
end

local function check(x)
  for way = 1, 8 do
    if check_way(x,way) > 0 then
      return true
    end
  end
  return false
end

local function gen_move()
  local num = 1
  local list = move_list[list_top + 1]
  for x = 11,81 do
    if board[x] == 0 and check(x) then
      num = num + 1
      list[num] = x
    end
  end
  list[1] = num - 1
  return list
end

local function can_move()
  for x = 11,81 do
    if board[x] == 0 and check(x) then
      return true
    end
  end
  return false
end

local function turn(x)

  list_top = list_top + 1
  local list = turn_list[list_top]
  
  local count = 0
  for way = 1,8 do
    local num = check_way(x,way)
    list[way] = num
    if num > 0 then
      local dir = direction[way]
      local now_x = x + dir
      count = count + num
      while num > 0 do
        board[now_x] = color
        now_x = now_x + dir
        num = num - 1
      end
    end
  end
  board[x] = color
  
  list[9] = x
  list[10] = color
  list[11] = black
  list[12] = white 
  
  if color == 1 then
    black = black + count + 1
    white = white - count
  else
    black = black - count
    white = white + count + 1
  end

  color = 3 - color
end

local function back()
  local list = turn_list[list_top]
  list_top = list_top - 1
  
  color = list[10]
  local opp = 3 - color
  local x = list[9]
  
  for way = 1, 8 do
    local num = list[way]
    if num > 0 then
      local dir = direction[way]
      local now_x = x + dir
      while num > 0 do
        board[now_x] = opp
        now_x = now_x + dir
        num = num - 1
      end
    end
  end
  black = list[11]
  white = list[12]
  board[x] = 0
end

local function turn_with_ptn(x)
  list_top = list_top + 1
  local list = turn_list[list_top]
  local opp = 3 - color
  
  local count = 0
  for way = 1,8 do
    local num = check_way(x,way)
    list[way] = num
    if num > 0 then
      local dir = direction[way]
      local now_x = x + dir
      count = count + num
      while num > 0 do
        board[now_x] = color
        update_pos_ptn(now_x,opp,color)
        now_x = now_x + dir
        num = num - 1
      end
    end
  end
  board[x] = color
  update_pos_ptn(x,0,color)
  list[9] = x
  list[10] = color
  color = 3 - color
end

local function back_with_ptn()
  local list = turn_list[list_top]
  list_top = list_top - 1
  
  color = list[10]
  local opp = 3 - color
  local x = list[9]
  
  for way = 1, 8 do
    local num = list[way]
    if num > 0 then
      local dir = direction[way]
      local now_x = x + dir
      while num > 0 do
        board[now_x] = opp
        update_pos_ptn(now_x,color,opp)
        now_x = now_x + dir
        num = num - 1
      end
    end
  end
  board[x] = 0
  update_pos_ptn(x,color,0)
end

------------------------BOARD END------------------------

---------------------EVALUATE START----------------------

-- pattern :
-- 1-8 col1-8
-- 9-16 row1-8
-- 17-27 diag xy
-- 28-38 diag yx

-- turn with pattern
-- back with pattern
-- update pattern

local ptn_book = {}
local now_ptn = {}
local ptn2pos = {}
local pos2ptn = {}

local function write_book(name)
  name = name or "data"
  local fout = io.open(name,"w")
  for i = 1,6 do
    for j = 1,38 do
      for k = 1,math.pow(3,#ptn2pos[j]) do
        fout:write(ptn_book[i][j][k])
		fout:write("\n")
      end
    end
  end
  fout:close()
end

local function read_book()
  local fin = io.open("data","r")
  if fin == nil then
    return write_book()
  end
  for i = 1,6 do
    local a = ptn_book[i]
    for j = 1,38 do
      local b = a[j]
      for k = 1,math.pow(3,#ptn2pos[j]) do
        b[k] = fin:read("*number")
      end
    end
  end
  fin:close()
end

do
  init_array_d1(now_ptn,38)
  init_array_d1(ptn2pos,38,{})
  init_array_d1(pos2ptn,81,{})

  --local y2ptn_offset = 8
  --local xy2ptn_offset = 16
  --local yx2ptn_offset = 27
  local xy2ptn = {0,1,1,1,2,3,4,5,6,7,8,9,10,11,11,11}

  for i = 1,8 do
  for j = 1,8 do
    local num = d2_to_d1(i,j)
    insert(ptn2pos[ i ], num)
    insert(ptn2pos[ j + 8 ], num) 
    insert(ptn2pos[ xy2ptn[ i + j ] + 16 ], num)
    insert(ptn2pos[ xy2ptn[ 9 + i - j ] + 27 ], num)
  end
  end

  for ptn_num,list in ipairs(ptn2pos) do
    for index,num in ipairs(list) do
      local pow3 = math.pow(3,index - 1)
      insert(pos2ptn[num],ptn_num)
      insert(pos2ptn[num],pow3)
    end
  end

  -- init pattern book
  -- TODO load pattern book
  init_array_d1(ptn_book,6,{})
  for i = 1,6 do
    local book = ptn_book[i]
    init_array_d1(book,38,{})
    for j = 1,38 do
      local count = math.pow(3,#ptn2pos[j])
      init_array_d1(book[j],count,math.random)
    end
  end
  
  read_book()
  
end

update_pos_ptn = function(num,old,new)
  local p2n = pos2ptn[num]
  local diff = new - old

  local ptn_num = p2n[1]
  now_ptn[ ptn_num ] = now_ptn[ ptn_num ] + diff * p2n[ 2 ]
  
  ptn_num = p2n[3]
  now_ptn[ ptn_num ] = now_ptn[ ptn_num ] + diff * p2n[ 4 ]
  
  ptn_num = p2n[5]
  now_ptn[ ptn_num ] = now_ptn[ ptn_num ] + diff * p2n[ 6 ]
  
  ptn_num = p2n[7]
  now_ptn[ ptn_num ] = now_ptn[ ptn_num ] + diff * p2n[ 8 ]
end

local function update_all_ptn()
  for i = 1,38 do
    now_ptn[i] = 1
  end
  for i = 11,81 do
    local now = board[i]
    if now ~=0 and now ~= 3 then
      update_pos_ptn(i,0,now)
    end
  end
end

local function evaluate()
  local score = 0
  for i = 1,38 do
    score = score + now_book[i][ now_ptn[i] ]
  end
  if color == 1 then
    return score
  else
    return -score
  end
end

local function learn(score)
  black = count_table(board,1)
  white = count_table(board,2)
  local f = black + white - 4
  if f == 0 then f = 1 end
  now_book = ptn_book[ math.ceil( f / 10 ) ]
  local now = evaluate()
  local diff = score - now
  if color == 2 then
    diff = -diff
  end
  local one_diff = step * diff / 38
  if black + white + end_depth >= 64 then
    one_diff = one_diff / end_depth
  end
  for i = 1,38 do
    now_book[i][ now_ptn[i] ] = now_book[i][ now_ptn[i] ] + one_diff
  end
  total_diff = total_diff + math.abs(diff)
end

local function reset_total_diff()
  total_diff = 0
end

local function get_total_diff()
  return total_diff
end

----------------------EVALUATE END-----------------------

---------------------MODSEARCH START---------------------

local function search_exact(depth,alpha,beta)

  if depth == 0 then
    if color == 1 then
      return black - white
    else
      return white - black
    end
  end

  local list = gen_move()
  local count = list[1]

  -- no move
  if count == 0 then
    color = 3 - color
    if can_move() then
      local score = -search_exact( depth, -beta, -alpha )
      color = 3 - color
      return score
    else
      color = 3 - color
      if color == 1 then
        return black - white
      else
        return white - black
      end
    end  
  end
  
  local a = alpha
  local b = beta
  local num

  for i = 2,count + 1 do
    local now = list[i]
    turn( now )
    local t = -search_exact( depth - 1, -b, -a )
    if t > a and t < beta and i > 2 and depth > 1 then
      a = -search_exact( depth - 1, -beta, -t )
      num = now
    end
    back()
    if t > a then
      a = t
      num = now
    end
    if a >= beta then
      return a
    end
    b = a + 1
  end

  return a,num
end

local function search_evaluate(depth,alpha,beta)

  -- TODO OR NOT TODO ID(iterative deepening)
  -- TODO OR NOT TODO aspiration search

  -- if depth == 6 then no ID&AS 
  -- only sort by one-depth evaluate()
  
  -- TODO sort move_list
  
  if depth == 0 then
    return evaluate()
  end

  local list = gen_move()
  local count = list[1]

  -- no move
  if count == 0 then
    color = 3 - color
    if can_move() then
      local score = -search_evaluate( depth, -beta, -alpha )
      color = 3 - color
      return score
    else
      color = 3 - color
      return evaluate()
    end  
  end
  
  local a = alpha
  local b = beta
  local num

  for i = 2,count + 1 do
    local now = list[i]
    turn_with_ptn( now )
    local t = -search_evaluate( depth - 1, -b, -a )
    if t > a and t < beta and i > 2 and depth > 1 then
      a = -search_evaluate( depth - 1, -beta, -t )
      num = now
    end
    back_with_ptn()
    if t > a then
      a = t
      num = now
    end
    if a >= beta then
      return a
    end
    b = a + 0.001
  end

  return a,num
end

----------------------MODSEARCH END----------------------

---------------------ENDSEARCH START---------------------

local function search_end(depth)
  local score,num = search_exact(depth,-65,65)
  return num,score
end

----------------------ENDSEARCH END----------------------

---------------------MIDSEARCH START---------------------

local function search_mid(depth)
  update_all_ptn()
  local score,num = search_evaluate(depth,-999,999)
  return num,score
end

----------------------MIDSEARCH END----------------------

---------------------OP SEARCH START---------------------

local function search_opening()
  -- TODO OR NOT TODO opening book
  local list = gen_move()
  local rand = math.random( 2, list[1] + 1 )
  return list[rand]
end

----------------------OP SEARCH END----------------------

-------------------SEARCH SELECT START-------------------

local function change_op_depth(depth)
  op_depth = depth
end

local function change_mid_depth(depth)
  mid_depth = depth
end

local function change_end_depth(depth)
  end_depth = depth
end

local function search_select()
  black = count_table(board,1)
  white = count_table(board,2)
  local space = 64 - black - white
  if space <= end_depth then
    now_book = ptn_book[6]
    return search_end,space
  elseif space > 60 - op_depth then
    return search_opening 
  else
    local f = math.min( white + black + mid_depth , 64 ) - 4
    now_book = ptn_book[ math.ceil( f / 10 ) ]
    return search_mid,math.min(mid_depth,space)
  end
end

local function search()
  local search_func,depth = search_select()
  local num,score = search_func(depth)
  if score then
    learn( score )
  end
  return num,score or 0
end

--------------------SEARCH SELECT END--------------------

local kix = {}
kix.init = init
kix.change_color = change_color
kix.turn = turn
kix.check = check
kix.can_move = can_move
kix.search = search
kix.get_board = get_board
kix.count_table = count_table
kix.change_op_depth = change_op_depth
kix.change_mid_depth = change_mid_depth
kix.change_end_depth = change_end_depth
kix.reset_total_diff = reset_total_diff
kix.get_total_diff = get_total_diff
kix.write_book = write_book

return kix
