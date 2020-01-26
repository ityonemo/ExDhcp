# Understanding your PXE Booter

ExDhcp ships with a "snooping" tool that you can use to understand how your PXE bootstrap system works.

Here's how to use it.

0. Turn off your DHCP server.
1. Run `mix snoop -s <prefix>` on your testing machine.
2. Boot up your target PXE system.
    - You should see your PXE request fly by, gather the saved DHCP request.
3. Turn off `snoop` and restart your DHCP server (usually that is `dnsmasq` or `ihc-dhcp-server`).
4. From a place where you can see the same server, use `mix dhcp <file>` to send the packet you collected
  and get the response back.

If you're writing a PXE boot system, you can use this system to write snapshot testing against your
PXE server. 