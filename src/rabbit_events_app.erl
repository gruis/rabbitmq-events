-module(rabbit_events_app).

-behaviour(application).
-export([start/2, stop/1]).

-rabbit_boot_step({rabbit_events_handler,
                   [{description, "events notifiction agent"},
                    {mfa,         {rabbit_events_handler, add_handler,
                                   []}},
                    {requires,    rabbit_event},
                    {enables,     recovery}]}).

start(_Type, _StartArgs) ->
    log_startup(),
    rabbit_events_sup:start_link().

stop(_State) ->
    ok.

log_startup() ->
    rabbit_log:info("Events Notification Agents started.~n", []).
