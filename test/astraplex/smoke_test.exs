defmodule Astraplex.SmokeTest do
  @moduledoc false
  use Astraplex.DataCase, async: true

  test "test harness is operational" do
    assert true
  end

  test "factory module is available" do
    # Smokestack module is importable and functional
    assert function_exported?(Astraplex.Factory, :__info__, 1)
  end
end
