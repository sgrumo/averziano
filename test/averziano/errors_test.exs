defmodule Averziano.ErrorsTest do
  use ExUnit.Case, async: true

  alias Ash.Error.Changes.InvalidAttribute
  alias Ash.Error.Changes.Required
  alias Ash.Error.Invalid.InvalidPrimaryKey
  alias Averziano.Accounts.User
  alias Averziano.Errors

  @bread_crumbs ["Error returned from: Averziano.Accounts.User.register"]

  describe "normalize/1 field errors" do
    test "renders required attributes without bread crumbs" do
      error =
        Required.exception(
          field: :name,
          type: :attribute,
          resource: User,
          bread_crumbs: @bread_crumbs
        )

      assert normalize(error) == {:error, :unprocessable_entity, %{name: ["is required"]}}
    end

    test "interpolates vars of any type and leaves unknown placeholders alone" do
      error =
        InvalidAttribute.exception(
          field: :role,
          message: "must be one of %{values}, at most %{max} (%{unknown})",
          vars: [values: [:admin, "user"], max: 3]
        )

      assert normalize(error) ==
               {:error, :unprocessable_entity,
                %{role: ["must be one of admin, user, at most 3 (%{unknown})"]}}
    end

    test "falls back to the exception message, without bread crumbs, under :base" do
      error =
        InvalidPrimaryKey.exception(resource: User, value: "nope", bread_crumbs: @bread_crumbs)

      assert normalize(error) ==
               {:error, :unprocessable_entity, %{base: [~s(invalid primary key "nope" provided)]}}
    end
  end

  defp normalize(error), do: Errors.normalize({:error, Ash.Error.to_error_class(error)})
end
