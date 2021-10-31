defmodule Assignment do
  @moduledoc """
    This purpose of this project is to get transaction status in the ethereum network in near realtime and send back to the user and
    a slack webhook as well.
    It consists of two parts:
    1. The blocknative webclient `Assignment.Clients.BlockWebsocket` that connects to blocknative server to get back transaction status through websocket.
    2. The websocket server `Assignment.TxWebsocket` to which the user connects and receives realtime info about their pending transaction.
  """
end
