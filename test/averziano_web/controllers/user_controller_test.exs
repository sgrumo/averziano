defmodule AverzianoWeb.UserControllerTest do
  use AverzianoWeb.ConnCase, async: true

  # The subject `authenticate/1`'s token maps to (see `Averziano.Auth.TokenMock`).
  @subject "test-user-id"

  setup %{conn: conn} do
    {:ok, conn: put_req_header(conn, "accept", "application/json")}
  end

  test "rejects unauthenticated requests", %{conn: conn} do
    assert %{"errors" => %{"detail" => "Unauthorized"}} =
             conn |> get(~p"/api/users") |> json_response(401)
  end

  test "GET /api/users lists only the caller's user, or every user for admins", %{conn: conn} do
    own = generate(user(subject: @subject))
    other = generate(user())

    assert %{"data" => [%{"id" => id}]} =
             conn |> authenticate() |> get(~p"/api/users") |> json_response(200)

    assert id == own.id

    assert %{"data" => data} =
             conn |> authenticate_admin() |> get(~p"/api/users") |> json_response(200)

    assert Enum.sort(Enum.map(data, & &1["id"])) == Enum.sort([own.id, other.id])
  end

  test "GET /api/users pages with limit and the meta.next cursor", %{conn: conn} do
    conn = authenticate_admin(conn)
    generate_many(user(), 2)

    assert %{"data" => [%{"id" => first_id}], "meta" => %{"next" => cursor}} =
             conn |> get(~p"/api/users?limit=1") |> json_response(200)

    assert %{"data" => [%{"id" => second_id}], "meta" => %{"next" => nil}} =
             conn |> get(~p"/api/users?limit=1&after=#{cursor}") |> json_response(200)

    assert first_id != second_id

    for limit <- ["0", "101", "abc"] do
      assert %{"errors" => %{"detail" => "Bad Request"}} =
               conn |> get(~p"/api/users?limit=#{limit}") |> json_response(400)
    end
  end

  test "GET /api/users/:id returns the caller's user and 404 for anyone else's", %{conn: conn} do
    conn = authenticate(conn)
    user = generate(user(subject: @subject, name: "Ada"))

    assert %{"data" => %{"id" => id, "name" => "Ada", "email" => email}} =
             conn |> get(~p"/api/users/#{user.id}") |> json_response(200)

    assert id == user.id
    assert email == to_string(user.email)

    other = generate(user())

    assert %{"errors" => %{"detail" => "Not Found"}} =
             conn |> get(~p"/api/users/#{other.id}") |> json_response(404)

    assert %{"errors" => %{"id" => ["is invalid"]}} =
             conn |> get(~p"/api/users/not-a-uuid") |> json_response(422)
  end

  test "POST /api/users registers the caller; 400 without a user, 422 if invalid, 403 for another subject",
       %{conn: conn} do
    conn = authenticate(conn)

    assert_error_sent 400, fn -> post(conn, ~p"/api/users", %{"email" => "ada@example.com"}) end

    assert %{"errors" => %{"name" => ["is required"]}} =
             conn
             |> post(~p"/api/users", user: %{"email" => "ada@example.com"})
             |> json_response(422)

    assert %{"errors" => %{"detail" => "Forbidden"}} =
             conn
             |> post(~p"/api/users",
               user: %{"email" => "ada@example.com", "name" => "Ada", "subject" => "someone-else"}
             )
             |> json_response(403)

    created =
      conn
      |> post(~p"/api/users", user: %{"email" => "ada@example.com", "name" => "Ada"})
      |> json_response(201)

    assert %{"data" => %{"id" => id, "email" => "ada@example.com", "name" => "Ada"}} = created

    assert %{"data" => %{"id" => ^id}} =
             conn |> get(~p"/api/users/#{id}") |> json_response(200)
  end

  test "PATCH and DELETE work on the caller's user and 404 on anyone else's", %{conn: conn} do
    conn = authenticate(conn)
    own = generate(user(subject: @subject))
    other = generate(user())

    assert conn
           |> patch(~p"/api/users/#{other.id}", user: %{"name" => "Renamed"})
           |> json_response(404)

    assert conn |> delete(~p"/api/users/#{other.id}") |> json_response(404)

    assert %{"data" => %{"name" => "Renamed"}} =
             conn
             |> patch(~p"/api/users/#{own.id}", user: %{"name" => "Renamed"})
             |> json_response(200)

    assert conn |> delete(~p"/api/users/#{own.id}") |> response(204)
    assert conn |> get(~p"/api/users/#{own.id}") |> json_response(404)
  end
end
