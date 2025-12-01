/**
 * Extract and compare performance metrics from k6 load test results
 * Usage: node extract_metrics.js [local_results.json] [cloud_results.json]
 */

const fs = require('fs');
const path = require('path');

function extractMetrics(jsonFile) {
    try {
        const content = fs.readFileSync(jsonFile, 'utf8');
        let data = JSON.parse(content);

        // Handle k6 --summary-export format (direct metrics object)
        if (data.metrics) {
            const metrics = data.metrics;
            const duration = metrics.http_req_duration;
            const reqs = metrics.http_reqs;
            const iterations = metrics.iterations;
            const failed = metrics.http_req_failed;

            return {
                'Avg latency': `${duration.avg.toFixed(2)}ms`,
                'P95 latency': `${duration['p(95)'].toFixed(2)}ms`,
                'P90 latency': `${duration['p(90)'].toFixed(2)}ms`,
                'Max latency': `${duration.max.toFixed(2)}ms`,
                'Min latency': `${duration.min.toFixed(2)}ms`,
                'Median latency': `${duration.med.toFixed(2)}ms`,
                'Throughput': `${reqs.rate.toFixed(2)} req/sec`,
                'Total requests': reqs.count,
                'Total iterations': iterations.count,
                'Error rate': `${(failed.rate * 100).toFixed(2)}%`,
                'Success rate': `${((1 - failed.rate) * 100).toFixed(2)}%`
            };
        }

        // Fallback: k6 JSON output format (one JSON object per line)
        const lines = content.trim().split('\n');
        for (const line of lines) {
            try {
                const obj = JSON.parse(line);
                // Look for the summary object that has all metrics
                if (obj.type === 'summary' || obj.metrics) {
                    data = obj;
                    break;
                }
            } catch (e) {
                // Skip invalid JSON lines
                continue;
            }
        }

        if (!data || !data.metrics) {
            console.error(`Could not find metrics summary in ${jsonFile}`);
            return null;
        }

        const duration = data.metrics.http_req_duration;
        const reqs = data.metrics.http_reqs;
        const iterations = data.metrics.iterations;
        const failed = data.metrics.http_req_failed;

        return {
            'Avg latency': `${duration.avg.toFixed(2)}ms`,
            'P95 latency': `${duration['p(95)'].toFixed(2)}ms`,
            'P90 latency': `${duration['p(90)'].toFixed(2)}ms`,
            'Max latency': `${duration.max.toFixed(2)}ms`,
            'Min latency': `${duration.min.toFixed(2)}ms`,
            'Median latency': `${duration.med.toFixed(2)}ms`,
            'Throughput': `${reqs.rate.toFixed(2)} req/sec`,
            'Total requests': reqs.count,
            'Total iterations': iterations.count,
            'Error rate': `${(failed.value * 100).toFixed(2)}%`,
            'Success rate': `${((1 - failed.value) * 100).toFixed(2)}%`
        };
    } catch (error) {
        console.error(`Error reading ${jsonFile}:`, error.message);
        return null;
    }
}

function printMetrics(label, metrics) {
    if (!metrics) {
        console.log(`\n❌ ${label}: No data available\n`);
        return;
    }

    console.log(`\n📊 ${label}`);
    console.log('═'.repeat(60));
    Object.entries(metrics).forEach(([key, value]) => {
        console.log(`  ${key.padEnd(20)}: ${value}`);
    });
    console.log('═'.repeat(60));
}

