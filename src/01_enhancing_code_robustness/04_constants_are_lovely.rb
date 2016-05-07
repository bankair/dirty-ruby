##
# Ruby developpers seems to have contracted a bad case of symbol fever. Whenever
# they need a state info or a constant token, they use a symbol. That's quite smart,
# because symbols are somewhat 'mini-singletons'. Each time you are using the symbol
# `:foobar`, you are refering to the same Symbol instance.
#
# The only drawback to using those Symbol literals everywhere is that it does not
# prevent from typos (There is no such thing as software failure. In the very end, the
# error is still human).
#
# Take in consideration the following code:

class UnsafeFileWrapper
  def initialize(path, options)
    @path = path
    @options = options
  end

  def file
    return @file if defined?(@file)
    @file = File.new(@path, @options.include?(:readonly) ? 'r' : 'w')
  end

  def write(buffer)
    file.write buffer
  end
  # ...
end

##
# There is several flagrant design flaw in this code, but I'd like you to focus on
# the options mechanism: If the symbol `:readonly` is included in the given options,
# then the file is open in read mode. If it's not included, then the file is open
# in write mode, by default.
#
# Now, let's take a quick glance at the following code that use the UnsafeFileWrapper:

config_file = UnsafeFileWrapper.new('system.conf', [:read_only])

##
# At first, it may seem that this config file is okay, but if you pay a little
# attention to the options, you'll notice that :readonly is misspelled with an
# additional underscore, which makes `config_file` a writable file.
#
# A simple approach to limit the exposure to such risks is to encapsulate your symbols
# in public and meaningful constants:

class MoreSafeFileWrapper
  READONLY = :readonly
  def initialize(path, options)
    @path = path
    @options = options
  end

  def file
    return @file if defined?(@file)
    @file = File.new(@path, @options.include?(READONLY) ? 'r' : 'w')
  end

  def write(buffer)
    file.write buffer
  end
  #...
end

##
# Now, a correct usage of that safer file wrapper would be:

safe_config_file = MoreSafeFileWrapper.new(
  'system.conf',
  [MoreSafeFileWrapper::READONLY]
)

##
# And if a typo happens, it will cause a NameError exception right where
# the problem is located in the source code, and you won't end up writing in
# protected files !

begin
  safe_config_file = MoreSafeFileWrapper.new(
    'system.conf',
    [MoreSafeFileWrapper::READ_ONLY] # <= typo !
  )
rescue StandardError => e
  puts e
  # Print "uninitialized constant MoreSafeFileWrapper::READ_ONLY"
end
