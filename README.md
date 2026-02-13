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

## License

MIT