function compareMetrics(localMetrics, cloudMetrics) {
    if (!localMetrics || !cloudMetrics) {
        console.log('\n⚠️  Cannot compare - missing data\n');
        return;
    }

    console.log('\n🔄 Comparison (Local vs Cloud)');
    console.log('═'.repeat(60));

    // Extract numeric values for comparison
    const parseMs = (str) => parseFloat(str.replace('ms', ''));
    const parseReqSec = (str) => parseFloat(str.replace(' req/sec', ''));
    const parsePercent = (str) => parseFloat(str.replace('%', ''));

    const comparisons = [
        {
            metric: 'Avg latency',
            local: parseMs(localMetrics['Avg latency']),
            cloud: parseMs(cloudMetrics['Avg latency']),
            unit: 'ms',
            lower_is_better: true
        },
        {
            metric: 'P95 latency',
            local: parseMs(localMetrics['P95 latency']),
            cloud: parseMs(cloudMetrics['P95 latency']),
            unit: 'ms',
            lower_is_better: true
        },
        {
            metric: 'Max latency',
            local: parseMs(localMetrics['Max latency']),
            cloud: parseMs(cloudMetrics['Max latency']),
            unit: 'ms',
            lower_is_better: true
        },
        {
            metric: 'Throughput',
            local: parseReqSec(localMetrics['Throughput']),
            cloud: parseReqSec(cloudMetrics['Throughput']),
            unit: 'req/sec',
            lower_is_better: false
        }
    ];

    comparisons.forEach(({ metric, local, cloud, unit, lower_is_better }) => {
        const diff = ((cloud - local) / local * 100).toFixed(2);
        const diffStr = diff > 0 ? `+${diff}%` : `${diff}%`;

        let indicator;
        if (lower_is_better) {
            indicator = cloud < local ? '✅ Better' : '⚠️  Ok';
        } else {
            indicator = cloud > local ? '✅ Better' : '⚠️  Ok';
        }

        console.log(`  ${metric.padEnd(20)}: ${local.toFixed(2)}${unit} → ${cloud.toFixed(2)}${unit} (${diffStr}) ${indicator}`);
    });

    console.log('═'.repeat(60));
}

function generateMarkdownTable(localMetrics, cloudMetrics) {
    if (!localMetrics && !cloudMetrics) {
        return '\n⚠️  No data to generate table\n';
    }

    console.log('\n📋 Markdown Table (copy-paste ready)');
    console.log('═'.repeat(60));

    const table = `
| Metric | Local | Cloud |
|--------|-------|-------|
| **Avg latency** | ${localMetrics?.['Avg latency'] || 'N/A'} | ${cloudMetrics?.['Avg latency'] || 'N/A'} |
| **P95 latency** | ${localMetrics?.['P95 latency'] || 'N/A'} | ${cloudMetrics?.['P95 latency'] || 'N/A'} |
| **Max latency** | ${localMetrics?.['Max latency'] || 'N/A'} | ${cloudMetrics?.['Max latency'] || 'N/A'} |
| **Throughput** | ${localMetrics?.['Throughput'] || 'N/A'} | ${cloudMetrics?.['Throughput'] || 'N/A'} |
| **Total requests** | ${localMetrics?.['Total requests'] || 'N/A'} | ${cloudMetrics?.['Total requests'] || 'N/A'} |
| **Success rate** | ${localMetrics?.['Success rate'] || 'N/A'} | ${cloudMetrics?.['Success rate'] || 'N/A'} |
`;

    console.log(table);
    console.log('═'.repeat(60));
}

// Main execution
const args = process.argv.slice(2);

// Default file paths
const localFile = args[0] || path.join(__dirname, 'local_results.json');
const cloudFile = args[1] || path.join(__dirname, 'cloud_results.json');

console.log('\n🚀 CareFlowAI Performance Metrics Extractor');
console.log('═'.repeat(60));
console.log(`  Local file:  ${localFile}`);
console.log(`  Cloud file:  ${cloudFile}`);

// Extract metrics
const localMetrics = fs.existsSync(localFile) ? extractMetrics(localFile) : null;
const cloudMetrics = fs.existsSync(cloudFile) ? extractMetrics(cloudFile) : null;

// Print individual metrics
printMetrics('LOCAL ENVIRONMENT', localMetrics);
printMetrics('CLOUD ENVIRONMENT', cloudMetrics);

// Compare metrics
if (localMetrics && cloudMetrics) {
    compareMetrics(localMetrics, cloudMetrics);
    generateMarkdownTable(localMetrics, cloudMetrics);
} else {
    console.log('\n💡 Tip: Run both local and cloud tests to enable comparison');
    console.log('   Local:  k6 run --out json=local_results.json aws/stress_test/load_stress_test.js');
    console.log('   Cloud:  k6 run --out json=cloud_results.json aws/stress_test/load_stress_test.js');
}

console.log('\n✨ Done!\n');
