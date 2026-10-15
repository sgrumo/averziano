defmodule AverzianoWeb.Health.Checks do
  @moduledoc false

  require Logger

  @spec database() :: :ok | {:error, String.t()}
  def database do
    case Ecto.Adapters.SQL.query(Averziano.Repo, "SELECT 1") do
      {:ok, _} ->
        :ok

      {:error, reason} ->
        # The health endpoint is public: log the detail, return a generic message.
        Logger.error("Health check: database unreachable: #{inspect(reason)}")
        {:error, "Database unreachable"}
    end
  end
end
