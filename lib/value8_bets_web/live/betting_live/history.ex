defmodule Value8BetsWeb.BettingLive.History do
  use Value8BetsWeb, :live_view
  alias Value8Bets.Betting

  @impl true
  def mount(_params, _session, socket) do
    current_user = socket.assigns[:current_user]
    user_id = current_user && current_user.id
    bets = Betting.list_user_bets_with_details(user_id)

    {:ok,
     socket
     |> assign(:page_title, "Betting History")
     |> assign(:current_user, current_user)
     |> assign(:user_id, user_id)
     |> assign(:bets, bets)}
  end

  @impl true
  def handle_params(_params, _uri, socket) do
    # Refresh bets when navigating to this page
    current_user = socket.assigns[:current_user]
    bets = if current_user, do: Betting.list_user_bets(current_user.id), else: []
    {:noreply, assign(socket, :bets, bets)}
  end

  @impl true
  def handle_event("cancel-bet", %{"id" => bet_id}, socket) do
    if socket.assigns.current_user do
      Betting.cancel_bet(bet_id, socket.assigns.current_user.id)
      # Refresh bets after cancellation
      bets = Betting.list_user_bets(socket.assigns.current_user.id)
      {:noreply, assign(socket, :bets, bets)}
    else
      {:noreply,
       socket
       |> put_flash(:error, "You must be logged in to cancel bets.")
       |> push_navigate(to: ~p"/users/log_in")}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
      <h1 class="text-2xl font-semibold mb-6">Betting History</h1>

      <div class="bg-white shadow overflow-hidden sm:rounded-md">
        <%= if @current_user do %>
          <%= if Enum.empty?(@bets) do %>
            <div class="p-4 text-center text-gray-500">
              You haven't placed any bets yet.
              <div class="mt-2">
                <.link
                  navigate={~p"/betting"}
                  class="text-indigo-600 hover:text-indigo-900"
                >
                  View available games to place a bet
                </.link>
              </div>
            </div>
          <% else %>
            <ul role="list" class="divide-y divide-gray-200">
              <%= for bet <- @bets do %>
                <li class="px-6 py-4">
                  <div class="flex items-center justify-between">
                    <div>
                      <div class="text-sm font-medium text-gray-900">
                        <%= bet.game.home_team %> vs <%= bet.game.away_team %>
                      </div>
                      <div class="text-sm text-gray-500">
                        Team Picked: <%= bet.team_picked %>
                      </div>
                      <div class="text-sm text-gray-500">
                        Amount: $<%= bet.amount %> (Odds: <%= bet.odds %>)
                      </div>
                      <div class="text-sm text-gray-500">
                        Potential Win: $<%= bet.potential_win %>
                      </div>
                      <%= if bet.status == "pending" do %>
                        <button
                          phx-click="cancel-bet"
                          phx-value-id={bet.id}
                          class="mt-2 text-sm text-red-600 hover:text-red-900"
                        >
                          Cancel Bet
                        </button>
                      <% end %>
                    </div>
                    <div>
                      <div class="text-sm text-gray-500">
                        <%= Calendar.strftime(bet.game.game_time, "%Y-%m-%d %H:%M UTC") %>
                      </div>
                      <div class={[
                        "mt-1 px-2 inline-flex text-xs leading-5 font-semibold rounded-full",
                        status_color(bet.status)
                      ]}>
                        <%= String.capitalize(bet.status) %>
                      </div>
                    </div>
                  </div>
                </li>
              <% end %>
            </ul>
          <% end %>
        <% else %>
        <% end %>
      </div>
    </div>
    """
  end

  defp status_color(status) do
    case status do
      "pending" -> "bg-yellow-100 text-yellow-800"
      "won" -> "bg-green-100 text-green-800"
      "lost" -> "bg-red-100 text-red-800"
      "cancelled" -> "bg-gray-100 text-gray-800"
    end
  end
end
