# Simplex noise benchmarks — mirrors the JS library's perf/index.js
#
# The JS benchmark evaluates 512 noise calls per iteration (8×8×8 grid).
# We do the same here so ops/sec numbers are directly comparable.
#
# Run with:
#   mix run bench/simplex_noise_bench.exs

noise2d = SimplexNoise.create_noise_2d(42)
noise3d = SimplexNoise.create_noise_3d(42)
noise4d = SimplexNoise.create_noise_4d(42)

# Pre-build the coordinate list so list construction isn't measured.
coords =
  for x <- 0..7, y <- 0..7, z <- 0..7 do
    {x / 8, y / 8, z / 8}
  end

Benchee.run(
  %{
    "noise2d (512 calls)" => fn ->
      Enum.each(coords, fn {x, y, _z} ->
        SimplexNoise.noise2d(noise2d, x, y)
      end)
    end,
    "noise3d (512 calls)" => fn ->
      Enum.each(coords, fn {x, y, z} ->
        SimplexNoise.noise3d(noise3d, x, y, z)
      end)
    end,
    "noise4d (512 calls)" => fn ->
      Enum.each(coords, fn {x, y, z} ->
        SimplexNoise.noise4d(noise4d, x, y, z, (x + y) / 2)
      end)
    end
  },
  time: 10,
  warmup: 2,
  memory_time: 2,
  formatters: [
    Benchee.Formatters.Console,
    {Benchee.Formatters.Markdown,
     file: "bench/output/results.md",
     description: """
     Benchmarks for simplex_noise on Elixir #{System.version()}, \
     Erlang/OTP #{:erlang.system_info(:otp_release)}.

     Each scenario evaluates 512 noise calls (8×8×8 grid) per iteration, \
     matching the methodology of the upstream JS library's `perf/index.js`.
     """}
  ]
)
