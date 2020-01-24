defmodule BasicDhcp do
  use ExDhcp

  alias ExDhcp.Packet

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

  # discovery packet request example taken from wikipedia:
  # https://en.wikipedia.org/wiki/Dynamic_Host_Configuration_Protocol#Discovery

  @dhcp_discover %Packet{
    op: 1, xid: 0x3903_F326, chaddr: {0x00, 0x05, 0x3C, 0x04, 0x8D, 0x59},
    options: %{message_type: :discover, requested_address: {192, 168, 1, 100},
    parameter_request_list: [1, 3, 15, 6]}
  }

  def discover, do: @dhcp_discover

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

  def offer, do: @dhcp_offer

  # request packet request example taken from wikipedia:
  # https://en.wikipedia.org/wiki/Dynamic_Host_Configuration_Protocol#Request

  @dhcp_request %Packet{
    op: 1, xid: 0x3903_F326, chaddr: {0x00, 0x05, 0x3C, 0x04, 0x8D, 0x59},
    siaddr: {192, 168, 1, 1},
    options: %{message_type: :request, requested_address: {192, 168, 1, 100},
               server: {192, 168, 1, 1}}
  }

  def request, do: @dhcp_request

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

  def acknowledge, do: @dhcp_ack
end
