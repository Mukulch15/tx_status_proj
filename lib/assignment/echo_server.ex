defmodule EchoSocket do
  alias Phoenix.PubSub
  @behaviour Phoenix.Socket.Transport

  def child_spec(_opts) do
    %{id: Task, start: {Task, :start_link, [fn -> :ok end]}, restart: :transient}
  end

  def connect(state) do
    case state.params do
      %{"user_id" => user_id} ->
        {:ok, %{user_id: user_id}}
      _ -> :error
    end

  end

  def init(%{user_id: user_id} = state) do
    IO.inspect self()
    PubSub.subscribe Assignment.PubSub, user_id
    {:ok, state}
  end

  def handle_in({text, _opts}, state) do
    IO.inspect self()
    {:reply, :ok, {:text, text}, state}
  end

  def handle_info(message, state) do
    IO.inspect message
    {:ok, state}
  end

  def terminate(_reason, _state) do
    :ok
  end
end
