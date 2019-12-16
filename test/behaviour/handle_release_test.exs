defmodule DhcpTest.Behaviour.HandleReleaseTest do

  @moduledoc false

  use ExUnit.Case, async: true
  alias ExDhcp.Packet

  @moduletag [handle_release: true, behaviour: true]

  @dhcp_release %Packet{
    op: 1, xid: 0x3903_F326, chaddr: {0x00, 0x05, 0x3C, 0x04, 0x8D, 0x59},
    ciaddr: {192, 168, 1, 100},
    siaddr: {192, 168, 1, 1},
    options: %{message_type: :release}
  }

  defmodule RelSrvNoRespond do
    alias DhcpTest.Behaviour.CommonDhcp
    require CommonDhcp
    CommonDhcp.setup

    def handle_release(pack, xid, chaddr, test_pid) do
      send(test_pid, {:release, xid, pack, chaddr})
      {:norespond, :new_state}
    end
  end

  test "a dhcp release message gets sent to handle_release" do
    conn = RelSrvNoRespond.connect()
    RelSrvNoRespond.send_packet(conn, @dhcp_release)

    assert_receive {:release, xid, pack, chaddr}
    assert pack == @dhcp_release
    assert xid == @dhcp_release.xid
    assert chaddr == @dhcp_release.chaddr
  end

  defmodule RelParserlessSrv do
    alias DhcpTest.Behaviour.CommonDhcp
    require CommonDhcp
    CommonDhcp.setup dhcp_options: []

    def handle_release(pack, xid, chaddr, test_pid) do
      send(test_pid, {:release, pack, xid, chaddr})
      {:norespond, :new_state}
    end
  end

  test "dhcp will respond to release without options parsers" do
    conn = RelParserlessSrv.connect()
    RelParserlessSrv.send_packet(conn, @dhcp_release)

    assert_receive {:release, pack, xid, chaddr}
    # make sure that the inner contents are truly unencoded.
    assert %{53 => <<7>>} == pack.options
    assert xid == @dhcp_release.xid
    assert chaddr == @dhcp_release.chaddr
  end

  defmodule RelNoSrv do
    alias DhcpTest.Behaviour.CommonDhcp
    require CommonDhcp
    CommonDhcp.setup
  end

  test "not implementing release is just a-ok" do
    conn = RelNoSrv.connect()
    RelNoSrv.send_packet(conn, @dhcp_release)

    # make sure that the inner contents are truly unencoded.
    Process.sleep(100)
    Process.alive?(conn.server)
  end

end
