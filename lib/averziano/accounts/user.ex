defmodule Averziano.Accounts.User do
  @moduledoc """
  An application user, linked to the identity provider through `subject` (the
  token's `sub` claim).

  Non-admin actors can only see and change the user whose `subject` matches
  their own; admins (see `Averziano.Auth.Actor`) can act on any user.
  """

  use Ash.Resource,
    otp_app: :averziano,
    domain: Averziano.Accounts,
    data_layer: AshPostgres.DataLayer,
    authorizers: [Ash.Policy.Authorizer]

  postgres do
    table "users"
    repo Averziano.Repo
  end

  actions do
    defaults [:read, :destroy]

    create :register do
      description "Registers the actor's own user. Admins may pass `subject` to register someone else."
      accept [:email, :name, :subject]
      change set_new_attribute(:subject, actor(:subject))
    end

    update :update do
      accept [:name]
    end
  end

  policies do
    bypass actor_attribute_equals(:admin?, true) do
      authorize_if always()
    end

    policy always() do
      authorize_if expr(subject == ^actor(:subject))
    end
  end

  attributes do
    uuid_primary_key :id

    attribute :subject, :string do
      allow_nil? false
      public? true
    end

    attribute :email, :ci_string do
      allow_nil? false
      public? true
    end

    attribute :name, :string do
      allow_nil? false
      public? true
    end

    timestamps()
  end

  identities do
    identity :unique_subject, [:subject]
    identity :unique_email, [:email]
  end
end
