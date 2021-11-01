defmodule AssignmentWeb.TransactionsController do
  alias Assignment.Transactions
  use AssignmentWeb, :controller

  def index(conn, _params) do
    pending_txs = Transactions.get_all_pending_transactions()
    json(conn, pending_txs)
  end

  def get_confirmed_txs(conn, params) do
    confirmed_txs = Transactions.get_user_confirmed_transactions(params["user_id"])
    json(conn, confirmed_txs)
  end
end
