function1 = lambda do |x| # !> assigned but unused variable - function1
  x + 1
end

function2 = lambda{|x| x + 1} # !> assigned but unused variable - function2

# Shorthand to declare a lambda
function3 = -> (x) { x + 1 }

function3.call(9) # => 10
