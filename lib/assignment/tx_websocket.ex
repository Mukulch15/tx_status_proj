defmodule TxWebsocket do
  alias Assignment.Clients
  alias Phoenix.PubSub
  @behaviour Phoenix.Socket.Transport

  def child_spec(_opts) do
    %{id: Task, start: {Task, :start_link, [fn -> :ok end]}, restart: :transient}
  end

  @spec connect(atom | %{:params => any, optional(any) => any}) :: :error | {:ok, %{user_id: any}}
  def connect(state) do
    case state.params do
      %{"user_id" => user_id} ->
        {:ok, %{user_id: user_id}}
      _ -> :error
    end

  end

  def init(%{user_id: user_id} = state) do
    PubSub.subscribe Assignment.PubSub, user_id
    {:ok, state}
  end

  def handle_in({text, _opts}, %{user_id: user_id} = state) do
    case Jason.decode(text) do
      {:ok, %{"tx_id" => tx_id}} ->
        pid = :global.whereis_name(:blocknative_client)
        :ets.insert(:pending_tx_ids, {tx_id, user_id})
        Clients.BlockWebsocket.get_tx_status(pid, tx_id)
        {:ok, state}
      _error -> {:reply, :error}

    end
  end

  def handle_info(message, state) do
    {:push, {:text, message}, state}
  end

  def terminate(_reason, _state) do
    :ok
  end
end
