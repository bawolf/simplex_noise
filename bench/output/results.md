Benchmark

Benchmarks for simplex_noise on Elixir 1.18.4, Erlang/OTP 28.

Each scenario evaluates 512 noise calls (8×8×8 grid) per iteration, matching the methodology of the upstream JS library's `perf/index.js`.


## System

Benchmark suite executing on the following system:

<table style="width: 1%">
  <tr>
    <th style="width: 1%; white-space: nowrap">Operating System</th>
    <td>macOS</td>
  </tr><tr>
    <th style="white-space: nowrap">CPU Information</th>
    <td style="white-space: nowrap">Apple M2</td>
  </tr><tr>
    <th style="white-space: nowrap">Number of Available Cores</th>
    <td style="white-space: nowrap">8</td>
  </tr><tr>
    <th style="white-space: nowrap">Available Memory</th>
    <td style="white-space: nowrap">24 GB</td>
  </tr><tr>
    <th style="white-space: nowrap">Elixir Version</th>
    <td style="white-space: nowrap">1.18.4</td>
  </tr><tr>
    <th style="white-space: nowrap">Erlang Version</th>
    <td style="white-space: nowrap">28.0.2</td>
  </tr>
</table>

## Configuration

Benchmark suite executing with the following configuration:

<table style="width: 1%">
  <tr>
    <th style="width: 1%">:time</th>
    <td style="white-space: nowrap">10 s</td>
  </tr><tr>
    <th>:parallel</th>
    <td style="white-space: nowrap">1</td>
  </tr><tr>
    <th>:warmup</th>
    <td style="white-space: nowrap">2 s</td>
  </tr>
</table>

## Statistics



Run Time

<table style="width: 1%">
  <tr>
    <th>Name</th>
    <th style="text-align: right">IPS</th>
    <th style="text-align: right">Average</th>
    <th style="text-align: right">Devitation</th>
    <th style="text-align: right">Median</th>
    <th style="text-align: right">99th&nbsp;%</th>
  </tr>

  <tr>
    <td style="white-space: nowrap">noise2d_many (512 calls)</td>
    <td style="white-space: nowrap; text-align: right">8.98 K</td>
    <td style="white-space: nowrap; text-align: right">111.33 &micro;s</td>
    <td style="white-space: nowrap; text-align: right">&plusmn;619.32%</td>
    <td style="white-space: nowrap; text-align: right">79.46 &micro;s</td>
    <td style="white-space: nowrap; text-align: right">412.97 &micro;s</td>
  </tr>

  <tr>
    <td style="white-space: nowrap">noise3d (512 calls)</td>
    <td style="white-space: nowrap; text-align: right">6.81 K</td>
    <td style="white-space: nowrap; text-align: right">146.80 &micro;s</td>
    <td style="white-space: nowrap; text-align: right">&plusmn;284.82%</td>
    <td style="white-space: nowrap; text-align: right">126.75 &micro;s</td>
    <td style="white-space: nowrap; text-align: right">427.39 &micro;s</td>
  </tr>

  <tr>
    <td style="white-space: nowrap">noise2d (512 calls)</td>
    <td style="white-space: nowrap; text-align: right">6.67 K</td>
    <td style="white-space: nowrap; text-align: right">149.87 &micro;s</td>
    <td style="white-space: nowrap; text-align: right">&plusmn;926.50%</td>
    <td style="white-space: nowrap; text-align: right">75 &micro;s</td>
    <td style="white-space: nowrap; text-align: right">639.56 &micro;s</td>
  </tr>

  <tr>
    <td style="white-space: nowrap">noise4d (512 calls)</td>
    <td style="white-space: nowrap; text-align: right">4.46 K</td>
    <td style="white-space: nowrap; text-align: right">224.12 &micro;s</td>
    <td style="white-space: nowrap; text-align: right">&plusmn;117.87%</td>
    <td style="white-space: nowrap; text-align: right">208.88 &micro;s</td>
    <td style="white-space: nowrap; text-align: right">534.60 &micro;s</td>
  </tr>

  <tr>
    <td style="white-space: nowrap">noise3d_many (512 calls)</td>
    <td style="white-space: nowrap; text-align: right">4.35 K</td>
    <td style="white-space: nowrap; text-align: right">229.96 &micro;s</td>
    <td style="white-space: nowrap; text-align: right">&plusmn;608.44%</td>
    <td style="white-space: nowrap; text-align: right">138.25 &micro;s</td>
    <td style="white-space: nowrap; text-align: right">775.04 &micro;s</td>
  </tr>

  <tr>
    <td style="white-space: nowrap">noise4d_many (512 calls)</td>
    <td style="white-space: nowrap; text-align: right">2.75 K</td>
    <td style="white-space: nowrap; text-align: right">363.10 &micro;s</td>
    <td style="white-space: nowrap; text-align: right">&plusmn;128.63%</td>
    <td style="white-space: nowrap; text-align: right">314.92 &micro;s</td>
    <td style="white-space: nowrap; text-align: right">957.79 &micro;s</td>
  </tr>

