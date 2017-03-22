# Vault::Transit

This gem wraps the endpoints for [HashiCorp's Vault Transit secret backend](https://www.vaultproject.io/docs/secrets/transit/). It is dependent upon the [vault gem](https://github.com/hashicorp/vault-ruby). This gem has patterns and code copied from HashiCorp's [vault-ruby gem](https://github.com/hashicorp/vault-rails). Use this gem when you simply want to use the Transit secret backend and you don't need the Rails integration.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'vault-transit'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install vault-transit

## Usage

TODO: Write usage instructions here

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/jgaxn/vault-transit.


## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).

