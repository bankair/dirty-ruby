# encoding: utf-8
require 'generator'
require 'section_generator'
class ChapterGenerator < Generator
  attr_accessor :sections, :intro_path

  def self.basename(path)
    File.basename(path)
  end

  NO_INTRO = :no_intro

  def initialize(path, title: ChapterGenerator.title_from(path))
    fail 'path must be a directory' unless File.directory? path
    self.sections = []
    self.title = title
    self.intro_path = NO_INTRO
    Dir[path + '/*'].each do |subpath|
      if File.directory? subpath
        sub_chapter = ChapterGenerator.new(subpath)
        sections << sub_chapter unless sub_chapter.empty?
      elsif subpath =~ /\.rb$/
        section =  SectionGenerator.parse(subpath)
        sections << section unless section.empty?
      elsif File.basename(subpath) == 'intro.md'
        self.intro_path = subpath
      else
        warn "Ignoring file #{subpath}"
      end
    end
  end

  def empty?
    sections.all?(&:empty?)
  end

  def table_of_content(depth)
    result = ('#' * depth) << ' Table of content' << end_of_line
    result << end_of_line
    result << table_of_content_elements(depth)
    result << end_of_line
    result
  end

  def table_of_content_elements(depth)
    result = ''
    prefix = '  ' * (depth - 1)
    sections.each do |section|
      result << prefix
      result << "1. [#{section.title}](##{section.anchor})"
      result << end_of_line
      result << section.table_of_content_elements(depth + 1)
    end
    result
  end

  def dump(depth: 1, toc: true)
    result = make_title(depth)
    result << end_of_line
    result << File.read(intro_path) unless intro_path == NO_INTRO
    result << table_of_content(depth) if toc
    sections.each do |section|
      result << section.dump(depth: depth + 1, toc: false)
      result << end_of_line
    end
    result
  end

end
