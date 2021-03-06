

Web application that gives you real time ethereum transaction updates over a websocket.
You will need to setup the following environment variables before running the app:
1. BLOCKNATIVE_URL 
2. SLACK_URL
3. DAPP_ID (API key)
The blocknative url is `wss://api.blocknative.com/v0`

To connect to the app websocket server:
1. Use the url `ws://localhost:4000/socket/websocket?user_id=<user_id>`
2. Send json payload `{"tx_ids": [<transaction_hashes>]}`
3. You will be replied with the status of the pending transaction and a message will be sent over the slack webhook as well.

To start your Phoenix server:

  * Install dependencies with `mix deps.get`
  * Start Phoenix endpoint with `mix phx.server` or inside IEx with `iex -S mix phx.server`

To get pending transactions:
`GET http://localhost:4000/pending_transactions`

To get confirmed transactions per user_id:
`GET http://localhost:4000/confirmed_transactions?user_id=<user_id>`

The above api is written so that in case the user websocket disconnects before they get any status update,
the front end can call the api to get all the list of confirmed transactions within the timeframe.


