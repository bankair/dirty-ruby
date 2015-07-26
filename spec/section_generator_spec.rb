require 'section_generator'
describe SectionGenerator do
  it 'parse markdown in comments preceded from ##' do
    buffer=<<-RUBY

##
# some md

puts 'ruby'

class FooBar
  ##
  # Some more md:
  # 1. item 1
  # 2. item 2
 
  # Genuine comment
  def some_method
    42
  end
end
    RUBY
    expected_result=<<-MD
# title
some md

```ruby
puts 'ruby'

class FooBar
```

Some more md:
1. item 1
2. item 2

```ruby
  # Genuine comment
  def some_method
    42
  end
end
```
    MD
    buffer = buffer.split("\n")
    generator = SectionGenerator.new('title', buffer)
    expect(generator.dump).to eq expected_result
  end
end
