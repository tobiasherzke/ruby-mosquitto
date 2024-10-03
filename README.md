# mosquitto - a high perf MQTT 3.1 client

The mosquitto gem is meant to serve as an easy, performant and standards compliant client for interacting with MQTT brokers.

The API consists of two classes:

[Mosquitto::Client](http://rubydoc.info/github/xively/mosquitto/master/Mosquitto/Client) - the client

[Mosquitto::Message](http://rubydoc.info/github/xively/mosquitto/master/Mosquitto/Message) - returned from the client

## About MQTT and libmosquitto

[MQ Telemetry Transport](https://mqtt.org/) is :

```
MQTT stands for MQ Telemetry Transport. It is a publish/subscribe, extremely simple and lightweight messaging
protocol, designed for constrained devices and low-bandwidth, high-latency or unreliable networks. The design
principles are to minimise network bandwidth and device resource requirements whilst also attempting to ensure
reliability and some degree of assurance of delivery. These principles also turn out to make the protocol ideal of
the emerging “machine-to-machine” (M2M) or “Internet of Things” world of connected devices, and for mobile
applications where bandwidth and battery power are at a premium.
```
Please see the [FAQ](https://mqtt.org/faq).

### libmosquitto

```
Mosquitto is an open source (BSD licensed) message broker that implements the MQ Telemetry Transport protocol
version 3.1. MQTT provides a lightweight method of carrying out messaging using a publish/subscribe model. This
makes it suitable for "machine to machine" messaging such as with low power sensors or mobile devices such as
phones, embedded computers or microcontrollers like the Arduino. 
```

See the [project website](https://mosquitto.org/) for more information.

## Requirements

This gem links against `libmosquitto` >= version 1.3.1. You will need to install additional packages for your system.

### OS X

The preferred installation method for libmosquitto on OS X is with the [Homebrew](https://github.com/Homebrew/homebrew) package manager :

``` sh
brew install mosquitto
```

### Linux Ubuntu

``` sh
sudo apt-get update
sudo apt-get install libmosquitto-dev
```

## Installing

### OSX / Linux

When libmosquitto-dev and ruby are installed and this ruby-mosquitto
git repository is cloned, the following should install 
this mosquitto binding:

``` sh
gem build mosquitto.gemspec
sudo gem install ./mosquitto-0.3.1.gem
```

The extension checks for libmosquitto presence.

## Usage

### Threaded loop

The simplest mode of operation - starts a new thread to process network traffic.

``` ruby
require 'mosquitto'

publisher = Mosquitto::Client.new("threaded")

# Spawn a network thread with a main loop
publisher.loop_start

# On publish callback
publisher.on_publish do |mid|
  p "Published #{mid}"
end

# On connect callback
publisher.on_connect do |rc|
  p "Connected with return code #{rc}"
  # publish a test message once connected
  publisher.publish(nil, "topic", "test message", Mosquitto::AT_MOST_ONCE, true)
end

# Connect to MQTT broker
publisher.connect("test.mosquitto.org", 1883, 10)

# Allow some time for processing
sleep 2

publisher.disconnect

# Optional, stop the threaded loop - the network thread would be reaped on Ruby exit as well
publisher.loop_stop(true)
```

### Blocking loop (simple clients)

The client supports a blocking main loop as well which is useful for building simple MQTT clients. Reconnects
etc. and other misc operations are handled for you.

``` ruby
require 'mosquitto'

publisher = Mosquitto::Client.new("blocking")

# On publish callback
publisher.on_publish do |mid|
  p "Published #{mid}"
end

# On connect callback
publisher.on_connect do |rc|
  p "Connected with return code #{rc}"
  # publish a test message once connected
  publisher.publish(nil, "topic", "test message", Mosquitto::AT_MOST_ONCE, true)
end

# Connect to MQTT broker
publisher.connect("test.mosquitto.org", 1883, 10)

# Blocking main loop
publisher.loop_forever
```

### Logging

The client supports any of the Ruby Logger libraries with the standard #add method interface

``` ruby
require 'mosquitto'

publisher = Mosquitto::Client.new("blocking")

# Sets a custom log callback for us that pipes to the given logger instance
publisher.logger = Logger.new(STDOUT)

# Connect to MQTT broker
publisher.connect("test.mosquitto.org", 1883, 10)
```

### Callbacks

The following callbacks are supported (please follow links for further documentation) :

* [connect](http://rubydoc.info/github/xively/mosquitto/master/Mosquitto/Client:on_connect) - called when the broker sends a CONNACK message in response to a connection.
* [disconnect](http://rubydoc.info/github/xively/mosquitto/master/Mosquitto/Client:on_disconnect) - called when the broker has received the DISCONNECT command and has disconnected the client.
* [log](http://rubydoc.info/github/xively/mosquitto/master/Mosquitto/Client:on_log) - should be used if you want event logging information from the client library.
* [subscribe](http://rubydoc.info/github/xively/mosquitto/master/Mosquitto/Client:on_subscribe) - called when the broker responds to a subscription request.
* [unsubscribe](http://rubydoc.info/github/xively/mosquitto/master/Mosquitto/Client:on_unsubscribe) - called when the broker responds to a unsubscription request.
* [publish](http://rubydoc.info/github/xively/mosquitto/master/Mosquitto/Client:on_publish) - called when a message initiated with Mosquitto::Client#publish has been sent to the broker successfully.
* [message](http://rubydoc.info/github/xively/mosquitto/master/Mosquitto/Client:on_message) - called when a message is received from the broker.

### TLS / SSL

libmosquitto builds with TLS support.

``` ruby
tls_client = Mosquitto::Client.new

tls_client.logger = Logger.new(STDOUT)

tls_client.loop_start

tls_client.on_connect do |rc|
  p :tls_connection
end
tls_client.tls_opts_set(Mosquitto::SSL_VERIFY_PEER, "tlsv1.2", nil)
tls_client.tls_set('/path/to/mosquitto.org.crt'), nil, nil, nil, nil)
tls_client.connect('test.mosquitto.org', 8883, 10)
```

See [documentation](http://rubydoc.info/github/xively/mosquitto) for the full API specification.

## Development

To run the tests, you can use RVM and Bundler to create a pristine environment for mosquitto development/hacking.
Use 'bundle install' to install the necessary development and testing gems:

``` sh
bundle install
bundle exec rake
```
Tests by default run against an MQTT server on localhost, which is expected to support TLS on port 8883 as well.

``` ruby
class MosquittoTestCase < Test::Unit::TestCase
  TEST_HOST = "localhost"
  TEST_PORT = 1883

  TLS_TEST_HOST = "localhost"
  TLS_TEST_PORT = 8883
```

## Resources

Documentation available at http://rubydoc.info/github/xively/mosquitto

## Special Thanks

* Roger Light - for libmosquitto
