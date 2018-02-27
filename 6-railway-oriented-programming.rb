# PUT REQUEST
# request -> validate -> get_user -> update_db -> send_email -> return_message

require 'dry-monads'
extend Dry::Monads::Try::Mixin
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

# {{{1 List of defined functions
## {{{2 core functions
validate = -> (input) { input[:id] ? M.Success(input) : M.Failure('Validation failed: Id is missing') }
get_user = -> (input) { User.find_by(id: input[:id]) }
update_db = -> (user) { M.Maybe(user.save) }
send_email = -> (user) { Try() { Job::SendEmail.call(user) }.to_result }
## }}}

## {{{2 composed function
request_to_update_user = lambda do |input|
  update_user = M.Maybe(input)
    .bind(validate)
    .fmap(get_user)
    .tee(update_db)
    .bind(send_email)

  if update_user.success?
    "#{update_user.value} is successfully updated"
  else
    "Failed to update user because of #{update_user.failure}"
  end
end
## }}}
# }}}

# {{{1 Successful Request
request_to_update_user.call({id: 1}) # => "User with id 1 is successfully updated"
# }}}

# {{{1 When failed validation
request_to_update_user.call({}) # => "Failed to update user because of Validation failed: Id is missing"
# }}}

# {{{1 When there is a network error in sending email
class NetworkError < StandardError
end

module Job
  class SendEmail
    def self.call(user) # !> method redefined; discarding old call
      raise NetworkError.new('Kaboom!')
    end
  end
end

request_to_update_user.call({id: 123}) # => "Failed to update user because of Kaboom!"
#}}}
