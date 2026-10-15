defmodule AverzianoWeb.UserJSON do
  @moduledoc false

  alias Averziano.Accounts.User

  @spec index(%{page: Ash.Page.Keyset.t()}) :: map()
  def index(%{page: page}) do
    %{data: Enum.map(page.results, &data/1), meta: %{next: next_cursor(page)}}
  end

  @spec show(%{user: User.t()}) :: map()
  def show(%{user: user}), do: %{data: data(user)}

  defp next_cursor(%{more?: true, results: results}), do: List.last(results).__metadata__.keyset
  defp next_cursor(_page), do: nil

  defp data(%User{} = user) do
    %{
      id: user.id,
      email: to_string(user.email),
      name: user.name,
      inserted_at: user.inserted_at,
      updated_at: user.updated_at
    }
  end
end
