<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>BLDC Motor Live Dashboard</title>
    <script src="https://cdnjs.cloudflare.com/ajax/libs/Chart.js/4.4.0/chart.umd.min.js"></script>
    <style>
        * { box-sizing: border-box; margin: 0; padding: 0; }
        body {
            font-family: Arial, sans-serif;
            background: #1e1e1e;
            color: white;
            padding: 20px;
        }
        h1 { color: #00bfff; text-align: center; margin-bottom: 20px; }

        .status {
            text-align: center;
            padding: 8px;
            border-radius: 6px;
            margin-bottom: 15px;
            font-weight: bold;
        }
        .ok      { background: #2d6a2d; color: #51cf66; }
        .error   { background: #6a2d2d; color: #ff6b6b; }
        .waiting { background: #4a4a00; color: #ffd43b; }

        .controls {
            display: flex;
            gap: 10px;
            justify-content: center;
            margin-bottom: 20px;
        }
        button {
            padding: 10px 24px;
            border: none;
            border-radius: 6px;
            font-size: 1em;
            font-weight: bold;
            cursor: pointer;
        }
        .btn-start    { background: #51cf66; color: black; }
        .btn-freeze   { background: #ffd43b; color: black; }
        .btn-shutdown { background: #ff6b6b; color: black; }

        .cards {
            display: grid;
            grid-template-columns: repeat(4, 1fr);
            gap: 15px;
            margin-bottom: 20px;
        }
        .card {
            background: #2b2b2b;
            border-radius: 8px;
            padding: 20px;
            text-align: center;
            border: 1px solid #444;
        }
        .card .value { font-size: 2em; font-weight: bold; color: #00bfff; }
        .card .label { color: #aaaaaa; margin-top: 5px; font-size: 0.9em; }

        .voltage-buttons {
            display: flex;
            gap: 8px;
            justify-content: center;
            margin-bottom: 20px;
            flex-wrap: wrap;
        }
        .volt-btn {
            background: #444;
            color: white;
            padding: 8px 16px;
            font-size: 0.9em;
        }

        .load-control {
            text-align: center;
            margin-bottom: 20px;
        }
        .load-control label { color: #aaaaaa; margin-right: 10px; }
        input[type=range] { width: 300px; }

        .charts {
            display: grid;
            grid-template-columns: 1fr 1fr;
            gap: 15px;
        }
        .chart-box {
            background: #2b2b2b;
            border-radius: 8px;
            padding: 20px;
            border: 1px solid #444;
        }
        .chart-box h3 {
            color: #aaaaaa;
            margin-bottom: 10px;
            font-size: 0.85em;
            text-transform: uppercase;
        }
    </style>
</head>
<body>

<h1>Castle Creations 2200KV BLDC Motor</h1>

<div id="status" class="status waiting">Waiting for simulation...</div>

<!-- Sim controls -->
<div class="controls">
    <button class="btn-start"    onclick="simCmd('run')">▶ Start</button>
    <button class="btn-freeze"   onclick="simCmd('freeze')">⏸ Freeze</button>
    <button class="btn-shutdown" onclick="simCmd('shutdown')">⏹ Shutdown</button>
</div>

<!-- Voltage quick select -->
<div class="voltage-buttons">
    <span style="color:#aaa; line-height:2em;">Voltage:</span>
    <button class="volt-btn" onclick="setVoltage(3.7)">1S 3.7V</button>
    <button class="volt-btn" onclick="setVoltage(7.4)">2S 7.4V</button>
    <button class="volt-btn" onclick="setVoltage(11.1)">3S 11.1V</button>
    <button class="volt-btn" onclick="setVoltage(14.8)">4S 14.8V</button>
    <button class="volt-btn" onclick="setVoltage(18.5)">5S 18.5V</button>
    <button class="volt-btn" onclick="setVoltage(22.2)">6S 22.2V</button>
</div>

<!-- Load control -->
<div class="load-control">
    <label>Load Torque: <span id="load_val">0.00</span> N·m</label>
    <input type="range" min="0" max="5" step="0.01" value="0"
        oninput="document.getElementById('load_val').textContent =
            parseFloat(this.value).toFixed(2); setLoad(this.value)">
</div>

<!-- Cards -->
<div class="cards">
    <div class="card">
        <div class="value" id="rpm">---</div>
        <div class="label">RPM</div>
    </div>
    <div class="card">
        <div class="value" id="current">---</div>
        <div class="label">Current (A)</div>
    </div>
    <div class="card">
        <div class="value" id="voltage">---</div>
        <div class="label">Voltage (V)</div>
    </div>
    <div class="card">
        <div class="value" id="power">---</div>
        <div class="label">Power (W)</div>
    </div>
    <div class="card">
        <div class="value" id="torque">---</div>
        <div class="label">Torque (N·m)</div>
    </div>
    <div class="card">
        <div class="value" id="back_emf">---</div>
        <div class="label">Back-EMF (V)</div>
    </div>
    <div class="card">
        <div class="value" id="time">---</div>
        <div class="label">Sim Time (s)</div>
    </div>
    <div class="card">
        <div class="value" id="efficiency">---</div>
        <div class="label">Efficiency (%)</div>
    </div>
</div>

<!-- Charts -->
<div class="charts">
    <div class="chart-box">
        <h3>RPM vs Time</h3>
        <canvas id="rpmChart"></canvas>
    </div>
    <div class="chart-box">
        <h3>Current vs Time</h3>
        <canvas id="currentChart"></canvas>
    </div>
    <div class="chart-box">
        <h3>Power vs Time</h3>
        <canvas id="powerChart"></canvas>
    </div>
    <div class="chart-box">
        <h3>Back-EMF vs Time</h3>
        <canvas id="bemfChart"></canvas>
    </div>
</div>

<script>
const MAX_POINTS = 300;

function makeChart(id, label, color) {
    return new Chart(document.getElementById(id), {
        type: 'line',
        data: {
            labels: [],
            datasets: [{
                label: label,
                data: [],
                borderColor: color,
                backgroundColor: color + '22',
                borderWidth: 2,
                pointRadius: 0,
                tension: 0.1
            }]
        },
        options: {
            responsive: true,
            animation: false,
            plugins: { legend: { labels: { color: 'white' } } },
            scales: {
                x: {
                    ticks: { color: '#888', maxTicksLimit: 6 },
                    title: { display: true, text: 'Time (s)', color: '#888' }
                },
                y: {
                    ticks: { color: '#888' }
                }
            }
        }
    });
}

const rpmChart     = makeChart('rpmChart',     'RPM',         '#00bfff');
const currentChart = makeChart('currentChart', 'Current (A)', '#ff6b6b');
const powerChart   = makeChart('powerChart',   'Power (W)',   '#51cf66');
const bemfChart    = makeChart('bemfChart',    'Back-EMF (V)','#ffd43b');

function addPoint(chart, time, value) {
    chart.data.labels.push(time.toFixed(2));
    chart.data.datasets[0].data.push(value);
    if (chart.data.labels.length > MAX_POINTS) {
        chart.data.labels.shift();
        chart.data.datasets[0].data.shift();
    }
    chart.update('none');
}

async function fetchData() {
    try {
        const r = await fetch('/motor/data');
        const d = await r.json();

        document.getElementById('status').className = 'status ok';
        document.getElementById('status').textContent =
            'Running — t = ' + d.time.toFixed(3) + 's';

        document.getElementById('rpm').textContent      = Math.round(d.rpm);
        document.getElementById('current').textContent  = d.current.toFixed(2);
        document.getElementById('voltage').textContent  = d.voltage.toFixed(1);
        document.getElementById('power').textContent    = d.power.toFixed(1);
        document.getElementById('torque').textContent   = d.torque.toFixed(4);
        document.getElementById('back_emf').textContent = d.back_emf.toFixed(3);
        document.getElementById('time').textContent     = d.time.toFixed(3);

        const mech = d.torque * (d.rpm * 2 * Math.PI / 60);
        const eff  = d.power > 0 ? (mech / d.power * 100).toFixed(1) : '0.0';
        document.getElementById('efficiency').textContent = eff;

        addPoint(rpmChart,     d.time, d.rpm);
        addPoint(currentChart, d.time, d.current);
        addPoint(powerChart,   d.time, d.power);
        addPoint(bemfChart,    d.time, d.back_emf);

    } catch(e) {
        document.getElementById('status').className = 'status error';
        document.getElementById('status').textContent = 'Simulation not running';
    }
}

async function simCmd(action) {
    await fetch('/motor/control?action=' + action);
}

async function setVoltage(v) {
    await fetch('/motor/control?voltage=' + v);
}

async function setLoad(l) {
    await fetch('/motor/control?load=' + l);
}

setInterval(fetchData, 200);
fetchData();
</script>
</body>
</html>