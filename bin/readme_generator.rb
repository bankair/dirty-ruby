# encoding: utf-8

$:.unshift(File.dirname(__FILE__) << '/../lib')

require 'chapter_generator'

PATH = 'src'
TITLE = 'Ruby patterns and tips collection'

generator = ChapterGenerator.new(PATH, title: TITLE)

puts generator.dump
