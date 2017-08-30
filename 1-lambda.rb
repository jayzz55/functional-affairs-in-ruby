add1 = lambda do |x|
  x + 1
end

add1 = lambda{|x| x + 1}

# Shorthand to declare a lambda
add1 = -> (x) { x + 1 }

add1.call(9) # => 10

# Shorthand to call a lambda
add1.(9) # => 10

# Shorthand to call a lambda
add1[9] # => 10
