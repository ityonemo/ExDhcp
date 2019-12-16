defmodule DhcpTest.Behaviour.HandleInformTest do

  @moduledoc false

  use ExUnit.Case, async: true
  alias ExDhcp.Packet

  @moduletag [handle_inform: true, behaviour: true]

  @dhcp_inform %Packet{
    op: 1, xid: 0x3903_F326, chaddr: {0x00, 0x05, 0x3C, 0x04, 0x8D, 0x59},
    options: %{message_type: :inform, parameter_request_list: [1, 3, 15, 6]}
  }

  defmodule InfSrvNoRespond do
    alias DhcpTest.Behaviour.CommonDhcp
    require CommonDhcp
    CommonDhcp.setup

    def handle_inform(pack, xid, chaddr, test_pid) do
      send(test_pid, {:inform, xid, pack, chaddr})
      {:norespond, :new_state}
    end
  end

  test "a dhcp inform message gets sent to handle_inform" do
    conn = InfSrvNoRespond.connect()
    InfSrvNoRespond.send_packet(conn, @dhcp_inform)

    assert_receive {:inform, xid, pack, chaddr}
    assert pack == @dhcp_inform
    assert xid == @dhcp_inform.xid
    assert chaddr == @dhcp_inform.chaddr
  end

  defmodule InfSrvRespond do
    alias DhcpTest.Behaviour.CommonDhcp
    require CommonDhcp
    CommonDhcp.setup

    def handle_inform(pack, _, _, _) do
      # for simplicity, just send back the same packet.
      {:respond, pack, :new_state}
    end
  end

  test "a dhcp inform message can respond to the caller" do
    conn = InfSrvRespond.connect()
    InfSrvRespond.send_packet(conn, @dhcp_inform)

    assert_receive {:udp, _, _, _, binary}
    assert @dhcp_inform == Packet.decode(binary)
  end

  defmodule InfParserlessSrv do
    alias DhcpTest.Behaviour.CommonDhcp
    require CommonDhcp
    CommonDhcp.setup dhcp_options: []

    def handle_inform(pack, xid, chaddr, test_pid) do
      send(test_pid, {:inform, pack, xid, chaddr})
      {:norespond, :new_state}
    end
  end

  test "dhcp will respond to inform without options parsers" do
    conn = InfParserlessSrv.connect
    InfParserlessSrv.send_packet(conn, @dhcp_inform)

    assert_receive {:inform, pack, xid, chaddr}
    # make sure that the inner contents are truly unencoded.
    assert %{53 => <<8>>, 55 => <<1, 3, 15, 6>>} == pack.options
    assert xid == @dhcp_inform.xid
    assert chaddr == @dhcp_inform.chaddr
  end

  defmodule InfNoSrv do
    alias DhcpTest.Behaviour.CommonDhcp
    require CommonDhcp
    CommonDhcp.setup
  end

  test "not implementing inform is just a-ok" do
    conn = InfNoSrv.connect()
    InfNoSrv.send_packet(conn, @dhcp_inform)

    # make sure that the inner contents are truly unencoded.
    Process.sleep(100)
    Process.alive?(conn.server)
  end

end
