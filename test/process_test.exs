defmodule MerkleTreeRoot.ProcessTest do
  use ExUnit.Case

  alias MerkleTreeRoot.Process

  import ExUnit.CaptureLog
  require Logger

  @fixture_path "test/fixtures/transactions.txt"

  describe "start/1" do
    test "returns correct merkletreeroot" do
      assert Process.start(@fixture_path) == ["a9ca5d20435beb6e93ffe03e2836dbb06afca9767dfdc3c931a3acd15fe0e09e"]
    end
  end

  describe "benchmark/1" do
    test "returns correct merkletreeroot speed measurament" do
      assert capture_log(fn -> 
        Process.benchmark(@fixture_path) 
      end) =~ "Queue finished in"
    end
  end
end
