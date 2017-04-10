# DagLinkCalculator

For a DAG (Direct Acyclic Graph, like the one used with [acts-as-dag](https://github.com/resgraph/acts-as-dag)), it calculates the list of all links (direct and indirect) based on the list of direct links (parent-child).  

Example:

We have a DAG like this:

```
  A --- B --- C --- D --- H
     |           |
     -- F --- E --
 ```

we receive the direct links info that describe that DAG like this:

```ruby
[
   { ancestor_id: 'A', descendant_id: 'B' },
   { ancestor_id: 'A', descendant_id: 'F' },
   { ancestor_id: 'B', descendant_id: 'C' },
   { ancestor_id: 'C', descendant_id: 'D' },
   { ancestor_id: 'F', descendant_id: 'E' },
   { ancestor_id: 'E', descendant_id: 'D' },
   { ancestor_id: 'D', descendant_id: 'H' },
]
```

we'll produce an intermediate structures (routes) like this:

```
[
   <struct DagLinkCalculator::NodeRoute nodes=['H', 'D']>
   <struct DagLinkCalculator::NodeRoute nodes=['H', 'D', 'C']>
   <struct DagLinkCalculator::NodeRoute nodes=['H', 'D', 'C', 'B']>
   <struct DagLinkCalculator::NodeRoute nodes=['H', 'D', 'C', 'B', 'A']>
   <struct DagLinkCalculator::NodeRoute nodes=['H', 'D', 'E']>
   <struct DagLinkCalculator::NodeRoute nodes=['H', 'D', 'E', 'F']>
   <struct DagLinkCalculator::NodeRoute nodes=['H', 'D', 'E', 'F', 'A']>
   <struct DagLinkCalculator::NodeRoute nodes=['D', 'C']>
   <struct DagLinkCalculator::NodeRoute nodes=['D', 'C', 'B']>
   <struct DagLinkCalculator::NodeRoute nodes=['D', 'C', 'B', 'A']>
   <struct DagLinkCalculator::NodeRoute nodes=['D', 'E']>
   <struct DagLinkCalculator::NodeRoute nodes=['D', 'E', 'F']>
   <struct DagLinkCalculator::NodeRoute nodes=['D', 'E', 'F', 'A']>
   <struct DagLinkCalculator::NodeRoute nodes=['C', 'B']>
   <struct DagLinkCalculator::NodeRoute nodes=['C', 'B', 'A']>
   <struct DagLinkCalculator::NodeRoute nodes=['B', 'A']>
   <struct DagLinkCalculator::NodeRoute nodes=['E', 'F']>
   <struct DagLinkCalculator::NodeRoute nodes=['E', 'F', 'A']>
   <struct DagLinkCalculator::NodeRoute nodes=['F', 'A']>
]
```

and then return a list of links like this:
 ```ruby

 [
  { ancestor_id: 'A', descendant_id: 'B', direct: true, count: 1 },
  { ancestor_id: 'A', descendant_id: 'C', direct: false, count: 1 },
  { ancestor_id: 'A', descendant_id: 'D', direct: false, count: 2 },
  { ancestor_id: 'A', descendant_id: 'E', direct: false, count: 1 },
  { ancestor_id: 'A', descendant_id: 'F', direct: true, count: 1 },
  { ancestor_id: 'A', descendant_id: 'H', direct: false, count: 2 },
  { ancestor_id: 'B', descendant_id: 'C', direct: true, count: 1 },
  { ancestor_id: 'B', descendant_id: 'D', direct: false, count: 1 },
  { ancestor_id: 'B', descendant_id: 'H', direct: false, count: 1 },
  { ancestor_id: 'C', descendant_id: 'D', direct: true, count: 1 },
  { ancestor_id: 'C', descendant_id: 'H', direct: false, count: 1 },
  { ancestor_id: 'D', descendant_id: 'H', direct: true, count: 1 },
  { ancestor_id: 'E', descendant_id: 'D', direct: true, count: 1 },
  { ancestor_id: 'E', descendant_id: 'H', direct: false, count: 1 },
  { ancestor_id: 'F', descendant_id: 'D', direct: false, count: 1 },
  { ancestor_id: 'F', descendant_id: 'E', direct: true, count: 1 },
  { ancestor_id: 'F', descendant_id: 'H', direct: false, count: 1 },
]
```

## Usage

Given a list of objects defining the direct links:
```ruby
# it will recognise keys:
# - for the ancestor => `ancestor`, `ancestor_id`, `parent` and `parent_id`
# - for the descendant => `descendant`, `descendant_id`, `child` and `child_id`

direct_link_hashes = [
  { ancestor_id: 'A', descendant_id: 'B' },
  { ancestor: 'A', descendant_id: 'F' },
  { ancestor_id: 'B', descendant: 'C' },
  { parent_id: 'C', descendant_id: 'D' },
  { ancestor_id: 'F', child_id: 'E' },
  { parent_id: 'E', child_id: 'D' },
  { parent: 'D', child: 'H' },
]

calculator = DagLinkCalculator.from_direct_links_hashes(direct_link_hashes)

calculator.all_links_hashes
#=>
# [
#   { ancestor_id: 'A', descendant_id: 'B', direct: true, count: 1 },
#   { ancestor_id: 'A', descendant_id: 'C', direct: false, count: 1 },
#   { ancestor_id: 'A', descendant_id: 'D', direct: false, count: 2 },
#   { ancestor_id: 'A', descendant_id: 'E', direct: false, count: 1 },
#   { ancestor_id: 'A', descendant_id: 'F', direct: true, count: 1 },
#   { ancestor_id: 'A', descendant_id: 'H', direct: false, count: 2 },
#   { ancestor_id: 'B', descendant_id: 'C', direct: true, count: 1 },
#   { ancestor_id: 'B', descendant_id: 'D', direct: false, count: 1 },
#   { ancestor_id: 'B', descendant_id: 'H', direct: false, count: 1 },
#   { ancestor_id: 'C', descendant_id: 'D', direct: true, count: 1 },
#   { ancestor_id: 'C', descendant_id: 'H', direct: false, count: 1 },
#   { ancestor_id: 'D', descendant_id: 'H', direct: true, count: 1 },
#   { ancestor_id: 'E', descendant_id: 'D', direct: true, count: 1 },
#   { ancestor_id: 'E', descendant_id: 'H', direct: false, count: 1 },
#   { ancestor_id: 'F', descendant_id: 'D', direct: false, count: 1 },
#   { ancestor_id: 'F', descendant_id: 'E', direct: true, count: 1 },
#   { ancestor_id: 'F', descendant_id: 'H', direct: false, count: 1 },
# ]

calculator.all_links_structs
#=>
# [
#   DagLinkCalculator::NodeLink.new('A', 'B', true, 1),
#   DagLinkCalculator::NodeLink.new('A', 'C', false, 1),
#   DagLinkCalculator::NodeLink.new('A', 'D', false, 2),
#   DagLinkCalculator::NodeLink.new('A', 'E', false, 1),
#   DagLinkCalculator::NodeLink.new('A', 'F', true, 1),
#   DagLinkCalculator::NodeLink.new('A', 'H', false, 2),
#   DagLinkCalculator::NodeLink.new('B', 'C', true, 1),
#   DagLinkCalculator::NodeLink.new('B', 'D', false, 1),
#   DagLinkCalculator::NodeLink.new('B', 'H', false, 1),
#   DagLinkCalculator::NodeLink.new('C', 'D', true, 1),
#   DagLinkCalculator::NodeLink.new('C', 'H', false, 1),
#   DagLinkCalculator::NodeLink.new('D', 'H', true, 1),
#   DagLinkCalculator::NodeLink.new('E', 'D', true, 1),
#   DagLinkCalculator::NodeLink.new('E', 'H', false, 1),
#   DagLinkCalculator::NodeLink.new('F', 'D', false, 1),
#   DagLinkCalculator::NodeLink.new('F', 'E', true, 1),
#   DagLinkCalculator::NodeLink.new('F', 'H', false, 1),
# ]

calculator.all_links_structs
#=>
# [
#   DagLinkCalculator::NodeLink.new('A', 'B', true, 1),
#   DagLinkCalculator::NodeLink.new('A', 'C', false, 1),
#   DagLinkCalculator::NodeLink.new('A', 'D', false, 2),
#   DagLinkCalculator::NodeLink.new('A', 'E', false, 1),
#   DagLinkCalculator::NodeLink.new('A', 'F', true, 1),
#   DagLinkCalculator::NodeLink.new('A', 'H', false, 2),
#   DagLinkCalculator::NodeLink.new('B', 'C', true, 1),
#   DagLinkCalculator::NodeLink.new('B', 'D', false, 1),
#   DagLinkCalculator::NodeLink.new('B', 'H', false, 1),
#   DagLinkCalculator::NodeLink.new('C', 'D', true, 1),
#   DagLinkCalculator::NodeLink.new('C', 'H', false, 1),
#   DagLinkCalculator::NodeLink.new('D', 'H', true, 1),
#   DagLinkCalculator::NodeLink.new('E', 'D', true, 1),
#   DagLinkCalculator::NodeLink.new('E', 'H', false, 1),
#   DagLinkCalculator::NodeLink.new('F', 'D', false, 1),
#   DagLinkCalculator::NodeLink.new('F', 'E', true, 1),
#   DagLinkCalculator::NodeLink.new('F', 'H', false, 1),
# ]
```

## TODO:

- for now it assumes that the direct links are ok. It should raise an exception if it detects a cycle. 

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'dag_link_calculator'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install dag_link_calculator


## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/artirix/dag_link_calculator. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.


## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).

