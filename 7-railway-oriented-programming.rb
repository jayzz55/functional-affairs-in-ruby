# POST REQUEST
# request -> handle_request -> validate_model -> save_db -> notify -> render_response

require 'dry-transaction'
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
parse_params = -> (input) { input[:customer] ? M.Right(input[:customer]) : M.Left('params[:customer] is required') }
build_customer = -> (input) { M.Right(Customer.new(name: input[:name], gender: input[:gender])) }
handle_request_operations = [authenticate, parse_params, build_customer]

handle_request = fmap.(handle_request_operations)
validate_model = -> (model) { model.name ? M.Right(model) : M.Left('Validation failed: Name is missing') }
save_db = -> (model) { model.save; model }
notify = -> (model) { Notifier.notify(model); model }
render_response = -> (model) { M.Right(model.to_s) }

params = { customer: { name: 'john', gender: 'male' }}
# params = { customer: {} }
# params = {}


save_user = Dry.Transaction(container: []) do
  step :handle_request, with: handle_request
  step :validate_model, with: validate_model
  try :save_db, with: save_db, catch: NetworkError
  try :notify, with: notify, catch: NetworkError
  step :render_response, with: render_response
end

save_user.(M.Maybe(params)) do |transaction|
  transaction.success do |value|
    puts "SUCCESS!!! - #{value}"
  end

  # transaction.failure :handle_request do |error|
  #   puts "Error in handle_request: #{error}"
  # end

  transaction.failure :validate_model do |error|
    puts "Validation error: #{error}"
  end

  transaction.failure :save_db do |error|
    puts "Error in saving to database: #{error}"
  end

  transaction.failure :notify do |error|
    puts "Error in notifier: #{error}"
  end

  transaction.failure do |error|
    # Runs for any failure case
    puts "Errors!: #{error}"
  end
end 

# >> Errors!: params[:customer] is required
