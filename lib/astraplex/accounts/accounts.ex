defmodule Astraplex.Accounts do
  @moduledoc "Accounts domain for user management and authentication."

  use Ash.Domain, otp_app: :astraplex

  resources do
    resource(Astraplex.Accounts.User)
    resource(Astraplex.Accounts.Token)
  end
end
