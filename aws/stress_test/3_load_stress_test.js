import http from "k6/http";
import { check, sleep } from "k6";
import { Trend, Counter } from "k6/metrics";

// Custom metrics
const latency = new Trend("latency_ms");
const errorCount = new Counter("errors");

// Read max users & duration from env, with defaults
const MAX_VUS = 100;       // 100 by default
const TEST_DURATION = "2m";  // 2m by default

export const options = {
  insecureSkipTLSVerify: true,
  stages: [
    { duration: "30s", target: MAX_VUS },   // ramp up to MAX_VUS
    { duration: TEST_DURATION, target: MAX_VUS }, // hold at MAX_VUS
    { duration: "30s", target: 0 },         // ramp down
  ],
  thresholds: {
    http_req_failed: ["rate<0.02"],       // <2% errors
    http_req_duration: ["p(95)<800"],     // 95% < 800ms
    latency_ms: ["p(95)<800"],
  },
};

// Set API URL via env or fallback
const API_URL = "http://localhost:8000/health";
//const API_URL = "https://54-225-66-151.nip.io/health"; // cloud deployment URL

export default function () {
  const res = http.get(API_URL);

  latency.add(res.timings.duration);

  const ok = check(res, {
    "status is 2xx": (r) => r.status >= 200 && r.status < 300,
  });

  if (!ok) {
    errorCount.add(1);
  }

  sleep(1); // small think-time
}
