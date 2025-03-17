defmodule Value8BetsWeb.AdminLive.Users do
  use Value8BetsWeb, :live_view
  alias Value8Bets.Accounts

  @impl true
  def mount(_params, session, socket) do
    if user = socket.assigns[:current_user], 
       do: check_admin_access(socket, user),
       else: deny_access(socket)
  end

  defp check_admin_access(socket, user) do
    if Accounts.is_admin?(user) do
      users = Accounts.list_users_with_bets()
      profits = Accounts.calculate_profits()
      
      {:ok,
       socket
       |> assign(:users, users)
       |> assign(:profits, profits)
       |> assign(:current_user, user)}
    else
      deny_access(socket)
    end
  end

  defp deny_access(socket) do
    {:ok,
     socket
     |> put_flash(:error, "Unauthorized access")
     |> redirect(to: ~p"/")}
  end

  @impl true
  def handle_event("delete-user", %{"id" => user_id}, socket) do
    case Accounts.soft_delete_user(user_id) do
      {:ok, _user} ->
        {:noreply,
         socket
         |> put_flash(:info, "User deleted successfully")
         |> assign(:users, Accounts.list_users_with_bets())}

      {:error, _changeset} ->
        {:noreply,
         socket
         |> put_flash(:error, "Failed to delete user")}
    end
  end

  @impl true
  def handle_event("toggle-admin", %{"id" => user_id}, socket) do
    current_user = socket.assigns.current_user
    
    if Accounts.is_superuser?(current_user) do
      user = Accounts.get_user!(user_id)
      
      case user.is_admin do
        true -> Accounts.revoke_admin_access(current_user, user_id)
        false -> Accounts.grant_admin_access(current_user, user_id)
      end
      
      {:noreply,
       socket
       |> put_flash(:info, "Admin status updated")
       |> assign(:users, Accounts.list_users_with_bets())}
    else
      {:noreply,
       socket
       |> put_flash(:error, "Unauthorized action")}
    end
  end
end 