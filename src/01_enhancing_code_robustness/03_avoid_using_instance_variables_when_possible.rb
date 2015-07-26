##
# Using references on instance variables directly can lead to errors in several
# ways, for example by bypassing any validation you would add prior to value
# assignment or updating accidentally a value meant to be immutable.
#
# For a start, let's imagine you create a car class that has a color variable
# that accept only 'red', 'green' and 'blue' as values:

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

##
# If someone introduce a method with a bad side effect to your perfect code:

class Car
  def unsafe_repaint(new_color)
    @color = new_color
    puts "car painted #{new_color}"
  end
end

##
# Your car can now take any colour:

car = Car.new 'red'
puts car.color
# Print 'red'
car.unsafe_repaint 'magenta'
# Print 'car painted magenta'
puts car.color
# Print 'magenta'

##
# A good solution to that kind of issue is to stop using references to the
# instance variable in the class. Actually, only a single reference to the
# instance variable should exists (in the setter), and you could even move
# it out of the way by externalizing that code in a module, included in your
# class.
#
# Now, only refer to the color attribute through its getter and setter.
#
# Example of a safe implementation of the car:

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

##
# Now, a car instance can be repainted, but only in the expected colours:

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
