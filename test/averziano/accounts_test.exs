defmodule Averziano.AccountsTest do
  use Averziano.DataCase, async: true

  alias Averziano.Accounts
  alias Averziano.Accounts.User
  alias Averziano.Errors

  describe "register_user/2" do
    test "registers the actor's own user from its subject" do
      assert {:ok, %User{} = user} =
               Accounts.register_user(%{email: "ada@example.com", name: "Ada"}, actor: actor())

      assert user.subject == actor().subject
    end

    test "rejects an email that is taken, case-insensitively" do
      generate(user(email: "Ada@Example.com"))

      assert {:error, error} =
               Accounts.register_user(%{email: "ada@example.com", name: "Dup"}, actor: actor())

      assert {:error, :unprocessable_entity, %{email: [message]}} =
               Errors.normalize({:error, error})

      assert message =~ "already been taken"
    end

    test "returns field errors for missing attributes" do
      assert {:error, error} = Accounts.register_user(%{}, actor: actor())

      assert {:error, :unprocessable_entity, errors} = Errors.normalize({:error, error})
      assert Map.has_key?(errors, :email)
      assert Map.has_key?(errors, :name)
    end

    test "validates the email format and field lengths" do
      params = %{email: "not-an-email", name: String.duplicate("a", 101)}

      assert {:error, error} = Accounts.register_user(params, actor: actor())

      assert {:error, :unprocessable_entity,
              %{email: ["must be a valid email address"], name: [name_message]}} =
               Errors.normalize({:error, error})

      assert name_message =~ "100"
    end

    test "only admins can register another subject" do
      params = %{email: "bob@example.com", name: "Bob", subject: "bob"}

      assert {:error, error} = Accounts.register_user(params, actor: actor())
      assert Errors.normalize({:error, error}) == {:error, :forbidden}

      assert {:ok, %User{subject: "bob"}} = Accounts.register_user(params, actor: admin())
    end
  end

  describe "reads" do
    test "non-admins only see their own user" do
      own = generate(user(subject: actor().subject))
      other = generate(user())

      assert {:ok, %{results: [%User{id: id}]}} = Accounts.list_users(actor: actor())
      assert id == own.id

      assert {:ok, %User{id: ^id}} = Accounts.get_user(own.id, actor: actor())

      assert {:error, error} = Accounts.get_user(other.id, actor: actor())
      assert Errors.normalize({:error, error}) == {:error, :not_found}
    end

    test "admins see every user" do
      users = generate_many(user(), 2)

      assert {:ok, %{results: listed}} = Accounts.list_users(actor: admin())
      assert Enum.sort(Enum.map(listed, & &1.id)) == Enum.sort(Enum.map(users, & &1.id))
    end
  end

  describe "list_users/1" do
    test "pages through users with a keyset cursor" do
      generate_many(user(), 3)

      assert {:ok, %{results: [_, _] = first, more?: true}} =
               Accounts.list_users(actor: admin(), page: [limit: 2])

      cursor = List.last(first).__metadata__.keyset

      assert {:ok, %{results: [last], more?: false}} =
               Accounts.list_users(actor: admin(), page: [limit: 2, after: cursor])

      refute last.id in Enum.map(first, & &1.id)
    end
  end

  describe "update_user/3 and delete_user/2" do
    test "non-admins can update and delete only their own user" do
      own = generate(user(subject: actor().subject, name: "Before"))
      other = generate(user())

      assert {:ok, %User{name: "After"}} =
               Accounts.update_user(own, %{name: "After"}, actor: actor())

      assert {:error, error} = Accounts.update_user(other, %{name: "Nope"}, actor: actor())
      assert Errors.normalize({:error, error}) == {:error, :forbidden}

      assert {:error, error} = Accounts.delete_user(other, actor: actor())
      assert Errors.normalize({:error, error}) == {:error, :forbidden}

      assert :ok = Accounts.delete_user(own, actor: actor())
      assert {:ok, %{results: [%User{id: other_id}]}} = Accounts.list_users(actor: admin())
      assert other_id == other.id
    end

    test "admins can update and delete any user" do
      user = generate(user())

      assert {:ok, %User{name: "Renamed"}} =
               Accounts.update_user(user, %{name: "Renamed"}, actor: admin())

      assert :ok = Accounts.delete_user(user, actor: admin())
    end
  end

  describe "without an actor" do
    test "reads are filtered to nothing and writes are rejected" do
      user = generate(user())

      # `no_filter_static_forbidden_reads?: false` turns a forbidden read into an empty result.
      assert {:ok, %{results: []}} = Accounts.list_users()

      # The subject comes from the actor, so the changeset is invalid before policies run.
      assert {:error, error} = Accounts.register_user(%{email: "x@example.com", name: "X"})
      assert {:error, :unprocessable_entity, %{subject: _}} = Errors.normalize({:error, error})

      assert {:error, error} = Accounts.update_user(user, %{name: "Nope"})
      assert Errors.normalize({:error, error}) == {:error, :forbidden}
    end
  end
end
