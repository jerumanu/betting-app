defmodule Value8BetsWeb.UserSettingsController do
  use Value8BetsWeb, :controller

  def edit(conn, _params) do
    render(conn, :edit)
  end

  def confirm_email(conn, %{"token" => token}) do
    conn
    |> put_flash(:info, "Email confirmed successfully.")
    |> redirect(to: ~p"/users/settings")
  end
end 