# encoding: utf-8

require 'parser'
require 'generator'

class SectionGenerator < Generator
  extend Forwardable
  protected
  attr_writer :buffer

  def parse!(fd)
    parser = Parser.new self
    fd.each do |line|
      self.buffer << parser.parse_line(line.chomp)
    end
    self.buffer << parser.close
  end

  public
  attr_reader :buffer

  def_delegators :@buffer, :empty?

  def initialize(title, fd)
    self.title = title
    self.buffer = ''
    parse!(fd)
  end

  def dump(depth: 1, toc: false)
    result = make_title(depth)
    result << buffer
    result
  end

  def self.parse(path)
    title = title_from path
    io = File.new(path)
    new(title, io)
  ensure
    io.close
  end
end
