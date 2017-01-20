local kix = require("kix")

kix.change_op_depth(6)
kix.change_mid_depth(6)
kix.change_end_depth(12)

for i = 1,1000 do
  kix.reset_total_diff()
  for j = 1,30 do
    
    kix.init()
    local moveable = true

    while moveable do
      local num = kix.search()
      kix.turn(num)

      if not kix.can_move() then
        kix.change_color()
        if not kix.can_move() then
          moveable = false
        end
      end

    end
  end
  
  print( kix.get_total_diff() / 30 )
  kix.write_book("data")
  kix.write_book("data2")
  print("write done.")
  print()
  
end
