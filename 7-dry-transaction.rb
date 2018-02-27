# PUT REQUEST
# request -> validate -> get_user -> update_db -> send_email -> return_message

require 'dry-transaction'
require 'dry-monads'
M = Dry::Monads

# {{{1 User
class User
  def self.find_by(id:)
    new(id: id)
  end

  attr_reader :id

  def initialize(id:)
    @id = id
  end

  def save
    true
  end

  def to_s
    "User with id #{id}"
  end
end
# }}}

# {{{1 Job::SendEmail
module Job
  class SendEmail
    def self.call(user) # !> previous definition of call was here
      user
    end
  end
end
# }}}

# {{{1 Dry::Transaction
## {{{2 UpdateUserTransaction
class NetworkError < StandardError
end

class Logger
  def self.log(e)
    puts "Logging error - #{e}"
  end
end

class UpdateUserTransaction
  include Dry::Transaction
  include Dry::Monads::Try::Mixin

  step :validate
  map :get_user
  tee :update_db
  try :send_email, catch: NetworkError
  map :render_response

  def validate(input)
    input[:id] ? M.Success(input) : M.Failure('Validation failed: Id is missing')
  end

  def get_user(input)
    User.find_by(id: input[:id])
  end

  def update_db(user)
    user.save ? M.Success(nil) : M.Failure(user)
  end

  def send_email(user)
    Job::SendEmail.call(user)
  end

  def render_response(input)
    "#{input} is successfully updated"
  end
end
## }}}

## {{{2 pattern matching on transaction result
request_to_update_user = lambda do |input_params|
  UpdateUserTransaction.new.call(input_params) do |transaction|
    transaction.success do |value|
      "SUCCES!!! - #{value}"
    end

    transaction.failure :send_email do |error|
      Logger.log(error)
      "Failed to send email to user because of #{error}"
    end

    transaction.failure do |error|
      "Failed to update user because of #{error}"
    end
  end
end
## }}}

## {{{2 When successful request
request_to_update_user.call({id: 1}) # => "SUCCES!!! - User with id 1 is successfully updated"
### }}}

## {{{2 When failed request due to validation
request_to_update_user.call({}) # => "Failed to update user because of Validation failed: Id is missing"
## }}}

## {{{2 When failed request due to exception
module Job
  class SendEmail
    def self.call(user) # !> method redefined; discarding old call
      raise NetworkError.new('Kaboom!')
    end
  end
end

request_to_update_user.call({id: 1}) # => "Failed to send email to user because of Kaboom!"

## }}}
# }}}
# >> Logging error - Kaboom!
