# encoding: utf-8

$:.unshift(File.dirname(__FILE__) << '/../lib')

require 'chapter_generator'

PATH = 'src'
TITLE = 'Dirty ruby'

generator = ChapterGenerator.new(PATH, title: TITLE)

puts generator.dump
