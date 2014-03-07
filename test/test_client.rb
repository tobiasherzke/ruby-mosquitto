# encoding: utf-8

require File.join(File.dirname(__FILE__), 'helper')

class TestClient < MosquittoTestCase
  def test_init
    client = Mosquitto::Client.new
    assert_instance_of Mosquitto::Client, client
    client = Mosquitto::Client.new("test")
    assert_raises TypeError do
      Mosquitto::Client.new(:invalid)
    end
  end

  def test_reinitialize
    client = Mosquitto::Client.new
    assert client.reinitialise("test")
    assert_raises TypeError do
      client.reinitialise(:invalid)
    end
  end

  def test_will_set
    client = Mosquitto::Client.new
    assert client.will_set("topic", "test", Mosquitto::AT_MOST_ONCE, true)
    assert_raises TypeError do
      client.will_set("topic", :invalid, Mosquitto::AT_MOST_ONCE, true)
    end
    assert_raises Mosquitto::Error do
      client.will_set("topic", ('a' * 268435456), Mosquitto::AT_MOST_ONCE, true)
    end
  end

  def test_will_clear
    client = Mosquitto::Client.new
    assert client.will_set("topic", "test", Mosquitto::AT_MOST_ONCE, true)
    assert client.will_clear
  end

  def test_auth
    client = Mosquitto::Client.new
    assert client.auth("username", "password")
    assert client.auth("username", nil)
    assert_raises TypeError do
      client.auth(:invalid, "password")
    end
  end

  def test_connect
    client = Mosquitto::Client.new
    assert client.loop_start
    assert_raises TypeError do
      client.connect(:invalid, 1883, 10)
    end
    assert client.connect("localhost", 1883, 10)
  end

  def test_connect_async
    client = Mosquitto::Client.new
    assert client.loop_start
    assert_raises TypeError do
      client.connect_async(:invalid, 1883, 10)
    end
    assert client.connect_async("localhost", 1883, 10)
    sleep 1
    assert client.socket != -1
  end

  def test_disconnect
    client = Mosquitto::Client.new
    assert client.loop_start
    assert_raises Mosquitto::Error do
      client.disconnect
    end
    assert client.connect("localhost", 1883, 10)
    assert client.disconnect
  end

  def test_reconnect
    client = Mosquitto::Client.new
    assert_raises Mosquitto::Error do
      client.reconnect
    end
    assert client.connect("localhost", 1883, 10)
    assert client.reconnect
  end

  def test_publish
    client = Mosquitto::Client.new
    assert_raises Mosquitto::Error do
      client.publish(nil, "topic", "test", Mosquitto::AT_MOST_ONCE, true)
    end
    assert client.connect("localhost", 1883, 10)
    assert_raises TypeError do
      client.publish(nil, :invalid, "test", Mosquitto::AT_MOST_ONCE, true)
    end
    assert client.publish(nil, "topic", "test", Mosquitto::AT_MOST_ONCE, true)
  end

  def test_subscribe
    client = Mosquitto::Client.new
    assert_raises Mosquitto::Error do
      client.subscribe(nil, "topic", Mosquitto::AT_MOST_ONCE)
    end
    assert client.connect("localhost", 1883, 10)
    assert_raises TypeError do
      client.subscribe(nil, :topic, Mosquitto::AT_MOST_ONCE)
    end
    assert client.subscribe(nil, "topic", Mosquitto::AT_MOST_ONCE)
  end

  def test_unsubscribe
    client = Mosquitto::Client.new
    assert_raises Mosquitto::Error do
      client.unsubscribe(nil, "topic")
    end
    assert client.connect("localhost", 1883, 10)
    assert_raises TypeError do
      client.unsubscribe(nil, :topic)
    end
    assert client.unsubscribe(nil, "topic")
  end

  def test_subscribe_unsubscribe
    client = Mosquitto::Client.new
    assert client.connect("localhost", 1883, 10)
    assert client.subscribe(nil, "topic", Mosquitto::AT_MOST_ONCE)
    assert client.unsubscribe(nil, "topic")
  end

  def test_socket
    client = Mosquitto::Client.new
    assert_equal(-1, client.socket)
    assert client.socket == -1
    assert client.connect("localhost", 1883, 10)
    assert_instance_of Fixnum, client.socket
    sleep 1
    assert client.socket != -1
  end

  def test_loop
    client = Mosquitto::Client.new
    assert_raises Mosquitto::Error do
      client.loop(10,10)
    end
    assert client.connect("localhost", 1883, 10)
    assert client.publish(nil, "topic", "test", Mosquitto::AT_MOST_ONCE, true)
    assert client.loop(10,10)
  end
