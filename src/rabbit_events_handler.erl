-module(rabbit_events_handler).
-behaviour(gen_event).
-export([add_handler/0]).
-export([init/1, handle_call/2, handle_event/2, handle_info/2,
         terminate/2, code_change/3]).

-include_lib("amqp_client/include/amqp_client.hrl").

add_handler() ->
    gen_event:add_sup_handler(rabbit_event, ?MODULE, []).

init([]) ->
  [ ok=store_config(Key) || Key <- [host, username, password, virtual_host, exchange, debug] ],
  {ok, []}.

store_config(Key) ->
  {ok, Value} = application:get_env(rabbitmq_events, Key),
  put(Key, Value),
  ok.

handle_call(_Request, State) ->
  log("[events] got state that isn't understood ~p.~n", [State]),
  {ok, not_understood, State}.

handle_info(_Info, State) ->
  log("[events] caught an info ~p for state ~p.~n", [_Info, State]),
  {ok, State}.

terminate(_Arg, _State) ->
  log("[events] terminating.~n", []),
  ok.

code_change(_OldVsn, State, _Extra) ->
  log("[events] code change called.~n", []),
  {ok, State}.


%%------------------------------------------------------------------------------------------------------------
handle_event({event, Type, [{pid, Pid}|_Event], _}, _State) when Pid == self() ->
  log("[events:~p] caught my own event.~n", [Type]);

%% Receive a proplist from the internal event stream, sanitize it and preprocess it for the 
%% JSON encoder then expose it via the rabbitevents fanout.
handle_event({event, Type, Event, _}, State) ->
  log_event(Type, Event),
  Preped   = [prepro(C) || C <- [{event, Type} | Event]],
  Filtered = {struct, [C || C <- Preped, C =/= null]},
  Json = mochijson2:encode(Filtered),

  Channel    = get_channel(),
  log("publishing ~p on ~p.~n", [list_to_binary(Json), get(exchange)]),
  Properties   = #'P_basic'{content_type  = <<"application/json">>, 
                            delivery_mode = 1},
  BasicPublish = #'basic.publish'{exchange    = get(exchange)},
  Content      = #amqp_msg{props   = Properties,
                           payload = list_to_binary(Json)},
  amqp_channel:cast(Channel, BasicPublish, Content),
  {ok, State}.

%%------------------------------------------------------------------------------------------------------------
log(Msg, Values) ->
  case get(debug) of
    undefined ->
      rabbit_log:info(Msg, Values);
    true ->
      rabbit_log:info(Msg, Values);
    _ -> nothing
  end.

log_event(Type, Event) ->
  log("[events:~p] ~p.~n", [Type, Event]),
  true.

get_channel() ->
  case get(channel) of
    undefined ->
      {ok, Connection} = amqp_connection:start(#amqp_params_network{
                                                  host         = get(host)
                                                , username     = get(username)
                                                , password     = get(password)
                                                , virtual_host = get(virtual_host) 
                                               }),
      {ok, Channel}    = amqp_connection:open_channel(Connection),
      amqp_channel:call(Channel, #'exchange.declare'{exchange = get(exchange),
                                                     type     = <<"fanout">>}),
      put(channel, Channel),
      Channel;
    Channel ->
      Channel
  end.

%% Preprocessors to normalize event information before encoding as json. 
%% Any preprocessor that returns null will force that element to be filtered
%% out of the message.


%% Prevent the raw Erlang connection information from being exposed
prepro({connection, _}) ->
  null;

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
prepro({Key, _Type, Value}) when is_binary(Key), is_binary(Value) ->
  {Key, Value};
prepro({Key, _Type, Value}) when is_binary(Key), is_atom(Value) ->
  {Key, Value};

% TODO handle tuples with arbitrary even number contents; assume key/value pairs
prepro({name,{resource,R,exchange,E}}) ->
  {name, {struct, [{resource, R}, {exchange, E}] }};
prepro({name,{resource,R,queue,Q}}) ->
  {name, {struct, [{resource, R}, {queue, Q}] }};

%% Prevent the raw Erlang process information from being exposed
prepro({Type, Pid}) when is_pid(Pid) ->
  {Type, list_to_binary(pid_to_list(Pid))};

%% By default just return the component and assume that mochijson2 will be
%% able to convert it.
prepro(Other) ->
  Other.
