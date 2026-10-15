defmodule Averziano.DataCase do
  use ExUnit.CaseTemplate

  alias Averziano.Auth.Actor

  using do
    quote do
      alias Averziano.Repo

      require Ash.Query

      import Averziano.DataCase
      import Averziano.Generator
    end
  end

  setup tags do
    Averziano.DataCase.setup_sandbox(tags)
    :ok
  end

  @spec setup_sandbox(map()) :: :ok
  def setup_sandbox(tags) do
    pid = Ecto.Adapters.SQL.Sandbox.start_owner!(Averziano.Repo, shared: not tags[:async])
    on_exit(fn -> Ecto.Adapters.SQL.Sandbox.stop_owner(pid) end)
  end

  @doc """
  A non-admin actor for authorized domain calls. With no argument it mirrors
  `Averziano.Auth.TokenMock`'s `"valid_token"`.
  """
  @spec actor(String.t()) :: Actor.t()
  def actor(subject \\ "test-user-id"), do: %Actor{subject: subject}

  @doc """
  An admin actor. Mirrors `Averziano.Auth.TokenMock`'s `"valid_admin_token"`.
  """
  @spec admin() :: Actor.t()
  def admin, do: %Actor{subject: "test-admin-id", admin?: true}
end
