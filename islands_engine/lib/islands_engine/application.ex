defmodule IslandsEngine.Application do
  alias IslandsEngine.GameSupervisor
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @game_ets_table Application.fetch_env!(:islands_engine, :game_ets_table_name)

  def start(_type, _args) do
    # List all child processes to be supervised
    children = [
      {Registry, [keys: :unique, name: Registry.Game]},
      {GameSupervisor, []}
    ]

    :ets.new(@game_ets_table, [:public, :named_table])
    opts = [strategy: :one_for_one, name: IslandsEngine.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
