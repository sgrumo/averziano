defmodule AverzianoWeb.UnauthorizedError do
  @moduledoc """
  Raised when a request needs a signed-in session user and has none.
  `plug_status: 401` makes Phoenix render it as a 401 response.
  """

  defexception message: "Unauthorized", plug_status: 401
end
