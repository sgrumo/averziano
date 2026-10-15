defmodule Averziano.Auth.TokenVerifier do
  @moduledoc """
  Behaviour for Bearer token verification. The implementation is chosen with
  `config :averziano, token_verifier: module` and called by
  `AverzianoWeb.Plugs.Auth`.
  """

  @typedoc "Verified token claims, keyed by claim name."
  @type claims :: %{optional(String.t()) => term()}

  @callback verify_token(String.t()) :: {:ok, claims()} | {:error, :unauthorized}
end
