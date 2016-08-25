defmodule LoopsWithFriends.LoopCyclerTest do
  use ExUnit.Case

  alias LoopsWithFriends.LoopCycler

  setup do
    LoopCycler.start_link(name: __MODULE__)

    {:ok, next_loop: fn -> LoopCycler.next_loop(__MODULE__) end}
  end

  describe "`.next_loop`" do
    test "cycles the loop list", %{next_loop: next_loop} do
      assert next_loop.() == "80s_Back_Beat"
      assert next_loop.() == "Amsterdam_Layers"
      assert next_loop.() == "Synthetic_String_Bass"
      assert next_loop.() == "Degenerating_Pitch_Vox"
      assert next_loop.() == "Kyoto_Night_Guitar"
      assert next_loop.() == "Conga_Groove"
      assert next_loop.() == "African_Rain_Caxixi"
      assert next_loop.() == "80s_Back_Beat"
    end
  end
end
