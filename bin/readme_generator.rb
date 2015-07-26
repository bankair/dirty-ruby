# encoding: utf-8

$:.unshift(File.dirname(__FILE__) << '/../lib')

require 'chapter_generator'

generator = ChapterGenerator.new('src', title: 'Ruby patterns collection')

puts generator.dump
