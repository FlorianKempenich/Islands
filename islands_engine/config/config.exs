use Mix.Config

config :islands_engine,
  # 1 Day
  game_timeout: 24 * 60 * 60 * 1000

import_config "#{Mix.env()}.exs"
