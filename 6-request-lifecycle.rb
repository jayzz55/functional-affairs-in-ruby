# POST REQUEST
# request -> handle_request -> validate_model -> save_db -> notify -> render_response

require 'dry-monads'

extend Dry::Monads::Try::Mixin

M = Dry::Monads

class Customer
  attr_reader :name, :gender

  def initialize(name:, gender:)
    @name = name
    @gender = gender
  end

  def save
    true
  end

  def to_s
    "Customer #{name} is a #{gender}"
  end
end

class Notifier
  def self.notify(object)
    true
  end
end

class NetworkError < StandardError
end

fmap = -> (functions, wrapped_input) { functions.inject(wrapped_input) { |sum, n| sum.bind(n) } }.curry

authenticate = -> (input) { M.Right(input) }
parse_params = -> (input) { input[:customer] ? M.Right(input[:customer]) : M.Left('params[:customer] is missing!') }
build_customer = -> (input) { M.Right(Customer.new(name: input[:name], gender: input[:gender])) }

handle_request_operations = [authenticate, parse_params, build_customer]

handle_request = fmap.(handle_request_operations) # => #<Proc:0x007fede20a49c0 (lambda)>

validate_model = -> (model) { model.name ? M.Right(model) : M.Left('Validation failed: Name is missing') }
save_db = -> (model) { Try() { model.save } }
notify = -> (model) { Try() { Notifier.notify(model) } }
render_response = -> (model) { M.Right(model.to_s) }

# params = { customer: { name: 'john', gender: 'male' }}
# params = { customer: {}}
params = { }

response = handle_request.(M.Maybe(params))
  .bind(validate_model)
  .tee(save_db)
  .tee(notify)
  .bind(render_response) 

response # => Left("params[:customer] is missing!")

