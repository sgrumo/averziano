defmodule Averziano.Repo.Migrations.AddTelemetryUiEventsTable do
  @moduledoc """
  Creates TelemetryUI's `telemetry_ui_events` table. Hand-written because it is
  owned by the `telemetry_ui` library, not an Ash resource (see its README).
  """

  use Ecto.Migration

  @disable_migration_lock true
  @disable_ddl_transaction true

  def up do
    TelemetryUI.Backend.EctoPostgres.Migrations.up()
  end

  # `version: 1` rolls all the way back regardless of which version `up` reached.
  def down do
    TelemetryUI.Backend.EctoPostgres.Migrations.down(version: 1)
  end
end
