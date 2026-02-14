defmodule SimplexNoiseTest do
  use ExUnit.Case, async: true
  use ExUnitProperties

  # ---------------------------------------------------------------
  # Permutation table parity
  # ---------------------------------------------------------------

  describe "permutation table" do
    @perm_fixture "test/fixtures/perm_table_seed42.json"
    @external_resource @perm_fixture

    @expected_perm @perm_fixture |> File.read!() |> Jason.decode!()

    test "build_perm_table matches TS for seed 42" do
      perm = SimplexNoise.build_perm_table(42)
      assert tuple_size(perm) == 512

      for i <- 0..511 do
        expected = Enum.at(@expected_perm, i)

        assert elem(perm, i) == expected,
               "perm[#{i}]: got #{elem(perm, i)}, expected #{expected}"
      end
    end

    test "first half contains all indices 0..255 exactly once" do
      perm = SimplexNoise.build_perm_table(42)
      first_half = for i <- 0..255, do: elem(perm, i)

      assert Enum.sort(first_half) == Enum.to_list(0..255)
    end

    test "second half mirrors first half" do
      perm = SimplexNoise.build_perm_table(42)
      first_half = for i <- 0..255, do: elem(perm, i)
      second_half = for i <- 256..511, do: elem(perm, i)

      assert first_half == second_half
    end

    test "different seeds produce different tables" do
      perm_a = SimplexNoise.build_perm_table(1)
      perm_b = SimplexNoise.build_perm_table(2)

      refute perm_a == perm_b
    end

    test "zero-returning PRNG produces natural order" do
      perm = SimplexNoise.build_perm_table(fn -> 0.0 end)

      for i <- 0..511 do
        assert elem(perm, i) == Bitwise.band(i, 255),
               "perm[#{i}]: got #{elem(perm, i)}, expected #{Bitwise.band(i, 255)}"
      end
    end
  end

  # ---------------------------------------------------------------
  # Noise2D golden vectors
  # ---------------------------------------------------------------

  describe "noise2d golden vectors" do
    @noise_fixture "test/fixtures/noise2d_golden_vectors.json"
    @external_resource @noise_fixture

    @noise_vectors @noise_fixture |> File.read!() |> Jason.decode!()

    test "all #{length(@noise_vectors)} noise2d values match TS output" do
      noise_state = SimplexNoise.create_noise_2d(42)

      for {tc, i} <- Enum.with_index(@noise_vectors) do
        result = SimplexNoise.noise2d(noise_state, tc["x"], tc["y"])

        assert_in_delta result,
                        tc["expected"],
                        1.0e-10,
                        "case #{i} (#{tc["x"]}, #{tc["y"]}): got #{result}, expected #{tc["expected"]}"
      end
    end
  end

  # ---------------------------------------------------------------
  # Noise2D property tests
  # ---------------------------------------------------------------

  describe "noise2d properties" do
    setup do
      {:ok, noise: SimplexNoise.create_noise_2d(42)}
    end

    property "output is in [-1, 1]", %{noise: noise} do
      check all(
              x <- StreamData.float(min: -500.0, max: 500.0),
              y <- StreamData.float(min: -500.0, max: 500.0)
            ) do
        val = SimplexNoise.noise2d(noise, x, y)
        assert val >= -1.0 and val <= 1.0, "noise2d(#{x}, #{y}) = #{val} is outside [-1, 1]"
      end
    end

    property "noise2d(0, 0) is deterministic", %{noise: noise} do
      val = SimplexNoise.noise2d(noise, 0.0, 0.0)

      check all(_ <- StreamData.constant(nil)) do
        assert SimplexNoise.noise2d(noise, 0.0, 0.0) == val
      end
    end

    test "different input produces different output", %{noise: noise} do
      a = SimplexNoise.noise2d(noise, 0.1, 0.2)
      b = SimplexNoise.noise2d(noise, 0.101, 0.202)
      refute a == b
    end

    test "different seed produces different output" do
      noise_a = SimplexNoise.create_noise_2d(1)
      noise_b = SimplexNoise.create_noise_2d(2)

      refute SimplexNoise.noise2d(noise_a, 0.1, 0.2) ==
               SimplexNoise.noise2d(noise_b, 0.1, 0.2)
    end

    test "similar inputs produce similar outputs (continuity)", %{noise: noise} do
      a = SimplexNoise.noise2d(noise, 0.1, 0.2)
      b = SimplexNoise.noise2d(noise, 0.101, 0.202)
      assert abs(a - b) < 0.1
    end
  end

  # ---------------------------------------------------------------
  # Mulberry32 PRNG
  # ---------------------------------------------------------------

  describe "mulberry32" do
    test "produces deterministic sequence from seed" do
      {v1, s1} = SimplexNoise.PRNG.mulberry32(42)
      {v2, _s2} = SimplexNoise.PRNG.mulberry32(s1)

      {v1_again, s1_again} = SimplexNoise.PRNG.mulberry32(42)
      {v2_again, _} = SimplexNoise.PRNG.mulberry32(s1_again)

      assert v1 == v1_again
      assert v2 == v2_again
    end

    test "values are in [0, 1)" do
      {values, _} = SimplexNoise.PRNG.mulberry32_seq(42, 1000)

      for v <- values do
        assert v >= 0.0 and v < 1.0, "value #{v} out of range [0, 1)"
      end
    end
  end

  # ---------------------------------------------------------------
  # Custom PRNG function
  # ---------------------------------------------------------------

  describe "custom PRNG function" do
    test "create_noise_2d accepts a function" do
      state = SimplexNoise.create_noise_2d(fn -> :rand.uniform() end)
      val = SimplexNoise.noise2d(state, 1.0, 2.0)
      assert is_float(val)
      assert val >= -1.0 and val <= 1.0
    end

    test "create_noise_3d accepts a function" do
      state = SimplexNoise.create_noise_3d(fn -> :rand.uniform() end)
      val = SimplexNoise.noise3d(state, 1.0, 2.0, 3.0)
      assert is_float(val)
      assert val >= -1.0 and val <= 1.0
    end

    test "create_noise_4d accepts a function" do
      state = SimplexNoise.create_noise_4d(fn -> :rand.uniform() end)
      val = SimplexNoise.noise4d(state, 1.0, 2.0, 3.0, 4.0)
      assert is_float(val)
      assert val >= -1.0 and val <= 1.0
    end
  end

  # ---------------------------------------------------------------
  # Batch APIs
  # ---------------------------------------------------------------

  describe "noise*_many batch APIs" do
    test "noise2d_many matches per-point noise2d" do
      state = SimplexNoise.create_noise_2d(42)
      coords = [{0.0, 0.0}, {0.125, 0.25}, {1.5, -2.25}, {-10.0, 2.75}]

      expected = Enum.map(coords, fn {x, y} -> SimplexNoise.noise2d(state, x, y) end)

      assert SimplexNoise.noise2d_many(state, coords) == expected
    end

    test "noise3d_many matches per-point noise3d" do
      state = SimplexNoise.create_noise_3d(42)
      coords = [{0.0, 0.0, 0.0}, {0.125, 0.25, 0.5}, {1.5, -2.25, 3.125}, {-10.0, 2.75, 9.0}]

      expected = Enum.map(coords, fn {x, y, z} -> SimplexNoise.noise3d(state, x, y, z) end)

      assert SimplexNoise.noise3d_many(state, coords) == expected
    end

    test "noise4d_many matches per-point noise4d" do
      state = SimplexNoise.create_noise_4d(42)
      coords = [{0.0, 0.0, 0.0, 0.0}, {0.125, 0.25, 0.5, 0.75}, {1.5, -2.25, 3.125, -4.0}]

      expected =
        Enum.map(coords, fn {x, y, z, w} ->
          SimplexNoise.noise4d(state, x, y, z, w)
        end)

      assert SimplexNoise.noise4d_many(state, coords) == expected
    end
  end
end
