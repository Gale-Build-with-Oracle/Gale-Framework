---
name: financial
description: 'On-demand financial tools — market data, portfolio, trading with guardrails. Wraps CCXT via CLI.'
---

# Financial Tools

On-demand market data, portfolio, and trading via CCXT.
Zero context cost until invoked — runs as CLI, not always-on MCP.

## Usage

Run commands via the CLI at `$HOME/ghq/github.com/deachawatss/mcp-financial`:

### Market Data (no API keys needed)
```bash
bun $HOME/ghq/github.com/deachawatss/mcp-financial/src/cli.ts price '{"symbol":"BTC/USDT"}'
bun $HOME/ghq/github.com/deachawatss/mcp-financial/src/cli.ts candles '{"symbol":"BTC/USDT","timeframe":"1h","limit":50}'
bun $HOME/ghq/github.com/deachawatss/mcp-financial/src/cli.ts orderbook '{"symbol":"BTC/USDT","limit":10}'
bun $HOME/ghq/github.com/deachawatss/mcp-financial/src/cli.ts ticker '{"symbol":"BTC/USDT"}'
bun $HOME/ghq/github.com/deachawatss/mcp-financial/src/cli.ts markets '{"quote":"USDT"}'
```

### Portfolio (requires API keys in .env)
```bash
bun $HOME/ghq/github.com/deachawatss/mcp-financial/src/cli.ts balance '{}'
bun $HOME/ghq/github.com/deachawatss/mcp-financial/src/cli.ts positions '{"symbol":"BTC/USDT"}'
bun $HOME/ghq/github.com/deachawatss/mcp-financial/src/cli.ts orders '{"symbol":"BTC/USDT"}'
bun $HOME/ghq/github.com/deachawatss/mcp-financial/src/cli.ts trades '{"symbol":"BTC/USDT","limit":50}'
bun $HOME/ghq/github.com/deachawatss/mcp-financial/src/cli.ts pnl '{}'
```

### Trading (requires API keys + GUARDED)
```bash
bun $HOME/ghq/github.com/deachawatss/mcp-financial/src/cli.ts place '{"symbol":"BTC/USDT","side":"buy","type":"market","amount":0.01}'
bun $HOME/ghq/github.com/deachawatss/mcp-financial/src/cli.ts cancel '{"orderId":"123","symbol":"BTC/USDT"}'
bun $HOME/ghq/github.com/deachawatss/mcp-financial/src/cli.ts close '{"symbol":"BTC/USDT"}'
```

## Guardrails (fail-closed)
Trading tools pass through 3 guards before execution:
- **Position limit**: max 10% of portfolio per trade (MAX_POSITION_PCT)
- **Drawdown circuit breaker**: stops if daily loss > 5% (DRAWDOWN_THRESHOLD_PCT)
- **Approval gate**: blocks orders > $500 (APPROVAL_THRESHOLD_USD)

## Configuration
Edit `$HOME/ghq/github.com/deachawatss/mcp-financial/.env`:
- EXCHANGE_ID (default: okx)
- EXCHANGE_API_KEY, EXCHANGE_SECRET, EXCHANGE_PASSWORD
- SANDBOX=true (default — no real money)
- MAX_POSITION_PCT, DRAWDOWN_THRESHOLD_PCT, APPROVAL_THRESHOLD_USD

## Examples

**"What's the price of BTC?"**
```bash
bun $HOME/ghq/github.com/deachawatss/mcp-financial/src/cli.ts price '{"symbol":"BTC/USDT"}'
```

**"Show me ETH candles for the last 24h"**
```bash
bun $HOME/ghq/github.com/deachawatss/mcp-financial/src/cli.ts candles '{"symbol":"ETH/USDT","timeframe":"1h","limit":24}'
```

**"What pairs are available?"**
```bash
bun $HOME/ghq/github.com/deachawatss/mcp-financial/src/cli.ts markets '{"quote":"USDT"}'
```
