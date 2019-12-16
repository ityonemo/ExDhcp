defmodule DhcpTest.Behaviour.HandleDiscoverTest do

  @moduledoc false

  use ExUnit.Case, async: true
  alias ExDhcp.Packet

  @moduletag [handle_discover: true, behaviour: true]

  # packet request example taken from wikipedia:
  # https://en.wikipedia.org/wiki/Dynamic_Host_Configuration_Protocol#Discovery

  @dhcp_discover %Packet{
    op: 1, xid: 0x3903_F326, chaddr: {0x00, 0x05, 0x3C, 0x04, 0x8D, 0x59},
    options: %{message_type: :discover, requested_address: {192, 168, 1, 100},
    parameter_request_list: [1, 3, 15, 6]}
  }

  defmodule DiscSrvNoRespond do
    alias DhcpTest.Behaviour.CommonDhcp
    require CommonDhcp
    CommonDhcp.setup

    def handle_discover(pack, xid, chaddr, test_pid) do
      send(test_pid, {:discover, xid, pack, chaddr})
      {:norespond, :new_state}
    end
  end

  test "a dhcp discover message gets sent to handle_discover" do
    conn = DiscSrvNoRespond.connect
    DiscSrvNoRespond.send_packet(conn, @dhcp_discover)

    assert_receive {:discover, xid, pack, chaddr}
    assert pack == @dhcp_discover
    assert xid == @dhcp_discover.xid
    assert chaddr == @dhcp_discover.chaddr
  end

  defmodule DiscSrvRespond do
    alias DhcpTest.Behaviour.CommonDhcp
    require CommonDhcp
    CommonDhcp.setup

    def handle_discover(pack, _, _, _) do
      # for simplicity, just send back the same packet.
      {:respond, pack, :new_state}
    end
  end

  test "a dhcp discover message can respond to the caller" do
    conn = DiscSrvRespond.connect()
    DiscSrvRespond.send_packet(conn, @dhcp_discover)

    assert_receive {:udp, _, _, _, binary}
    assert @dhcp_discover == Packet.decode(binary)
  end

  defmodule DiscParserlessSrv do
    alias DhcpTest.Behaviour.CommonDhcp
    require CommonDhcp
    CommonDhcp.setup dhcp_options: []

    def handle_discover(pack, xid, chaddr, test_pid) do
      send(test_pid, {:discover, xid, pack, chaddr})
      {:respond, pack, :new_state}
    end
  end

  test "dhcp will respond to discover without options parsers" do
    conn = DiscParserlessSrv.connect()
    DiscParserlessSrv.send_packet(conn, @dhcp_discover)

    assert_receive {:discover, xid, pack, chaddr}
    # make sure that the inner contents are truly unencoded.
    assert %{50 => <<192, 168, 1, 100>>, 53 => <<1>>, 55 => <<1, 3, 15, 6>>}
      == pack.options

    assert xid == @dhcp_discover.xid
    assert chaddr == @dhcp_discover.chaddr

    assert_receive {:udp, _, _, _, packet}

    assert @dhcp_discover == Packet.decode(packet)
  end

end
