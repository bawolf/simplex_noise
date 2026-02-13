defmodule SimplexNoise.Noise3DTest do
  use ExUnit.Case, async: true
  use ExUnitProperties

  @seed 42

  setup_all do
    path = Path.join([__DIR__, "../fixtures/noise3d_golden_vectors.json"])
    cases = path |> File.read!() |> Jason.decode!()
    noise_state = SimplexNoise.create_noise_3d(@seed)
    {:ok, cases: cases, noise: noise_state}
  end

  describe "golden vectors" do
    test "all noise3d golden vectors match TS output", %{cases: cases, noise: noise} do
      Enum.each(cases, fn %{"x" => x, "y" => y, "z" => z, "expected" => expected} ->
        result = SimplexNoise.noise3d(noise, x, y, z)

        assert_in_delta result, expected, 1.0e-10,
          "noise3d(#{x}, #{y}, #{z}): got #{result}, expected #{expected}"
      end)
    end
  end

  describe "properties" do
    test "output is in [-1, 1]" do
      noise = SimplexNoise.create_noise_3d(@seed)

      check all(
              x <- StreamData.float(min: -100.0, max: 100.0),
              y <- StreamData.float(min: -100.0, max: 100.0),
              z <- StreamData.float(min: -100.0, max: 100.0)
            ) do
        v = SimplexNoise.noise3d(noise, x, y, z)
        assert v >= -1.0 and v <= 1.0
      end
    end

    test "deterministic with same seed" do
      n1 = SimplexNoise.create_noise_3d(42)
      n2 = SimplexNoise.create_noise_3d(42)
      assert SimplexNoise.noise3d(n1, 1.5, 2.3, -0.7) == SimplexNoise.noise3d(n2, 1.5, 2.3, -0.7)
    end

    test "different input produces different output" do
      noise = SimplexNoise.create_noise_3d(@seed)
      a = SimplexNoise.noise3d(noise, 0.1, 0.2, 0.3)
      b = SimplexNoise.noise3d(noise, 0.101, 0.202, 0.303)
      refute a == b
    end

    test "different seed produces different output" do
      noise_a = SimplexNoise.create_noise_3d(1)
      noise_b = SimplexNoise.create_noise_3d(2)

      refute SimplexNoise.noise3d(noise_a, 0.1, 0.2, 0.3) ==
               SimplexNoise.noise3d(noise_b, 0.1, 0.2, 0.3)
    end

    test "similar inputs produce similar outputs (continuity)" do
      noise = SimplexNoise.create_noise_3d(@seed)
      a = SimplexNoise.noise3d(noise, 0.1, 0.2, 0.3)
      b = SimplexNoise.noise3d(noise, 0.101, 0.202, 0.303)
      assert abs(a - b) < 0.1
    end
  end
end
