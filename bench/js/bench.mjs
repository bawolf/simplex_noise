/**
 * Benchmark simplex-noise.js — comparable to the Elixir bench/simplex_noise_bench.exs
 *
 * Each scenario evaluates 512 noise calls (8×8×8 grid) per iteration,
 * matching the upstream library's perf/index.js methodology.
 *
 * Run with:
 *   cd bench/js && npm install && npm run bench
 */

import { createNoise2D, createNoise3D, createNoise4D } from "simplex-noise";

// --- Configuration ---
const WARMUP_ITERATIONS = 1000;
const BENCH_DURATION_MS = 10_000; // 10 seconds per scenario

// Use a simple seeded PRNG (mulberry32) to match the Elixir seed=42 setup
function mulberry32(seed) {
  return function () {
    let t = (seed += 0x6d2b79f5);
    t = Math.imul(t ^ (t >>> 15), t | 1);
    t ^= t + Math.imul(t ^ (t >>> 7), t | 61);
    return ((t ^ (t >>> 14)) >>> 0) / 4294967296;
  };
}

const noise2D = createNoise2D(mulberry32(42));
const noise3D = createNoise3D(mulberry32(42));
const noise4D = createNoise4D(mulberry32(42));

// Pre-build coordinate list
const coords = [];
for (let x = 0; x < 8; x++) {
  for (let y = 0; y < 8; y++) {
    for (let z = 0; z < 8; z++) {
      coords.push([x / 8, y / 8, z / 8]);
    }
  }
}

function benchScenario(name, fn) {
  // Warmup
  for (let i = 0; i < WARMUP_ITERATIONS; i++) {
    fn();
  }

  // Timed run
  let iterations = 0;
  const start = performance.now();
  const deadline = start + BENCH_DURATION_MS;

  while (performance.now() < deadline) {
    fn();
    iterations++;
  }

  const elapsed = performance.now() - start;
  const ipsRaw = (iterations / elapsed) * 1000;
  const callsPerSec = ipsRaw * 512;
  const avgUs = (elapsed / iterations) * 1000; // microseconds per 512-call batch

  return { name, iterations, elapsed, ipsRaw, callsPerSec, avgUs };
}

// --- Run benchmarks ---
console.log("simplex-noise.js benchmark (512 calls per iteration)\n");
console.log(`Duration: ${BENCH_DURATION_MS / 1000}s per scenario`);
console.log(`Warmup:   ${WARMUP_ITERATIONS} iterations\n`);

const results = [];

// Prevent dead-code elimination
let sideEffect = 0;

results.push(
  benchScenario("noise2D (512 calls)", () => {
    let a = 0;
    for (const [x, y] of coords) {
      a += noise2D(x, y);
    }
    sideEffect += a;
  })
);

results.push(
  benchScenario("noise3D (512 calls)", () => {
    let a = 0;
    for (const [x, y, z] of coords) {
      a += noise3D(x, y, z);
    }
    sideEffect += a;
  })
);

results.push(
  benchScenario("noise4D (512 calls)", () => {
    let a = 0;
    for (const [x, y, z] of coords) {
      a += noise4D(x, y, z, (x + y) / 2);
    }
    sideEffect += a;
  })
);

// --- Output ---
console.log("Results:");
console.log("-".repeat(70));

for (const r of results) {
  const fmt = (n) => n.toLocaleString("en-US", { maximumFractionDigits: 0 });
  console.log(`${r.name}`);
  console.log(`  ${fmt(r.ipsRaw)} iterations/s (${fmt(r.callsPerSec)} noise calls/s)`);
  console.log(`  avg ${r.avgUs.toFixed(2)} μs per 512-call batch`);
  console.log();
}

// Markdown table for easy pasting
console.log("\nMarkdown table:");
console.log("| Scenario | iterations/s | noise calls/s | avg per batch |");
console.log("|----------|-------------|---------------|---------------|");
for (const r of results) {
  const fmt = (n) => n.toLocaleString("en-US", { maximumFractionDigits: 0 });
  console.log(
    `| ${r.name} | ${fmt(r.ipsRaw)} | ${fmt(r.callsPerSec)} | ${r.avgUs.toFixed(2)} μs |`
  );
}

// Keep sideEffect alive
if (sideEffect === Infinity) console.log(sideEffect);
