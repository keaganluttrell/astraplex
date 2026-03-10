defmodule Astraplex.System.HealthTest do
  use Astraplex.DataCase

  describe "Health :check action" do
    test "returns a health struct with expected fields" do
      result = Ash.run_action!(Astraplex.System.Health, :check)

      assert %Astraplex.System.Health{} = result
      assert result.status == :healthy
      assert is_binary(result.version) and result.version != ""
      assert is_integer(result.uptime_seconds) and result.uptime_seconds >= 0
      assert is_binary(result.node)
    end
  end
end
