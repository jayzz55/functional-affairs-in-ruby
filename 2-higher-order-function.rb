map = ->(function, collection) { collection.map(&function) }
add1 = ->(x){x + 1} 

map.(add1, [1,2,3,4,5]) # => [2, 3, 4, 5, 6]
