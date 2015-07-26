##
# Ruby does not include the abstract interface construct.
# In order to enforce an implementation policy, you can however
# use a fake abstract interface (which, actually, is a class
# with functions to implement that raise errors if not overriden).
#
# *Why to use it*: Ensure that specific methods are implemented
# in inheriting/including classes. Useful when, for example, you want to
# propose several adapters implementations.
#
# *Drawback*: Errors are only raised at runtime

module LoggerInterface
  class MissingImplementation < RuntimeError; end
  def write(_string)
    fail MissingImplementation, 'Missing Implementation for method write'
  end
  def log(message)
    write('[%s]: %s' % [Time.now, message])
  end
end

##
# Now, including the LoggerInterface module to any class have two consequences:
# 1. A 'log' instance method is added to the class
# 2. Calling that log method throws an error if no specific implementation of
# the write instance method is found.

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

##
# As seen just above, a missing implementation raise an explicit error at
# runtime. This is quite useful when several person work on the same codebase,
# that fake abstract instance being used as guard against incomplete
# implementation of a designed interface.
