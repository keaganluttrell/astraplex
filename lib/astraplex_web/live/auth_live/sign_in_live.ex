defmodule AstraplexWeb.AuthLive.SignInLive do
  @moduledoc "Custom sign-in LiveView with centered card layout."

  use AstraplexWeb, :live_view

  def mount(_params, _session, socket) do
    form =
      AshPhoenix.Form.for_action(Astraplex.Accounts.User, :sign_in_with_password, as: "user")

    {:ok, assign(socket, form: to_form(form), trigger_action: false)}
  end

  def handle_event("validate", %{"user" => params}, socket) do
    form =
      socket.assigns.form.source
      |> AshPhoenix.Form.validate(params, errors: false)
      |> to_form()

    {:noreply, assign(socket, form: form)}
  end

  def handle_event("submit", %{"user" => params}, socket) do
    form =
      socket.assigns.form.source
      |> AshPhoenix.Form.validate(params)

    {:noreply, assign(socket, form: to_form(form), trigger_action: form.valid?)}
  end

  def render(assigns) do
    ~H"""
    <div class="min-h-screen flex items-center justify-center bg-base-200">
      <div class="card w-96 bg-base-100 shadow-xl">
        <div class="card-body">
          <h1 class="text-2xl font-bold text-center mb-4">Astraplex</h1>

          <.form
            for={@form}
            phx-change="validate"
            phx-submit="submit"
            phx-trigger-action={@trigger_action}
            action={~p"/auth/user/password/sign_in"}
            method="POST"
          >
            <.form_input
              field={@form[:email]}
              type="email"
              label="Email"
              placeholder="you@example.com"
              required
            />
            <.form_input
              field={@form[:password]}
              type="password"
              label="Password"
              required
            />

            <p :if={@form.source.errors != []} class="mt-2 text-sm text-error">
              Invalid email or password
            </p>

            <div class="mt-6">
              <.button color="primary" block type="submit">
                Sign in
              </.button>
            </div>
          </.form>
        </div>
      </div>
    </div>
    """
  end
end
