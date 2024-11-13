# [`binance.sh`](lib/binance.sh)

This repository contains shell programs for downloading Binance public market data.

## Usage

### Import

```sh
wget https://github.com/system4-tech/binance-sh/blob/main/lib/binance.sh
. binance.sh
```

### Kline / Candlestick data

```sh
klines spot BTCUSDT 1m
klines um BTCUSDT 1h
klines cm BTCETH 1d
```

### Symbols

```sh
symbols spot
symbols um
symbols cm
```

See [tests](tests/) for more examples.
