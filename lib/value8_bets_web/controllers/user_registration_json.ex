defmodule Value8BetsWeb.UserRegistrationJSON do
  def created(%{user: user}) do
    %{
      status: :ok,
      data: %{
        id: user.id,
        email: user.email
      }
    }
  end

  def error(%{changeset: changeset}) do
    %{
      status: :error,
      errors: Ecto.Changeset.traverse_errors(changeset, &translate_error/1)
    }
  end

  defp translate_error({msg, opts}) do
    Enum.reduce(opts, msg, fn {key, value}, acc ->
      String.replace(acc, "%{#{key}}", fn _ -> to_string(value) end)
    end)
  end
end 