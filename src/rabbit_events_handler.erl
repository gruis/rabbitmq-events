
-module(rabbit_events_handler).

-behaviour(gen_event).

-export([add_handler/0]).

-export([init/1, handle_call/2, handle_event/2, handle_info/2,
         terminate/2, code_change/3]).


add_handler() ->
    gen_event:add_sup_handler(rabbit_event, ?MODULE, []).

init([]) ->
    {ok, []}.

handle_call(_Request, State) ->
  rabbit_log:info("[events] got state that isn't understood ~p.~n", [State]),
  {ok, not_understood, State}.

handle_info(_Info, State) ->
  rabbit_log:info("[events] caught an info ~p for state ~p.~n", [_Info, State]),
  {ok, State}.

terminate(_Arg, _State) ->
  rabbit_log:info("[events] terminating.~n", []),
  ok.

code_change(_OldVsn, State, _Extra) ->
  rabbit_log:info("[events] code change called.~n", []),
  {ok, State}.


%%------------------------------------------------------------------------------------------------------------

log_event(Type, Event) ->
  rabbit_log:info("[events:~p] ~p.~n", [Type, Event]).

%% Convert the AMQP version tuple into a three element list
prep_comp({protocol, {'Direct', Version}}) when is_tuple(Version) ->
  {protocol, {struct, [{'Direct', tuple_to_list(Version)}]}};

% TODO handle tuples with arbitrary even number contents; assume key/value pairs
prep_comp({name,{resource,R,exchange,E}}) ->
  {name, {struct, [{resource, R}, {exchange, E}] }};

%% Prevent the raw Erlang connection information from being exposed
prep_comp({connection, _}) ->
  null;

%% Prevent the raw Erlang process information from being exposed
prep_comp({pid, _}) ->
  null;

%% By default just return the component and assume that mochijson2 will be
%% able to convert it.
prep_comp(Other) ->
  Other.

%% Receive a proplist from the internal event stream, sanitize it and preprocess it for the 
%% JSON encoder then expose it via a known exchange..
handle_event({event, Type, Event, _}, State) ->
  rabbit_log:info("[events:~p] caught an event ~p in state ~p.~n", [Type, Event, State]),
  log_event(Type, Event),
  MEvent = [prep_comp(C) || C <- [{event, Type} | Event]],
  rabbit_log:info(mochijson2:encode({struct, [C || C <- MEvent, C =/= null]})),
  {ok, State}.

%%------------------------------------------------------------------------------------------------------------


