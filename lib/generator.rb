class Generator
  protected
  attr_writer :title
  public
  attr_reader :title
  def end_of_line
    '' + $/
  end
  def make_title(depth)
    raise 'Invalid depth' if depth < 1
    '#' * depth << ' ' << title << end_of_line
  end

  def anchor
    title.tr(' ', '_').downcase
  end

  def table_of_content_elements(depth)
    ''
  end

  def self.title_from(path)
    basename(path).tr('_', ' ').sub(/^[0-9]* */, '').capitalize
  end

  def self.basename(path)
    File.basename(path, '.rb')
  end

end
