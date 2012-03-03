#!/usr/bin/env ruby -wW1

# listen.rb is a simple script that receives rabbit events as JSON
# blobs, decodes and pretty prints them on teh console.

require 'amqp'
require 'json'

EventMachine.run do
  connection = AMQP.connect(:host => '127.0.0.1')
  puts "Connected to AMQP broker. Running #{AMQP::VERSION} version of the gem..."

  channel  = AMQP::Channel.new(connection)
  exchange = channel.fanout("rabbitevents")
  channel.queue("rabbitevents-#{Process.pid}", :auto_delete => true).bind(exchange).subscribe do |headers, payload|
    puts "[event] Received a message"
    if headers.content_type && headers.content_type == 'application/json'
      puts JSON.pretty_generate(JSON.parse(payload))
    else
      puts "        headers: #{headers.attributes}"
      puts "        payload: #{payload.inspect}"
    end
  end

end