=begin
  def test_loop_forever
    connected = false
    Thread.new do
      client = Mosquitto::Client.new
      client.on_connect do |rc|
        connected = true
        Thread.current.kill
      end
      assert_raises TypeError do
        client.loop_forever(:invalid,1)
      end
      assert_raises Mosquitto::Error do
        client.loop_forever(10,10)
      end
      assert client.connect("localhost", 1883, 10)
      assert client.loop_forever(-1,1)
    end.join(1)
    sleep 1
    assert connected
  end
=end
  def test_loop_stop_start
    client = Mosquitto::Client.new
    assert client.connect("localhost", 1883, 10)
    assert client.publish(nil, "topic", "test", Mosquitto::AT_MOST_ONCE, true)
    assert client.loop_start
    assert client.loop_stop(true)
  end

  def test_connect_disconnect_callback
    connected, disconnected = false
    client = Mosquitto::Client.new
    assert client.loop_start
    client.on_connect do |rc|
      connected = true
    end
    client.on_disconnect do |rc|
      disconnected = true
    end
    client.on_log do |level, msg|
      p "log [#{level}]: #{msg}"
    end
    assert client.connect("localhost", 1883, 10)
    sleep 1.5
    assert client.disconnect
    sleep 1.5
    assert connected
    assert disconnected
  ensure
    client.loop_stop(true)
  end

  def test_log_callback
    logs = []
    client = Mosquitto::Client.new
    client.on_log do |level, msg|
      logs << msg
    end
    assert client.connect("localhost", 1883, 10)
    assert client.disconnect
    assert_equal 2, logs.size
    assert_match(/CONNECT/, logs[0])
    assert_match(/DISCONNECT/, logs[1])
  end

  def test_subscribe_unsubscribe_callback
    msg_id = 0
    subscribed = false
    unsubscribed = false
    client = Mosquitto::Client.new
    assert client.loop_start
    client.on_subscribe do |mid,qos_count,granted_qos|
      subscribed = true
      msg_id = mid
    end
    client.on_unsubscribe do |mid|
      unsubscribed = true
    end
    client.on_log do |level, msg|
      p "log [#{level}]: #{msg}"
    end
    assert client.connect("localhost", 1883, 10)
    sleep 1.5
    assert client.subscribe(nil, "topic", Mosquitto::AT_MOST_ONCE)
    assert client.unsubscribe(nil, "topic")
    sleep 1.5
    assert subscribed
    assert unsubscribed
    assert client.disconnect
    assert msg_id != 0
  ensure
    client.loop_stop(true)
  end

  def test_message_callback
    message = nil
    publisher = Mosquitto::Client.new
    publisher.loop_start
    publisher.on_connect do |rc|
      publisher.publish(nil, "topic", "test", Mosquitto::AT_MOST_ONCE, true)
    end
    publisher.connect("localhost", 1883, 10)

    subscriber = Mosquitto::Client.new
    subscriber.loop_start
    subscriber.on_connect do |rc|
      subscriber.subscribe(nil, "topic", Mosquitto::AT_MOST_ONCE)
    end
    subscriber.connect("localhost", 1883, 10)
    subscriber.on_message do |msg|
      message = msg
    end
    sleep 1.5
    assert_equal "test", message.to_s
  end
end