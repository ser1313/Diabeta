#!/usr/bin/env node
/**
 * DIABETA integration smoke test: health -> login -> authenticated glucose read.
 * Uses only Node 22 built-ins. Never creates or modifies clinical records.
 *
 * Usage:
 * API_URL=http://localhost:3000 TEST_EMAIL=... TEST_PASSWORD=... node scripts/smoke-test.mjs
 */
const baseUrl = (process.env.API_URL ?? "http://localhost:3000").replace(/\/$/, "");
const email = process.env.TEST_EMAIL;
const password = process.env.TEST_PASSWORD;
const timeoutMs = Number(process.env.TEST_TIMEOUT_MS ?? 8000);

async function request(path, options = {}) {
  const controller = new AbortController();
  const timer = setTimeout(() => controller.abort(), timeoutMs);
  try {
    return await fetch(`${baseUrl}${path}`, {
      ...options,
      signal: controller.signal,
      headers: { "content-type": "application/json", ...(options.headers ?? {}) },
    });
  } finally {
    clearTimeout(timer);
  }
}

async function main() {
  const health = await request("/health");
  if (!health.ok) throw new Error(`Health endpoint failed: HTTP ${health.status}`);
  const healthBody = await health.json();
  if (healthBody.status !== "ok") throw new Error("Unexpected health response");

  if (!email || !password) {
    console.log("PASS health; SKIP auth (set TEST_EMAIL and TEST_PASSWORD to test login and protected API).");
    return;
  }

  const login = await request("/auth/login", {
    method: "POST",
    body: JSON.stringify({ email, password }),
  });
  if (!login.ok) throw new Error(`Login failed: HTTP ${login.status}`);
  const loginBody = await login.json();
  if (typeof loginBody.accessToken !== "string" || !loginBody.accessToken) {
    throw new Error("Login response did not contain accessToken");
  }

  const glucose = await request("/glucose", {
    headers: { authorization: `Bearer ${loginBody.accessToken}` },
  });
  if (!glucose.ok) throw new Error(`Authenticated glucose read failed: HTTP ${glucose.status}`);
  if (!Array.isArray(await glucose.json())) throw new Error("Glucose endpoint did not return a list");

  console.log("PASS health -> login -> authenticated glucose read.");
}

main().catch((error) => {
  console.error(`FAIL DIABETA smoke test: ${error.message}`);
  process.exitCode = 1;
});
