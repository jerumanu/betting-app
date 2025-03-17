defmodule Value8BetsWeb.BettingLive.PlaceBet do
  use Value8BetsWeb, :live_view
  alias Value8Bets.{Betting, Accounts}
  alias Value8BetsWeb.UserAuth
  alias Value8BetsWeb.Auth.Guardian

  @impl true
  @doc """
  Mounts the LiveView for placing a bet.

  Checks if the user is authenticated. If authenticated, fetches the game details and assigns them to the socket.
  Otherwise, redirects to the login page.

  ## Parameters
    - params: The parameters map containing the game ID
    - session: The session map
    - socket: The LiveView socket

  ## Returns
    - The updated socket with game and user details assigned or a redirect to the login page
  """
  def mount(%{"id" => game_id}, _session, socket) do
    # Check if user is authenticated
    if socket.assigns[:current_user] do
      game = Betting.get_game!(game_id)
      current_user = socket.assigns.current_user

      {:ok,
       socket
       |> assign(:page_title, "Place Bet")
       |> assign(:game, game)
       |> assign(:user_bets, 1)
       |> assign(:bet, %{
         "amount" => "",
         "team_picked" => "",
         "odds" => nil,
         "game_id" => game_id,
         "user_id" => current_user.id
       })}
    else
      {:ok,
       socket
       |> put_flash(:error, "You must be logged in to place bets")
       |> redirect(to: ~p"/users/log_in?#{[return_to: "/betting/#{game_id}/place-bet"]}")}
    end
  end

  @impl true
  @doc """
  Handles the validation of bet parameters.

  Ensures the team picked is retained if not present in bet parameters and calculates the odds based on the team picked.

  ## Parameters
    - event: The event name (ignored)
    - params: The parameters map containing bet data
    - socket: The LiveView socket

  ## Returns
    - The updated socket with the validated bet parameters
  """
  def handle_event("validate", %{"bet" => bet_params}, socket) do
    IO.inspect(socket.assigns.user_id, label: "User ID in validate")
    IO.inspect(bet_params, label: "Validate Params")

    # Ensure team_picked is retained if not present in bet_params
    team_picked = Map.get(bet_params, "team_picked", socket.assigns.bet["team_picked"])

    odds =
      case team_picked do
        team when team == socket.assigns.game.home_team ->
          socket.assigns.game.odds_home

        team when team == socket.assigns.game.away_team ->
          socket.assigns.game.odds_away

        _ ->
          nil
      end

    bet =
      Map.merge(socket.assigns.bet, bet_params)
      |> Map.put("odds", odds)
      # Explicitly set team_picked
      |> Map.put("team_picked", team_picked)
      |> Map.put("user_id", socket.assigns.user_id)

    IO.inspect(bet, label: "Updated Bet")

    {:noreply, assign(socket, :bet, bet)}
  end

  @impl true
  @doc """
  Handles the placement of a bet.

  Validates the bet parameters and creates a new bet. If successful, redirects to the bet history page.
  Otherwise, displays an error message.

  ## Parameters
    - event: The event name (ignored)
    - params: The parameters map containing bet data
    - socket: The LiveView socket

  ## Returns
    - The updated socket with the bet placed or an error message
  """
  def handle_event("place-bet", %{"bet" => bet_params}, socket) do
    IO.inspect(socket.assigns.user_id, label: "User ID in place-bet")

    if socket.assigns.user_id do
      bet_params =
        Map.merge(bet_params, %{
          "game_id" => socket.assigns.game.id,
          "user_id" => socket.assigns.user_id,
          "odds" => socket.assigns.bet["odds"]
        })

      IO.inspect(bet_params, label: "Final Bet Params")

      case Betting.create_bet(bet_params) do
        {:ok, _bet} ->
          {:noreply,
           socket
           |> put_flash(:info, "Bet placed successfully!")
           |> push_navigate(to: ~p"/betting/history")}

        {:error, _changeset} ->
          {:noreply,
           socket
           |> put_flash(:error, "Error placing bet")
           |> push_navigate(to: ~p"/betting")}
      end
    else
      {:noreply,
       socket
       |> put_flash(:error, "You must be logged in to place bets")
       |> redirect(
         to: ~p"/users/log_in?#{[return_to: "/betting/#{socket.assigns.game.id}/place-bet"]}"
       )}
    end
  end

  @impl true
  @doc """
  Renders the LiveView template for placing a bet.

  ## Parameters
    - assigns: The assigns map containing game and bet data

  ## Returns
    - The rendered LiveView template
  """
  def render(assigns) do
    ~H"""
    <div class="max-w-2xl mx-auto px-4 sm:px-6 lg:px-8">
      <h1 class="text-2xl font-semibold mb-6">Place Bet</h1>

      <div class="bg-white shadow rounded-lg p-6">
        <div class="mb-6">
          <h2 class="text-lg font-medium">{@game.sport_type}</h2>
          <p class="mt-2">{@game.home_team} vs {@game.away_team}</p>
          <p class="mt-1 text-sm text-gray-500">
            Game time: {Calendar.strftime(@game.game_time, "%Y-%m-%d %H:%M UTC")}
          </p>
        </div>

        <.form for={%{}} phx-submit="place-bet" phx-change="validate">
          <div class="space-y-4">
            <div>
              <label class="block text-sm font-medium text-gray-700">Select Team</label>
              <select
                name="bet[team_picked]"
                phx-change="validate"
                value={@bet["team_picked"]}
                class="mt-1 block w-full pl-3 pr-10 py-2 text-base border-gray-300 focus:outline-none focus:ring-indigo-500 focus:border-indigo-500 sm:text-sm rounded-md"
              >
                <option value="">Select a team</option>
                <option value={@game.home_team}>
                  {@game.home_team} (Odds: {@game.odds_home})
                </option>
                <option value={@game.away_team}>
                  {@game.away_team} (Odds: {@game.odds_away})
                </option>
              </select>
            </div>

            <div>
              <label class="block text-sm font-medium text-gray-700">Bet Amount</label>
              <input
                type="number"
                name="bet[amount]"
                value={@bet["amount"]}
                class="mt-1 block w-full border-gray-300 rounded-md shadow-sm focus:ring-indigo-500 focus:border-indigo-500 sm:text-sm"
                step="0.01"
                min="0"
              />
            </div>

            <%= if @bet["odds"] do %>
              <div class="text-sm text-gray-600">
                Potential win: {if @bet["amount"] != "",
                  do: Decimal.mult(Decimal.new(@bet["amount"]), @bet["odds"]),
                  else: "0.00"}
              </div>
            <% end %>

            <button
              type="submit"
              class="w-full flex justify-center py-2 px-4 border border-transparent rounded-md shadow-sm text-sm font-medium text-white bg-indigo-600 hover:bg-indigo-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500"
              disabled={@bet["team_picked"] == "" || @bet["amount"] == ""}
            >
              Place Bet
            </button>
          </div>
        </.form>
      </div>
    </div>
    """
  end
end
