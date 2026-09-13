const http = require('http');

const PORT = 8085;

// Complete mock telemetry state for all YoRHa Rainmeter suite modules
const state = {
  // ==========================================
  // DISKS MODULE
  // ==========================================
  ssd: {
    temp: '26.0 °C',
    readRate: '24.5 MB/s',
    writeRate: '68.0 MB/s',
    readAct: '5.0 %',
    writeAct: '8.5 %',
  },
  nvme: {
    temp: '32.0 °C',
    readRate: '450.0 MB/s',
    writeRate: '820.0 MB/s',
    readAct: '7.0 %',
    writeAct: '12.0 %',
  },
  hdd: {
    temp: '24.0 °C',
    readRate: '12.0 MB/s',
    writeRate: '22.5 MB/s',
    readAct: '4.0 %',
    writeAct: '7.5 %',
  },

  // ==========================================
  // CPU MODULE (13th Gen Intel Core i7-13700K: 8P + 8E = 24 threads)
  // ==========================================
  cpu: {
    totalLoad: '14.2 %',
    temp: '46.0 °C',
    coreMaxTemp: '52.0 °C',
    // P-Cores Thread 1 (Cores 1-8 Primary)
    threads: [
      '18.5 %', '12.0 %', '24.0 %', '15.5 %', '10.0 %', '8.0 %', '22.0 %', '14.0 %',
      // P-Cores Thread 2 (Cores 1-8 Hyperthreaded)
      '6.0 %', '4.5 %', '11.0 %', '5.0 %', '3.5 %', '2.0 %', '9.0 %', '5.5 %',
      // E-Cores (Cores 9-16 Single-threaded)
      '16.0 %', '14.5 %', '20.0 %', '18.0 %', '12.5 %', '10.0 %', '15.0 %', '11.5 %'
    ]
  },

  // ==========================================
  // GPU MODULE (NVIDIA GeForce RTX 4070 Ti)
  // ==========================================
  gpu: {
    load: '22.5 %',
    vramLoad: '34.2 %',
    temp: '44.0 °C',
    hotspot: '53.0 °C',
    fan: '950 RPM',
  },

  // ==========================================
  // RAM MODULE (DDR5 Dual Channel)
  // ==========================================
  ram: {
    dimm1Temp: '38.5 °C',
    dimm3Temp: '39.0 °C',
  },

  // ==========================================
  // FANS MODULE (Motherboard / Case Arrays)
  // ==========================================
  fans: {
    cpu: '1020 RPM',
    gpu: '950 RPM',
    exhaust: '685 RPM',
    top: '860 RPM',
    front: '840 RPM',
    side: '740 RPM',
  }
};

/**
 * Builds the complete LHM JSON tree.
 * Node layout rules:
 * 1. "Text" appears first (matches `(?s).*?"Text":\s*"<NAME>".*?"Value":\s*"([\d\.,]+)`)
 * 2. "Value" precedes "SensorId" (matches `(?s).*?"Value":\s*"([^"]+)",[^}]*?"SensorId":\s*"..."`)
 */
