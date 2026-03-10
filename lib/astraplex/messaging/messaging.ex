defmodule Astraplex.Messaging do
  @moduledoc "Messaging domain for channels, conversations, and messages."

  use Ash.Domain, otp_app: :astraplex

  resources do
    resource(Astraplex.Messaging.Channel)
    resource(Astraplex.Messaging.Conversation)
    resource(Astraplex.Messaging.ConversationMembership)
    resource(Astraplex.Messaging.Membership)
    resource(Astraplex.Messaging.Message)
  end
end
