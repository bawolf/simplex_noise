defmodule SimplexNoise.PRNG do
  @moduledoc false

  # Mulberry32 PRNG — a fast 32-bit PRNG used as the default seeding
  # strategy. This is an internal module; use integer seeds with the
  # `SimplexNoise.create_noise_*` functions instead of calling this directly.

  import Bitwise

  @doc """
  Advance the mulberry32 PRNG by one step.

  Returns `{random_value, new_state}` where `random_value` is in `[0, 1)`.
  """
  @spec mulberry32(integer()) :: {float(), integer()}
  def mulberry32(seed) do
    seed = to_int32(seed)
    seed = to_int32(seed + 0x6D2B79F5)
    t = imul(bxor(seed, unsigned_right_shift(seed, 15)), bor(1, seed))
    t = bxor(to_int32(t + imul(bxor(t, unsigned_right_shift(t, 7)), bor(61, t))), t)
    value = to_uint32(bxor(t, unsigned_right_shift(t, 14))) / 4_294_967_296.0
    {value, seed}
  end

  @doc """
  Generate a sequence of `count` random values from `seed`.

  Returns `{values_list, final_state}`.
  """
  @spec mulberry32_seq(integer(), non_neg_integer()) :: {[float()], integer()}
  def mulberry32_seq(seed, count) do
    {values_rev, final_seed} =
      Enum.reduce(1..count, {[], seed}, fn _i, {acc, s} ->
        {val, s2} = mulberry32(s)
        {[val | acc], s2}
      end)

    {Enum.reverse(values_rev), final_seed}
  end

  # -- 32-bit integer helpers (matching JS bitwise semantics) --

  defp to_int32(x) do
    x = band(x, 0xFFFFFFFF)
    if x >= 0x80000000, do: x - 0x100000000, else: x
  end

  defp to_uint32(x), do: band(x, 0xFFFFFFFF)

  defp unsigned_right_shift(x, n), do: to_uint32(x) >>> n

  defp imul(a, b), do: to_int32(a * b)
end
