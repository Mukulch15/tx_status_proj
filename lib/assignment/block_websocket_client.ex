defmodule BlockWebsocketClient do
  use WebSockex
  require Logger
  @initialize %{
    "timeStamp"=>"2021-01-11T06:21:40.197Z",
    "dappId"=>"a75f09b8-c506-43c3-a116-d0402152a676",
    "version"=>"1",
    "blockchain"=>%{
       "system"=>"ethereum",
       "network"=>"main"
    },
   "categoryCode"=> "initialize",
     "eventCode"=> "checkDappId"
 }
  def start_link(url) do
    WebSockex.start_link(url, __MODULE__, :blocknative)
  end

  def echo(client, message) do
    Logger.info("Sending message: #{message}")
    WebSockex.send_frame(client, {:text, message})
  end

  def handle_connect(_conn, state) do
    Logger.info("Connected!")

    {:ok,state}
  end

  def handle_frame({:text, msg}, state) do
    IO.inspect Jason.decode(msg)
    handle_message(Jason.decode(msg), state)
  end

  defp handle_message({:ok,%{"event" => %{"categoryCode" => "initialize"}, "status" => "ok"}}, state) do
    Logger.info("Initialized!")
    {:ok, state}
  end

  defp handle_message({:ok,%{"status" => "ok"}}, state) do
    {:reply, {:text, Jason.encode!(@initialize)}, state}
  end
end
