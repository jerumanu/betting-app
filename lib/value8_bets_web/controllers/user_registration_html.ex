defmodule Value8BetsWeb.UserRegistrationHTML do
  use Value8BetsWeb, :html

  def new(assigns) do
    ~H"""
    <.simple_form :let={f} for={@changeset} action={~p"/users/register"}>
      <.error :if={@changeset.action}>
        Oops, something went wrong! Please check the errors below.
      </.error>

      <.input field={f[:email]} type="email" label="Email" required />
      <.input field={f[:password]} type="password" label="Password" required />

      <:actions>
        <.button phx-disable-with="Creating account..." class="w-full">Create an account</.button>
      </:actions>
    </.simple_form>
    """
  end
end 