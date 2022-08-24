defmodule NarwinChat.Accounts.User do
  use Ecto.Schema
  import Ecto.Changeset

  @type t() :: %__MODULE__{
          id: integer(),
          first_name: String.t(),
          last_name: String.t(),
          email: String.t(),
          is_admin: boolean(),
          is_shadow_banned: boolean(),
          inserted_at: NaiveDateTime.t(),
          updated_at: NaiveDateTime.t()
        }

  schema "users" do
    field :first_name, :string
    field :last_name, :string
    field :email, :string
    field :is_admin, :boolean, default: false
    field :is_shadow_banned, :boolean, default: false

    timestamps()
  end

  @optional_params ~w(is_admin)a
  @required_params ~w(first_name last_name email is_admin)a
  @allowed_params @required_params ++ @optional_params

  def changeset(user, params) do
    user
    |> cast(params, @allowed_params)
    |> validate_required(@required_params)
    |> validate_format(:email, ~r/@/)
    |> unique_constraint(:email)
  end
end