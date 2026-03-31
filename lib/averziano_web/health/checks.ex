defmodule AverzianoWeb.Health.Checks do
  @moduledoc false

  def database do
    case Ecto.Adapters.SQL.query(Averziano.Repo, "SELECT 1") do
      {:ok, _} -> :ok
      {:error, reason} -> {:error, "Database unreachable: #{inspect(reason)}"}
    end
  end
end
