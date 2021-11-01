defmodule Assignment.Transactions do
  @moduledoc false
  def get_all_pending_transactions do
    :pending_tx_ids
    |> :ets.tab2list()
    |> Enum.map(fn {tx_id, _} ->
      tx_id
    end)
  end

  def get_user_confirmed_transactions(user_id) do
    :confirmed_tx_ids
    |> :ets.lookup(user_id)
    |> Enum.map(fn {_, tx_id} -> tx_id end)
  end
end
