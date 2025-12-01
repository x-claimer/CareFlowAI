import http from 'k6/http';
import { check, sleep } from 'k6';

//const BASE_URL = 'http://localhost:8000'; // override when running
const BASE_URL = "https://54-225-66-151.nip.io"; // cloud deployment URL

// JWT token for authentication
const AUTH_TOKEN = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiJhZG1pbkBob3NwaXRhbC5jb20iLCJyb2xlIjoiYWRtaW4iLCJleHAiOjE3NjQ2MDkyMzd9.PIdRmidD3GPe0RPwLXWMtbcSSiHQNWd12PH7eZyO9NM';

export const options = {
    // same for local & cloud so numbers are comparable
    vus: 100,                // concurrent virtual users
    duration: '2m',         // total test duration
    thresholds: {
        http_req_failed: ['rate<0.02'],   // < 2% failures
        http_req_duration: ['p(95)<800'], // 95% requests under 800 ms (example SLA)
    },
};

export default function () {
    // realistic request body that triggers your usual pipeline (Gemini + DB)
    const payload = JSON.stringify({
        "query": "Cancer"
    });

    const res = http.post(`${BASE_URL}/api/ai/tutor/search/`, payload, {
        headers: {
            'Content-Type': 'application/json',
            'Authorization': `Bearer ${AUTH_TOKEN}`,
            'accept': 'application/json'
        },
    });

    check(res, {
        'status is 2xx': (r) => r.status >= 200 && r.status < 300,
    });

    // small think-time to simulate real users
    sleep(1);
}
