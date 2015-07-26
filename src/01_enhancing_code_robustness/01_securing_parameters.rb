##
# There is no strong typing in ruby (for the moment). Duck typing is fun
# and quite useful, but sometimes, you want to ensure that your friends
# will give your functions the right kind of value.
#
# *Why to use it*: Ensure that a given parameter is compliant with what
# you intent to do with it inside a function.
#
# *Drawback*: Some additionnal declarations at the start of your function.
#
# Example: Let's imagine a function that multiply by 2

def unsafe_mult_2(value)
  value * 2
end

##
# That function seems pretty straight forward to use:

puts unsafe_mult_2(3)
# Print:
# 6

##
# But if you inadvertly give it a string:

puts unsafe_mult_2('3')
# Print:
# 33
puts unsafe_mult_2('alice')
# Print:
# alicealice

##
# If you really where intending to manipulate numbers with that function,
# the safest way to do it is to use one of the following methods before
# anything else:
#
# * Kernel::Integer(value)
# * Kernel::Float(value)
#
# Those methods convert the given value in the expected format _if possible_.
#
# Now, our function looks like follow:

def safe_mult_2(value)
  value = Float(value)
  value * 2
end

##
# Now, your function behave like it really expect a numeric value:

puts safe_mult_2(3)
# Print:
# 6.0
puts safe_mult_2('3')
# Print:
# 6.0
puts safe_mult_2('alice')
# Raise:
# invalid value for Float(): "alice" (ArgumentError)

##
# There exists two more kernel methods for value conversion:
#
# * Kernel::String(value)
# * Kernel::Array(value)