function getTelemetryJson() {
  const data = {
    id: 0,
    Text: 'Sensor',
    Children: [
      // -------------------------------------------------------------
      // CPU
      // -------------------------------------------------------------
      {
        id: 1,
        Text: '13th Gen Intel Core i7-13700K',
        Children: [
          { id: 101, Text: 'CPU Total', Value: state.cpu.totalLoad, SensorId: '/intelcpu/0/load/0' },
          { id: 102, Text: 'CPU Package', Value: state.cpu.temp, SensorId: '/intelcpu/0/temperature/1' },
          { id: 103, Text: 'Core Max', Value: state.cpu.coreMaxTemp, SensorId: '/intelcpu/0/temperature/0' },

          // Row 1: P-Cores Thread 1
          { id: 111, Text: 'CPU Core #1 Thread #1', Value: state.cpu.threads[0], SensorId: '/intelcpu/0/load/1' },
          { id: 112, Text: 'CPU Core #2 Thread #1', Value: state.cpu.threads[1], SensorId: '/intelcpu/0/load/2' },
          { id: 113, Text: 'CPU Core #3 Thread #1', Value: state.cpu.threads[2], SensorId: '/intelcpu/0/load/3' },
          { id: 114, Text: 'CPU Core #4 Thread #1', Value: state.cpu.threads[3], SensorId: '/intelcpu/0/load/4' },
          { id: 115, Text: 'CPU Core #5 Thread #1', Value: state.cpu.threads[4], SensorId: '/intelcpu/0/load/5' },
          { id: 116, Text: 'CPU Core #6 Thread #1', Value: state.cpu.threads[5], SensorId: '/intelcpu/0/load/6' },
          { id: 117, Text: 'CPU Core #7 Thread #1', Value: state.cpu.threads[6], SensorId: '/intelcpu/0/load/7' },
          { id: 118, Text: 'CPU Core #8 Thread #1', Value: state.cpu.threads[7], SensorId: '/intelcpu/0/load/8' },

          // Row 2: P-Cores Thread 2
          { id: 121, Text: 'CPU Core #1 Thread #2', Value: state.cpu.threads[8], SensorId: '/intelcpu/0/load/9' },
          { id: 122, Text: 'CPU Core #2 Thread #2', Value: state.cpu.threads[9], SensorId: '/intelcpu/0/load/10' },
          { id: 123, Text: 'CPU Core #3 Thread #2', Value: state.cpu.threads[10], SensorId: '/intelcpu/0/load/11' },
          { id: 124, Text: 'CPU Core #4 Thread #2', Value: state.cpu.threads[11], SensorId: '/intelcpu/0/load/12' },
          { id: 125, Text: 'CPU Core #5 Thread #2', Value: state.cpu.threads[12], SensorId: '/intelcpu/0/load/13' },
          { id: 126, Text: 'CPU Core #6 Thread #2', Value: state.cpu.threads[13], SensorId: '/intelcpu/0/load/14' },
          { id: 127, Text: 'CPU Core #7 Thread #2', Value: state.cpu.threads[14], SensorId: '/intelcpu/0/load/15' },
          { id: 128, Text: 'CPU Core #8 Thread #2', Value: state.cpu.threads[15], SensorId: '/intelcpu/0/load/16' },

          // Row 3: E-Cores (Cores 9-16)
          { id: 131, Text: 'CPU Core #9', Value: state.cpu.threads[16], SensorId: '/intelcpu/0/load/17' },
          { id: 132, Text: 'CPU Core #10', Value: state.cpu.threads[17], SensorId: '/intelcpu/0/load/18' },
          { id: 133, Text: 'CPU Core #11', Value: state.cpu.threads[18], SensorId: '/intelcpu/0/load/19' },
          { id: 134, Text: 'CPU Core #12', Value: state.cpu.threads[19], SensorId: '/intelcpu/0/load/20' },
          { id: 135, Text: 'CPU Core #13', Value: state.cpu.threads[20], SensorId: '/intelcpu/0/load/21' },
          { id: 136, Text: 'CPU Core #14', Value: state.cpu.threads[21], SensorId: '/intelcpu/0/load/22' },
          { id: 137, Text: 'CPU Core #15', Value: state.cpu.threads[22], SensorId: '/intelcpu/0/load/23' },
          { id: 138, Text: 'CPU Core #16', Value: state.cpu.threads[23], SensorId: '/intelcpu/0/load/24' }
        ]
      },

      // -------------------------------------------------------------
      // MOTHERBOARD / FANS
      // -------------------------------------------------------------
      {
        id: 2,
        Text: 'Nuvoton NCT6798D',
        Children: [
          { id: 201, Text: 'Fan #1 (CPU)', Value: state.fans.cpu, SensorId: '/lpc/nct6798d/0/fan/0' },
          { id: 202, Text: 'Fan #2 (Exhaust)', Value: state.fans.exhaust, SensorId: '/lpc/nct6798d/0/fan/1' },
          { id: 203, Text: 'Fan #3 (Top)', Value: state.fans.top, SensorId: '/lpc/nct6798d/0/fan/2' },
          { id: 204, Text: 'Fan #4 (Front)', Value: state.fans.front, SensorId: '/lpc/nct6798d/0/fan/3' },
          { id: 206, Text: 'Fan #6 (Side)', Value: state.fans.side, SensorId: '/lpc/nct6798d/0/fan/5' }
        ]
      },

      // -------------------------------------------------------------
      // GPU
      // -------------------------------------------------------------
      {
        id: 3,
        Text: 'NVIDIA GeForce RTX 4070 Ti',
        Children: [
          { id: 301, Text: 'GPU Core Load', Value: state.gpu.load, SensorId: '/gpu-nvidia/0/load/0' },
          { id: 302, Text: 'GPU Memory Load', Value: state.gpu.vramLoad, SensorId: '/gpu-nvidia/0/load/3' },
          { id: 303, Text: 'GPU Temperature', Value: state.gpu.temp, SensorId: '/gpu-nvidia/0/temperature/0' },
          { id: 304, Text: 'GPU Hot Spot Temperature', Value: state.gpu.hotspot, SensorId: '/gpu-nvidia/0/temperature/2' },
          { id: 305, Text: 'GPU Fan #1', Value: state.fans.gpu, SensorId: '/gpu-nvidia/0/fan/1' }
        ]
      },

      // -------------------------------------------------------------
      // RAM
      // -------------------------------------------------------------
      {
        id: 4,
        Text: 'Generic Memory',
        Children: [
          { id: 401, Text: 'DIMM 1 Temperature', Value: state.ram.dimm1Temp, SensorId: '/memory/dimm/1/temperature/0' },
          { id: 403, Text: 'DIMM 3 Temperature', Value: state.ram.dimm3Temp, SensorId: '/memory/dimm/3/temperature/0' }
        ]
      },

      // -------------------------------------------------------------
      // STORAGE DISKS
      // -------------------------------------------------------------
      {
        id: 5,
        Text: 'Storage Disks',
        Children: [
          // Disk 1: SSD (/ssd/0)
          { id: 510, Text: 'SSD Temperature', Value: state.ssd.temp, SensorId: '/ssd/0/temperature/0' },
          { id: 511, Text: 'SSD Read Rate', Value: state.ssd.readRate, SensorId: '/ssd/0/throughput/54' },
          { id: 512, Text: 'SSD Write Rate', Value: state.ssd.writeRate, SensorId: '/ssd/0/throughput/55' },
          { id: 513, Text: 'SSD Read Activity', Value: state.ssd.readAct, SensorId: '/ssd/0/load/51' },
          { id: 514, Text: 'SSD Write Activity', Value: state.ssd.writeAct, SensorId: '/ssd/0/load/52' },

          // Disk 2: NVMe (/nvme/2)
          { id: 520, Text: 'NVMe Temperature', Value: state.nvme.temp, SensorId: '/nvme/2/temperature/0' },
          { id: 521, Text: 'NVMe Read Rate', Value: state.nvme.readRate, SensorId: '/nvme/2/throughput/54' },
          { id: 522, Text: 'NVMe Write Rate', Value: state.nvme.writeRate, SensorId: '/nvme/2/throughput/55' },
          { id: 523, Text: 'NVMe Read Activity', Value: state.nvme.readAct, SensorId: '/nvme/2/load/51' },
          { id: 524, Text: 'NVMe Write Activity', Value: state.nvme.writeAct, SensorId: '/nvme/2/load/52' },

          // Disk 3: HDD (/hdd/1)
          { id: 530, Text: 'HDD Temperature', Value: state.hdd.temp, SensorId: '/hdd/1/temperature/0' },
          { id: 531, Text: 'HDD Read Rate', Value: state.hdd.readRate, SensorId: '/hdd/1/throughput/54' },
          { id: 532, Text: 'HDD Write Rate', Value: state.hdd.writeRate, SensorId: '/hdd/1/throughput/55' },
          { id: 533, Text: 'HDD Read Activity', Value: state.hdd.readAct, SensorId: '/hdd/1/load/51' },
          { id: 534, Text: 'HDD Write Activity', Value: state.hdd.writeAct, SensorId: '/hdd/1/load/52' }
        ]
      }
    ]
  };

  return JSON.stringify(data, null, 2);
}

