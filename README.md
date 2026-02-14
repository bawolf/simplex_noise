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

# Batch APIs (higher throughput for field generation)
SimplexNoise.noise2d_many(state, [{0.0, 0.0}, {0.125, 0.25}, {0.25, 0.5}])
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

For best throughput on BEAM, prefer batch APIs (`noise2d_many/2`, `noise3d_many/2`, `noise4d_many/2`) over calling scalar `noise*` in `Enum` loops.

### Elixir (BEAM JIT)

Run with `mix run bench/simplex_noise_bench.exs`:

Run both Elixir + JS benchmarks and refresh these README tables with:
`mix bench.update_readme`

| Scenario | IPS | Avg per batch | Median |
|----------|-----|---------------|--------|
| noise2d_many (512 calls) | 8.98 K | 111.33 us | 79.46 us |
| noise3d (512 calls) | 6.81 K | 146.80 us | 126.75 us |
| noise2d (512 calls) | 6.67 K | 149.87 us | 75 us |
| noise4d (512 calls) | 4.46 K | 224.12 us | 208.88 us |
| noise3d_many (512 calls) | 4.35 K | 229.96 us | 138.25 us |
| noise4d_many (512 calls) | 2.75 K | 363.10 us | 314.92 us |

### JavaScript (Node.js / V8 JIT)

Run with `cd bench/js && npm install && npm run bench`:

| Scenario | iterations/s | noise calls/s | avg per batch |
|----------|-------------|---------------|---------------|
| noise2D (512 calls) | 11,403 | 5,838,413 | 87.70 μs |
| noise3D (512 calls) | 12,764 | 6,535,316 | 78.34 μs |
| noise4D (512 calls) | 10,663 | 5,459,224 | 93.79 μs |

### Comparison

V8's JIT is heavily optimized for tight numerical loops, so the JS library is still faster in raw single-threaded scalar throughput. The Elixir implementation improves total generation throughput by using batch APIs, dropping 512-point generation to ~111.33us (2D), ~229.96us (3D), and ~363.10us (4D), and benefits from BEAM concurrency when computing multiple regions in parallel.

> **Machine:** Apple M2, 8 cores, macOS. Elixir 1.18.4 / OTP 28.0.2, Node.js v22.17.0.
> Full Benchee output is saved to [`bench/output/results.md`](bench/output/results.md).

## License

MIT
