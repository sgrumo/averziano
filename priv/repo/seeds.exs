# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs
#
# Seed through the domain code interfaces (or `Ash.Seed.seed!/2` to bypass
# actions) so validations and defaults apply:
#
#     Averziano.Accounts.register_user!(
#       %{subject: "idp-subject", email: "admin@example.com", name: "Admin"},
#       authorize?: false
#     )
