defmodule Value8BetsWeb.BettingLive.Index do
  use Value8BetsWeb, :live_view
  alias Value8Bets.Betting

  @impl true
  def mount(_params, session, socket) do
    games = Betting.list_games()
    {:ok, assign(socket, games: games, current_user: session["current_user"])}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Available Games")
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
      <h1 class="text-2xl font-semibold mb-6">Available Games</h1>
      
      <div class="grid grid-cols-1 gap-4 sm:grid-cols-2 lg:grid-cols-3">
        <%= for game <- @games do %>
          <div class="bg-white shadow rounded-lg p-6">
            <div class="text-lg font-medium">
              <%= game.sport_type %>
            </div>
            <div class="mt-2">
              <div class="flex justify-between items-center">
                <span><%= game.home_team %></span>
                <span class="text-blue-600">(<%= game.odds_home %>)</span>
              </div>
              <div class="flex justify-between items-center mt-2">
                <span><%= game.away_team %></span>
                <span class="text-blue-600">(<%= game.odds_away %>)</span>
              </div>
            </div>
            <div class="mt-4">
              <.link
                navigate={~p"/betting/#{game.id}/place-bet"}
                class="inline-flex items-center px-4 py-2 border border-transparent text-sm font-medium rounded-md text-white bg-indigo-600 hover:bg-indigo-700"
              >
                Place Bet
              </.link>
            </div>
          </div>
        <% end %>
      </div>
    </div>
    """
  end
end 