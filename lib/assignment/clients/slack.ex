defmodule Assignment.Clients.Slack do
  @moduledoc false
  def send_tx_status_message(user_id, tx_id, status) do
    payload = %{
      "blocks" => [
        %{
          "type" => "section",
          "text" => %{
            "type" => "mrkdwn",
            "text" =>
              "*Transacton Status*\n User id: #{user_id}\nTx id: #{tx_id}\nStatus: #{status}\n \n"
          }
        }
      ]
    }

    Tesla.post!(Application.get_env(:assignment, :slack_url), Jason.encode!(payload))
  end
end
