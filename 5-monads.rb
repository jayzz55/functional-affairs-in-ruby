require 'dry-monads'

extend Dry::Monads::Try::Mixin
M = Dry::Monads

# {{{1 Maybe Monads
## {{{2 Pizza in a box
M.Maybe('pizza').inspect
M.Maybe(nil).inspect 
# }}}

## {{{2 Slicing the pizza with bind and fmap
slize_pizza = -> (pizza) { M.Some('pizza slices') }

result = M.Maybe('some pizza').bind(slize_pizza)
result = M.Maybe('some pizza').fmap(slize_pizza)
## }}}

## {{{2 Chaining to deliver the pizza
deliver_pizza = -> (pizza) { M.Some('pizza delivered to Zendesk office') }

result = M.Maybe('some pizza').bind(slize_pizza).bind(deliver_pizza)
result = M.Maybe('some pizza').fmap(slize_pizza).bind(deliver_pizza)
## }}

## {{{2 Teeing to find parking
### {{{3 When can find parking
find_parking = -> (_) { M.Some(true) }

result = M.Maybe('some pizza').bind(slize_pizza).tee(find_parking).bind(deliver_pizza)
### }}}

### {{{3 When can NOT find parking
find_parking = -> (_) { M.None }

result = M.Maybe('some pizza').bind(slize_pizza).tee(find_parking).bind(deliver_pizza)
### }}}
## }}}
#}}}

# {{{1 Result Monads (a.k.a Either Monads)
## {{{2 I want to know why my pizza is NOT here
find_parking = -> (_) { M.Failure('cannot find parking ¯\_(ツ)_/¯') }
deliver_pizza = -> (pizza) { M.Success('pizza delivered to Zendesk office') }

result = M.Maybe('some pizza').bind(slize_pizza).tee(find_parking).bind(deliver_pizza)
## }}}

## {{{2 OR.. 
find_parking = -> (_) { M.Failure('cannot find parking ¯\_(ツ)_/¯') }
deliver_pizza = -> (pizza) { M.Success('pizza delivered to Zendesk office') }
flip_it = M.Failure('(ノ°Д°）ノ︵ ')

result = M.Maybe('some pizza').bind(slize_pizza).tee(find_parking).bind(deliver_pizza).or(flip_it)
## }}}

## {{{2 When Pizza is successfully delivered
find_parking = -> (_) { M.Success('cannot find parking ¯\_(ツ)_/¯') }
deliver_pizza = -> (pizza) { M.Success('pizza delivered to Zendesk office') }

result = M.Maybe('some pizza').bind(slize_pizza).tee(find_parking).bind(deliver_pizza)
## }}}
# }}}

# {{{1 Try Monads - When handling exception, ie: Calling Roro staff to deliver pizza
## {{{2 When Successful call
find_parking = -> (_) { M.Some(true) }
call_roro_staff = -> (_) { Try() { 'calling roro staff' }.to_result }

result = M.Maybe('some pizza').bind(slize_pizza).tee(find_parking).bind(call_roro_staff).bind(deliver_pizza)
## }}}

## {{{2 When there's an exception
class NetworkError < StandardError
end

call_roro_staff = -> (_) { Try() { raise NetworkError.new('Sorry Vodafone network is currently down T__T') }.to_result }

result = M.Maybe('some pizza').bind(slize_pizza).tee(find_parking).bind(call_roro_staff).bind(deliver_pizza)
## }}}
# }}}
