require 'transproc'
require 'dry-monads'

extend Dry::Monads::Try::Mixin

module Fn
  extend Transproc::Registry
end

add_header = Fn[-> (val) { "Title: #{val}" } ]
append_name = Fn[-> (val) { "#{val} My name" } ]
strip_word = Fn[-> (val) { :strip.to_proc.(val) } ]
strip_word = Fn[strip_word]
capitalize = Fn[:capitalize.to_proc]
format_as_title = strip_word >> capitalize >> add_header >> append_name

M = Dry::Monads

M.Maybe(1234).inspect # => "Some(1234)"
M.Maybe(nil).inspect # => "None"

result = M.Maybe('  hello world  ').bind(format_as_title) # => "Title: Hello world My name"

result = M.Maybe('  hello world  ').fmap(format_as_title) # => Some("Title: Hello world My name")


class NetworkError < StandardError
end

fetch_data = ->(_) { raise NetworkError, 'some network error' }

format_as_title = strip_word >> capitalize >> fetch_data >> add_header >> append_name

try_result = Try(NetworkError) { M.Maybe('  hello world  ').bind(format_as_title) }.to_either
try_result.inspect # => "Left(#<NetworkError: some network error>)"
M.Right(134).value.inspect # => "134"
M.Left("error").value.inspect # => "\"error\""
