defmodule Value8BetsWeb.UserSessionHTML do
  use Value8BetsWeb, :html

  def new(assigns) do
    ~H"""
    <.simple_form :let={f} for={@conn.params["user"]} as={:user} action={~p"/users/log_in"}>
      <.error :if={@error_message}><%= @error_message %></.error>

      <.input field={f[:email]} type="email" label="Email" required />
      <.input field={f[:password]} type="password" label="Password" required />

      <:actions :let={f}>
        <.input field={f[:remember_me]} type="checkbox" label="Keep me logged in" />
      </:actions>
      <:actions>
        <.button phx-disable-with="Signing in..." class="w-full">
          Sign in <span aria-hidden="true">→</span>
        </.button>
      </:actions>
    </.simple_form>
    """
  end
end 