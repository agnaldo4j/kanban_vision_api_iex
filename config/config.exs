# This file is responsible for configuring your umbrella
# and **all applications** and their dependencies with the
# help of the Config module.
#
# Note that all applications in your umbrella share the
# same configuration and dependencies, which is why they
# all use the same configuration file. If you want different
# configurations or dependencies per app, it is best to
# move said applications out of the umbrella.
import Config

# Configure Logger with structured metadata for observability
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [
    :correlation_id,
    :organization_id,
    :organization_name,
    :simulation_id,
    :simulation_name,
    :board_id,
    :board_name,
    :tribes_count,
    :count,
    :reason
  ]
