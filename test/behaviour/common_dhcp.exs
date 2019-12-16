defmodule DhcpTest.Behaviour.CommonDhcp do

  # a "common" dhcp module that is used by several of the
  # handler testing suites

  defmacro setup(options \\ []) do
    quote do
      alias ExDhcp.Packet

      use ExDhcp, unquote(options)

      @localhost {127, 0, 0, 1}

      def connect(data \\ self()) do
        # open up a free port for the client.
        {:ok, client_sock} = :gen_udp.open(0, [:binary])
        {:ok, client_port} = :inet.port(client_sock)

        # start up a server on a free port and retrieve the value
        {:ok, srv} = ExDhcp.start_link(__MODULE__, data,
          port: 0, client_port: client_port, broadcast_addr: @localhost)
        {:ok, srv_port} = srv |> GenServer.call(:port) |> :inet.port
        # note that after this call, the state inside the GenServer will be
        # mutated to be the naked data we passed in.

        # save it as a "connection" object
        %{server: srv, server_port: srv_port, client_sock: client_sock}
      end

      def send_packet(%{server_port: srv_port, client_sock: sock}, packet) do
        pack_bin = Packet.encode(packet)
        :gen_udp.send(sock, @localhost, srv_port, pack_bin)
      end

      @impl true
      def init(data, port), do: {:ok, %{data: data, port: port}}
      @impl true
      def handle_discover(_, _, _, _), do: :error
      @impl true
      def handle_request(_, _, _, _), do: :error
      @impl true
      def handle_decline(_, _, _, _), do: :error

      @impl true
      # a one-time call that sneaks in and returns the port.  This is done
      # by the "connect" mechanism, so the tests should never see the inter-
      # mediate map form.
      def handle_call(:port, _from, state = %{port: port, data: data}) do
        {:reply, port, data}
      end

      defoverridable handle_discover: 4, handle_request: 4, handle_decline: 4
    end
  end
end
