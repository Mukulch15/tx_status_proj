defmodule AssignmentWeb.TransactionsController do
  alias Assignment.Transactions
  use AssignmentWeb, :controller

  def index(conn, _params) do
    pending_txs = Transactions.get_all_transactions()
    json(conn, pending_txs)
  end
end
