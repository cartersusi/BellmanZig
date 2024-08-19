Bellman Ford implementation in Zig

```sh
---@mac ~/BellmanZig (main)> ./zig-out/bin/BellmanZig
Targets: { EUR, INR, MXN, PLN, RUB, USD }
Timestamp: 1724036401
Num Rates: 6
Arbitrage opportunity:
USD --->EUR --->USD
Arbitrage opportunity:
EUR --->INR --->PLN --->RUB --->USD --->MXN --->EUR
Arbitrage opportunity:
EUR --->INR --->PLN --->EUR
Arbitrage opportunity:
MXN --->EUR --->USD --->MXN
Arbitrage opportunity:
INR --->EUR --->INR
Arbitrage opportunity:
RUB --->INR --->RUB
Arbitrage opportunity:
INR --->PLN --->RUB --->INR
Arbitrage opportunity:
MXN --->EUR --->USD --->MXN
Arbitrage opportunity:
INR --->EUR --->INR
Arbitrage opportunity:
RUB --->INR --->RUB
Arbitrage opportunity:
INR --->PLN --->RUB --->INR
---@mac ~/BellmanZig (main)> 
```