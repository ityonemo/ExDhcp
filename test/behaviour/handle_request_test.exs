defmodule DhcpTest.Behaviour.HandleRequestTest do

  @moduledoc false

  use ExUnit.Case, async: true
  alias ExDhcp.Packet

  @moduletag [handle_request: true, behaviour: true]

  # packet request example taken from wikipedia:
  # https://en.wikipedia.org/wiki/Dynamic_Host_Configuration_Protocol#Request

  @dhcp_request %Packet{
    op: 1, xid: 0x3903_F326, chaddr: {0x00, 0x05, 0x3C, 0x04, 0x8D, 0x59},
    siaddr: {192, 168, 1, 1},
    options: %{message_type: :request, requested_address: {192, 168, 1, 100},
               server: {192, 168, 1, 1}}
  }

  defmodule ReqSrvNoRespond do
    alias DhcpTest.Behaviour.CommonDhcp
    require CommonDhcp

    CommonDhcp.setup

    def handle_request(pack, xid, chaddr, test_pid) do
      send(test_pid, {:request, xid, pack, chaddr})
      {:norespond, :new_state}
    end
  end

  test "a dhcp request message gets sent to handle_request" do
    conn = ReqSrvNoRespond.connect()
    ReqSrvNoRespond.send_packet(conn, @dhcp_request)

    assert_receive {:request, xid, pack, chaddr}
    assert pack == @dhcp_request
    assert xid == @dhcp_request.xid
    assert chaddr == @dhcp_request.chaddr
  end

  defmodule ReqSrvRespond do
    alias DhcpTest.Behaviour.CommonDhcp
    require CommonDhcp

    CommonDhcp.setup

    def handle_request(pack, _, _, _) do
      # for simplicity, just send back the same packet.
      {:respond, pack, :new_state}
    end
  end

  test "a dhcp request message can respond to the caller" do
    conn = ReqSrvRespond.connect()
    ReqSrvRespond.send_packet(conn, @dhcp_request)

    assert_receive {:udp, _, _, _, binary}
    assert @dhcp_request == Packet.decode(binary)
  end

  defmodule ReqParserlessSrv do
    alias DhcpTest.Behaviour.CommonDhcp
    require CommonDhcp
    CommonDhcp.setup dhcp_options: []

    def handle_request(pack, xid, chaddr, test_pid) do
      send(test_pid, {:request, pack, xid, chaddr})
      {:respond, pack, :new_state}
    end
  end

  test "dhcp will respond to request without options parsers" do
    conn = ReqParserlessSrv.connect()
    ReqParserlessSrv.send_packet(conn, @dhcp_request)

    assert_receive {:request, pack, xid, chaddr}
    # make sure that the inner contents are truly unencoded.
    assert %{50 => <<192, 168, 1, 100>>, 53 => <<3>>, 54 => <<192, 168, 1, 1>>}
      == pack.options

    assert xid == @dhcp_request.xid
    assert chaddr == @dhcp_request.chaddr

    assert_receive {:udp, _, _, _, packet}

    assert @dhcp_request == Packet.decode(packet)
  end

end
