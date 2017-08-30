# map = lambda do |function, collection|
#   collection.map do |item|
#     function.call(item)
#   end
# end

# map = lambda do |function, collection|
#   collection.map(&function)
# end


map = ->(function, collection) { collection.map(&function) }
add1 = ->(x){x + 1} 

map.(add1, [1,2,3,4,5]) # => [2, 3, 4, 5, 6]
