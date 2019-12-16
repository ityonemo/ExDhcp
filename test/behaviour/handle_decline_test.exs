defmodule DhcpTest.Behaviour.HandleDeclineTest do

  @moduledoc false

  use ExUnit.Case, async: true
  alias ExDhcp.Packet

  @moduletag [handle_decline: true, behaviour: true]

  @dhcp_decline %Packet{
    op: 1, xid: 0x3903_F326, chaddr: {0x00, 0x05, 0x3C, 0x04, 0x8D, 0x59},
    options: %{message_type: :decline, parameter_request_list: [1, 3, 15, 6]}
  }

  defmodule DeclSrvNoRespond do
    alias DhcpTest.Behaviour.CommonDhcp
    require CommonDhcp

    CommonDhcp.setup

    def handle_decline(pack, xid, chaddr, test_pid) do
      send(test_pid, {:decline, xid, pack, chaddr})
      {:norespond, :new_state}
    end
  end

  test "a dhcp decline message gets sent to handle_decline" do
    conn = DeclSrvNoRespond.connect()
    DeclSrvNoRespond.send_packet(conn, @dhcp_decline)

    assert_receive {:decline, xid, pack, chaddr}
    assert pack == @dhcp_decline
    assert xid == @dhcp_decline.xid
    assert chaddr == @dhcp_decline.chaddr
  end

  defmodule DeclSrvRespond do
    alias DhcpTest.Behaviour.CommonDhcp
    require CommonDhcp

    CommonDhcp.setup

    def handle_decline(pack, _, _, _) do
      # just reflect the packet, for simplicity.
      {:respond, pack, :new_state}
    end
  end

  test "a dhcp decline message can respond to the caller" do
    conn = DeclSrvRespond.connect()
    DeclSrvRespond.send_packet(conn, @dhcp_decline)

    assert_receive({:udp, _, _, _, binary})
  end

  defmodule DeclParserlessSrv do
    alias DhcpTest.Behaviour.CommonDhcp
    require CommonDhcp
    CommonDhcp.setup dhcp_options: []

    def handle_decline(pack, xid, chaddr, test_pid) do
      send(test_pid, {:decline, xid, pack, chaddr})
      {:respond, pack, :new_state}
    end
  end

  test "dhcp will respond to decline without options parsers" do
    conn = DeclParserlessSrv.connect()
    DeclParserlessSrv.send_packet(conn, @dhcp_decline)

    assert_receive {:decline, xid, pack, chaddr}
    # make sure that the inner contents are truly unencoded.
    assert %{55 => <<1, 3, 15, 6>>, 53 => <<4>>}
      == pack.options

    assert chaddr == @dhcp_decline.chaddr
    assert xid == @dhcp_decline.xid

    assert_receive {:udp, _, _, _, packet}

    assert @dhcp_decline == Packet.decode(packet)
  end

end
