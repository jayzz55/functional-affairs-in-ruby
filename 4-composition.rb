# https://bugs.ruby-lang.org/issues/6284
class Proc
  def +(other) # forward compose operation
    other.to_proc * self
  end

  def *(other) # backward compose operation
    -> arg { self.call other.(arg) } # with only one argument for performance reason.
  end
end


f = -> n { n  * 2 }
g = -> n { n  * 3 }
h = -> n { n  + 1 }

x = f * g * h  # !> assigned but unused variable - x

y = h + g + f  # !> assigned but unused variable - y


add_header = -> (val) { "Title: #{val}" }
append_name = -> (val) { "#{val} My name" }
strip_word = -> (val) { :strip.to_proc.(val) }

format_as_title =  strip_word + :capitalize + add_header + append_name

# strip_word.call(input) |> :capitalize |> add_header |> append_name

format_as_title.('  hello world   ') # => "Title: Hello world My name"


require 'transproc'

module Fn
  extend Transproc::Registry
end

add_header = Fn[-> (val) { "Title: #{val}" } ]
append_name = Fn[-> (val) { "#{val} My name" } ]
strip_word = Fn[-> (val) { :strip.to_proc.(val) } ]
strip_word = Fn[strip_word]
capitalize = Fn[:capitalize.to_proc]
format_as_title = strip_word >> capitalize >> add_header >> append_name

result = format_as_title.('  hello world   ')
result.inspect # => "\"Title: Hello world My name\""