const server = http.createServer((req, res) => {
  const url = new URL(req.url, `http://${req.headers.host}`);
  const q = url.searchParams;

  // Query parameter overrides
  if (q.has('ssdRead')) state.ssd.readAct = `${q.get('ssdRead')} %`;
  if (q.has('ssdWrite')) state.ssd.writeAct = `${q.get('ssdWrite')} %`;
  if (q.has('nvmeRead')) state.nvme.readAct = `${q.get('nvmeRead')} %`;
  if (q.has('nvmeWrite')) state.nvme.writeAct = `${q.get('nvmeWrite')} %`;
  if (q.has('hddRead')) state.hdd.readAct = `${q.get('hddRead')} %`;
  if (q.has('hddWrite')) state.hdd.writeAct = `${q.get('hddWrite')} %`;
  if (q.has('cpuLoad')) state.cpu.totalLoad = `${q.get('cpuLoad')} %`;
  if (q.has('gpuLoad')) state.gpu.load = `${q.get('gpuLoad')} %`;

  const jsonResponse = getTelemetryJson();
  res.writeHead(200, {
    'Content-Type': 'application/json; charset=utf-8',
    'Content-Length': Buffer.byteLength(jsonResponse, 'utf8'),
    'Access-Control-Allow-Origin': '*',
  });
  res.end(jsonResponse);
});

server.listen(PORT, '127.0.0.1', () => {
  console.log('============================================================');
  console.log(` YoRHa Telemetry Mock Server running on http://127.0.0.1:${PORT}`);
  console.log(' Providing signals for: Disks, CPU (24 threads), GPU, Fans, RAM');
  console.log(' Disks:');
  console.log(`   SSD  : Read = ${state.ssd.readAct} (${state.ssd.readRate}) | Write = ${state.ssd.writeAct} (${state.ssd.writeRate})`);
  console.log(`   NVMe : Read = ${state.nvme.readAct} (${state.nvme.readRate}) | Write = ${state.nvme.writeAct} (${state.nvme.writeRate})`);
  console.log(`   HDD  : Read = ${state.hdd.readAct} (${state.hdd.readRate}) | Write = ${state.hdd.writeAct} (${state.hdd.writeRate})`);
  console.log(` CPU    : Total = ${state.cpu.totalLoad} | Temp = ${state.cpu.temp}`);
  console.log(` GPU    : Core = ${state.gpu.load} | VRAM = ${state.gpu.vramLoad} | Temp = ${state.gpu.temp}`);
  console.log(` Fans   : CPU = ${state.fans.cpu} | GPU = ${state.fans.gpu}`);
  console.log(' Press Ctrl+C to terminate.');
  console.log('============================================================');
});
