defmodule Value8BetsWeb.AdminLive.UserDetail do
  use Value8BetsWeb, :live_view
  alias Value8Bets.Accounts

  @impl true
  def mount(%{"id" => user_id}, _session, socket) do
    current_user = socket.assigns[:current_user]
    viewing_user_id = current_user && current_user.id || 2  # Default to 1 if no user
    user_with_bets = Accounts.get_user_with_bet_history(String.to_integer(user_id))

    {:ok,
     socket
     |> assign(:page_title, "User Details")
     |> assign(:user, user_with_bets)
     |> assign(:current_user, current_user)
     |> assign(:user_id, viewing_user_id)}
  end
end
