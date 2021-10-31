defmodule Assignment.Clients.Slack do
  def send_tx_status_message(user_id, tx_id, status) do
    payload = %{
      "text" => "Transaction status",
      "blocks" => [
        %{
          "type" => "section",
          "text" => %{
            "type" => "mrkdwn",
            "text" => "\n User id: #{user_id}"
          }
        },
        %{
          "type" => "section",
          "text" => %{
            "type" => "mrkdwn",
            "text" => "Tx id: #{tx_id}"
          }
        },
        %{
          "type" => "section",
          "text" => %{
            "type" => "mrkdwn",
            "text" => "Status: #{status}\n \n"
          }
        }
      ]
    }

    Tesla.post!(Application.get_env(:assignment, :slack_url), Jason.encode!(payload))
  end
end
