defmodule Averziano.Auth.Actor do
  @moduledoc """
  The Ash actor for authenticated requests, built from verified token claims.

  Policies match `subject` (the token's `sub`) against `User.subject`;
  `admin?` is true when the token's `roles` claim contains `"admin"`.
  """

  @enforce_keys [:subject]
  defstruct [:subject, admin?: false]

  @type t :: %__MODULE__{subject: String.t(), admin?: boolean()}

  @admin_role "admin"

  @spec from_claims(map()) :: t()
  def from_claims(%{"sub" => subject} = claims) when is_binary(subject) do
    %__MODULE__{subject: subject, admin?: @admin_role in List.wrap(claims["roles"])}
  end
end
