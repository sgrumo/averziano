defmodule Averziano.Auth.TokenMock do
  @moduledoc false

  @behaviour Averziano.Auth.TokenVerifier

  @impl Averziano.Auth.TokenVerifier
  @spec verify_token(String.t()) ::
          {:ok, Averziano.Auth.TokenVerifier.claims()} | {:error, :unauthorized}
  def verify_token("valid_token"), do: {:ok, %{"sub" => "test-user-id"}}

  def verify_token("valid_admin_token"),
    do: {:ok, %{"sub" => "test-admin-id", "roles" => ["admin"]}}

  def verify_token(_token), do: {:error, :unauthorized}
end
