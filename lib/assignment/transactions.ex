defmodule Assignment.Transactions do
  def get_all_transactions do
    :pending_tx_ids
    |> :ets.tab2list()
    |> Enum.map(fn {tx_id, _} ->
      tx_id
    end)
  end
end
