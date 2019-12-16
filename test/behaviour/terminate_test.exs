defmodule DhcpTest.Behaviour.TerminateTest do
  #
  #  tests that the handle_info behaviour works as intended.
  #
  use ExUnit.Case, async: true

  @moduletag [terminate: true, behaviour: true]

  describe "when overriding terminate" do

    defmodule Term do
      alias DhcpTest.Behaviour.CommonDhcp
      require CommonDhcp
      CommonDhcp.setup

      @impl true
      def handle_info(:end_it, pid) do
        {:stop, :normal, pid}
      end

      @impl true
      def terminate(reason, pid) do
        send(pid, {:dying, reason})
        :foo
      end
    end

    test "we can trap the termination event without bleeding state" do
      conn = Term.connect()
      send(conn.server, :end_it)
      assert_receive {:dying, :normal}
    end
  end
end
