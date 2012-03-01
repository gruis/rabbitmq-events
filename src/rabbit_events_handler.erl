
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

%%------------------------------------------------------------------------------------------------------------
fields_to_xml_simple(Fields) ->
    [ {field, [{name, K}], [V]} || {K, V} <- Fields ].

handle_event({event, connection_created, Event, _}, State) ->
  %log_event(connection_created, Event),
  %MEvent = [[address,unknown], [port,unknown]],
  MEvent = [{address,unknown}, {port,unknown},
            {host,"<rabbit@kiff.2.207.0>"}],
  %         {peer_address,unknown}, {peer_port,unknown},
  %         {user,"guest"}, {vhost,"/"},
  %         {client_properties,[]}, {type,direct}],
  %rabbit_log:info(mochijson2:encode(MEvent)),
  MFields = fields_to_xml_simple(MEvent),
  rabbit_log:info(xmerl:export_simple(MFields, xmerl_xml)),
  {ok, State};


handle_event({event, Type, Event, _}, State) ->
  rabbit_log:info("[events:~p] caught an event ~p in state ~p.~n", [Type, Event, State]),
  log_event(Type, Event),
  %io:write(mochijson2:encode(tuple_to_list(Event))),
  %rabbit_log:info("[events] caught an event ~p in state ~p.~n", [mochijson2:encode(Event), mochijson2:encode(State)]),
  %rabbit_log:info("[events] caught an event ~p in state ~p.~n", [Event, State]),
  {ok, State}.


log_event(Type, Event) ->
  rabbit_log:info("[events:~p] ~p.~n", [Type, Event]).

%%------------------------------------------------------------------------------------------------------------

handle_info(_Info, State) ->
  %rabbit_log:info("[events] caught an info ~p for state ~p.~n", [mochijson2:encode(_Info), mochijson2:encode(State)]),
  rabbit_log:info("[events] caught an info ~p for state ~p.~n", [_Info, State]),
  {ok, State}.

terminate(_Arg, _State) ->
  rabbit_log:info("[events] terminating.~n", []),
  ok.

code_change(_OldVsn, State, _Extra) ->
  rabbit_log:info("[events] code change called.~n", []),
  {ok, State}.

