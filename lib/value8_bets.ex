defmodule Value8Bets do
  @moduledoc """
  Value8Bets keeps the contexts that define your domain
  and business logic.

  Contexts are also responsible for managing your data, regardless
  if it comes from the database, an external API or others.
  """

  use Application
  require Protocol

  def start(_type, _args) do
    children = [
      Value8Bets.Repo,
      Value8BetsWeb.Telemetry,
      {Phoenix.PubSub, name: Value8Bets.PubSub},
      Value8BetsWeb.Endpoint
    ]

    opts = [strategy: :one_for_one, name: Value8Bets.Supervisor]
    Supervisor.start_link(children, opts)
  end

  def config_change(changed, _new, removed) do
    Value8BetsWeb.Endpoint.config_change(changed, removed)
    :ok
  end

  # Implement Jason.Encoder for Decimal
  Protocol.derive(Jason.Encoder, Decimal)
end
