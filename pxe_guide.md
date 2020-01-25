# Understanding your PXE Booter

ExDhcp ships with a "snooping" tool that you can use to understand how your PXE bootstrap system works.

Here's how to use it.

1. Run `mix snoop` on your testing machine.
2. Boot up your target PXE system.
    - You should see your PXE request fly by.
3. Turn off `snoop` and boot your DHCP server (usually that is `dnsmasq` or `ihc-dhcp-server`).  
4. Fire up iex and use `ExDhcp.Packet.send/2` to send the packet and get the response back.

If you're writing a PXE boot system, you can use this system to write snapshot testing against your
PXE server. 

This workflow might change to be more efficient in the future; expect updates to hit over time.