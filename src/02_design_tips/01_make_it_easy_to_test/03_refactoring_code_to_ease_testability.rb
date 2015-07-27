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

class BigShinyCarDB
  Car = Struct.new(:brand, :model, :color, :local_price)
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

puts BigShinyCarDB.where { |car| car.color == 'red'}.map(&:local_price).inspect
# Print '["$15000", "€9999.99"]'

##
# Unfortunately, the developer in charge of the implementation of the software
# component did not read our design recommendation in the previous section,
# and came up with the following implementation:

class PrototypeCalculator
  EURO_CONV = 1.109
  def calculate
    cars = BigShinyCarDB.where { |car| car.color != 'green' }
    prices = cars.map(&:local_price).map do |price|
      result = price[1..-1].to_f
      result = result * EURO_CONV if price[0] == '€'
      result
    end
    prices.reduce(&:+) / prices.size
  end
end

puts PrototypeCalculator.new.calculate
# Print '10696.9699775'

##
# The result given by that code is correct, but it's pretty hard to test
# its edge cases accurately.
# Further more, in case of failure, the test report won't allow to reckon
# which part of the process (filtering, conversion or calculation) did fail.
#
# To be continued
