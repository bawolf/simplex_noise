defmodule SimplexNoise do
  @moduledoc """
  A fast simplex noise implementation in Elixir.

  Faithful port of the [`simplex-noise`](https://github.com/jwagner/simplex-noise.js)
  npm package by Jonas Wagner. Supports 2D, 3D, and 4D simplex noise with
  deterministic seeding.

  ## Usage

      # Create a noise state with an integer seed
      state = SimplexNoise.create_noise_2d(42)
      value = SimplexNoise.noise2d(state, 1.0, 2.0)
      # => a float in [-1, 1]

      # 3D and 4D noise
      state3d = SimplexNoise.create_noise_3d(42)
      SimplexNoise.noise3d(state3d, 1.0, 2.0, 3.0)

      state4d = SimplexNoise.create_noise_4d(42)
      SimplexNoise.noise4d(state4d, 1.0, 2.0, 3.0, 4.0)

      # With a custom PRNG function (must return a float in [0, 1))
      state = SimplexNoise.create_noise_2d(fn -> :rand.uniform() end)

  ## Seeding

  When an integer seed is provided, the built-in mulberry32 PRNG is used
  to generate the permutation table, ensuring deterministic output that
  matches the JS library when seeded with the same PRNG.

  You can also pass a zero-arity function returning floats in `[0, 1)`.
  This matches the JS library's API which accepts a `random` function
  (defaulting to `Math.random`).
  """

  import Bitwise

  @compile {:inline,
            [
              fast_floor: 1,
              bool_to_int: 1,
              corner2d: 9,
              corner3d: 13,
              corner4d: 17,
              do_noise2d: 5,
              do_noise3d: 7,
              do_noise4d: 9
            ]}

  # -------------------------------------------------------------------
  # Types
  # -------------------------------------------------------------------

  @typedoc "An integer seed for the built-in mulberry32 PRNG."
  @type seed :: integer()

  @typedoc "A zero-arity function returning a float in `[0, 1)`."
  @type random_fn :: (-> float())

  @typedoc "Either an integer seed or a custom PRNG function."
  @type seed_or_random :: seed() | random_fn()

  @typedoc "Opaque state for 2D noise sampling. Created by `create_noise_2d/1`."
  @opaque noise2d_state :: {:noise2d_state, tuple(), tuple(), tuple()}

  @typedoc "Opaque state for 3D noise sampling. Created by `create_noise_3d/1`."
  @opaque noise3d_state :: {:noise3d_state, tuple(), tuple(), tuple(), tuple()}

  @typedoc "Opaque state for 4D noise sampling. Created by `create_noise_4d/1`."
  @opaque noise4d_state :: {:noise4d_state, tuple(), tuple(), tuple(), tuple(), tuple()}

  # -------------------------------------------------------------------
  # Constants (matching JS source exactly)
  # -------------------------------------------------------------------

  @sqrt3 :math.sqrt(3.0)
  @sqrt5 :math.sqrt(5.0)

  @f2 0.5 * (@sqrt3 - 1.0)
  @g2 (3.0 - @sqrt3) / 6.0

  @f3 1.0 / 3.0
  @g3 1.0 / 6.0

  @f4 (@sqrt5 - 1.0) / 4.0
  @g4 (5.0 - @sqrt5) / 20.0

  # -------------------------------------------------------------------
  # Gradient tables (stored as tuples for O(1) access)
  # -------------------------------------------------------------------

  # 2D: 12 gradient vectors, 2 components each (24 values)
  @grad2 {
    1.0,
    1.0,
    -1.0,
    1.0,
    1.0,
    -1.0,
    -1.0,
    -1.0,
    1.0,
    0.0,
    -1.0,
    0.0,
    1.0,
    0.0,
    -1.0,
    0.0,
    0.0,
    1.0,
    0.0,
    -1.0,
    0.0,
    1.0,
    0.0,
    -1.0
  }

  # 3D: 12 gradient vectors, 3 components each (36 values)
  @grad3 {
    1.0,
    1.0,
    0.0,
    -1.0,
    1.0,
    0.0,
    1.0,
    -1.0,
    0.0,
    -1.0,
    -1.0,
    0.0,
    1.0,
    0.0,
    1.0,
    -1.0,
    0.0,
    1.0,
    1.0,
    0.0,
    -1.0,
    -1.0,
    0.0,
    -1.0,
    0.0,
    1.0,
    1.0,
    0.0,
    -1.0,
    1.0,
    0.0,
    1.0,
    -1.0,
    0.0,
    -1.0,
    -1.0
  }

  # 4D: 32 gradient vectors, 4 components each (128 values)
  @grad4 {
    0.0,
    1.0,
    1.0,
    1.0,
    0.0,
    1.0,
    1.0,
    -1.0,
    0.0,
    1.0,
    -1.0,
    1.0,
    0.0,
    1.0,
    -1.0,
    -1.0,
    0.0,
    -1.0,
    1.0,
    1.0,
    0.0,
    -1.0,
    1.0,
    -1.0,
    0.0,
    -1.0,
    -1.0,
    1.0,
    0.0,
    -1.0,
    -1.0,
    -1.0,
    1.0,
    0.0,
    1.0,
    1.0,
    1.0,
    0.0,
    1.0,
    -1.0,
    1.0,
    0.0,
    -1.0,
    1.0,
    1.0,
    0.0,
    -1.0,
    -1.0,
    -1.0,
    0.0,
    1.0,
    1.0,
    -1.0,
    0.0,
    1.0,
    -1.0,
    -1.0,
    0.0,
    -1.0,
    1.0,
    -1.0,
    0.0,
    -1.0,
    -1.0,
    1.0,
    1.0,
    0.0,
    1.0,
    1.0,
    1.0,
    0.0,
    -1.0,
    1.0,
    -1.0,
    0.0,
    1.0,
    1.0,
    -1.0,
    0.0,
    -1.0,
    -1.0,
    1.0,
    0.0,
    1.0,
    -1.0,
    1.0,
    0.0,
    -1.0,
    -1.0,
    -1.0,
    0.0,
    1.0,
    -1.0,
    -1.0,
    0.0,
    -1.0,
    1.0,
    1.0,
    1.0,
    0.0,
    1.0,
    1.0,
    -1.0,
    0.0,
    1.0,
    -1.0,
    1.0,
    0.0,
    1.0,
    -1.0,
    -1.0,
    0.0,
    -1.0,
    1.0,
    1.0,
    0.0,
    -1.0,
    1.0,
    -1.0,
    0.0,
    -1.0,
    -1.0,
    1.0,
    0.0,
    -1.0,
    -1.0,
    -1.0,
    0.0
  }

  # ===================================================================
  # Permutation Table
  # ===================================================================

  @doc false
  @spec build_perm_table(seed_or_random()) :: tuple()
  def build_perm_table(seed) when is_integer(seed) do
    {randoms, _} = SimplexNoise.PRNG.mulberry32_seq(seed, 256)
    do_build_perm_table(randoms)
  end

  def build_perm_table(random_fn) when is_function(random_fn, 0) do
    randoms = Enum.map(1..256, fn _ -> random_fn.() end)
    do_build_perm_table(randoms)
  end

  defp do_build_perm_table(randoms) do
    # Using Erlang's :array for O(1) random-access swaps during the shuffle
    p = :array.from_list(Enum.to_list(0..255))

    # Fisher-Yates shuffle — uses first 255 random values (matching JS loop: i in 0..254)
    p =
      Enum.reduce(Enum.zip(0..254, randoms), p, fn {i, r}, arr ->
        swap_target = i + trunc(r * (256 - i))
        val_i = :array.get(i, arr)
        val_r = :array.get(swap_target, arr)
        arr = :array.set(i, val_r, arr)
        :array.set(swap_target, val_i, arr)
      end)

    # Mirror first 256 entries to positions 256..511
    list_256 = :array.to_list(p)
    List.to_tuple(list_256 ++ list_256)
  end

  # ===================================================================
  # 2D Simplex Noise
  # ===================================================================

  @doc """
  Create a 2D noise state from a seed or PRNG function.

  ## Examples

      state = SimplexNoise.create_noise_2d(42)
      SimplexNoise.noise2d(state, 1.0, 2.0)

      state = SimplexNoise.create_noise_2d(fn -> :rand.uniform() end)
  """
  @spec create_noise_2d(seed_or_random()) :: noise2d_state()
  def create_noise_2d(seed_or_random) do
    perm = build_perm_table(seed_or_random)

    {grad2x, grad2y} =
      Enum.reduce(511..0//-1, {[], []}, fn i, {xs, ys} ->
        base = rem(elem(perm, i), 12) * 2
        {[elem(@grad2, base) | xs], [elem(@grad2, base + 1) | ys]}
      end)

    {:noise2d_state, perm, List.to_tuple(grad2x), List.to_tuple(grad2y)}
  end

  @doc """
  Sample 2D simplex noise at `(x, y)`. Returns a float in `[-1, 1]`.
  """
  @spec noise2d(noise2d_state(), number(), number()) :: float()
  def noise2d({:noise2d_state, perm, pg2x, pg2y}, x, y) do
    do_noise2d(perm, pg2x, pg2y, x, y)
  end

  @doc """
  Sample many 2D simplex noise coordinates.

  Accepts a list of `{x, y}` tuples and returns a list of values in `[-1, 1]`
  in the same order.
  """
  @spec noise2d_many(noise2d_state(), [{number(), number()}]) :: [float()]
  def noise2d_many({:noise2d_state, perm, pg2x, pg2y}, coords) when is_list(coords) do
    noise2d_many(coords, perm, pg2x, pg2y, [])
  end

  defp noise2d_many([], _perm, _pg2x, _pg2y, acc), do: :lists.reverse(acc)

  defp noise2d_many([{x, y} | rest], perm, pg2x, pg2y, acc) do
    noise2d_many(rest, perm, pg2x, pg2y, [do_noise2d(perm, pg2x, pg2y, x, y) | acc])
  end

  defp do_noise2d(perm, pg2x, pg2y, x, y) do
    s = (x + y) * @f2
    i = fast_floor(x + s)
    j = fast_floor(y + s)
    t = (i + j) * @g2

    x0 = x - (i - t)
    y0 = y - (j - t)

    {i1, j1} = if x0 > y0, do: {1, 0}, else: {0, 1}

    x1 = x0 - i1 + @g2
    y1 = y0 - j1 + @g2
    x2 = x0 - 1.0 + 2.0 * @g2
    y2 = y0 - 1.0 + 2.0 * @g2

    ii = i &&& 255
    jj = j &&& 255

    n0 = corner2d(pg2x, pg2y, perm, ii, jj, x0, y0, 0, 0)
    n1 = corner2d(pg2x, pg2y, perm, ii, jj, x1, y1, i1, j1)
    n2 = corner2d(pg2x, pg2y, perm, ii, jj, x2, y2, 1, 1)

    # Scale to [-1, 1] (standard 2D simplex scaling factor)
    70.0 * (n0 + n1 + n2)
  end

  defp corner2d(pg2x, pg2y, perm, ii, jj, dx, dy, oi, oj) do
    attn = 0.5 - dx * dx - dy * dy

    if attn >= 0 do
      gi = ii + oi + elem(perm, jj + oj)
      attn_sq = attn * attn
      attn_sq * attn_sq * (elem(pg2x, gi) * dx + elem(pg2y, gi) * dy)
    else
      0.0
    end
  end

  # ===================================================================
  # 3D Simplex Noise
  # ===================================================================

  @doc """
  Create a 3D noise state from a seed or PRNG function.

  ## Examples

      state = SimplexNoise.create_noise_3d(42)
      SimplexNoise.noise3d(state, 1.0, 2.0, 3.0)
  """
  @spec create_noise_3d(seed_or_random()) :: noise3d_state()
  def create_noise_3d(seed_or_random) do
    perm = build_perm_table(seed_or_random)

    {grad3x, grad3y, grad3z} =
      Enum.reduce(511..0//-1, {[], [], []}, fn i, {xs, ys, zs} ->
        base = rem(elem(perm, i), 12) * 3

        {
          [elem(@grad3, base) | xs],
          [elem(@grad3, base + 1) | ys],
          [elem(@grad3, base + 2) | zs]
        }
      end)

    {:noise3d_state, perm, List.to_tuple(grad3x), List.to_tuple(grad3y), List.to_tuple(grad3z)}
  end

  @doc """
  Sample 3D simplex noise at `(x, y, z)`. Returns a float in `[-1, 1]`.
  """
  @spec noise3d(noise3d_state(), number(), number(), number()) :: float()
  def noise3d({:noise3d_state, perm, pg3x, pg3y, pg3z}, x, y, z) do
    do_noise3d(perm, pg3x, pg3y, pg3z, x, y, z)
  end

  @doc """
  Sample many 3D simplex noise coordinates.

  Accepts a list of `{x, y, z}` tuples and returns a list of values in `[-1, 1]`
  in the same order.
  """
  @spec noise3d_many(noise3d_state(), [{number(), number(), number()}]) :: [float()]
  def noise3d_many({:noise3d_state, perm, pg3x, pg3y, pg3z}, coords) when is_list(coords) do
    noise3d_many(coords, perm, pg3x, pg3y, pg3z, [])
  end

  defp noise3d_many([], _perm, _pg3x, _pg3y, _pg3z, acc), do: :lists.reverse(acc)

  defp noise3d_many([{x, y, z} | rest], perm, pg3x, pg3y, pg3z, acc) do
    noise3d_many(rest, perm, pg3x, pg3y, pg3z, [do_noise3d(perm, pg3x, pg3y, pg3z, x, y, z) | acc])
  end

  defp do_noise3d(perm, pg3x, pg3y, pg3z, x, y, z) do
    s = (x + y + z) * @f3
    i = fast_floor(x + s)
    j = fast_floor(y + s)
    k = fast_floor(z + s)
    t = (i + j + k) * @g3

    x0 = x - (i - t)
    y0 = y - (j - t)
    z0 = z - (k - t)

    # Determine which simplex we are in (6-way branch)
    {i1, j1, k1, i2, j2, k2} =
      if x0 >= y0 do
        cond do
          y0 >= z0 -> {1, 0, 0, 1, 1, 0}
          x0 >= z0 -> {1, 0, 0, 1, 0, 1}
          true -> {0, 0, 1, 1, 0, 1}
        end
      else
        cond do
          y0 < z0 -> {0, 0, 1, 0, 1, 1}
          x0 < z0 -> {0, 1, 0, 0, 1, 1}
          true -> {0, 1, 0, 1, 1, 0}
        end
      end

    x1 = x0 - i1 + @g3
    y1 = y0 - j1 + @g3
    z1 = z0 - k1 + @g3
    x2 = x0 - i2 + 2.0 * @g3
    y2 = y0 - j2 + 2.0 * @g3
    z2 = z0 - k2 + 2.0 * @g3
    x3 = x0 - 1.0 + 3.0 * @g3
    y3 = y0 - 1.0 + 3.0 * @g3
    z3 = z0 - 1.0 + 3.0 * @g3

    ii = i &&& 255
    jj = j &&& 255
    kk = k &&& 255

    n0 = corner3d(pg3x, pg3y, pg3z, perm, ii, jj, kk, x0, y0, z0, 0, 0, 0)
    n1 = corner3d(pg3x, pg3y, pg3z, perm, ii, jj, kk, x1, y1, z1, i1, j1, k1)
    n2 = corner3d(pg3x, pg3y, pg3z, perm, ii, jj, kk, x2, y2, z2, i2, j2, k2)
    n3 = corner3d(pg3x, pg3y, pg3z, perm, ii, jj, kk, x3, y3, z3, 1, 1, 1)

    # Scale to [-1, 1] (standard 3D simplex scaling factor)
    32.0 * (n0 + n1 + n2 + n3)
  end

  defp corner3d(pgx, pgy, pgz, perm, ii, jj, kk, dx, dy, dz, oi, oj, ok) do
    attn = 0.6 - dx * dx - dy * dy - dz * dz

    if attn >= 0 do
      gi = ii + oi + elem(perm, jj + oj + elem(perm, kk + ok))
      attn_sq = attn * attn
      attn_sq * attn_sq * (elem(pgx, gi) * dx + elem(pgy, gi) * dy + elem(pgz, gi) * dz)
    else
      0.0
    end
  end

  # ===================================================================
  # 4D Simplex Noise
  # ===================================================================

  @doc """
  Create a 4D noise state from a seed or PRNG function.

  ## Examples

      state = SimplexNoise.create_noise_4d(42)
      SimplexNoise.noise4d(state, 1.0, 2.0, 3.0, 4.0)
  """
  @spec create_noise_4d(seed_or_random()) :: noise4d_state()
  def create_noise_4d(seed_or_random) do
    perm = build_perm_table(seed_or_random)

    {grad4x, grad4y, grad4z, grad4w} =
      Enum.reduce(511..0//-1, {[], [], [], []}, fn i, {xs, ys, zs, ws} ->
        base = rem(elem(perm, i), 32) * 4

        {
          [elem(@grad4, base) | xs],
          [elem(@grad4, base + 1) | ys],
          [elem(@grad4, base + 2) | zs],
          [elem(@grad4, base + 3) | ws]
        }
      end)

    {:noise4d_state, perm, List.to_tuple(grad4x), List.to_tuple(grad4y), List.to_tuple(grad4z),
     List.to_tuple(grad4w)}
  end

  @doc """
  Sample 4D simplex noise at `(x, y, z, w)`. Returns a float in `[-1, 1]`.
  """
  @spec noise4d(noise4d_state(), number(), number(), number(), number()) :: float()
  def noise4d({:noise4d_state, perm, pg4x, pg4y, pg4z, pg4w}, x, y, z, w) do
    do_noise4d(perm, pg4x, pg4y, pg4z, pg4w, x, y, z, w)
  end

  @doc """
  Sample many 4D simplex noise coordinates.

  Accepts a list of `{x, y, z, w}` tuples and returns a list of values in `[-1, 1]`
  in the same order.
  """
  @spec noise4d_many(noise4d_state(), [{number(), number(), number(), number()}]) :: [float()]
  def noise4d_many({:noise4d_state, perm, pg4x, pg4y, pg4z, pg4w}, coords) when is_list(coords) do
    noise4d_many(coords, perm, pg4x, pg4y, pg4z, pg4w, [])
  end

  defp noise4d_many([], _perm, _pg4x, _pg4y, _pg4z, _pg4w, acc), do: :lists.reverse(acc)

  defp noise4d_many([{x, y, z, w} | rest], perm, pg4x, pg4y, pg4z, pg4w, acc) do
    noise4d_many(rest, perm, pg4x, pg4y, pg4z, pg4w, [
      do_noise4d(perm, pg4x, pg4y, pg4z, pg4w, x, y, z, w) | acc
    ])
  end

  defp do_noise4d(perm, pg4x, pg4y, pg4z, pg4w, x, y, z, w) do
    s = (x + y + z + w) * @f4
    i = fast_floor(x + s)
    j = fast_floor(y + s)
    k = fast_floor(z + s)
    l = fast_floor(w + s)
    t = (i + j + k + l) * @g4

    x0 = x - (i - t)
    y0 = y - (j - t)
    z0 = z - (k - t)
    w0 = w - (l - t)

    # Rank each coordinate by pairwise comparison
    rankx = bool_to_int(x0 > y0) + bool_to_int(x0 > z0) + bool_to_int(x0 > w0)
    ranky = bool_to_int(y0 >= x0) + bool_to_int(y0 > z0) + bool_to_int(y0 > w0)
    rankz = bool_to_int(z0 >= x0) + bool_to_int(z0 >= y0) + bool_to_int(z0 > w0)
    rankw = bool_to_int(w0 >= x0) + bool_to_int(w0 >= y0) + bool_to_int(w0 >= z0)

    # Simplex corner offsets based on rank thresholds
    i1 = bool_to_int(rankx >= 3)
    j1 = bool_to_int(ranky >= 3)
    k1 = bool_to_int(rankz >= 3)
    l1 = bool_to_int(rankw >= 3)
    i2 = bool_to_int(rankx >= 2)
    j2 = bool_to_int(ranky >= 2)
    k2 = bool_to_int(rankz >= 2)
    l2 = bool_to_int(rankw >= 2)
    i3 = bool_to_int(rankx >= 1)
    j3 = bool_to_int(ranky >= 1)
    k3 = bool_to_int(rankz >= 1)
    l3 = bool_to_int(rankw >= 1)

    x1 = x0 - i1 + @g4
    y1 = y0 - j1 + @g4
    z1 = z0 - k1 + @g4
    w1 = w0 - l1 + @g4
    x2 = x0 - i2 + 2.0 * @g4
    y2 = y0 - j2 + 2.0 * @g4
    z2 = z0 - k2 + 2.0 * @g4
    w2 = w0 - l2 + 2.0 * @g4
    x3 = x0 - i3 + 3.0 * @g4
    y3 = y0 - j3 + 3.0 * @g4
    z3 = z0 - k3 + 3.0 * @g4
    w3 = w0 - l3 + 3.0 * @g4
    x4 = x0 - 1.0 + 4.0 * @g4
    y4 = y0 - 1.0 + 4.0 * @g4
    z4 = z0 - 1.0 + 4.0 * @g4
    w4 = w0 - 1.0 + 4.0 * @g4

    ii = i &&& 255
    jj = j &&& 255
    kk = k &&& 255
    ll = l &&& 255

    n0 = corner4d(pg4x, pg4y, pg4z, pg4w, perm, ii, jj, kk, ll, x0, y0, z0, w0, 0, 0, 0, 0)
    n1 = corner4d(pg4x, pg4y, pg4z, pg4w, perm, ii, jj, kk, ll, x1, y1, z1, w1, i1, j1, k1, l1)
    n2 = corner4d(pg4x, pg4y, pg4z, pg4w, perm, ii, jj, kk, ll, x2, y2, z2, w2, i2, j2, k2, l2)
    n3 = corner4d(pg4x, pg4y, pg4z, pg4w, perm, ii, jj, kk, ll, x3, y3, z3, w3, i3, j3, k3, l3)
    n4 = corner4d(pg4x, pg4y, pg4z, pg4w, perm, ii, jj, kk, ll, x4, y4, z4, w4, 1, 1, 1, 1)

    # Scale to [-1, 1] (standard 4D simplex scaling factor)
    27.0 * (n0 + n1 + n2 + n3 + n4)
  end

  defp corner4d(pgx, pgy, pgz, pgw, perm, ii, jj, kk, ll, dx, dy, dz, dw, oi, oj, ok, ol) do
    attn = 0.6 - dx * dx - dy * dy - dz * dz - dw * dw

    if attn >= 0 do
      gi = ii + oi + elem(perm, jj + oj + elem(perm, kk + ok + elem(perm, ll + ol)))
      attn_sq = attn * attn

      attn_sq * attn_sq *
        (elem(pgx, gi) * dx + elem(pgy, gi) * dy + elem(pgz, gi) * dz + elem(pgw, gi) * dw)
    else
      0.0
    end
  end

  # ===================================================================
  # Private helpers
  # ===================================================================

  # `trunc/1` followed by one correction branch is faster than :math.floor/1.
  defp fast_floor(x) do
    xi = trunc(x)
    if x < xi, do: xi - 1, else: xi
  end

  defp bool_to_int(true), do: 1
  defp bool_to_int(false), do: 0
end
