defmodule DhcpTest.Behaviour.HandleInfoTest do
  #
  #  tests that the handle_info behaviour works as intended.
  #
  use ExUnit.Case, async: true

  @moduletag [handle_info: true, behaviour: true]

  @localhost {127, 0, 0, 1}

  describe "when overriding handle_info" do

    defmodule NonUdp do
      alias DhcpTest.Behaviour.CommonDhcp
      require CommonDhcp
      CommonDhcp.setup

      @impl true
      def handle_info(any, pid) do
        send(pid, {:recv, any})
        {:noreply, pid}
      end
    end

    test "we can trap non-udp packets" do
      conn = NonUdp.connect()
      send(conn.server, :ping)
      assert_receive {:recv, :ping}
    end

    defmodule YesUdp do
      alias DhcpTest.Behaviour.CommonDhcp
      require CommonDhcp
      CommonDhcp.setup

      @impl true
      def handle_info({:udp, _, _, _, data}, pid) do
        send(pid, {:recv, data})
        {:noreply, pid}
      end
    end

    test "we can trap a udp packet forwarded" do
      conn = YesUdp.connect()
      send(conn.server, {:udp, nil, nil, nil, "test"})
      assert_receive {:recv, "test"}
    end

    test "we can trap a generic udp message" do
      conn = YesUdp.connect()
      :gen_udp.send(conn.client_sock, @localhost, conn.server_port, "test")
      assert_receive {:recv, "test"}
    end

    defmodule ChgUdp do
      alias DhcpTest.Behaviour.CommonDhcp
      require CommonDhcp
      CommonDhcp.setup

      @impl true
      def handle_info({:chg, from, new}, old) do
        send(from, {:old_state, old})
        {:noreply, new}
      end
    end

    test "changes to the state are respected" do
      conn = ChgUdp.connect()
      send(conn.server, {:chg, self(), :foo})
      assert_receive {:old_state, _}
      send(conn.server, {:chg, self(), :bar})
      assert_receive {:old_state, :foo}
    end

  end
end
