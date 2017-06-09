map = ->(function, collection) { collection.map(&function) }

adder = proc { |x, y| x + y }

add1 = adder.curry.(1) # => #<Proc:0x007f85a28aa758>

map.(add1, [1,2,3,4,5]) # => [2, 3, 4, 5, 6]

add2 = adder.curry.(2)
map.(add2, [1,2,3,4,5]) # => [3, 4, 5, 6, 7]
