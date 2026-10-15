defmodule Averziano.Auth.Token do
  @moduledoc """
  Verifies Bearer JWTs against the signer, issuer and audience configured in
  `config :averziano, Averziano.Auth.Token` (production values come from env
  vars in `config/runtime.exs`).

  Joken only validates claims that are present in the token, so a token
  missing `exp`, `iss` or `aud` would otherwise pass. `@required_claims` are
  therefore checked explicitly.
  """

  use Joken.Config

  @behaviour Averziano.Auth.TokenVerifier

  @required_claims ~w(sub exp iss aud)

  @impl true
  def token_config do
    [skip: [:iss, :aud, :jti]]
    |> default_claims()
    |> add_claim("iss", nil, &(&1 == config(:issuer)))
    |> add_claim("aud", nil, &audience_valid?/1)
    |> add_claim("sub", nil, &(is_binary(&1) and &1 != ""))
  end

  @impl Averziano.Auth.TokenVerifier
  @spec verify_token(String.t()) ::
          {:ok, Averziano.Auth.TokenVerifier.claims()} | {:error, :unauthorized}
  def verify_token(token) do
    with {:ok, claims} <- verify_and_validate(token, signer()),
         true <- Enum.all?(@required_claims, &Map.has_key?(claims, &1)) do
      {:ok, claims}
    else
      _ -> {:error, :unauthorized}
    end
  end

  @doc """
  The signer built from config. Exposed so tests can mint tokens.
  """
  @spec signer() :: Joken.Signer.t()
  def signer do
    alg = config(:signer_alg)
    Joken.Signer.create(alg, signer_key(alg, config(:signer_key)))
  end

  # `aud` may be a single string or a list of strings (RFC 7519 §4.1.3).
  defp audience_valid?(aud), do: config(:audience) in List.wrap(aud)

  defp signer_key("HS" <> _, secret), do: secret
  defp signer_key(_alg, pem), do: %{"pem" => pem}

  defp config(key) do
    :averziano |> Application.fetch_env!(__MODULE__) |> Keyword.fetch!(key)
  end
end
