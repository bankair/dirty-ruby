##
# As stated by Robert C. Martin:
#
# > a class should have only a single responsibility.
#
# Martin describe a responsibility as a reason to change (when the specifications are updated).
#
# In the case of a function that can open a file and return the first character
# of every line of that file, for example, we identify the following
# requirements:
#
# 1. The function can open and read a file
# 2. The function can extract the first character of every line
#
# There is two responsibilities, here. The only things we can imagine to change
# are:
#
# 1. Reading from something else than a file
# 2. Returning something else than the first line of every line
#
# Thanks to ruby's API, we can tinker a quick implementation of the given
# requirements:

def first_chars_of(path)
  File.readlines(path).map{ |line| line[0] }
end

##
# But, if we want to be a bit more close to the single responsibility
# principle, we'd rather use two structures:
#
# 1. A content adapter (roughly a File.readlines call for the moment)
# 2. A content processor (that extract the first char of every line)

class ContentProcessor
  def self.process(content)
    content.map { |line| line[0] }
  end
end

def first_chars_of_file(path)
  ContentProcessor.process(File.readlines(path))
end

##
# Now that the file opening part was fully extracted from the processing
# logic, changing the content adapter logic or the content processing logic
# is really easy.
#
# For example, here is an implementation for extracting all first characters
# of an array:

def first_chars_of_array(array)
  ContentProcessor.process array
end

##
# Or if you want to take the last character only, just change your
# ContentProcessor implementation to:

class ContentProcessor
  def self.process(content)
    content.map { |line| line[-1] }
  end
end

##
# The point here is that splitting software components per responsibility
# allow a greater modularity, and ease the software maintainability.

