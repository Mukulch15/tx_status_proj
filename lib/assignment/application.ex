defmodule Assignment.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      # Start the Ecto repository
      # Assignment.Repo,
      # Start the Telemetry supervisor
      AssignmentWeb.Telemetry,
      # Start the PubSub system
      {Phoenix.PubSub, name: Assignment.PubSub},
      # Start the Endpoint (http/https)
      AssignmentWeb.Endpoint,

      {Assignment.Clients.BlockWebsocket, Application.get_env(:assignment, :blocknative_url, "wss://api.blocknative.com/v0")}
      # Start a worker by calling: Assignment.Worker.start_link(arg)
      # {Assignment.Worker, arg}
    ]
    :ets.new(:pending_tx_ids, [:set, :public, :named_table])

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Assignment.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    AssignmentWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
