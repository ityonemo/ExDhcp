defmodule Mix.Tasks.Snoop do

  use Mix.Task

  @moduledoc """
  A tool for snooping on DHCP transactions that are passing by this particular
  connected device.

  ## Usage

  Run this mix task on a device on the same layer-2 network as the network
  where you'd like to watch DHCP packets go by.  It's probably a good idea to
  *not* have this be the same machine that you're using to serve DHCP.

  ```bash
  mix snoop
  ```

  `Ctrl-c` will exit out of this mix task

  You'll probably want to set the following `iptables` settings before running:

  ```bash
  iptables -t nat -I PREROUTING -p udp --dport 67 -j DNAT --to :6767
  iptables -t nat -I PREROUTING -p udp --dport 68 -j DNAT --to :6767
  ```

  This will cause DHCP packets streaming to be logged to the console.
  """

  @shortdoc "snoop on DHCP packets as they go by"

  defmodule DhcpSnooper do

    @moduledoc false

    use ExDhcp
    require Logger

    @impl true
    def init(_), do: {:ok, :ok}

    @impl true
    def handle_discover(packet, _, _, :ok) do
      Logger.info(inspect packet)
      {:norespond, :ok}
    end

    @impl true
    def handle_request(packet, _, _, :ok) do
      Logger.info(inspect packet)
      {:norespond, :ok}
    end

    @impl true
    def handle_decline(packet, _, _, :ok) do
      Logger.info(inspect packet)
      {:norespond, :ok}
    end

    @impl true
    def handle_inform(packet, _, _, :ok) do
      Logger.info(inspect packet)
      {:norespond, :ok}
    end

     @impl true
     def handle_release(packet, _, _, :ok) do
       Logger.info(inspect packet)
       {:norespond, :ok}
     end

    @impl true
    def handle_packet(packet, _, _, :ok) do
      Logger.info(inspect packet)
      {:norespond, :ok}
    end

    @impl true
    def handle_info({:udp, _, _, _, binary}, :ok) do
      unrolled_binary = binary
      |> :erlang.binary_to_list
      |> Enum.chunk_every(16)
      |> Enum.map(&Enum.join(&1, ", "))
      |> Enum.join("\n")

      Logger.warn("untrapped udp: \n <<#{unrolled_binary}>> ")
      {:noreply, :ok}
    end
    def handle_info(info, :ok) do
      Logger.warn(inspect info)
      {:noreply, :ok}
    end
  end

  @doc false
  def run(_) do
    DhcpSnooper.start_link(:ok)
    receive do after :infinity -> :ok end
  end
end
