#rabbitmq-events

rabbitmq-events exposes the internal RabbitMQ event stream as JSON
messages published on the ``rabbitevents`` fanout exchange.

# Configuration

By default the event stream will be published on the ``rabbitevents``
fanout exchange under the ``/`` vhost by via the ``guest`` account.

To change the exchange, user, password, or vhost just set the relevant
variable in the rabbitmq.config, which is usually in ``/etc/rabbitmq/``.

## Example

  [{rabbitmq_events, [ 
           {host         , "localhost"}
         , {username     , <<"guest">>}
         , {password     , <<"guest">>}
         , {virtual_host , <<"/">>}
         , {exchange     , <<"rabbitevents">>}
         , {debug        , false}
    ]}
  ].


# Events Exposed

## connection_created

    {
      "event": "connection_created",
      "type": "network",
      "pid": "<0.303.0>",
      "name": "127.0.0.1:59375 -> 127.0.0.1:5672",
      "address": [
        127,
        0,
        0,
        1
      ],
      "port": 5672,
      "peer_address": [
        127,
        0,
        0,
        1
      ],
      "peer_port": 59375,
      "ssl": false,
      "peer_cert_subject": "",
      "peer_cert_issuer": "",
      "peer_cert_validity": "",
      "auth_mechanism": "PLAIN",
      "ssl_protocol": "",
      "ssl_key_exchange": "",
      "ssl_cipher": "",
      "ssl_hash": "",
      "protocol": [
        0,
        9,
        1
      ],
      "user": "guest",
      "vhost": "/",
      "timeout": 0,
      "frame_max": 131072,
      "client_properties": {
        "product": "RabbitMQ",
        "version": "2.7.0",
        "platform": "Erlang",
        "copyright": "Copyright (c) 2007-2011 VMware, Inc.",
        "information": "Licensed under the MPL.  See http://www.rabbitmq.com/",
        "capabilities": {
          "publisher_confirms": true,
          "exchange_exchange_bindings": true,
          "basic.nack": true,
          "consumer_cancel_notify": true
        }
      }
    }

## channel_created

    {
      "event": "channel_created",
      "pid": "<0.307.0>",
      "name": "127.0.0.1:59375 -> 127.0.0.1:5672 (1)",
      "number": 1,
      "user": "guest",
      "vhost": "/"
    }

## binding_created

    {
      "event": "binding_created",
      "source_name": "",
      "source_kind": "exchange",
      "destination_name": "amq.gen-AFytz3Fag4zs7k6Yp-KdOq",
      "destination_kind": "queue",
      "routing_key": "amq.gen-AFytz3Fag4zs7k6Yp-KdOq",
      "arguments": [

      ]
    }

## queue_created

    {
      "event": "queue_created",
      "slave_pids": "",
      "synchronised_slave_pids": "",
      "pid": "<0.308.0>",
      "name": {
        "resource": "/",
        "queue": "amq.gen-AFytz3Fag4zs7k6Yp-KdOq"
      },
      "durable": false,
      "auto_delete": false,
      "arguments": [

      ],
      "owner_pid": "<0.303.0>"
    }

## consumer_created

    {
      "event": "consumer_created",
      "consumer_tag": "amq.ctag-AsyjDeJsmx6wWEELZjDyv2",
      "exclusive": false,
      "ack_required": false,
      "channel": "<0.307.0>",
      "queue": "<0.308.0>"
    }

## consumer_deleted

    {
      "event": "consumer_deleted",
      "consumer_tag": "amqpgem.examples.helloworld-1330780405000-410602107340",
      "channel": "<0.325.0>",
      "queue": "<0.326.0>"
    }

## queue_deleted

    {
      "event": "queue_deleted",
      "pid": "<0.326.0>",
      "name": {
        "resource": "/",
        "queue": "amqpgem.examples.helloworld"
      }
    }

## binding_deleted

    {
      "event": "binding_deleted",
      "source_name": "",
      "source_kind": "exchange",
      "destination_name": "amqpgem.examples.helloworld",
      "destination_kind": "queue",
      "routing_key": "amqpgem.examples.helloworld",
      "arguments": [

      ]
    }

## channel_closed

    {
      "event": "channel_closed",
      "pid": "<0.325.0>"
    }

## connection_closed

    {
      "event": "connection_closed",
      "pid": "<0.321.0>"
    }

