-module(rabbit_events_handler).
-behaviour(gen_event).
-export([add_handler/0]).
-export([init/1, handle_call/2, handle_event/2, handle_info/2,
         terminate/2, code_change/3]).
-include_lib("amqp_client/include/amqp_client.hrl").

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
get_channel() ->
  case get(channel) of
    undefined ->
      {ok, Connection} = amqp_connection:start(#amqp_params_network{host = "localhost"}),
      {ok, Channel}    = amqp_connection:open_channel(Connection),
      amqp_channel:call(Channel, #'exchange.declare'{exchange = <<"rabbitevents">>,
                                                     type     = <<"fanout">>}),
      put(channel, Channel),
      Channel;
    Channel ->
      rabbit_log:info("[events] get_channel returning ~p.~n", [Channel]),
      Channel
  end.

log_event(Type, Event) ->
  rabbit_log:info("[events:~p] ~p.~n", [Type, Event]).

%% Convert the AMQP version tuple into a three element list
prepro({protocol, {'Direct', Version}}) when is_tuple(Version) ->
  {protocol, {struct, [{'Direct', tuple_to_list(Version)}]}};

prepro({protocol, Proto}) when is_tuple(Proto) ->
  {protocol, tuple_to_list(Proto)};
prepro({address, Addr}) when is_tuple(Addr) ->
  {address, tuple_to_list(Addr)};
prepro({peer_address, Addr}) when is_tuple(Addr) ->
  {peer_address, tuple_to_list(Addr)};

prepro({client_properties, Props}) ->
  {client_properties, {struct, [prepro(P) || P <- Props]}};
prepro({Key, table, Table}) when is_list(Table) ->
  {Key, {struct, [prepro(E) || E <- Table]}};
prepro({Key, longstr, Value}) when is_binary(Key), is_binary(Value) ->
  {Key, Value};
prepro({Key, bool, Value}) when is_binary(Key), is_atom(Value) ->
  {Key, Value};

% TODO handle tuples with arbitrary even number contents; assume key/value pairs
prepro({name,{resource,R,exchange,E}}) ->
  {name, {struct, [{resource, R}, {exchange, E}] }};
prepro({name,{resource,R,queue,Q}}) ->
  {name, {struct, [{resource, R}, {queue, Q}] }};

%% Prevent the raw Erlang connection information from being exposed
prepro({connection, _}) ->
  null;

%% Prevent the raw Erlang process information from being exposed
prepro({Type, Pid}) when is_pid(Pid) ->
  {Type, list_to_binary(pid_to_list(Pid))};

%% By default just return the component and assume that mochijson2 will be
%% able to convert it.
prepro(Other) ->
  Other.

handle_event({event, Type, [{pid, Pid}|_Event], _}, _State) when Pid == self() ->
  rabbit_log:info("[events:~p] caught my own event.~n", [Type]);

%% Receive a proplist from the internal event stream, sanitize it and preprocess it for the 
%% JSON encoder then expose it via the rabbitevents fanout.
handle_event({event, Type, Event, _}, State) ->
  rabbit_log:info("[~p events:~p] caught an event ~p in state ~p.~n", [self(), Type, Event, State]),
  log_event(Type, Event),
  Preped   = [prepro(C) || C <- [{event, Type} | Event]],
  Filtered = {struct, [C || C <- Preped, C =/= null]},
  Json = mochijson2:encode(Filtered),
  rabbit_log:info(Json),

  Channel    = get_channel(),
  rabbit_log:info("publishing ~p on rabbitevents ~p.~n", [list_to_binary(Json), Type]),
  Properties   = #'P_basic'{content_type  = <<"application/json">>, 
                            delivery_mode = 1},
  BasicPublish = #'basic.publish'{exchange    = <<"rabbitevents">>},
  Content      = #amqp_msg{props   = Properties,
                           payload = list_to_binary(Json)},
  amqp_channel:cast(Channel, BasicPublish, Content),
  {ok, State}.
%%------------------------------------------------------------------------------------------------------------
