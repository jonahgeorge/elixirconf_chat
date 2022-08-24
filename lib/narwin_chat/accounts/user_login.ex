defmodule NarwinChat.Accounts.UserLogin do
  use Ecto.Schema
  import Ecto.Changeset

  alias NarwinChat.Repo
  alias NarwinChat.Words
  alias NarwinChat.Accounts.User

  embedded_schema do
    field :email, :string
    field :login_code, :string, virtual: true
    field :login_code_confirmation, :string

    embeds_one :user, User
  end

  @optional_params ~w(login_code_confirmation)a
  @required_params ~w(email)a

  @allowed_params @optional_params ++ @required_params

  def changeset(user_login, params \\ %{}) do
    user_login
    |> cast(params, @allowed_params)
    |> validate_required(@required_params)
    |> validate_format(:email, ~r/@/)
    |> attach_login_code()
    |> attach_user()
  end

  def confirmation_changeset(user_login, params) do
    user_login
    |> cast(params, @allowed_params)
    |> check_login_confirmation()
  end

  ###

  defp attach_login_code(%Ecto.Changeset{valid?: true} = changeset) do
    put_change(changeset, :login_code, generate_login_code())
  end

  defp attach_login_code(changeset), do: changeset

  defp attach_user(%Ecto.Changeset{valid?: true} = changeset) do
    email = get_field(changeset, :email)
    user = Repo.get_by(User, email: email)

    case user do
      nil ->
        add_error(changeset, :user, "no such user")

      user ->
        put_change(changeset, :user, user)
    end
  end

  defp attach_user(changeset), do: changeset

  defp generate_login_code do
    Enum.join([Words.random_big(), Words.random_big(), Words.random_big()], "-")
  end

  defp check_login_confirmation(changeset) do
    code = get_field(changeset, :login_code)
    confirmation = get_field(changeset, :login_code_confirmation)

    if code == confirmation do
      changeset
    else
      add_error(changeset, :login_code_confirmation, "does not match login code")
    end
  end
end