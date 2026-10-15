defmodule AverzianoWeb.ConnCase do
  use ExUnit.CaseTemplate

  using do
    quote do
      @endpoint AverzianoWeb.Endpoint

      use AverzianoWeb, :verified_routes

      import Plug.Conn
      import Phoenix.ConnTest
      import AverzianoWeb.ConnCase
      import Averziano.Generator
    end
  end

  setup tags do
    Averziano.DataCase.setup_sandbox(tags)
    {:ok, conn: Phoenix.ConnTest.build_conn()}
  end

  @doc """
  Adds a valid Bearer token to the connection for authenticated API tests.
  """
  @spec authenticate(Plug.Conn.t()) :: Plug.Conn.t()
  def authenticate(conn) do
    Plug.Conn.put_req_header(conn, "authorization", "Bearer valid_token")
  end

  @doc """
  Adds an admin Bearer token to the connection.
  """
  @spec authenticate_admin(Plug.Conn.t()) :: Plug.Conn.t()
  def authenticate_admin(conn) do
    Plug.Conn.put_req_header(conn, "authorization", "Bearer valid_admin_token")
  end
end
