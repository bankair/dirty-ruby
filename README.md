# Ruby patterns collection
<sup>[[link](#ruby_patterns_collection)]</sup>

This repo is a collection of some ruby patterns, sorted by motivation.

# Table of content

1. [Enhancing code robustness](#enhancing_code_robustness)
  1. [Securing parameters](#securing_parameters)
  1. [Fake abstract interface](#fake_abstract_interface)

## Enhancing code robustness
<sup>[[link](#enhancing_code_robustness)]</sup>

Ruby is a quite an awesome language.

The duck typing is pretty fun to use, as you no longer have to specify
what your functions expect.

And there is always a lots of way to achieve what you are trying to do.

But that freedom can lead to a big pot of trouble:

* When you don't know what to give as input to some existing code
* When you don't know how to inherit from / extend some existing code
* When ... (countless related issues)

In this section, you'll find some interesting patterns to enhance your code
robustness.

### Securing parameters
<sup>[[link](#securing_parameters)]</sup>
There is no strong typing in ruby (for the moment). Duck typing is fun
and quite useful, but sometimes, you want to ensure that your friends
will give your functions the right kind of value.

*Why to use it*: Ensure that a given parameter is compliant with what
you intent to do with it inside a function.

*Drawback*: Some additionnal declarations at the start of your function.

Example: Let's imagine a function that multiply by 2

```ruby
def unsafe_mult_2(value)
  value * 2
end

```

That function seems pretty straight forward to use:

```ruby
puts unsafe_mult_2(3)
# Print:
# 6

```

But if you inadvertly give it a string:

```ruby
puts unsafe_mult_2('3')
# Print:
# 33
puts unsafe_mult_2('alice')
# Print:
# alicealice

```

If you really where intending to manipulate numbers with that function,
the safest way to do it is to use one of the following methods before
anything else:

* Kernel::Integer(value)
* Kernel::Float(value)

Those methods convert the given value in the expected format _if possible_.

Now, our function looks like follow:

```ruby
def safe_mult_2(value)
  value = Float(value)
  value * 2
end

```

Now, your function behave like it really expect a numeric value:

```ruby
puts safe_mult_2(3)
# Print:
# 6.0
puts safe_mult_2('3')
# Print:
# 6.0
puts safe_mult_2('alice')
# Raise:
# invalid value for Float(): "alice" (ArgumentError)

```

There exists two more kernel methods for value conversion:

* Kernel::String(value)
* Kernel::Array(value)

### Fake abstract interface
<sup>[[link](#fake_abstract_interface)]</sup>
Ruby does not include the abstract interface construct.
In order to enforce an implementation policy, you can however
use a fake abstract interface (which, actually, is a class
with functions to implement that raise errors if not overriden).

*Why to use it*: Ensure that specific methods are implemented
in inheriting/including classes. Useful when, for example, you want to
propose several adapters implementations.

*Drawback*: Errors are only raised at runtime

```ruby
module LoggerInterface
  class MissingImplementation < RuntimeError; end
  def write(_string)
    fail MissingImplementation, 'Missing Implementation for method write'
  end
  def log(message)
    write('[%s]: %s' % [Time.now, message])
  end
end

```

Now, including the LoggerInterface module to any class have two consequences:
1. A 'log' instance method is added to the class
2. Calling that log method throws an error if no specific implementation of
the write instance method is found.

```ruby
# That class concatenate all log message into the string instance attribute
class StringLogger
  include LoggerInterface
  attr_reader :string
  def initialize
    @string = ''
  end
  def write(str)
    @string += str + "\n"
  end
end

# That class just throw everything it gets to log into calls to the puts
# method
class PutsLogger
  include LoggerInterface
  def write(string)
    puts string
  end
end

# That class is an example of a failed implementation of LoggerInterface
class BadLogger
  include LoggerInterface
  def wite(string) # Note the typo here
    'Derp!'
  end
end

string_logger = StringLogger.new
string_logger.log 'foo'
string_logger.log 'bar'
puts string_logger.string
# Print:
# [2015-07-25 20:41:13 +0200]: foo
# [2015-07-25 20:41:13 +0200]: bar

PutsLogger.new.log('foobar')
# Print:
# [2015-07-25 20:41:13 +0200]: foobar

BadLogger.new.log('derp!')
# Raise an error:
# Missing Implementation for method write (LoggerInterface::MissingImplementation)

```

As seen just above, a missing implementation raise an explicit error at
runtime. This is quite useful when several person work on the same codebase,
that fake abstract instance being used as guard against incomplete
implementation of a designed interface.


