# ExDhcp

**An instrumentable DHCP Packet GenServer for Elixir**

_Largely inspired by [one_dhcpd][1]_

<a href="https://travis-ci.com/RstorLabs/ex_dhcp"><img src="https://api.travis-ci.com/RstorLabs/ex_dhcp.svg?branch=master"/></a>

## General Description

ExDhcp is an instrumentable DHCP GenServer, with an opinionated interface that 
takes after the `GenStage` design.  We couldn't use GPL licenced material 
in-house, so this project was derived from `one_dhcpcd`. 

At the moment, unlike `one_dhcpcd`, it does not implement a full DHCP server, 
but you *could* use ExDhcp to implement that functionality. ExDhcp is ideal for 
using DHCP functionality for some other purpose, such as [PXE][2] booting.

If you would like to easily implement distributed DHCP with custom code hooks 
for custom functionality, ExDhcp might be for you.

## Usage Notes

A minimal ExDhcp server implements the following three methods:
- `handle_discover`
- `handle_request`
- `handle_decline`

It might look something like this:

```elixir

defmodule MyDhcpServer do
  use ExDhcp
  alias ExDhcp.Packet

  def start_link(init_state) do
    ExDhcp.start_link(__MODULE__, init_state)
  end

  @impl true
  def init(init_state), do: {:ok, init_state}

  @impl true
  def handle_discover(request, xid, mac, state) do

    # insert code here. Should assign the unimplemented values 
    # for the response below:

    response = Packet.respond(request, :offer,
      yiaddr: issued_your_address,
      siaddr: server_ip_address,
      subnet_mask: subnet_mask,
      routers: [router],
      lease_time: lease_time,
      server: server_ip_address,
      domain_name_servers: [dns_server]))

    {:respond, response, new_state}
  end

  @impl true
  def handle_request(request, xid, mac, state) do
    
    # insert code here

    response = Packet.respond(request, :ack,
      yiaddr: issued_your_address ...)

    {:respond, response, state}
  end

  @impl true
  def handle_decline(request, xid, mac, state) do
    
    # insert code here

    response = Packet.respond(request, :offer,
      yiaddr: new_issued_address ...)

    {:respond, response, state}
  end

end

```
For more details, see the [documentation](https://hexdocs.pm/ex_dhcp).

### Deployment

The [DHCP protocol][3] listens in on port *67*, which is below the privileged 
port limit *(1024)* for most, e.g. Linux distributions.

ExDhcp doesn't presume that it will be running as root or have access to that 
port, and by default listens in to port *6767*.  If you expect to have access 
to privileged ports, you can set the port number in the module `start_link` 
options.

Alternatively, on most linux distributions you can use `iptables` to forward 
broadcast UDP from port *67* to port *6767* and vice versa.  The following 
incantations will achieve this:

```bash
iptables -t nat -A PREROUTING -p udp --src 0.0.0.0 --dport 67 -j DNAT --to 0.0.0.0:6767
iptables -t nat -A POSTROUTING -p udp --sport 6767 -j SNAT --to <server ip address>:67
```
_NB: If you're using a port besides *6767*, be sure to replace it with your chosen port._

On some Linux Distributions (we see this on **Ubuntu 18.04**), the `conntrack`
netfilter will be enabled by default, which will cause the server to throttle 
outgoing broadcast UDP packets, and this could adversely affect the success of 
your DHCP functionality.  If this is the case, you will see most of your UDP 
send events drop with an `{:error, :eperm}` error.  The DHCP module traps these 
and will remind you to check your conntrack settings.  We were unable to 
resolve this as desired except by downgrading to **Ubuntu 16.04** or switching
to **Alpine Linux**.


### Interface Binding

There may be situations where you would like to bind DHCP activity to a specific 
ethernet interface; this is settable in the module `start_link` options.

In order to successfully bind to the interface on Linux machines, do the 
following as superuser:

```bash
setcap cap_net_raw=ep /path/to/beam.smp
```

### Fun Tools

When implementing a DHCP service, you may want to spy on the requests and responses
in successful DHCP exchanges.  For that purpose, we provide a *DHCP snooper*.  To
run this snooper, forward both DHCP ports (67 and 68) to 6767 and run `mix snoop`.
This will log `%Packet{}` structs to the console that you may later use to generate
snapshot tests.

## Installation

Available from [Hex](https://hex.pm/packages/ex_dhcp). 
Documentation on [Hexdocs](https://hexdocs.pm/ex_dhcp/ExDhcp.html).
The package can be installed by adding `ex_dhcp` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:ex_dhcp, "~> 0.1.3"}
  ]
end
```

<!-- References -->
[1]: https://github.com/fhunleth/one_dhcpd
[2]: https://en.wikipedia.org/wiki/Preboot_Execution_Environment
[3]: https://en.wikipedia.org/wiki/Dynamic_Host_Configuration_Protocol
