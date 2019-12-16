defmodule DhcpTest.Behaviour.HandleCallTest do
  #
  #  tests that the handle_call behaviour works as intended.
  #
  use ExUnit.Case, async: true

  @moduletag [handle_call: true, behaviour: true]

  describe "when overriding handle_call" do

    defmodule BasicCall do
      alias DhcpTest.Behaviour.CommonDhcp
      require CommonDhcp

      CommonDhcp.setup
      def handle_call(any, _from, test_pid) do
        send(test_pid, {:recv, any})
        {:reply, :foo, test_pid}
      end
    end

    test "handle_call is called, and correctly responds" do
      conn = BasicCall.connect()
      assert :foo == GenServer.call(conn.server, :bar)
      assert_receive {:recv, :bar}
    end

    defmodule ChgCall do
      alias DhcpTest.Behaviour.CommonDhcp
      require CommonDhcp

      CommonDhcp.setup
      def handle_call({:chg, any}, _from, old_state) do
        {:reply, old_state, any}
      end
    end

    test "changes to the state are respected" do
      conn = ChgCall.connect()
      GenServer.call(conn.server, {:chg, :foo})
      assert :foo == GenServer.call(conn.server, {:chg, :bar})
    end

  end
end
