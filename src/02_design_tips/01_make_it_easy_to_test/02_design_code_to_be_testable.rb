##
# In the previous section, we showed what is a responsibility.
#
# Respecting the single responsibility principle allow to have only simple
# software components, that achieve a single part of the whole software
# goal.
#
# Such components are fairly easy to test, as there is a single feature
# to check.
#
# In the following example, we'll be designing the tool used by the CEO of
# BigShinyCar Incorporated to make market analysis.
#
# The CEO of BigShinyCar wants a software to calculate the average price, in $,
# of all non green cars.
#
# We can deduce the following requirements (responsibilities):
#
# 1. Ability to fetch all non green car prices
# 1. Ability to convert a car to a price in $
# 1. Ability to calculate an average
#
# Here, we would design three modular software components:
#
# 1. A component A that select all non green cars
# 1. A component B that convert a car into a float value being the same price
# in $.
# 1. A component C that calculate an average from several float values.
#
# And the course of actions would look like follow:
#
# ```
# - car 1  ->┌───────────┐          ┌───────────┐            ┌───────────┐
# - car 2  ->│Component A│- car 1 ->│Component B│- price 1 ->│Component C│
# - car 3  ->├───────────┤- car 2 ->├───────────┤- price 2 ->├───────────┤   Average
#   . . .    │ Filter    │  . . .   │ Convert to│  . . .     │ Calculate │-> price of non
# - car n-1->│ cars      │- car m ->│ $ prices  │- price m ->│ average   │   green cars
# - car n  ->└───────────┘          └───────────┘            └───────────┘
# ```
#
# Those components would be named:
#
# * Component A: CarPresenter
# * Component B: PriceParser
# * Component C: AverageCalculator
