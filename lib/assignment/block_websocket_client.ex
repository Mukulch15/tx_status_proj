defmodule BlockWebsocketClient do
  use WebSockex
  require Logger
#   @initialize %{
#     "timeStamp"=>"2021-01-11T06:21:40.197Z",
#     "dappId"=>"a75f09b8-c506-43c3-a116-d0402152a676",
#     "version"=>"1",
#     "blockchain"=>%{
#        "system"=>"ethereum",
#        "network"=>"main"
#     },
#    "categoryCode"=> "initialize",
#      "eventCode"=> "checkDappId"
#  }
  def start_link(url) do
    WebSockex.start_link(url, __MODULE__, :blocknative)
  end

  def echo(client, message) do
    # Logger.info("Sending message: #{message}")
    WebSockex.send_frame(client, {:text, Jason.encode!(message)})
  end

  def handle_connect(_conn, state) do
    Logger.info("Connected!")

    {:ok,state}
  end

  def handle_frame({:text, msg}, state) do
    handle_message(Jason.decode(msg), state)
  end

  defp handle_message({:ok,%{"event" => %{"categoryCode" => "initialize"}, "status" => "ok"}}, state) do
    Logger.info("Initialized!")
    {:ok, state}
  end

  defp handle_message({:ok,%{"event" => %{"categoryCode" => "accountAddress"}, "status" => "ok"}} = msg, state) do
    IO.inspect msg
    {:ok, state}
  end

  defp handle_message({:ok,%{"status" => "ok"}}, state) do
    initialization_request = make_initialization_payload()
    {:reply, {:text, Jason.encode!(initialization_request)}, state}
  end

  defp handle_message(msg, state) do
    IO.inspect msg
    {:ok, state}
  end

  defp get_defaults do
    %{
      "timeStamp"=> DateTime.to_iso8601(DateTime.now!("Etc/UTC")),
      "dappId"=> Application.get_env(:assignment, :dapp_id),
      "version"=>"1",
      "blockchain"=>%{
         "system"=>"ethereum",
         "network"=>"main"
      }
    }
  end

  defp make_initialization_payload do
    data = get_defaults()
    data
    |> Map.put("categoryCode", "initialize")
    |> Map.put( "eventCode", "checkDappId")
  end

  def make_tx_status_payload do
    data = get_defaults()
    data
    |> Map.put("categoryCode", "accountAddress")
    |> Map.put( "eventCode", "txSent")
    |> Map.put("transaction",
        %{}
        |> Map.put(
        "hash", "0x9b7cb0553e1021f33e21ecac80e3433a645be31dda62e4248a3e03ce370a106b")
        |> Map.put("id", "0x9b7cb0553e1021f33e21ecac80e3433a645be31dda62e4248a3e03ce370a106b"))

  end

end
