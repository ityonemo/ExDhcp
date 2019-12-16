defmodule ExDhcpTest.RegressionTest do
  use ExUnit.Case

  alias ExDhcp.Packet

  @moduletag :regression

  ## regression test discovered 2 Jul 2019.
  ## Intel-NUC PXE booter emitted the following DHCP packet:

  @nuc_packet %Packet{
    chaddr: {244, 77, 48, 108, 147, 178},
    ciaddr: {0, 0, 0, 0},
    flags: 32_768,
    giaddr: {0, 0, 0, 0},
    hlen: 6,
    hops: 0,
    htype: 1,
    op: 1,
    options: %{
      client_ndi: {1, 3, 16},
      client_system: <<0, 7>>,
      max_message_size: 1472,
      message_type: :discover,
      parameter_request_list: [1, 2, 3, 4, 5, 6, 12, 13, 15, 17, 18, 22, 23, 28,
       40, 41, 42, 43, 50, 51, 54, 58, 59, 60, 66, 67, 97, 128, 129, 130, 131,
       132, 133, 134, 135],
      uuid_guid: <<0, 238, 195, 92, 194, 252, 183, 253, 21, 170, 124, 244, 77, 48,
        108, 147, 178>>,
      vendor_class_identifier: "PXEClient:Arch:00007:UNDI:003016"
    },
    secs: 28,
    siaddr: {0, 0, 0, 0},
    xid: 205_646_044,
    yiaddr: {0, 0, 0, 0}
  }

  #
  # this caused the DHCP system to crash because it wasn't expecting that the UUID/GUID
  # parameter could have an extra zero in front of it.
  #
  # mitigation:  just have uuid/guid parse as a naked string and let the operator decide
  # how to handle parsing UUID/GUID
  #

  test "nuc DHCP packet is handled correctly" do
    assert @nuc_packet == @nuc_packet
    |> Packet.encode
    |> :erlang.iolist_to_binary
    |> Packet.decode
  end

  ## regression test discovered 2 Jul 2019.
  ## A packet with a payload with both Basic and Pxe response items should have been encoded.
  ## it was not.  This replicates a minimal error condition.

  defmodule DualParser do
    use ExDhcp, dhcp_options: [ExDhcp.Options.Basic, ExDhcp.Options.Pxe]

    @testhost {192, 168, 0, 1}

    @impl true
    def init(_, socket), do: {:ok, socket}

    @impl true
    def handle_discover(packet, _xid, _mac, socket) do

      response = Packet.respond(packet, :offer,
         server: @testhost,     # basic parameter
         tftp_server: @testhost # pxe parameter
      )

      {:respond, response, socket}
    end

    @impl true
    def handle_request(_, _, _, _), do: {:norespond, :pumpkin}

    @impl true
    def handle_decline(_, _, _, _), do: {:norespond, :pumpkin}

    @impl true
    def handle_call(:socket, _from, socket), do: {:reply, socket, socket}

    def socket(srv), do: GenServer.call(srv, :socket)
  end

  #
  #  This was because the encode() functionality failed to encode across both modules.
  #
  @testhost {192, 168, 0, 1}
  @localhost {127, 0, 0, 1}

  @dhcp_discover %Packet{
    op: 1, xid: 0x3903_F326, chaddr: {0x00, 0x05, 0x3C, 0x04, 0x8D, 0x59},
    options: %{message_type: :discover, requested_address: {192, 168, 1, 100},
    parameter_request_list: [1, 3, 15, 6]}
  }

  test "multiple module encoding" do
    {:ok, sock} = :gen_udp.open(0, [:binary, active: true])
    {:ok, client_port} = :inet.port(sock)

    {:ok, srv} = DualParser.start_link(self(), port: 0, client_port: client_port, broadcast_addr: @localhost)
    {:ok, srv_port} = srv |> DualParser.socket |> :inet.port

    disc_pack = Packet.encode(@dhcp_discover)
    :gen_udp.send(sock, @localhost, srv_port, disc_pack)
    assert_receive {:udp, _, _, _, binary}
    assert %Packet{options: %{server: @testhost, tftp_server: @testhost}} =
      Packet.decode(binary, [ExDhcp.Options.Basic, ExDhcp.Options.Pxe])
  end

  defmodule NilParser do
    use ExDhcp

    @localhost {127, 0, 0, 1}

    @impl true
    def init(_, socket), do: {:ok, socket}

    @impl true
    def handle_discover(packet, _xid, _mac, socket) do

      response = Packet.respond(packet, :offer,
         server: @localhost,     # basic parameter
         client_system: nil     # pxe parameter
      )

      {:respond, response, socket}
    end

    @impl true
    def handle_request(_, _, _, _), do: {:norespond, :pumpkin}
    @impl true
    def handle_decline(_, _, _, _), do: {:norespond, :pumpkin}

    @impl true
    def handle_call(:socket, _from, socket), do: {:reply, socket, socket}

    def socket(srv), do: GenServer.call(srv, :socket)
  end

  @dhcp_discover %Packet{
    op: 1, xid: 0x3903_F326, chaddr: {0x00, 0x05, 0x3C, 0x04, 0x8D, 0x59},
    options: %{message_type: :discover, requested_address: {192, 168, 1, 100},
    parameter_request_list: [1, 3, 15, 6]}
  }

  test "nil module encoding" do
    {:ok, sock} = :gen_udp.open(0, [:binary, active: true])
    {:ok, client_port} = :inet.port(sock)

    {:ok, srv} = NilParser.start_link(self(), port: 0, client_port: client_port, broadcast_addr: @localhost)
    {:ok, srv_port} = srv |> NilParser.socket |> :inet.port

    disc_pack = Packet.encode(@dhcp_discover)
    :gen_udp.send(sock, @localhost, srv_port, disc_pack)
    assert_receive {:udp, _, _, _, binary}
    srv = Packet.decode(binary).options
    assert @localhost == srv.server
    refute Map.has_key?(srv, :client_system)
  end

  ## regression test discovered 8 Jul 2019.
  ## A PXE booting payload from the arch linux dnsmasq server was discovered to crash
  ## the PXE snooper on account of a poorly coded parser.

  @danger_binary :erlang.iolist_to_binary([
    <<2, 1, 6, 0, 179, 114, 174, 128, 0, 4, 128, 0, 0, 0, 0, 0, 10, 0, 17, 121,
    10, 0, 16, 129, 0, 0, 0, 0, 244, 77, 48, 108>>, <<147, 178, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0>>,
    <<0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0>>, <<0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 47, 97, 114,
    99, 104, 47, 98, 111, 111, 116, 47, 115, 121, 115, 47, 105, 110, 117, 120,
    47>>, <<108, 112, 120, 101, 108, 105, 110, 117, 120, 46, 48, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0>>, <<0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0>>, <<0,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0>>, <<0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 99, 130, 83, 99, 53,
    1, 2, 54, 4, 10, 0, 16, 129, 51, 4, 0, 0, 168, 192, 58>>, <<4, 0, 0, 84, 96,
    59, 4, 0, 0, 147, 168, 1, 4, 255, 255, 248, 0, 28, 4, 10, 0, 23, 255, 3, 4, 10,
    0, 16, 129, 66, 12, 49>>, <<48, 46, 48, 46, 49, 54, 46, 49, 50, 57, 0, 210, 6,
    47, 97, 114, 99, 104, 47, 209, 25, 98, 111, 111, 116, 47, 115, 121, 115, 108,
    105, 110>>, <<117, 120, 47, 108, 112, 120, 101, 108, 105, 110, 117, 120, 46,
    48, 255>>])

  test "dangerous binary" do
    assert %Packet{} = Packet.decode(@danger_binary)
  end

end
