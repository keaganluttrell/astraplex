defmodule Astraplex.Accounts.Token do
  @moduledoc "Token resource for AshAuthentication session management."

  use Ash.Resource,
    data_layer: AshPostgres.DataLayer,
    extensions: [AshAuthentication.TokenResource],
    authorizers: [Ash.Policy.Authorizer],
    domain: Astraplex.Accounts

  postgres do
    table("tokens")
    repo(Astraplex.Repo)
  end

  policies do
    bypass AshAuthentication.Checks.AshAuthenticationInteraction do
      authorize_if(always())
    end
  end
end
