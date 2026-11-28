#!/usr/bin/env node
// Benchmark the PostgreSQL readiness route from a disposable local environment.
// Start the API from this branch with an empty test database, then run:
//   node scripts/load-api-readiness.mjs
// Optional arguments: port, requests, concurrency (defaults: 3000, 100, 5).
// This measures a local SELECT 1 round trip, not clinical endpoint capacity.

import { performance } from 'node:perf_hooks';

if (process.argv.length > 5) {
  throw new Error('Usage: node scripts/load-api-readiness.mjs [port] [requests] [concurrency]');
}

const [port, requests, concurrency] = ['3000', '100', '5'].map((fallback, index) => {
  const value = process.argv[index + 2] ?? fallback;
  return /^\d+$/.test(value) ? Number(value) : NaN;
});
if (!Number.isInteger(port) || port < 1024 || port > 65535 ||
    !Number.isInteger(requests) || requests < 1 || requests > 1000 ||
    !Number.isInteger(concurrency) || concurrency < 1 || concurrency > 20 ||
    concurrency > requests) {
  throw new Error('Use port 1024–65535, 1–1000 requests and 1–20 workers (at most requests).');
}

const url = 'http://127.0.0.1:' + port + '/health/ready';
const runLimit = AbortSignal.timeout(60_000);
const durations = [];
const failures = new Map();
let allocated = 0;

async function probe() {
  const response = await fetch(url, {
    redirect: 'error',
    signal: AbortSignal.any([runLimit, AbortSignal.timeout(3000)]),
  });
  await response.body?.cancel();
  return response.status;
}

async function worker() {
  while (!runLimit.aborted && allocated < requests) {
    allocated++;
    const started = performance.now();
    let outcome;
    try {
      outcome = await probe();
    } catch (error) {
      outcome = error.name;
    }
    if (outcome === 200) {
      durations.push(performance.now() - started);
    } else {
      const key = String(outcome);
      failures.set(key, (failures.get(key) ?? 0) + 1);
    }
  }
}

const preflight = await probe();
if (preflight !== 200) throw new Error('Local readiness preflight returned HTTP ' + preflight);
const started = performance.now();
await Promise.all(Array.from({ length: concurrency }, worker));
const elapsed = (performance.now() - started) / 1000;
durations.sort((a, b) => a - b);

function percentile(value) {
  if (!durations.length) return null;
  return Number(durations[Math.ceil(durations.length * value) - 1].toFixed(2));
}

console.log(JSON.stringify({
  target: url,
  concurrency,
  requests,
  attempted: allocated,
  success: durations.length,
  failures: Object.fromEntries(failures),
  successPerSecond: Number((durations.length / elapsed).toFixed(2)),
  successLatencyMs: { p50: percentile(0.5), p95: percentile(0.95), p99: percentile(0.99) },
}, null, 2));
if (durations.length !== requests) process.exitCode = 1;
