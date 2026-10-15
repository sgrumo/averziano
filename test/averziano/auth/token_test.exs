defmodule Averziano.Auth.TokenTest do
  use ExUnit.Case, async: true

  alias Averziano.Auth.Token

  test "accepts a token signed with the configured signer, issuer and audience" do
    claims = valid_claims()

    assert {:ok, %{"sub" => "user-1"}} = claims |> sign() |> Token.verify_token()

    assert {:ok, _claims} =
             claims |> Map.put("aud", ["other", "averziano"]) |> sign() |> Token.verify_token()
  end

  test "rejects tokens with invalid or missing claims" do
    claims = valid_claims()

    for invalid <- [
          Map.put(claims, "iss", "someone-else"),
          Map.put(claims, "aud", "someone-else"),
          Map.put(claims, "exp", Joken.current_time() - 1),
          Map.put(claims, "sub", ""),
          Map.delete(claims, "exp"),
          Map.delete(claims, "iss"),
          Map.delete(claims, "aud"),
          Map.delete(claims, "sub")
        ] do
      assert Token.verify_token(sign(invalid)) == {:error, :unauthorized}, inspect(invalid)
    end
  end

  test "rejects tokens with a foreign signature or that are not JWTs" do
    foreign_signer = Joken.Signer.create("HS256", "some-other-secret")

    assert Token.verify_token(sign(valid_claims(), foreign_signer)) == {:error, :unauthorized}
    assert Token.verify_token("not-a-jwt") == {:error, :unauthorized}
  end

  defp valid_claims do
    %{
      "sub" => "user-1",
      "iss" => "averziano-test",
      "aud" => "averziano",
      "exp" => Joken.current_time() + 60
    }
  end

  defp sign(claims, signer \\ Token.signer()) do
    {:ok, token, _claims} = Joken.encode_and_sign(claims, signer)
    token
  end
end
