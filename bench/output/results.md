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
    <td style="white-space: nowrap">N/A</td>
  </tr><tr>
    <th style="white-space: nowrap">Number of Available Cores</th>
    <td style="white-space: nowrap">8</td>
  </tr><tr>
    <th style="white-space: nowrap">Available Memory</th>
    <td style="white-space: nowrap">N/A</td>
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
    <td style="white-space: nowrap">noise2d (512 calls)</td>
    <td style="white-space: nowrap; text-align: right">9.08 K</td>
    <td style="white-space: nowrap; text-align: right">110.10 &micro;s</td>
    <td style="white-space: nowrap; text-align: right">&plusmn;750.13%</td>
    <td style="white-space: nowrap; text-align: right">73.21 &micro;s</td>
    <td style="white-space: nowrap; text-align: right">335.21 &micro;s</td>
  </tr>

  <tr>
    <td style="white-space: nowrap">noise3d (512 calls)</td>
    <td style="white-space: nowrap; text-align: right">6.91 K</td>
    <td style="white-space: nowrap; text-align: right">144.73 &micro;s</td>
    <td style="white-space: nowrap; text-align: right">&plusmn;384.92%</td>
    <td style="white-space: nowrap; text-align: right">123.08 &micro;s</td>
    <td style="white-space: nowrap; text-align: right">345.53 &micro;s</td>
  </tr>

  <tr>
    <td style="white-space: nowrap">noise4d (512 calls)</td>
    <td style="white-space: nowrap; text-align: right">4.36 K</td>
    <td style="white-space: nowrap; text-align: right">229.39 &micro;s</td>
    <td style="white-space: nowrap; text-align: right">&plusmn;149.26%</td>
    <td style="white-space: nowrap; text-align: right">207 &micro;s</td>
    <td style="white-space: nowrap; text-align: right">505.04 &micro;s</td>
  </tr>

</table>


Run Time Comparison

<table style="width: 1%">
  <tr>
    <th>Name</th>
    <th style="text-align: right">IPS</th>
    <th style="text-align: right">Slower</th>
  <tr>
    <td style="white-space: nowrap">noise2d (512 calls)</td>
    <td style="white-space: nowrap;text-align: right">9.08 K</td>
    <td>&nbsp;</td>
  </tr>

  <tr>
    <td style="white-space: nowrap">noise3d (512 calls)</td>
    <td style="white-space: nowrap; text-align: right">6.91 K</td>
    <td style="white-space: nowrap; text-align: right">1.31x</td>
  </tr>

  <tr>
    <td style="white-space: nowrap">noise4d (512 calls)</td>
    <td style="white-space: nowrap; text-align: right">4.36 K</td>
    <td style="white-space: nowrap; text-align: right">2.08x</td>
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
    <td style="white-space: nowrap">noise2d (512 calls)</td>
    <td style="white-space: nowrap">183.02 KB</td>
    <td>&nbsp;</td>
  </tr>
    <tr>
    <td style="white-space: nowrap">noise3d (512 calls)</td>
    <td style="white-space: nowrap">311.21 KB</td>
    <td>1.7x</td>
  </tr>
    <tr>
    <td style="white-space: nowrap">noise4d (512 calls)</td>
    <td style="white-space: nowrap">432.79 KB</td>
    <td>2.36x</td>
  </tr>
</table>