defmodule DhcpTest.BasicTest do

  alias ExDhcp.Packet

  use ExUnit.Case

  @moduletag :basic

  defmodule BasicDhcp do
    use ExDhcp

    @impl true
    def init(_, socket), do: {:ok, socket}

    # offer packet request example taken from wikipedia:
    # https://en.wikipedia.org/wiki/Dynamic_Host_Configuration_Protocol#Offer

    @impl true
    def handle_discover(p, _, _, socket) do
      response = Packet.respond(p, :offer,
        yiaddr: {192, 168, 1, 100},
        siaddr: {192, 168, 1, 1},
        subnet_mask: {255, 255, 255, 0},
        routers: [{192, 168, 1, 1}],
        lease_time: 86_400,
        server: {192, 168, 1, 1},
        domain_name_servers: [
          {9, 7, 10, 15},
          {9, 7, 10, 16},
          {9, 7, 10, 18}])
      {:respond, response, socket}
    end

    @impl true
    def handle_request(p, _, _, socket) do
      response = Packet.respond(p, :ack,
        yiaddr: {192, 168, 1, 100},
        siaddr: {192, 168, 1, 1},
        subnet_mask: {255, 255, 255, 0},
        routers: [{192, 168, 1, 1}],
        lease_time: 86_400,
        server: {192, 168, 1, 1},
        domain_name_servers: [
          {9, 7, 10, 15},
          {9, 7, 10, 16},
          {9, 7, 10, 18}])
      {:respond, response, socket}
    end

    @impl true
    def handle_decline(_, _, _, socket), do: {:norespond, socket}

    def info(srv), do: GenServer.call(srv, :info)

    @impl true
    def handle_call(:info, _from, socket), do: {:reply, socket, socket}

  end

  # discovery packet request example taken from wikipedia:
  # https://en.wikipedia.org/wiki/Dynamic_Host_Configuration_Protocol#Discovery

  @dhcp_discover %Packet{
    op: 1, xid: 0x3903_F326, chaddr: {0x00, 0x05, 0x3C, 0x04, 0x8D, 0x59},
    options: %{message_type: :discover, requested_address: {192, 168, 1, 100},
    parameter_request_list: [1, 3, 15, 6]}
  }

  # offer packet request example taken from wikipedia:
  # https://en.wikipedia.org/wiki/Dynamic_Host_Configuration_Protocol#Offer

  @dhcp_offer %Packet{
    op: 2, xid: 0x3903_F326, chaddr: {0x00, 0x05, 0x3C, 0x04, 0x8D, 0x59},
    yiaddr: {192, 168, 1, 100}, siaddr: {192, 168, 1, 1},
    options: %{message_type: :offer, subnet_mask: {255, 255, 255, 0},
      routers: [{192, 168, 1, 1}], lease_time: 86_400,
      server: {192, 168, 1, 1}, domain_name_servers: [{9, 7, 10, 15},
                                                      {9, 7, 10, 16},
                                                      {9, 7, 10, 18}]}
  }

  # request packet request example taken from wikipedia:
  # https://en.wikipedia.org/wiki/Dynamic_Host_Configuration_Protocol#Request

  @dhcp_request %Packet{
    op: 1, xid: 0x3903_F326, chaddr: {0x00, 0x05, 0x3C, 0x04, 0x8D, 0x59},
    siaddr: {192, 168, 1, 1},
    options: %{message_type: :request, requested_address: {192, 168, 1, 100},
               server: {192, 168, 1, 1}}
  }

  # ack packet request example taken from wikipedia:
  # https://en.wikipedia.org/wiki/Dynamic_Host_Configuration_Protocol#Acknowledgement

  @dhcp_ack %Packet{
    op: 2, xid: 0x3903_F326, chaddr: {0x00, 0x05, 0x3C, 0x04, 0x8D, 0x59},
    yiaddr: {192, 168, 1, 100}, siaddr: {192, 168, 1, 1},
    options: %{message_type: :ack, subnet_mask: {255, 255, 255, 0},
      routers: [{192, 168, 1, 1}], lease_time: 86_400,
      server: {192, 168, 1, 1}, domain_name_servers: [{9, 7, 10, 15},
                                                      {9, 7, 10, 16},
                                                      {9, 7, 10, 18}]}
  }

  @localhost {127, 0, 0, 1}

  describe "performs a full cycle" do
    test "successfully" do

      {:ok, sock} = :gen_udp.open(0, [:binary, active: true])
      {:ok, client_port} = :inet.port(sock)

      {:ok, srv} = BasicDhcp.start_link(%{}, port: 0,
        client_port: client_port, broadcast_addr: @localhost)
      {:ok, srv_port} = srv |> BasicDhcp.info |> :inet.port

      dsc_pack = Packet.encode(@dhcp_discover)
      :gen_udp.send(sock, @localhost, srv_port, dsc_pack)

      resp1 = receive do {:udp, _, _, _, packet} -> packet end
      assert @dhcp_offer == Packet.decode(resp1)

      req_pack = Packet.encode(@dhcp_request)
      :gen_udp.send(sock, @localhost, srv_port, req_pack)

      resp2 = receive do {:udp, _, _, _, packet} -> packet end
      assert @dhcp_ack == Packet.decode(resp2)
    end
  end

end
