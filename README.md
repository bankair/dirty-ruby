# Dirty ruby

Before working with ruby, at the beginning of 2014, I spent ten years working
as a software contractor (C#/C++) for several quite big clients (mostly banks).

During that time, the most difficult part of the job was finding docs and
helpful third party softwares. You can imagine my amazement when I started
to work with ruby, its gems, and its ocean of helpful documentations.

The only thing I lacked at that time was some kind of collection of design
best practices and tips. That's why I'm trying to collect what I discovered
and tested (on the field) on this subject.

I hope it will help you as it helped me.
# Table of content

1. [Enhancing code robustness](#enhancing-code-robustness)
  1. [Securing parameters](#securing-parameters)
  1. [Fake abstract interface](#fake-abstract-interface)
  1. [Avoid using instance variables when possible](#avoid-using-instance-variables-when-possible)
  1. [Constants are lovely](#constants-are-lovely)
1. [Design tips](#design-tips)
  1. [Make it easy to test](#make-it-easy-to-test)
    1. [Identify responsibilities](#identify-responsibilities)
    1. [Design code to be testable](#design-code-to-be-testable)
    1. [Refactoring code to ease testability](#refactoring-code-to-ease-testability)

## Enhancing code robustness

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

### Avoid using instance variables when possible
Using references on instance variables directly can lead to errors in several
ways, for example by bypassing any validation you would add prior to value
assignment or updating accidentally a value meant to be immutable.

For a start, let's imagine you create a car class that has a color variable
that accept only 'red', 'green' and 'blue' as values:

```ruby
class Car
  attr_reader :color
  def validate!(color)
    raise 'Invalid color' unless %w(red green blue).include? color
    color
  end
  def color=(new_color)
    @color = validate! new_color
  end
  def initialize(color)
    @color = validate! color
  end
end

car = Car.new 'red'
puts car.color
# Print 'red'

begin
  car.color = 'teal'
  puts car.color
rescue
  puts 'expected error'
end
# Print 'error'

```

If someone introduce a method with a bad side effect to your perfect code:

```ruby
class Car
  def unsafe_repaint(new_color)
    @color = new_color
    puts "car painted #{new_color}"
  end
end

```

Your car can now take any colour:

```ruby
car = Car.new 'red'
puts car.color
# Print 'red'
car.unsafe_repaint 'magenta'
# Print 'car painted magenta'
puts car.color
# Print 'magenta'

```

A good solution to that kind of issue is to stop using references to the
instance variable in the class. Actually, only a single reference to the
instance variable should exists (in the setter), and you could even move
it out of the way by externalizing that code in a module, included in your
class.

Now, only refer to the color attribute through its getter and setter.

Example of a safe implementation of the car:

```ruby
module Color
  attr_reader :color
  def validate!(color)
    raise 'Invalid color' unless %w(red green blue).include? color
    color
  end
  def color=(new_color)
    @color = validate! new_color
  end
end

class SafeCar
  include Color
  def initialize(color)
    self.color = color
  end
  def repaint(new_color)
    self.color = new_color
    puts "car painted #{new_color}"
  end
end

```

Now, a car instance can be repainted, but only in the expected colours:

```ruby
safe_car = SafeCar.new('red')
safe_car.repaint('green')
# Print 'car painted green'
puts safe_car.color
# Print 'green'
begin
  safe_car.repaint('teal')
  puts safe_car.color
rescue
  puts 'expected error'
end
# print 'expected error'
```

### Constants are lovely
Ruby developpers seems to have contracted a bad case of symbol fever. Whenever
they need a state info or a constant token, they use a symbol. That's quite smart,
because symbols are somewhat 'mini-singletons'. Each time you are using the symbol
`:foobar`, you are refering to the same Symbol instance.

The only drawback to using those Symbol literals everywhere is that it does not
prevent from typos (There is no such thing as software failure. In the very end, the
error is still human).

Take in consideration the following code:

```ruby
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

```

There is several flagrant design flaw in this code, but I'd like you to focus on
the options mechanism: If the symbol `:readonly` is included in the given options,
then the file is open in read mode. If it's not included, then the file is open
in write mode, by default.

Now, let's take a quick glance at the following code that use the UnsafeFileWrapper:

```ruby
config_file = UnsafeFileWrapper.new('system.conf', [:read_only])

```

At first, it may seem that this config file is okay, but if you pay a little
attention to the options, you'll notice that :readonly is misspelled with an
additional underscore, which makes `config_file` a writable file.

A simple approach to limit the exposure to such risks is to encapsulate your symbols
in public and meaningful constants:

```ruby
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

```

Now, a correct usage of that safer file wrapper would be:

```ruby
safe_config_file = MoreSafeFileWrapper.new(
  'system.conf',
  [MoreSafeFileWrapper::READONLY]
)

```

And if a typo happens, it will cause a NameError exception right where
the problem is located in the source code, and you won't end up writing in
protected files !

```ruby
begin
  safe_config_file = MoreSafeFileWrapper.new(
    'system.conf',
    [MoreSafeFileWrapper::READ_ONLY] # <= typo !
  )
rescue StandardError => e
  puts e
  # Print "uninitialized constant MoreSafeFileWrapper::READ_ONLY"
end
```


## Design tips

### Make it easy to test

TDD is quite a dividing subject. Some say it's dead, and others that it's
the way to successful software crafting.

However, something that everybody agree upon is that a project with no tests
is meant to die painfully.

In this section, we'll cover several subjects:

1. How to identify and segment responsibility in your design.
1. How to design your ruby code to be easily testable (because easily tested
code is less likely to contain bugs).
1. How to cope with a code base that has no or poor tests.

#### Identify responsibilities
As stated by Robert C. Martin:

> a class should have only a single responsibility.

Martin describe a responsibility as a reason to change (when the specifications are updated).

In the case of a function that can open a file and return the first character
of every line of that file, for example, we identify the following
requirements:

1. The function can open and read a file
2. The function can extract the first character of every line

There is two responsibilities, here. The only things we can imagine to change
are:

1. Reading from something else than a file
2. Returning something else than the first line of every line

Thanks to ruby's API, we can tinker a quick implementation of the given
requirements:

```ruby
def first_chars_of(path)
  File.readlines(path).map{ |line| line[0] }
end

```

But, if we want to be a bit more close to the single responsibility
principle, we'd rather use two structures:

1. A content adapter (roughly a File.readlines call for the moment)
2. A content processor (that extract the first char of every line)

```ruby
class ContentProcessor
  def self.process(content)
    content.map { |line| line[0] }
  end
end

def first_chars_of_file(path)
  ContentProcessor.process(File.readlines(path))
end

```

Now that the file opening part was fully extracted from the processing
logic, changing the content adapter logic or the content processing logic
is really easy.

For example, here is an implementation for extracting all first characters
of an array:

```ruby
def first_chars_of_array(array)
  ContentProcessor.process array
end

```

Or if you want to take the last character only, just change your
ContentProcessor implementation to:

```ruby
class ContentProcessor
  def self.process(content)
    content.map { |line| line[-1] }
  end
end

```

The point here is that splitting software components per responsibility
allow a greater modularity, and ease the software maintainability.


#### Design code to be testable
In the previous section, we showed what is a responsibility.

Respecting the single responsibility principle allow to have only simple
software components, that achieve a single part of the whole software
goal.

Such components are fairly easy to test, as there is a single feature
to check.

In the following example, we'll be designing the tool used by the CEO of
BigShinyCar Incorporated to make market analysis.

The CEO of BigShinyCar wants a software to calculate the average price, in $,
of all non green cars.

We can deduce the following requirements (responsibilities):

1. Ability to fetch all non green car prices
1. Ability to convert a car to a price in $
1. Ability to calculate an average

Here, we would design three modular software components:

1. A component A that select all non green cars
1. A component B that convert a car into a float value being the same price
in $.
1. A component C that calculate an average from several float values.

And the course of actions would look like follow:

```
┌───────────┐          ┌───────────┐            ┌───────────┐
│Component A│- car 1 ->│Component B│- price 1 ->│Component C│
├───────────┤- car 2 ->├───────────┤- price 2 ->├───────────┤   Average
│ Filter    │  . . .   │ Convert to│  . . .     │ Calculate │-> price of non
│ cars      │- car m ->│ $ prices  │- price m ->│ average   │   green cars
└───────────┘          └───────────┘            └───────────┘
```

Those components would be named:

* Component A: CarPresenter
* Component B: PriceParser
* Component C: AverageCalculator

#### Refactoring code to ease testability
In the previous section, we designed a rough model for the tool to be used
by the CEO of BigShinyCar to calculate the average price (in $) of all
non green cars.

We stated that we where needing:

1. A component that select all non green cars
1. A component that convert a cars into a float value being the car price
in $.
1. A component that calculate an average from several float values.

Here is the database implementation of BigShinyCar:

```ruby
# A simple car model
Car = Struct.new(:brand, :model, :color, :local_price)
# A simple dataset implementation
class BigShinyCarDB
  DATA = [
    Car.new('MassiveTruck', 'TurboHonk',     'red',    '$15000'),
    Car.new('MassiveTruck', 'TurboHonk 1.5', 'green',  '$13000'),
    Car.new('PeopleCar',    'P42',           'red',    '€9999.99'),
    Car.new('Drof',         'Horse',         'blue',   '$4500'),
    Car.new('PeopleCar',    'P42',           'green',  '$12999.99'),
    Car.new('PeopleCar',    'P42',           'blue',   '€10999')
  ]

  def self.where(&block)
    DATA.select(&block)
  end
end

```

There is many wrong things with this code, but he will allow us to query
what looks like a mini-activerecord.

```ruby
puts BigShinyCarDB.where { |car| car.color == 'red' }.map(&:local_price).inspect
# Print '["$15000", "€9999.99"]'

```

Unfortunately, the developer in charge of the implementation of the software
component did not read our design recommendation in the previous section,
and came up with the following implementation:

```ruby
class PrototypeCalculator
  EURO_CONV = 1.109
  def self.calculate
    cars = BigShinyCarDB.where { |car| car.color != 'green' }
    prices = cars.map(&:local_price).map do |price|
      result = price[1..-1].to_f
      result = result * EURO_CONV if price[0] == '€'
      result
    end
    prices.reduce(&:+) / prices.size
  end
end

puts PrototypeCalculator.calculate
# Print '10696.9699775'

```

The result given by that code is correct, but it's pretty hard to test
its edge cases accurately.
Further more, in case of failure, the test report won't allow to reckon
which part of the process (filtering, conversion or calculation) did fail.

First, let's create the filtering service object:

```ruby
class CarPresenter
  def self.process(model = BigShinyCarDB)
    model.where { |e| e.color != 'green' }
  end
end

```

Next, we create a PriceParser service object:

```ruby
class PriceParser
  RATES = { '$' => 1.0, '€' => 1.109 }
  def self.process(car)
    price = String car.local_price
    currency = price[0]
    Float(price[1..-1]) * RATES.fetch(currency) do
      raise "Unknown currency #{currency}"
    end
  end
end

```

Now, we can create a new AverageCalculator
classes:

```ruby
class AverageCalculator
  def self.process(values)
    return if values.empty?
    values.reduce(&:+) / values.size
  end
end

```

And we can now use it to get the average price of non green cars:
puts AverageCalculator.process(CarPresenter.process.map do |car|
  PriceParser.process(car)
end)
Print '10696.9699775'

Now, you are able to test independantly the filtering logic, the price
conversion logic and the calculation logic. Please note that we make use of
optional parameters in order to allow the testing logic to easily mock
used dependencies.

Here are the tests of the CarPresenter class:

```ruby
# First, we mock the database (BigShinyCarDB#where works as Array#select)
class DbMock <  Array
  alias_method :where, :select
end

require 'rspec'
describe CarPresenter do
  describe '.process' do
    let(:empty_db) { DbMock.new }
    it { expect(CarPresenter.process(empty_db)).to be_empty }
    let(:db_with_only_green_cars) do
      DbMock.new.tap do |db|
        db << Car.new('MassiveTruck', 'TurboHonk',  'green', '$15000')
        db << Car.new('Drof',         'Horse',      'green', '$4500')
      end
    end
    it { expect(CarPresenter.process(db_with_only_green_cars)).to be_empty }
    let(:db_with_two_green_cars) do
      DbMock.new([
        Car.new('MassiveTruck', 'TurboHonk',     'red',    '$15000'),
        Car.new('Drof',         'Horse',         'blue',   '$4500'),
        Car.new('Draf',         'Horse',         'green',  '$4000'),
        Car.new('Drif',         'Horse',         'green',  '$3500'),
      ])
    end
    let(:non_green_cars) { CarPresenter.process(db_with_two_green_cars) }
    it { expect(non_green_cars.size).to eq 2 }
    it { expect(non_green_cars.map(&:brand)).to match_array %w(MassiveTruck Drof) }
  end
end

```

Next, we are able to only test the price extration logic:

```ruby
describe PriceParser do
  describe '.process' do
    {
      '£12'   => /Unknown currency £/,
      nil     => TypeError,
      :foobar => ArgumentError
    }.each do |invalid_price, exception|
      it "raise an exception when given #{invalid_price}" do
        car = Car.new(:no_brand, :no_model, :no_color, invalid_price)
        expect{PriceParser.process(car)}.to raise_error exception
      end
    end
    { '$1' => 1.0, '€1000' => 1109.0 }.each do |input, output|
      it "return #{output} when given #{input}" do
        car = Car.new(:no_brand, :no_model, :no_color, input)
        expect(PriceParser.process(car)).to eq output
      end
    end
  end
end

```

As shown in the following code snippet, the only remaining logic to test is
related to the average calculation (which is quite straight forward):

```ruby
describe AverageCalculator do
  describe '.process' do
    it { expect(AverageCalculator.process([])).to be_nil }
    it { expect(AverageCalculator.process([20.0])).to eq 20.0 }
    it { expect(AverageCalculator.process([10.0, 19.0, 31.0])).to eq 20.0 }
  end
end

```

Now, each aspect of the calculator is independently tested, and a test failure will
allow to target instantly the faulty class.

We took each component described in the section "[Design code to be testable](#design-code-to-be-testable)",
and implemented them into its own class. There is two interesting side effects to that:
1. It's pretty simple to test a component meant to calculate an average or convert a price
2. The three created components exists without coupling, which make it easy to reuse them

Some may object that the resulting code is more verbose than the prototype's implementation.
Personally, I'm always happy to exchange some time today against more clarity, more tests
and less time to maintain that logic in six months.




