defmodule Assignment.Clients.BlockWebsocket do
  @moduledoc """
    Websocket client to communicate with blocknative websocket api server.
    It uses the websockex library and is started supervised as a genserver.
    handle_frame callback handles incoming message from the websocket server.
    How it works:
    1. Connect to the blocknative websocket server.
    2. Send an initialization request where the api key is verified.
    3. Send request to get transaction status of pending transactions.
    4. Send the response(pending/confirmed) to the user websocket server(TxWebsocket) using pubsub.
    5. Send the response to a slack webhook as well.

    The client automatically connects and sends initialization request to the blocknative server when
    the application starts.

    `handle_message/1` is a private function that handles the incoming messages from blocknative.
    An incoming message can be a successful initialization event or a transaction status event.
    Types of messages sent to blocknative:
    Initialization payload:
      {
        "timeStamp":"2021-01-11T06:21:40.197Z",
        "dappId":"xyz",
        "version":"1",
        "blockchain":{
            "system":"ethereum",
            "network":"main"
        },
        "categoryCode":"initialize",
        "eventCode":"checkDappId"
      }

    Initialization response payload:
      {
        "connectionId": "C4-e78f1dcd-920e-48ea-bff8-d39f88719151",
        "serverVersion": "0.122.2",
        "showUX": true,
        "status": "ok",
        "version": 0
      }

    Get status of a transaction payload:
      {
          "timeStamp": "2021-01-11T06:21:40.197Z",
          "dappId": "xyz",
          "version": "1",
          "blockchain": {
              "system": "ethereum",
              "network": "main"
          },
          "categoryCode": "accountAddress",
          "eventCode": "txSent",
          "transaction": {
              "hash": "0x794b11732e221d1c38276c79650a3fdb4594697db6e030066167e0403b1ef369",
              "id": "0x794b11732e221d1c38276c79650a3fdb4594697db6e030066167e0403b1ef369"
          }
      }

    When transaction is confirmed we get a message with event code: `txConfirmed`



  """
  alias Assignment.Clients.Slack
  use WebSockex
  require Logger
  @doc false
  def start_link(url) do
    WebSockex.start_link(url, __MODULE__, :blocknative)
  end

  @doc """
  Sends message to the blocknative websocket server.
  """
  def send_message(client, message) do
    case Jason.encode(message) do
      {:ok, msg} ->
        WebSockex.send_frame(client, {:text, msg})

      err ->
        err
    end
  end

  def handle_connect(_conn, state) do
    Logger.info("Connected!")
    :global.register_name(:blocknative_client, self())
    {:ok, state}
  end

  def handle_info({:check_tx_status, tx_id}, state) do
    case :ets.lookup(:pending_tx_ids, tx_id) do
      [{^tx_id, user_id}] ->
        Slack.send_tx_status_message(user_id, tx_id, "Pending for more than 2 minutes")

      _ ->
        :ok
    end

    {:ok, state}
  end

  def handle_frame({:text, msg}, state) do
    handle_message(Jason.decode(msg), state)
  end

  defp handle_message(
         {:ok, %{"event" => %{"categoryCode" => "initialize"}, "status" => "ok"}},
         state
       ) do
    Logger.info("Initialized!")
    {:ok, state}
  end

  defp handle_message(
         {:ok, %{"event" => %{"eventCode" => "txConfirmed"}, "status" => "ok"}} = msg,
         state
       ) do
    {:ok, msg} = msg
    tx_id = msg["event"]["transaction"]["hash"]
    [{^tx_id, user_id}] = :ets.lookup(:pending_tx_ids, tx_id)
    :ets.delete(:pending_tx_ids, tx_id)
    :ets.insert(:confirmed_tx_ids, {user_id, tx_id})

    Phoenix.PubSub.broadcast(
      Assignment.PubSub,
      user_id,
      Jason.encode!(%{tx_id: tx_id, status: "confirmed"})
    )

    Slack.send_tx_status_message(user_id, tx_id, "confirmed")
    {:ok, state}
  end

  defp handle_message({:ok, %{"event" => event, "status" => "ok"}}, state) do
    tx_id = event["transaction"]["hash"]
    [{^tx_id, user_id}] = :ets.lookup(:pending_tx_ids, tx_id)

    case event["transaction"] do
      %{"status" => _status} ->
        Phoenix.PubSub.broadcast(
          Assignment.PubSub,
          user_id,
          Jason.encode!(%{tx_id: tx_id, status: "pending"})
        )

        Slack.send_tx_status_message(user_id, tx_id, "pending")
        {:ok, state}

      _ ->
        {:ok, state}
    end
  end

  @doc """
  Handles event for successful initialization. Example response:
    {
    "connectionId": "C4-e78f1dcd-920e-48ea-bff8-d39f88719151",
    "serverVersion": "0.122.2",
    "showUX": true,
    "status": "ok",
    "version": 0
    }
  """
  defp handle_message({:ok, %{"status" => "ok"}} = msg, state) do
    IO.inspect(msg)
    initialization_request = make_initialization_payload()
    {:reply, {:text, Jason.encode!(initialization_request)}, state}
  end

  defp handle_message(msg, state) do
    Logger.info("Received from blocknative#{inspect(msg)}")
    {:ok, state}
  end

  defp get_defaults do
    %{
      "timeStamp" => DateTime.to_iso8601(DateTime.now!("Etc/UTC")),
      "dappId" => Application.get_env(:assignment, :dapp_id),
      "version" => "1",
      "blockchain" => %{
        "system" => "ethereum",
        "network" => "main"
      }
    }
  end

  @doc """
    This method creates a request payload for getting transaction status and sends it to blocknative websocket server.
  """
  def get_tx_status(pid, tx_id) do
    payload = make_tx_status_payload(tx_id)
    send_message(pid, payload)
  end

  defp make_initialization_payload do
    data = get_defaults()

    data
    |> Map.put("categoryCode", "initialize")
    |> Map.put("eventCode", "checkDappId")
  end

  defp make_tx_status_payload(tx_id) do
    data = get_defaults()

    data
    |> Map.put("categoryCode", "accountAddress")
    |> Map.put("eventCode", "txSent")
    |> Map.put(
      "transaction",
      %{}
      |> Map.put(
        "hash",
        tx_id
      )
      |> Map.put("id", tx_id)
    )
  end
end
