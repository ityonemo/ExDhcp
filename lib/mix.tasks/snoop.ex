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

  Defaults to listening to UDP ports 67 and 68.  In order to use this feature
  on most Linux machines, you'll need give your erlang virtual machine
  permission to listen on (< 1024) port numbers.  You can do this with the
  following command as superuser:

  ```bash
  setcap 'cap_net_bind_service,cap_net_raw=+ep' /usr/lib/erlang/erts-10.6.1/bin/beam.smp
  ```

  Note that the path to your `beam.smp` might be different.

  `Ctrl-c` will exit out of this mix task

  ### Using without `setcap`

  You can use this program without changing the permissions on `beam.smp`.
  Instead, supply the `--port` or `-p` parameter to the mix task, like so:

  ```bash
  mix snoop -p 6767
  ```

  And you'll want to forward UDP port activity from 67 and 68 to
  the snoop port 6767, you may use `iptables` as superuser to achieve this.
  Note that these changes may not persist on certain network activity
  (such as (libvirt)[https://libvirt.org/] creating or destroying a network),
  and certainly not on reboot.  Instrumenting these settings as permanent is
  beyond the scope of this guide.

  ```bash
  iptables -t nat -I PREROUTING -p udp --dport 67 -j DNAT --to :6767
  iptables -t nat -I PREROUTING -p udp --dport 68 -j DNAT --to :6767
  ```

  This will cause DHCP packets streaming to be logged to the console.

  ## Options

  - `--bind <device>` or `-b <device>` binds this mix task to a specific
    network device.
  - `--save <prefix>` or `-s <prefix>` saves packets (as erlang term binaries) to files
    with the given prefix
  """

  @shortdoc "snoop on DHCP packets as they go by"

  defmodule DhcpSnooper do

    @moduledoc false

    defstruct [:save]

    use ExDhcp
    require Logger

    def start_link(_init, opts \\ []) do
      ExDhcp.start_link(__MODULE__, struct(__MODULE__, opts), opts)
    end

    @impl true
    def init(config), do: {:ok, config}

    @impl true
    def handle_discover(packet, _, _, state) do
      saveinfo = save(packet, state)
      Logger.info(saveinfo <> inspect packet)
      {:norespond, state}
    end

    @impl true
    def handle_request(packet, _, _, state) do
      saveinfo = save(packet, state)
      Logger.info(saveinfo <> inspect packet)
      {:norespond, state}
    end

    @impl true
    def handle_decline(packet, _, _, state) do
      saveinfo = save(packet, state)
      Logger.info(saveinfo <> inspect packet)
      {:norespond, state}
    end

    @impl true
    def handle_inform(packet, _, _, state) do
      saveinfo = save(packet, state)
      Logger.info(saveinfo <> inspect packet)
      {:norespond, state}
    end

    @impl true
    def handle_release(packet, _, _, state) do
      saveinfo = save(packet, state)
      Logger.info(saveinfo <> inspect packet)
      {:norespond, state}
    end

    @impl true
    def handle_packet(packet, _, _, state) do
      saveinfo = save(packet, state)
      Logger.info(saveinfo <> inspect packet)
      {:norespond, state}
    end

    @impl true
    def handle_info({:udp, _, _, _, binary}, state) do
      unrolled_binary = binary
      |> :erlang.binary_to_list
      |> Enum.chunk_every(16)
      |> Enum.map(&Enum.join(&1, ", "))
      |> Enum.join("\n")

      Logger.warning("untrapped udp: \n <<#{unrolled_binary}>> ")
      {:noreply, state}
    end
    def handle_info(info, state) do
      Logger.warning(inspect info)
      {:noreply, state}
    end

    defp save(_, %{save: nil}), do: ""
    defp save(packet, %{save: prefix}) do
      last_index = prefix
      |> Path.expand
      |> Path.dirname
      |> File.ls!
      |> Enum.filter(&String.starts_with?(&1, prefix))
      |> Enum.map(fn filename ->
        filename |> Path.basename(".pkt") |> String.split("-") |> List.last |> String.to_integer
      end)
      |> Enum.max(fn -> 0 end)

      filename = "#{prefix}-#{last_index + 1}.pkt"
      File.write!(filename, :erlang.term_to_binary(packet))

      "(saved to #{filename}) "
    end
  end

  @doc false
  def run(params) do
    params = parse_params(params)

    case params[:port] do
      [] ->
        # the default should be start up on both standard DHCP port
        DhcpSnooper.start_link(:ok, Keyword.put(params, :port, 67))
        DhcpSnooper.start_link(:ok, Keyword.put(params, :port, 68))
      lst ->
        Enum.map(lst, fn port ->
          DhcpSnooper.start_link(:ok, Keyword.put(params, :port, port))
        end)
    end

    receive do after :infinity -> :ok end
  end

  @bind ~w(-b --bind)
  @port ~w(-p --port)
  @save ~w(-s --save)

  defp parse_params(lst, params \\ [port: []])
  defp parse_params([], params), do: params
  defp parse_params([switch, dev | rest], params) when switch in @bind do
    parse_params(rest, Keyword.put(params, :bind_to_device, dev))
  end
  defp parse_params([switch, n | rest], params) when switch in @port do
    port = [String.to_integer(n) | params[:port]]
    parse_params(rest, Keyword.put(params, :port, port))
  end
  defp parse_params([switch, file_prefix | rest], params) when switch in @save do
    parse_params(rest, Keyword.put(params, :save, file_prefix))
  end
  defp parse_params([_ | rest], params), do: parse_params(rest, params)

end
