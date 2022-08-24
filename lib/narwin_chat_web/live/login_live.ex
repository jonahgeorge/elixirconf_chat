defmodule NarwinChatWeb.LoginLive do
  use NarwinChatWeb, :live_view
  use NarwinChatWeb.LiveViewNativeHelpers, template: "login_live"
  require Logger

  alias NarwinChat.{Accounts, Repo}

  on_mount {NarwinChat.LiveAuth, {false, :cont, {:redirect, NarwinChatWeb.LobbyLive}}}

  @impl true
  def render(assigns) do
    render_native(assigns)
  end

  @impl true
  def mount(params, _session, socket) do
    changeset = Accounts.new_login_changeset(params)

    {:ok,
     assign(socket,
       changeset: changeset,
       errors: [],
       submit_event: "login"
     )}
  end

  @impl true
  def handle_event("login", %{"email" => _} = login_params, socket) do
    # native doesn't convert foo[bar] to %{"foo" => %{"bar" => ...}}, so the fields have different names
    handle_event("login", %{"user_login" => login_params}, socket)
  end

  @impl true
  def handle_event("login", %{"user_login" => login_params}, socket) do
    login_params
    |> Accounts.new_login_changeset()
    |> Accounts.request_login_link()
    |> case do
      {:ok, changeset} ->
        Logger.info("[#{inspect(__MODULE__)}] - Login Link Requested - #{inspect(changeset)}")

        {:noreply,
         assign(socket,
           changeset: changeset,
           errors: [],
           submit_event: "confirm_login"
         )}

      {:error, errors} ->
        {:noreply,
         assign(socket,
           errors: errors,
           submit_event: "login"
         )}
    end
  end

  @impl true
  def handle_event("confirm_login", %{"login_code_confirmation" => _} = login_params, socket) do
    handle_event("confirm_login", %{"user_login" => login_params}, socket)
  end

  @impl true
  def handle_event("confirm_login", %{"user_login" => login_params}, socket) do
    changeset = Accounts.confirm_login_changeset(socket.assigns.changeset, login_params)

    if changeset.valid? do
      Accounts.new_token_changeset(%{
        user_id: Ecto.Changeset.get_field(changeset, :user).id
      })
      |> Repo.insert()
      |> case do
        {:error, changeset} ->
          {:noreply, assign(socket, errors: changeset.errors, submit_event: "confirm_login")}

        {:ok, %Accounts.UserToken{token: token}} ->
          case socket.assigns.platform do
            :ios ->
              {:noreply, push_event(socket, "login_token", %{token: token})}

            :web ->
              {:noreply,
               redirect(socket,
                 to: Routes.login_path(NarwinChatWeb.Endpoint, :login, login_token: token)
               )}
          end
      end
    else
      {:noreply, assign(socket, errors: changeset.errors, submit_event: "confirm_login")}
    end
  end
end