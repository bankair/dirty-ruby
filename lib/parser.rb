
class Block
  protected
  attr_accessor :formatter
  extend Forwardable
  def initialize(formatter)
    self.formatter = formatter
  end

  def_delegators :formatter, :end_of_line

  def convert(_line)
    raise 'Implementation missing'
  end
  def close
    ''
  end
end

class CodeBlock < Block
  attr_accessor :open
  def initialize(formatter)
    self.open = false
    super
  end

  def close(double_terminal = false)
    if open
      self.open = false
      terminal = end_of_line
      terminal << end_of_line if double_terminal
      return "```#{terminal}"
    end
    super()
  end

  def convert(line)
    return '' if !open && line.empty?
    if line =~ /^ *[#]{2}$/
      yield VerbatimBlock.new formatter
      return close(true)
    else
      result = ''
      unless open
        result << '```ruby' << end_of_line
        self.open = true
      end
      result << line << end_of_line
    end
  end
end

class VerbatimBlock < Block
  def convert(line)
    if line =~ /^ *$/
      yield CodeBlock.new formatter
      "\n"
    else
      line.sub(/^ *# */, '') << end_of_line
    end
  end
end

class Parser
  extend Forwardable

  def_delegators :@block, :close

  def initialize(formatter)
    self.block = CodeBlock.new formatter
  end

  def parse_line(line)
    block.convert(line) { |next_block| self.block = next_block }
  end

  protected

  attr_accessor :block, :formatter
end
