defmodule ExDhcpTest.OtpTest do
  # module for making sure that we are otp-compliant.
  use ExUnit.Case, async: true

  alias ExDhcp.Packet

  @localhost {127, 0, 0, 1}

  @tag :one
  test "a supervised trivial has a dynamic_supervisor" do

    # create a client
    {:ok, sock} = :gen_udp.open(0, [:binary, active: true])
    {:ok, client_port} = :inet.port(sock)

    # create a supervised DHCP

    children = [
      {BasicDhcp, {%{},
        port: 0,
        client_port: client_port,
        broadcast_addr: @localhost,
        name: :test_dhcp}}]

    {:ok, _} = Supervisor.start_link(children, strategy: :one_for_one)

    Process.sleep(20)

    # retrieve the pid
    dhcp = Process.whereis(:test_dhcp)
    # retreive the port number
    {:ok, srv_port} = dhcp |> BasicDhcp.info |> :inet.port

    # send a discover
    dsc_pack = Packet.encode(BasicDhcp.discover())
    :gen_udp.send(sock, @localhost, srv_port, dsc_pack)

    # claim we got an offer
    resp1 = receive do {:udp, _, _, _, packet} -> packet end
    assert BasicDhcp.offer() == Packet.decode(resp1)

    # kill the dhcp server.
    Process.exit(dhcp, :kill)
    Process.sleep(20)

    # because we're restarting the dhcp server, and we initialized
    # it with "port 0", we expect it to rebind to a new port when
    # the DHCP server is rezzed by the supervisor.

    # re-retrieve the pid
    dhcp = assert Process.whereis(:test_dhcp)
    # retreive the port number
    {:ok, srv_port} = dhcp |> BasicDhcp.info |> :inet.port

    # send a request
    req_pack = Packet.encode(BasicDhcp.request())
    :gen_udp.send(sock, @localhost, srv_port, req_pack)

    # claim we got an acknowledge
    resp2 = receive do {:udp, _, _, _, packet} -> packet end
    assert BasicDhcp.acknowledge() == Packet.decode(resp2)
  end

end
