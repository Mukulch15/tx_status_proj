defmodule BlockWebsocketClient do
  use WebSockex
  require Logger
  def start_link(url) do
    WebSockex.start_link(url, __MODULE__, :blocknative)
  end

  def send_message(client, message) do
    case Jason.encode(message) do
      {:ok, msg} ->
        WebSockex.send_frame(client, {:text, msg})
      err -> err
    end
  end

  def handle_connect(_conn, state) do
    Logger.info("Connected!")
    :global.register_name(:blocknative_client, self())
    {:ok,state}
  end

  def handle_frame({:text, msg}, state) do
    handle_message(Jason.decode(msg), state)
  end

  # Private functions to transform incoming messages from blocknative
  defp handle_message({:ok,%{"event" => %{"categoryCode" => "initialize"}, "status" => "ok"}}, state) do
    Logger.info("Initialized!")
    {:ok, state}
  end

  defp handle_message({:ok,%{"event" =>%{"eventCode" => "txConfirmed"}, "status" => "ok"}} = msg, state) do
    {:ok, msg} = msg
    tx_id = msg["event"]["transaction"]["hash"]
    [{^tx_id, user_id}] = :ets.lookup(:pending_tx_ids, tx_id)
    :ets.delete(:pending_tx_ids, tx_id)
    Phoenix.PubSub.broadcast(Assignment.PubSub, user_id, "confirmed")
    {:ok, state}
  end

  defp handle_message({:ok,%{"event" => event, "status" => "ok"}}, state) do
    tx_id = event["transaction"]["hash"]
    [{^tx_id, user_id}] = :ets.lookup(:pending_tx_ids, tx_id)
    case event["transaction"] do
      %{"status" => _status} ->
        Phoenix.PubSub.broadcast(Assignment.PubSub, user_id, "pending")
        {:ok, state}
      _ -> {:ok, state}
    end
    {:ok, state}
  end

  defp handle_message({:ok,%{"status" => "ok"}}, state) do
    initialization_request = make_initialization_payload()
    {:reply, {:text, Jason.encode!(initialization_request)}, state}
  end

  defp handle_message(msg, state) do
    Logger.info("Received from blocknative#{inspect(msg)}")
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

  def get_tx_status(pid, tx_id) do
    payload = make_tx_status_payload(tx_id)
    send_message(pid, payload)
  end

  defp make_initialization_payload do
    data = get_defaults()
    data
    |> Map.put("categoryCode", "initialize")
    |> Map.put( "eventCode", "checkDappId")
  end

  defp make_tx_status_payload(tx_id) do
    data = get_defaults()
    data
    |> Map.put("categoryCode", "accountAddress")
    |> Map.put( "eventCode", "txSent")
    |> Map.put("transaction",
        %{}
        |> Map.put(
        "hash", tx_id)
        |> Map.put("id", tx_id))

  end

end
