# https://bugs.ruby-lang.org/issues/6284
class Proc
  def +(other) # forward compose operation
    other.to_proc * self
  end

  def *(other) # backward compose operation
    -> arg { self.call other.(arg) } # with only one argument for performance reason.
  end
end


multiply2 = -> n { n  * 2 }
multiply3 = -> n { n  * 3 }
add1 = -> n { n  + 1 }

backward_composition = multiply2 * multiply3 * add1 
backward_composition.(5) # => 36

forward_composition = add1 + multiply3 + multiply2 
forward_composition.call(5) # => 36


add_header = -> (val) { "Title: #{val}" }
append_name = -> (val) { "#{val} My name" }
strip_word = -> (val) { :strip.to_proc.(val) }

# In Elixir
# input |> strip_word |> capitalize |> add_header |> append_name

format_as_title =  strip_word + :capitalize + add_header + append_name

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

format_as_title.('  hello world   ') # => "Title: Hello world My name"

payloads = [
  {
    'user_name' => 'Jane',
    'city' => 'Melbourne',
    'street' => 'King Street',
    'zipcode' => '123'
  },
  {
    'user_name' => 'John',
    'city' => 'Perth',
    'street' => 'Hay Street',
    'zipcode' => '123'
  }
]

require 'inflecto'

module FunctionsRegistry
  extend Transproc::Registry

  import Transproc::HashTransformations
  import Transproc::ArrayTransformations
  # import only necessary singleton methods from a module/class
  # and rename them locally
  import :camelize, from: Inflecto, as: :camel_case

  # define your own method
  def self.append_by(item, key, value)
    item.merge(key => "#{item[key]} #{value}")
  end
end

FunctionsRegistry[:append_by].call({user: 'John'}, :user, 'Doe') # => {:user=>"John Doe"}

def t(*args)
  FunctionsRegistry[*args]
end

CUSTOMER_TRANSFORMER = t(:symbolize_keys) >> t(:rename_keys, user_name: :user) >> t(:append_by, :user, 'Doe')
CUSTOMER_TRANSFORMER.call(payloads.first) # => {:city=>"Melbourne", :street=>"King Street", :zipcode=>"123", :user=>"Jane Doe"}

CUSTOMERS_TRANSFORMER =  t(:map_array, CUSTOMER_TRANSFORMER) >> t(:wrap, :address, [:city, :street, :zipcode])
CUSTOMERS_TRANSFORMER.call(payloads) # => [{:user=>"Jane Doe", :address=>{:city=>"Melbourne", :street=>"King Street", :zipcode=>"123"}}, {:user=>"John Doe", :address=>{:city=>"Perth", :street=>"Hay Street", :zipcode=>"123"}}]


class Customer
  def self.create(payload)
    "Customer #{payload[:user]} is created!"
  end
end

class Services
  class CreateCustomers
    def self.call(payloads, transformer: CUSTOMERS_TRANSFORMER)
      transformed_payloads = transformer.call(payloads)
      transformed_payloads.map { |customer_data| Customer.create customer_data }
    end
  end
end

Services::CreateCustomers.call(payloads) # => ["Customer Jane Doe is created!", "Customer John Doe is created!"]
