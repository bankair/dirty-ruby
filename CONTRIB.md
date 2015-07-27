# Creating a new section

1. Create a directory with a meaning full name (underscores are
replaced by spaces, and numeric prefix are stripped).
2. Add an 'intro.md' file in the directory giving some insights on the
content of the directory.

# Adding a new pattern to an existing section

Write a example of the pattern in a ruby file, which will be added to the
table of content and in the appropriate section after a run of the readme
generator script.

By default, all text of the .rb file will be considered as code block.
All verbatim markdown section must be contained in a comment block,
leaded by a double #.
For example, the following ruby code:
```ruby
##
# That is a *block* of markdown:
#
# 1. item 1
# 2. item 2

# Genuine comment
puts 'Ruby !'
```

Will result in the following formatted text:

That is a *block* of markdown:

1. item 1
2. item 2

```ruby
# Genuine comment
puts 'Ruby !'
```

# Updating the README.md file

Just run:

```
bundle exec ruby bin/readme_generator.rb > README.md
```

