# Shellex [![Build Status](https://secure.travis-ci.org/dsabanin/shellex.png)](http://travis-ci.org/dsabanin/shellex)

Shellex allows you to run shell commands from your ruby scripts in a more robust and secure way than the built-in options.
We're using this code in <a href="http://beanstalkapp.com">Beanstalk</a> to keep the shell commands we execute secure against shell injection and keep every executed command under a tight timeout.
This code also helps us construct complex shell commands easily thanks to the interpolation strategies listed below.

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

Providing STDIN input:

```ruby
shellex("cat -", :input => "hello").stdout # => "hello"
```

By default if you don't provide input we close the STDIN stream, but if you want you can leave it open:

```ruby
shellex("cat /dev/stdin", :close_stdin => false)
```

Timeouts (default timeout is set to 5 minutes):

```ruby
shellex("sleep 10", :timeout => 1) # raises ShellExecutionTimeout exception
```

Interpolation of arguments:

```ruby
# to_s gets called on all arguments
shellex("echo ? ? ?", 1, "blah", :symbol)
# executes: echo '1' 'blah' 'symbol'

# ?& interpolates each array element separately
shellex("? ?& ?", "echo", [1,2,3,4], "abc")
# executes: 'echo' '1' '2' '3' '4' 'abc'

# ?& requires array to be present in the respective position
shellex("? ?& ?", "echo", 1) # raises ShellArgumentMissing

# ?~ escapes question mark
shellex("? ?~", "echo", "ello")
# executes: 'echo' ?

# ? by default will turn nil into empty string
shellex("echo ?", nil)
# executes: echo ''

# ?? will skip the argument if it's nil
shellex("echo ??", nil)
# executes: echo

# Shell injection protection
shellex("echo ?", "'; rm -Rf /; '")
# executes harmless: echo ''\''; rm -Rf /; '\'''
```

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
