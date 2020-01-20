use Mix.Config

config :islands_engine,
  # 1 Day
  game_timeout: 24 * 60 * 60 * 1000,
  game_ets_table_name: :game_state

import_config "#{Mix.env()}.exs"
