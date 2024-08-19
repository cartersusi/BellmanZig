Bellman Ford implementation in Zig
```
├── build.zig
├── build.zig.zon
├── conf.conf/example.conf
├── py
├── README.md
├── requirements.txt
├── src/
│   ├── main.zig
│   ├── parser.zig
│   └── utils.zig
|   └── api.zig
├── data/
│   ├── data.db
│   └── data.csv
│   └── example.json
├── scripts/
│   ├── gen.py
│   └── init.py
└── tests/
    ├── test_main.zig
    └── test_parser.zig
    └── test_api.zig
```

```sh
-----@linux ~/BellmanZig (main)> ./zig-out/bin/BellmanZig
Timestamp: 1724032902
Num Rates: 6
Arbitrage opportunity:
RUB --->USD --->INR --->MXN --->RUB
Arbitrage opportunity:
RUB --->USD --->INR --->MXN --->RUB
Arbitrage opportunity:
RUB --->USD --->INR --->MXN --->RUB
Arbitrage opportunity:
INR --->RUB --->INR
Arbitrage opportunity:
INR --->RUB --->INR
Arbitrage opportunity:
RUB --->INR --->MXN --->RUB
Arbitrage opportunity:
INR --->RUB --->INR
Arbitrage opportunity:
INR --->RUB --->INR
Arbitrage opportunity:
RUB --->INR --->MXN --->RUB
Arbitrage opportunity:
INR --->RUB --->INR
Arbitrage opportunity:
INR --->RUB --->INR
Arbitrage opportunity:
RUB --->INR --->MXN --->RUB
-----@linux ~/BellmanZig (main)> 
```