</table>


Run Time Comparison

<table style="width: 1%">
  <tr>
    <th>Name</th>
    <th style="text-align: right">IPS</th>
    <th style="text-align: right">Slower</th>
  <tr>
    <td style="white-space: nowrap">noise2d_many (512 calls)</td>
    <td style="white-space: nowrap;text-align: right">8.98 K</td>
    <td>&nbsp;</td>
  </tr>

  <tr>
    <td style="white-space: nowrap">noise3d (512 calls)</td>
    <td style="white-space: nowrap; text-align: right">6.81 K</td>
    <td style="white-space: nowrap; text-align: right">1.32x</td>
  </tr>

  <tr>
    <td style="white-space: nowrap">noise2d (512 calls)</td>
    <td style="white-space: nowrap; text-align: right">6.67 K</td>
    <td style="white-space: nowrap; text-align: right">1.35x</td>
  </tr>

  <tr>
    <td style="white-space: nowrap">noise4d (512 calls)</td>
    <td style="white-space: nowrap; text-align: right">4.46 K</td>
    <td style="white-space: nowrap; text-align: right">2.01x</td>
  </tr>

  <tr>
    <td style="white-space: nowrap">noise3d_many (512 calls)</td>
    <td style="white-space: nowrap; text-align: right">4.35 K</td>
    <td style="white-space: nowrap; text-align: right">2.07x</td>
  </tr>

  <tr>
    <td style="white-space: nowrap">noise4d_many (512 calls)</td>
    <td style="white-space: nowrap; text-align: right">2.75 K</td>
    <td style="white-space: nowrap; text-align: right">3.26x</td>
  </tr>

</table>



Memory Usage

<table style="width: 1%">
  <tr>
    <th>Name</th>
    <th style="text-align: right">Average</th>
    <th style="text-align: right">Factor</th>
  </tr>
  <tr>
    <td style="white-space: nowrap">noise2d_many (512 calls)</td>
    <td style="white-space: nowrap">183 KB</td>
    <td>&nbsp;</td>
  </tr>
    <tr>
    <td style="white-space: nowrap">noise3d (512 calls)</td>
    <td style="white-space: nowrap">287.21 KB</td>
    <td>1.57x</td>
  </tr>
    <tr>
    <td style="white-space: nowrap">noise2d (512 calls)</td>
    <td style="white-space: nowrap">167.02 KB</td>
    <td>0.91x</td>
  </tr>
    <tr>
    <td style="white-space: nowrap">noise4d (512 calls)</td>
    <td style="white-space: nowrap">400.79 KB</td>
    <td>2.19x</td>
  </tr>
    <tr>
    <td style="white-space: nowrap">noise3d_many (512 calls)</td>
    <td style="white-space: nowrap">303.19 KB</td>
    <td>1.66x</td>
  </tr>
    <tr>
    <td style="white-space: nowrap">noise4d_many (512 calls)</td>
    <td style="white-space: nowrap">408.77 KB</td>
    <td>2.23x</td>
  </tr>
</table>