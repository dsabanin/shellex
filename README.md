# Shellex

Shellex allows you to run shell commands from your ruby scripts in a more robust and secure way than the built-in options.
We had a security audit in http://beanstalkapp.com recently which showed many problems caused by shell injections. This code
 is the result of our attempt to fix these issues once and for all.

## Installation

Add this line to your application's Gemfile:

    gem 'shellex'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install shellex

## Usage

Grabbing STDOUT output:

```ruby
stdout, stderr = shellex("echo hello, world!")
# stdout => "hello, world!\n"
# stderr => ""
```

Grabbing STDERR output:

```ruby
stdout, stderr = shellex("echo error here 1>&2")
# stdout => ""
# stderr => "error here\n"
```

Convenience methods:

```ruby
shellex("echo hello, world").to_s # => "hello, world\n"
shellex("echo hello, world").stdout # => "hello, world\n"
shellex("echo error here 1>&2").stderr # => "error here\n"
```

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
