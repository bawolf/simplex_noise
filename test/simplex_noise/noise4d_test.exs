defmodule SimplexNoise.Noise4DTest do
  use ExUnit.Case, async: true
  use ExUnitProperties

  @seed 42

  setup_all do
    path = Path.join([__DIR__, "../fixtures/noise4d_golden_vectors.json"])
    cases = path |> File.read!() |> Jason.decode!()
    noise_state = SimplexNoise.create_noise_4d(@seed)
    {:ok, cases: cases, noise: noise_state}
  end

  describe "golden vectors" do
    test "all noise4d golden vectors match TS output", %{cases: cases, noise: noise} do
      Enum.each(cases, fn %{"x" => x, "y" => y, "z" => z, "w" => w, "expected" => expected} ->
        result = SimplexNoise.noise4d(noise, x, y, z, w)

        assert_in_delta result,
                        expected,
                        1.0e-10,
                        "noise4d(#{x}, #{y}, #{z}, #{w}): got #{result}, expected #{expected}"
      end)
    end
  end

  describe "properties" do
    test "output is in [-1, 1]" do
      noise = SimplexNoise.create_noise_4d(@seed)

      check all(
              x <- StreamData.float(min: -100.0, max: 100.0),
              y <- StreamData.float(min: -100.0, max: 100.0),
              z <- StreamData.float(min: -100.0, max: 100.0),
              w <- StreamData.float(min: -100.0, max: 100.0)
            ) do
        v = SimplexNoise.noise4d(noise, x, y, z, w)
        assert v >= -1.0 and v <= 1.0
      end
    end

    test "deterministic with same seed" do
      n1 = SimplexNoise.create_noise_4d(42)
      n2 = SimplexNoise.create_noise_4d(42)

      assert SimplexNoise.noise4d(n1, 1.5, 2.3, -0.7, 0.4) ==
               SimplexNoise.noise4d(n2, 1.5, 2.3, -0.7, 0.4)
    end

    test "different input produces different output" do
      noise = SimplexNoise.create_noise_4d(@seed)
      a = SimplexNoise.noise4d(noise, 0.1, 0.2, 0.3, 0.4)
      b = SimplexNoise.noise4d(noise, 0.101, 0.202, 0.303, 0.404)
      refute a == b
    end

    test "different seed produces different output" do
      noise_a = SimplexNoise.create_noise_4d(1)
      noise_b = SimplexNoise.create_noise_4d(2)

      refute SimplexNoise.noise4d(noise_a, 0.1, 0.2, 0.3, 0.4) ==
               SimplexNoise.noise4d(noise_b, 0.1, 0.2, 0.3, 0.4)
    end

    test "similar inputs produce similar outputs (continuity)" do
      noise = SimplexNoise.create_noise_4d(@seed)
      a = SimplexNoise.noise4d(noise, 0.1, 0.2, 0.3, 0.4)
      b = SimplexNoise.noise4d(noise, 0.101, 0.202, 0.303, 0.404)
      assert abs(a - b) < 0.1
    end
  end
end
