# ExDhcp Versions

## 0.1

### 0.1.0

- initial release

### 0.1.1

- add DHCP snooping mix task
- improve documentation
- some regression testing/bugfixes

### 0.1.2

- add ip binding option
- clean up DHCP packet pattern matching
- warn if conntrack is activated on some linux distros (e.g. **Ubuntu 18.04**)
- warn about stray UDP packets coming your way
- more regression testing/bugfixes

### 0.1.3

- tests now have no hardcoded udp ports.
- `init/2` now implemented which lets you use the server socket

