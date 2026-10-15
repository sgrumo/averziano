defmodule AverzianoWeb.Live.AuthHookTest do
  use ExUnit.Case, async: true

  alias Averziano.Auth.Actor
  alias AverzianoWeb.Live.AuthHook
  alias AverzianoWeb.UnauthorizedError
  alias Phoenix.LiveView.Socket

  test "assigns the session user and its actor" do
    assert {:cont, socket} =
             AuthHook.on_mount(:default, %{}, %{"current_user_id" => "user-1"}, %Socket{})

    assert socket.assigns.current_user_id == "user-1"
    assert socket.assigns.actor == %Actor{subject: "user-1"}
  end

  test "raises a 401 error without a session user" do
    assert_raise UnauthorizedError, fn -> AuthHook.on_mount(:default, %{}, %{}, %Socket{}) end
    assert Plug.Exception.status(%UnauthorizedError{}) == 401
  end
end
