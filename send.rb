#!/usr/bin/env ruby -wW1
require "amqp"

EventMachine.run do
  connection = AMQP.connect(:host => '127.0.0.1')
  puts "Connected to AMQP broker. Running #{AMQP::VERSION} version of the gem..."

  channel  = AMQP::Channel.new(connection)
  queue    = channel.queue("amqpgem.examples.helloworld", :auto_delete => true)
  exchange = channel.direct("")

  queue.subscribe do |headers, payload|
    puts "Received a message"
    puts " headers: #{headers.attributes}"
    puts " payload: #{payload}"
    connection.close { EventMachine.stop }
  end

  exchange.publish "Hello, world!", :routing_key => queue.name
end
