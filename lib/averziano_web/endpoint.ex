defmodule AverzianoWeb.Endpoint do
  use Phoenix.Endpoint, otp_app: :averziano

  @session_options [
    store: :cookie,
    key: "_averziano_key",
    signing_salt: "LQVaD7sn",
    same_site: "Lax"
  ]

  socket "/live", Phoenix.LiveView.Socket,
    websocket: [connect_info: [session: @session_options]],
    longpoll: [connect_info: [session: @session_options]]

  plug Plug.Static,
    at: "/",
    from: :averziano,
    gzip: not code_reloading?,
    only: AverzianoWeb.static_paths(),
    raise_on_missing_only: code_reloading?

  if code_reloading? do
    socket "/phoenix/live_reload/socket", Phoenix.LiveReloader.Socket
    plug Phoenix.LiveReloader
    plug Phoenix.CodeReloader
    plug Phoenix.Ecto.CheckRepoStatus, otp_app: :averziano
  end

  plug Plug.RequestId
  plug Plug.Telemetry, event_prefix: [:phoenix, :endpoint]

  # Origins are read per request so production can set them via CORS_ORIGINS.
  # No credentials: the API authenticates with Bearer tokens, not cookies.
  plug Corsica,
    origins: {__MODULE__, :allowed_origin?, []},
    allow_headers: ["authorization", "content-type"],
    allow_methods: ["GET", "POST", "PUT", "PATCH", "DELETE", "OPTIONS"]

  plug Plug.Parsers,
    parsers: [:urlencoded, :multipart, :json],
    pass: ["*/*"],
    json_decoder: Phoenix.json_library()

  plug Plug.MethodOverride
  plug Plug.Head
  plug Plug.Session, @session_options
  plug AverzianoWeb.Router

  @doc false
  @spec allowed_origin?(Plug.Conn.t(), String.t()) :: boolean()
  def allowed_origin?(_conn, origin) do
    origin in Application.get_env(:averziano, :cors_origins, [])
  end
end
