defmodule AverzianoWeb.EndpointTest do
  use AverzianoWeb.ConnCase, async: true

  describe "CORS" do
    test "allows configured origins without credentials", %{conn: conn} do
      conn = conn |> put_req_header("origin", "http://localhost:3000") |> get(~p"/api/users")

      assert get_resp_header(conn, "access-control-allow-origin") == ["http://localhost:3000"]
      assert get_resp_header(conn, "access-control-allow-credentials") == []
    end

    test "ignores other origins", %{conn: conn} do
      conn = conn |> put_req_header("origin", "https://evil.example") |> get(~p"/api/users")

      assert get_resp_header(conn, "access-control-allow-origin") == []
    end
  end
end
