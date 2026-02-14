# SimplexNoise

A fast simplex noise implementation in Elixir supporting **2D, 3D, and 4D** noise generation with deterministic seeding.

This is a faithful port of the [`simplex-noise`](https://github.com/jwagner/simplex-noise.js) npm package by Jonas Wagner. Given the same seed and PRNG, it produces bit-identical output to the JS library.

## Installation

Add `simplex_noise` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:simplex_noise, "~> 0.1.0"}
  ]
end
```

## Usage

The API follows a two-step pattern: **create a noise state** with a seed, then **sample** it at any coordinates. All noise functions return a float in `[-1, 1]`.

```elixir
# 2D noise
state = SimplexNoise.create_noise_2d(42)
SimplexNoise.noise2d(state, 1.0, 2.0)
# => -0.4812...

# 3D noise
state = SimplexNoise.create_noise_3d(42)
SimplexNoise.noise3d(state, 1.0, 2.0, 3.0)

# 4D noise
state = SimplexNoise.create_noise_4d(42)
SimplexNoise.noise4d(state, 1.0, 2.0, 3.0, 4.0)
```

### Custom PRNG

Instead of an integer seed, you can pass a zero-arity function that returns floats in `[0, 1)`. This matches the JS library's API which accepts a `random` function.

```elixir
state = SimplexNoise.create_noise_2d(fn -> :rand.uniform() end)
SimplexNoise.noise2d(state, 1.0, 2.0)
```

### Seeding

When an integer seed is provided, a built-in **mulberry32** PRNG generates the permutation table, ensuring deterministic output. The same seed always produces the same noise values.

## Project Structure

```
lib/
  simplex_noise.ex        # Core module — noise state creation, 2D/3D/4D sampling
  simplex_noise/prng.ex   # Mulberry32 PRNG (internal, JS-compatible 32-bit arithmetic)

test/
  simplex_noise_test.exs              # Perm table parity, 2D golden vectors, property tests, PRNG tests
  simplex_noise/noise3d_test.exs      # 3D golden vectors + property tests
  simplex_noise/noise4d_test.exs      # 4D golden vectors + property tests
  fixtures/                           # JSON golden vectors generated from the JS library
```

## Testing

```bash
mix test
```

Tests include:

- **Golden vector tests** — output is compared against values produced by the JS `simplex-noise` library to verify bit-level parity.
- **Property-based tests** (via `stream_data`) — noise output is always within `[-1, 1]`, and identical seeds produce identical results.

## Benchmarks

Each scenario evaluates **512 noise calls** (8x8x8 grid) per iteration, matching the methodology of the upstream JS library's [`perf/index.js`](https://github.com/jwagner/simplex-noise.js/blob/main/perf/index.js).

### Elixir (BEAM JIT)

Run with `mix run bench/simplex_noise_bench.exs`:

| Scenario | IPS | Avg per batch | Median |
|----------|-----|---------------|--------|
| noise2d (512 calls) | 9.08 K | 110.10 us | 73.21 us |
| noise3d (512 calls) | 6.91 K | 144.73 us | 123.08 us |
| noise4d (512 calls) | 4.36 K | 229.39 us | 207.00 us |

### JavaScript (Node.js / V8 JIT)

Run with `cd bench/js && npm install && npm run bench`:

| Scenario | iterations/s | noise calls/s | avg per batch |
|----------|-------------|---------------|---------------|
| noise2D (512 calls) | 35,974 | 18,418,827 | 27.80 us |
| noise3D (512 calls) | 27,278 | 13,966,572 | 36.66 us |
| noise4D (512 calls) | 22,267 | 11,400,923 | 44.91 us |

### Comparison

V8's JIT is heavily optimized for tight numerical loops, so the JS library is roughly **3-4x faster** in raw single-threaded throughput. That said, the Elixir implementation is plenty fast for procedural generation workloads — generating a 512-point noise field in ~73-207 us — and benefits from BEAM's concurrency model when computing noise across multiple regions in parallel.

> **Machine:** Apple M2 Air, 8 cores, macOS. Elixir 1.18.4 / OTP 28, Node.js v22.
> Full Benchee output is saved to [`bench/output/results.md`](bench/output/results.md).

## License

MIT
