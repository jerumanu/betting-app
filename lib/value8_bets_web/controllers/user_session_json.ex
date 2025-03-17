defmodule Value8BetsWeb.UserSessionJSON do
  def created(%{user: user}) do
    %{
      status: :ok,
      data: %{
        id: user.id,
        email: user.email
      }
    }
  end

  def error(%{error_message: message}) do
    %{
      status: :error,
      message: message
    }
  end
end 