import http from "k6/http";
import { check, sleep } from "k6";

// Quick 30-second test for cloud metrics
export const options = {
  vus: 100,                // 100 concurrent users
  duration: "2m",       // short 2-minute test
  thresholds: {
    http_req_failed: ["rate<0.02"],
    http_req_duration: ["p(95)<800"],
  },
};

// local or Cloud API URL - update this to match your cloud endpoint
//const BASE_URL = 'http://localhost:8000'; // override when running
const BASE_URL = "https://54-225-66-151.nip.io"; // cloud deployment URL
const API_URL = `${BASE_URL}/health`;

export default function () {
  const res = http.get(API_URL);

  check(res, {
    "status is 2xx": (r) => r.status >= 200 && r.status < 300,
  });

  sleep(1);
}
