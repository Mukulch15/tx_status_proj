defmodule Assignment.TxWebsocket do
  @moduledoc """
  This is the websocket server that communicates with user about their transaction status.
  This is a raw websocket server written over Phoenix.Socket.Transport
  Working:
  1. The front-end connects with websocket by passing user_id.
  2. The websocket server accepts the connection request and subscribes the unique user id to a pub sub topic.
  3. The server then stores the tx_id and user_id mapping in ets and calls `get_tx_status/2` of the blocknative websocket client
     to send request for getting transaction status.
  4. The blocknative websocket client uses the ets tx_id->user_id mapping to broadcast the tx_id status back to the user_id topic.
  The websocket server doesn't handle authentication for now.
  """
  alias Assignment.Clients
  alias Phoenix.PubSub
  @behaviour Phoenix.Socket.Transport

  @doc false
  def child_spec(_opts) do
    %{id: Task, start: {Task, :start_link, [fn -> :ok end]}, restart: :transient}
  end

  def connect(state) do
    case state.params do
      %{"user_id" => user_id} ->
        {:ok, %{user_id: user_id}}

      _ ->
        :error
    end
  end

  def init(%{user_id: user_id} = state) do
    PubSub.subscribe(Assignment.PubSub, user_id)
    {:ok, state}
  end

  def handle_in({text, _opts}, %{user_id: user_id} = state) do
    case Jason.decode(text) do
      {:ok, %{"tx_ids" => tx_ids}} when is_list(tx_ids) ->
        pid = :global.whereis_name(:blocknative_client)

        Enum.each(tx_ids, fn tx_id ->
          :ets.insert(:pending_tx_ids, {tx_id, user_id})
          Clients.BlockWebsocket.get_tx_status(pid, tx_id)
          :timer.send_after(120_000, pid, {:check_tx_status, tx_id})
        end)

        {:ok, state}

      _error ->
        {:reply, :error, {:text, "Please check the request payload"}, state}
    end
  end

  def handle_info(message, state) do
    {:push, {:text, message}, state}
  end

  def terminate(_reason, _state) do
    :ok
  end
end
