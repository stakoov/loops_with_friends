defmodule LoopsWithFriends.JamCollection do
  @moduledoc """
  Behavior defining the explicit contract for real and stub jam collections.
  """

  alias LoopsWithFriends.StatsCollection

  @callback new :: Map

  @callback refresh(jams :: Map, jam_id :: String.t, [String.t]) ::
              Agent.on_start

  @callback most_populated_jam_with_capacity_or_new(jams :: Map) :: String.t

  @callback jam_capacity?(jams :: Map, jam_id :: String.t) :: boolean

  @callback remove_user(jams :: Map, jam_id :: String.t, user_id :: String.t) ::
              Map

  @callback stats(jams :: Map) :: StatsCollection.t
end
