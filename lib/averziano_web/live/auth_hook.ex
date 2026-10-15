defmodule AverzianoWeb.Live.AuthHook do
  @moduledoc """
  Session-based LiveView auth. Assigns `:current_user_id` (the user's token
  subject) and an `Averziano.Auth.Actor` as `:actor`, so LiveViews can pass
  `actor: socket.assigns.actor` to domain calls.

  Without a session user it raises `AverzianoWeb.UnauthorizedError` (rendered
  as 401). There is no login page to redirect to yet; add one here once a
  session login flow exists.
  """

  import Phoenix.Component

  alias Averziano.Auth.Actor
  alias AverzianoWeb.UnauthorizedError

  @spec on_mount(atom(), map(), map(), Phoenix.LiveView.Socket.t()) ::
          {:cont, Phoenix.LiveView.Socket.t()}
  def on_mount(:default, _params, %{"current_user_id" => user_id}, socket)
      when is_binary(user_id) do
    {:cont,
     socket
     |> assign(:current_user_id, user_id)
     |> assign(:actor, %Actor{subject: user_id})}
  end

  def on_mount(:default, _params, _session, _socket), do: raise(UnauthorizedError)
end
