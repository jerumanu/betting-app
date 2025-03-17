defmodule Value8BetsWeb.Auth.Pipeline do
  use Guardian.Plug.Pipeline,
    otp_app: :value8_bets,
    module: Value8BetsWeb.Auth.Guardian,
    error_handler: Value8BetsWeb.Auth.ErrorHandler

  plug Guardian.Plug.VerifyHeader, scheme: "Bearer"
  plug Guardian.Plug.EnsureAuthenticated
  plug Guardian.Plug.LoadResource
end 