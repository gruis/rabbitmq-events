
-module(rabbit_events_handler).

-behaviour(gen_event).

-export([add_handler/0]).

-export([init/1, handle_call/2, handle_event/2, handle_info/2,
         terminate/2, code_change/3]).

%%----------------------------------------------------------------------------

add_handler() ->
    rabbit_log:info("add_handler called"),
    gen_event:add_sup_handler(rabbit_event, ?MODULE, []).

%%----------------------------------------------------------------------------


init([]) ->
    {ok, []}.

handle_call(_Request, State) ->
  rabbit_log:info("[events] got state that isn't understood ~p.~n", [State]),
  {ok, not_understood, State}.

handle_event(Event, State) ->
  rabbit_log:info("[events] caught an event ~p in state ~p.~n", [Event, State]),
  {ok, State}.

handle_info(_Info, State) ->
  rabbit_log:info("[events] caught an info ~p for state ~p.~n", [_Info, State]),
  {ok, State}.

terminate(_Arg, _State) ->
  rabbit_log:info("[events] terminating.~n", []),
  ok.

code_change(_OldVsn, State, _Extra) ->
  rabbit_log:info("[events] code change called.~n", []),
  {ok, State}.
