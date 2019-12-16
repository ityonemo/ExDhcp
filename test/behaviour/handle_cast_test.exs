defmodule DhcpTest.Behaviour.HandleCastTest do
  #
  #  tests that the handle_call behaviour works as intended.
  #
  use ExUnit.Case, async: true

  @moduletag [handle_cast: true, behaviour: true]

  describe "when overriding handle_cast" do

    defmodule BasicCast do
      alias DhcpTest.Behaviour.CommonDhcp
      require CommonDhcp
      CommonDhcp.setup

      @impl true
      def handle_cast(any, test_pid) do
        send(test_pid, {:recv, any})
        {:noreply, test_pid}
      end
    end

    test "handle_cast is called" do
      conn = BasicCast.connect()
      GenServer.cast(conn.server, :bar)
      assert_receive {:recv, :bar}
    end

    defmodule ChgCast do
      alias DhcpTest.Behaviour.CommonDhcp
      require CommonDhcp
      CommonDhcp.setup

      @impl true
      def handle_cast({:chg, from, new_state}, old_state) do
        send(from, {:was, old_state})
        {:noreply, new_state}
      end
    end

    test "changes to the state are respected" do
      conn = ChgCast.connect()
      GenServer.cast(conn.server, {:chg, self(), :foo})
      assert_receive {:was, _}
      GenServer.cast(conn.server, {:chg, self(), :bar})
      assert_receive {:was, :foo}
    end

  end
end
