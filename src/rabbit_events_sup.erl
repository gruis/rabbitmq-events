-module(rabbit_events_sup).

-behaviour(supervisor).

-export([init/1]).
-export([start_link/0]).

init([]) -> {ok, {{one_for_one, 10, 10}, []}}.

start_link() ->
    supervisor:start_link({local, ?MODULE}, ?MODULE, []).
