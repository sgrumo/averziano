defmodule Averziano.Errors do
  @moduledoc """
  Typed error tuples shared by the domain and web layers, plus the bridge that
  turns `Ash.Error` classes into them.
  """

  @type reason ::
          :bad_request
          | :unauthorized
          | :forbidden
          | :not_found
          | :conflict
          | :unprocessable_entity
          | :internal_server_error

  @type t :: {:error, reason()}
  @type t(details) :: {:error, reason(), details}
  @type field_errors :: %{optional(atom() | String.t()) => [String.t()]}

  @doc """
  Normalizes an Ash error tuple into a typed error tuple.

  Already-typed tuples and `{:ok, _}` results pass through untouched, so this
  can be used at the boundary of any function that mixes Ash calls with
  hand-written error returns.

    * `Ash.Error.Forbidden` -> `{:error, :forbidden}`
    * `Ash.Error.Invalid` containing a `NotFound` -> `{:error, :not_found}`
    * any other `Ash.Error.Invalid` -> `{:error, :unprocessable_entity, %{field => [message]}}`
    * `Ash.Error.Framework` / `Ash.Error.Unknown` -> `{:error, :internal_server_error}`
  """
  @spec normalize({:ok, result} | {:error, term()}) ::
          {:ok, result} | t() | t(field_errors())
        when result: any()
  def normalize({:ok, _} = ok), do: ok
  def normalize({:error, %Ash.Error.Forbidden{}}), do: {:error, :forbidden}
  def normalize({:error, %Ash.Error.Framework{}}), do: {:error, :internal_server_error}
  def normalize({:error, %Ash.Error.Unknown{}}), do: {:error, :internal_server_error}

  def normalize({:error, %Ash.Error.Invalid{errors: errors}}) do
    if Enum.any?(errors, &match?(%Ash.Error.Query.NotFound{}, &1)) do
      {:error, :not_found}
    else
      {:error, :unprocessable_entity, field_errors(errors)}
    end
  end

  def normalize({:error, error} = tuple) do
    if Ash.Error.ash_error?(error) do
      normalize({:error, Ash.Error.to_error_class(error)})
    else
      tuple
    end
  end

  @spec field_errors([Exception.t()]) :: field_errors()
  defp field_errors(errors) do
    errors
    |> Enum.flat_map(&field_error/1)
    |> Enum.group_by(fn {field, _message} -> field end, fn {_field, message} -> message end)
  end

  # Errors with an `AshPhoenix.FormData.Error` implementation (the same mapping
  # Ash forms use) carry a short, client-facing message such as "is required".
  # Anything else falls back to the exception message, minus Ash's bread crumbs.
  defp field_error(error) do
    if AshPhoenix.FormData.Error.impl_for(error) do
      error
      |> AshPhoenix.FormData.Error.to_form_error()
      |> List.wrap()
      |> Enum.map(fn {field, message, vars} ->
        {field || :base, interpolate(message || "is invalid", vars)}
      end)
    else
      [{error_field(error), fallback_message(error)}]
    end
  end

  defp error_field(%{field: field}) when is_atom(field) and not is_nil(field), do: field
  defp error_field(%{fields: [field | _]}) when is_atom(field), do: field
  defp error_field(_error), do: :base

  defp fallback_message(error) do
    error
    |> Map.replace(:bread_crumbs, [])
    |> Exception.message()
    |> String.trim()
  end

  defp interpolate(message, vars) do
    vars = Map.new(vars || [], fn {key, value} -> {to_string(key), value} end)

    Regex.replace(~r"%{(\w+)}", message, fn placeholder, key ->
      case Map.fetch(vars, key) do
        {:ok, value} -> to_text(value)
        :error -> placeholder
      end
    end)
  end

  defp to_text(value) when is_binary(value), do: value
  defp to_text(value) when is_list(value), do: Enum.map_join(value, ", ", &to_text/1)

  defp to_text(value) do
    if String.Chars.impl_for(value), do: to_string(value), else: inspect(value)
  end
end
