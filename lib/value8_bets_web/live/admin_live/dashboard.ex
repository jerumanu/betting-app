defmodule Value8BetsWeb.AdminLive.Dashboard do
  use Value8BetsWeb, :live_view
  alias Value8Bets.Accounts
  alias Value8Bets.Betting

  @impl true
  def mount(_params, _session, socket) do
    current_user = socket.assigns[:current_user]
    user_id = current_user && current_user.id || 2  # Default to 2 if no user

    {:ok,
     socket
     |> assign(:page_title, "Admin Dashboard")
     |> assign(:users, Accounts.list_users_with_stats())
     |> assign(:profits, Accounts.calculate_profits())
     |> assign(:current_user, current_user)
     |> assign(:user_id, user_id)}
  end

  @impl true
  def handle_event("delete-user", %{"id" => user_id}, socket) do
    case Accounts.soft_delete_user(user_id) do
      {:ok, _user} ->
        {:noreply,
         socket
         |> put_flash(:info, "User deleted successfully")
         |> assign(:users, Accounts.list_users_with_stats())}

      {:error, _changeset} ->
        {:noreply,
         socket
         |> put_flash(:error, "Failed to delete user")}
    end
  end

  @impl true
  def handle_event("toggle-admin", %{"id" => user_id}, socket) do
    if Accounts.is_superuser?(socket.assigns.current_user) do
      user = Accounts.get_user!(user_id)

      case user.is_admin do
        true -> Accounts.revoke_admin_access(socket.assigns.current_user, user_id)
        false -> Accounts.grant_admin_access(socket.assigns.current_user, user_id)
      end

      {:noreply,
       socket
       |> put_flash(:info, "Admin status updated")
       |> assign(:users, Accounts.list_users_with_stats())}
    else
      {:noreply,
       socket
       |> put_flash(:error, "Unauthorized action")}
    end
  end
end
