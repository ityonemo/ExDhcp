defmodule DhcpTest.BasicTest do

  alias ExDhcp.Packet

  use ExUnit.Case

  @moduletag :basic

  @localhost {127, 0, 0, 1}

  describe "performs a full cycle" do
    test "successfully" do

      {:ok, sock} = :gen_udp.open(0, [:binary, active: true])
      {:ok, client_port} = :inet.port(sock)

      {:ok, srv} = BasicDhcp.start_link(%{}, port: 0,
        client_port: client_port, broadcast_addr: @localhost)
      {:ok, srv_port} = srv |> BasicDhcp.info |> :inet.port

      # send a discover
      dsc_pack = Packet.encode(BasicDhcp.discover())
      :gen_udp.send(sock, @localhost, srv_port, dsc_pack)

      # claim we got an offer
      resp1 = receive do {:udp, _, _, _, packet} -> packet end
      assert BasicDhcp.offer() == Packet.decode(resp1)

      # send a request
      req_pack = Packet.encode(BasicDhcp.request())
      :gen_udp.send(sock, @localhost, srv_port, req_pack)

      # claim we got an acknowledge
      resp2 = receive do {:udp, _, _, _, packet} -> packet end
      assert BasicDhcp.acknowledge() == Packet.decode(resp2)
    end
  end

end
