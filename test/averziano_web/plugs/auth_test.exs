defmodule AverzianoWeb.Plugs.AuthTest do
  use AverzianoWeb.ConnCase, async: true

  alias Averziano.Auth.Actor
  alias AverzianoWeb.Plugs.Auth

  test "sets the claims and an actor built from them for a valid Bearer token", %{conn: conn} do
    conn = conn |> authenticate_admin() |> Auth.call([])

    refute conn.halted
    assert conn.assigns.current_user_claims["sub"] == "test-admin-id"
    assert Ash.PlugHelpers.get_actor(conn) == %Actor{subject: "test-admin-id", admin?: true}
  end

  test "halts with 401 for a missing, malformed or invalid Authorization header", %{conn: conn} do
    for header <- [nil, "valid_token", "Token valid_token", "Bearer ", "Bearer bogus"] do
      conn =
        if header, do: put_req_header(conn, "authorization", header), else: conn

      conn = Auth.call(conn, [])

      assert conn.halted, inspect(header)
      assert %{"errors" => %{"detail" => "Unauthorized"}} = json_response(conn, 401)
    end
  end
end
