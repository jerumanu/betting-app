defmodule Value8Bets.Emails do
  import Swoosh.Email
  alias Value8Bets.Mailer

  def bet_confirmation(user, bet, game) do
    potential_win = Decimal.mult(Decimal.new(bet.amount), bet.odds)

    new()
    |> to({user.email, user.email})
    |> from({"Value8Bets", "notifications@value8bets.com"})
    |> subject("Your Bet Confirmation - #{game.home_team} vs #{game.away_team}")
    |> html_body("""
    <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;">
      <h2 style="color: #2563eb;">Bet Confirmation</h2>
      <p>Hello #{user.email},</p>
      <p>Your bet has been successfully placed:</p>
      <div style="background-color: #f3f4f6; padding: 16px; border-radius: 8px; margin: 16px 0;">
        <h3 style="margin-top: 0;">Game Details</h3>
        <p style="margin: 8px 0;">#{game.home_team} vs #{game.away_team}</p>
        <p style="margin: 8px 0;">Sport: #{game.sport_type}</p>
        <p style="margin: 8px 0;">Game Time: #{Calendar.strftime(game.game_time, "%B %d, %Y at %H:%M UTC")}</p>
      </div>
      <div style="background-color: #f3f4f6; padding: 16px; border-radius: 8px;">
        <h3 style="margin-top: 0;">Bet Details</h3>
        <ul style="list-style: none; padding: 0; margin: 0;">
          <li style="margin: 8px 0;">Team Selected: #{bet.team_picked}</li>
          <li style="margin: 8px 0;">Bet Amount: $#{bet.amount}</li>
          <li style="margin: 8px 0;">Odds: #{bet.odds}</li>
          <li style="margin: 8px 0; color: #059669;">Potential Win: $#{potential_win}</li>
        </ul>
      </div>
      <p style="margin-top: 24px;">Good luck!</p>
      <p style="color: #6b7280; font-size: 0.875rem;">
        This is an automated message, please do not reply to this email.
      </p>
    </div>
    """)
  end
end 