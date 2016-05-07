##
# In the previous section, we designed a rough model for the tool to be used
# by the CEO of BigShinyCar to calculate the average price (in $) of all
# non green cars.
#
# We stated that we where needing:
#
# 1. A component that select all non green cars
# 1. A component that convert a cars into a float value being the car price
# in $.
# 1. A component that calculate an average from several float values.
#
# Here is the database implementation of BigShinyCar:

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

##
# There is many wrong things with this code, but he will allow us to query
# what looks like a mini-activerecord.

puts BigShinyCarDB.where { |car| car.color == 'red' }.map(&:local_price).inspect
# Print '["$15000", "€9999.99"]'

##
# Unfortunately, the developer in charge of the implementation of the software
# component did not read our design recommendation in the previous section,
# and came up with the following implementation:

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

##
# The result given by that code is correct, but it's pretty hard to test
# its edge cases accurately.
# Further more, in case of failure, the test report won't allow to reckon
# which part of the process (filtering, conversion or calculation) did fail.
#
# First, let's create the filtering service object:

class CarPresenter
  def self.process(model = BigShinyCarDB)
    model.where { |e| e.color != 'green' }
  end
end

##
# Next, we create a PriceParser service object:

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

##
# Now, we can create a new AverageCalculator
# classes:

class AverageCalculator
  def self.process(values)
    return if values.empty?
    values.reduce(&:+) / values.size
  end
end

##
# And we can now use it to get the average price of non green cars:
puts AverageCalculator.process(CarPresenter.process.map do |car|
  PriceParser.process(car)
end)
# Print '10696.9699775'

##
# Now, you are able to test independantly the filtering logic, the price
# conversion logic and the calculation logic. Please note that we make use of
# optional parameters in order to allow the testing logic to easily mock
# used dependencies.
#
# Here are the tests of the CarPresenter class:

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

##
# Next, we are able to only test the price extration logic:

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

##
# As shown in the following code snippet, the only remaining logic to test is
# related to the average calculation (which is quite straight forward):

describe AverageCalculator do
  describe '.process' do
    it { expect(AverageCalculator.process([])).to be_nil }
    it { expect(AverageCalculator.process([20.0])).to eq 20.0 }
    it { expect(AverageCalculator.process([10.0, 19.0, 31.0])).to eq 20.0 }
  end
end

##
# Now, each aspect of the calculator is independently tested, and a test failure will
# allow to target instantly the faulty class.
#
# We took each component described in the section "[Design code to be testable](#design-code-to-be-testable)",
# and implemented them into its own class. There is two interesting side effects to that:
# 1. It's pretty simple to test a component meant to calculate an average or convert a price
# 2. The three created components exists without coupling, which make it easy to reuse them
#
# Some may object that the resulting code is more verbose than the prototype's implementation.
# Personally, I'm always happy to exchange some time today against more clarity, more tests
# and less time to maintain that logic in six months.

