defmodule DhcpTest.Behaviour.HandleContinueTest do
  #
  #  tests that the handle_continue behaviour works as intended.
  #
  use ExUnit.Case, async: true

  @moduletag [handle_continue: true, behaviour: true]

  describe "when overriding handle_continue" do
    defmodule BasicCont do
      alias DhcpTest.Behaviour.CommonDhcp
      require CommonDhcp
      CommonDhcp.setup

      @impl true
      def handle_call(any, from, pid) do
        send(pid, {:recv, any})
        {:noreply, pid, {:continue, from}}
      end

      @impl true
      def handle_continue(from, pid) do
        send(pid, :continued)
        GenServer.reply(from, :bar)
        {:noreply, pid}
      end
    end

    test "basic continue functionality works" do
      conn = BasicCont.connect()

      assert :bar == GenServer.call(conn.server, :foo)
      assert_received({:recv, :foo})
      assert_received(:continued)
    end

    defmodule ChgCont do
      alias DhcpTest.Behaviour.CommonDhcp
      require CommonDhcp

      CommonDhcp.setup
      def handle_call(new_val, _from, state) do
        {:reply, state, state, {:continue, new_val}}
      end

      @impl true
      def handle_continue(new_val, _) do
        {:noreply, new_val}
      end
    end

    test "state-changing continue functionality works" do
      conn = ChgCont.connect()

      assert self() == GenServer.call(conn.server, :foo)
      assert :foo == GenServer.call(conn.server, :bar)
    end
  end
end
