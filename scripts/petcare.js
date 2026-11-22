// PetCare - Script de controle do projeto (Node.js, modulos nativos)
// Uso: node scripts/petcare.js checar
//      node scripts/petcare.js iniciar --sem-front
//      node scripts/petcare.js front --dispositivo=emulator-5554
//      node scripts/petcare.js verificar

'use strict';

const { execFileSync, execSync, spawn } = require('child_process');
const net = require('net');
const http = require('http');
const os = require('os');
const fs = require('fs');
const path = require('path');
const readline = require('readline');

// ---------------------------------------------------------------------------
// Constantes de caminho
// ---------------------------------------------------------------------------
const SCRIPT_DIR = __dirname;
const REPO_ROOT = path.resolve(SCRIPT_DIR, '..');
const JAVA_DIR = path.join(REPO_ROOT, 'servidor_java');
const BACK_DIR = path.join(REPO_ROOT, 'backend');
const FRONT_DIR = path.join(REPO_ROOT, 'frontend');

const PORTA_JAVA = 5000;
const PORTA_BACK = 3000;

// ---------------------------------------------------------------------------
// Verificacao de plataforma
// ---------------------------------------------------------------------------
if (os.platform() !== 'win32') {
  console.error('[ERRO] Este script suporta apenas Windows (PowerShell / CMD). Sistema detectado: ' + os.platform());
  process.exit(1);
}

// ---------------------------------------------------------------------------
// Parse de argumentos
// ---------------------------------------------------------------------------
const rawArgs = process.argv.slice(2);
let acao = '';
const flags = {
  dispositivo: '',
  ip: '',
  comLembretes: false,
  semFront: false,
  janelas: false,
  dryRun: false,
};

for (const arg of rawArgs) {
  if (arg.startsWith('--dispositivo=')) {
    flags.dispositivo = arg.split('=')[1] || '';
  } else if (arg.startsWith('--ip=')) {
    flags.ip = arg.split('=')[1] || '';
  } else if (arg === '--com-lembretes') {
    flags.comLembretes = true;
  } else if (arg === '--sem-front') {
    flags.semFront = true;
  } else if (arg === '--janelas') {
    flags.janelas = true;
  } else if (arg === '--dry-run') {
    flags.dryRun = true;
  } else if (!arg.startsWith('-') && !acao) {
    acao = arg.toLowerCase();
  }
}

// Validacao de --ip
if (flags.ip && !/^\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}$/.test(flags.ip)) {
  console.error('[ERRO] Formato de IP invalido: ' + flags.ip + '. Use --ip=192.168.x.x');
  process.exit(1);
}

// Validacao de --dispositivo (alfanumerico, hifen, underline, ponto, dois-pontos)
if (flags.dispositivo && !/^[a-zA-Z0-9._:\-]+$/.test(flags.dispositivo)) {
  console.error('[ERRO] ID de dispositivo invalido: ' + flags.dispositivo);
  process.exit(1);
}

// ---------------------------------------------------------------------------
// Cores ANSI
// ---------------------------------------------------------------------------
const COR = {
  reset: '\x1b[0m',
  red: '\x1b[31m',
  green: '\x1b[32m',
  yellow: '\x1b[33m',
  cyan: '\x1b[36m',
  bold: '\x1b[1m',
};

function corStatus(status) {
  if (status === 'OK') return COR.green;
  if (status === 'AVISO') return COR.yellow;
  if (status === 'FALHA') return COR.red;
  return COR.reset;
}

// ---------------------------------------------------------------------------
// Utilitarios: execucao sincrona segura
// ---------------------------------------------------------------------------
function execSafe(cmd, args, opts) {
  try {
    const result = execFileSync(cmd, args || [], {
      encoding: 'utf8',
      timeout: 30000,
      windowsHide: true,
      ...opts,
    });
    return { ok: true, stdout: result.trim() };
  } catch (e) {
    return { ok: false, stdout: (e.stdout || '').toString().trim(), stderr: (e.stderr || '').toString().trim(), error: e };
  }
}

function execShellSafe(cmd, opts) {
  try {
    const result = execSync(cmd, {
      encoding: 'utf8',
      timeout: 30000,
      windowsHide: true,
      ...opts,
    });
    return { ok: true, stdout: result.trim() };
  } catch (e) {
    return { ok: false, stdout: (e.stdout || '').toString().trim(), stderr: (e.stderr || '').toString().trim(), error: e };
  }
}

function which(name) {
  const r = execShellSafe('where ' + name + ' 2>nul');
  if (r.ok && r.stdout) return r.stdout.split(/\r?\n/)[0];
  return null;
}

// ---------------------------------------------------------------------------
// Utilitarios: rede
// ---------------------------------------------------------------------------
function testPort(host, port, timeoutMs) {
  return new Promise((resolve) => {
    const sock = new net.Socket();
    let resolved = false;
    const done = (val) => { if (!resolved) { resolved = true; sock.destroy(); resolve(val); } };
    sock.setTimeout(timeoutMs || 1000);
    sock.on('connect', () => done(true));
    sock.on('timeout', () => done(false));
    sock.on('error', () => done(false));
    sock.connect(port, host);
  });
}

function waitPort(port, timeoutSec) {
  return new Promise((resolve) => {
    let elapsed = 0;
    const interval = setInterval(async () => {
      elapsed++;
      if (await testPort('127.0.0.1', port, 800)) {
        clearInterval(interval);
        resolve(true);
      } else if (elapsed >= timeoutSec) {
        clearInterval(interval);
        resolve(false);
      }
    }, 1000);
  });
}

function httpGet(url, timeoutMs) {
  return new Promise((resolve) => {
    const req = http.get(url, { timeout: timeoutMs || 1500 }, (res) => {
      res.resume();
      resolve(res.statusCode);
    });
    req.on('error', () => resolve(null));
    req.on('timeout', () => { req.destroy(); resolve(null); });
  });
}

function socketMessage(host, port, payload, timeoutMs) {
  return new Promise((resolve, reject) => {
    const sock = new net.Socket();
    let buf = '';
    let done = false;
    const finish = (err, data) => {
      if (!done) {
        done = true;
        sock.destroy();
        if (err) reject(err); else resolve(data);
      }
    };
    sock.setTimeout(timeoutMs || 5000);
    sock.on('connect', () => {
      sock.write(payload + '\n', 'utf8');
    });
    sock.on('data', (chunk) => {
      buf += chunk.toString('utf8');
      const idx = buf.indexOf('\n');
      if (idx !== -1) {
        finish(null, buf.substring(0, idx));
      }
    });
    sock.on('timeout', () => finish(new Error('Timeout')));
    sock.on('error', (e) => finish(e));
    sock.on('end', () => {
      if (buf.length > 0) finish(null, buf.trim());
      else finish(new Error('Conexao encerrada sem resposta'));
    });
    sock.connect(port, host);
  });
}

// ---------------------------------------------------------------------------
// Utilitarios: processos e portas (via netstat)
// ---------------------------------------------------------------------------
function getPortOwner(port) {
  // Usa netstat -ano e filtra LISTENING na porta desejada
  const r = execShellSafe('netstat -ano -p tcp');
  if (!r.ok) return [];
  const lines = r.stdout.split(/\r?\n/);
  const owners = [];
  const pidsSeen = new Set();
  for (const line of lines) {
    // Ex: TCP    0.0.0.0:5000    0.0.0.0:0    LISTENING    1234
    // ou  TCP    [::]:5000       [::]:0       LISTENING    1234
    if (!line.includes('LISTENING')) continue;
    const parts = line.trim().split(/\s+/);
    if (parts.length < 5) continue;
    const addr = parts[1] || '';
    const pidStr = parts[parts.length - 1];
    // Verificar se a porta local bate
    const portMatch = addr.match(/:(\d+)$/);
    if (!portMatch || parseInt(portMatch[1], 10) !== port) continue;
    const pid = parseInt(pidStr, 10);
    if (isNaN(pid) || pid <= 4 || pidsSeen.has(pid)) continue;
    pidsSeen.add(pid);
    // Buscar nome do processo via tasklist
    let procName = 'Desconhecido';
    const tl = execShellSafe('tasklist /FI "PID eq ' + pid + '" /FO CSV /NH');
    if (tl.ok && tl.stdout) {
      const csvLine = tl.stdout.split(/\r?\n/).find((l) => l.includes('"'));
      if (csvLine) {
        const match = csvLine.match(/^"([^"]+)"/);
        if (match) procName = match[1];
      }
    }
    owners.push({ pid, name: procName });
  }
  return owners;
}

function stopPortOwner(port) {
  const owners = getPortOwner(port);
  if (owners.length === 0) {
    console.log('Porta ' + port + ' livre. Nenhum processo para encerrar.');
    return;
  }
  for (const o of owners) {
    // Nunca encerrar o proprio processo
    if (o.pid === process.pid) {
      console.log('Porta ' + port + ': PID ' + o.pid + ' e o proprio script, pulando.');
      continue;
    }
    console.log('Encerrando processo na porta ' + port + ': PID ' + o.pid + ' (' + o.name + ') e processos filhos...');
    execShellSafe('taskkill /PID ' + o.pid + ' /T /F');
  }
}

// ---------------------------------------------------------------------------
// Utilitarios: IPv4 local
// ---------------------------------------------------------------------------
function getLocalIPv4() {
  const ifaces = os.networkInterfaces();
  const candidates = [];
  const virtualPatterns = /vethernet|virtualbox|vmware|hyper-v|docker|wsl/i;
  for (const [name, addrs] of Object.entries(ifaces)) {
    if (virtualPatterns.test(name)) continue;
    for (const a of addrs) {
      if (a.family !== 'IPv4' && a.family !== 4) continue;
      if (a.internal) continue;
      if (a.address.startsWith('169.254.')) continue;
      if (a.address.startsWith('127.')) continue;
      candidates.push({ iface: name, ip: a.address });
    }
  }
  return candidates;
}

// ---------------------------------------------------------------------------
// Utilitarios: JDK
// ---------------------------------------------------------------------------
const ANDROID_STUDIO_JBR = 'C:\\Program Files\\Android\\Android Studio\\jbr\\bin';

function findJdk() {
  // 1. Tentar no PATH
  const javac = which('javac');
  const java = which('java');
  if (javac && java) {
    let ver = '';
    const r = execSafe('java', ['-version'], { stdio: ['pipe', 'pipe', 'pipe'] });
    // java -version escreve em stderr
    ver = (r.stderr || r.stdout || '').split(/\r?\n/)[0] || '';
    return { status: 'OK', origin: 'PATH', binPath: null, version: ver, message: 'JDK encontrado no PATH (' + ver + ')' };
  }
  // 2. Tentar Android Studio JBR
  const aJavac = path.join(ANDROID_STUDIO_JBR, 'javac.exe');
  const aJava = path.join(ANDROID_STUDIO_JBR, 'java.exe');
  if (fs.existsSync(aJavac) && fs.existsSync(aJava)) {
    let ver = '';
    const r = execSafe(aJava, ['-version'], { stdio: ['pipe', 'pipe', 'pipe'] });
    ver = (r.stderr || r.stdout || '').split(/\r?\n/)[0] || '';
    return { status: 'AVISO', origin: 'AndroidStudio', binPath: ANDROID_STUDIO_JBR, version: ver, message: 'JDK encontrado no Android Studio, sera usado apenas pelos processos filhos' };
  }
  return { status: 'FALHA', origin: null, binPath: null, version: null, message: 'JDK nao encontrado no PATH nem no Android Studio. Instale o JDK 17+ ou Android Studio.' };
}

// ---------------------------------------------------------------------------
// Checagem completa
// ---------------------------------------------------------------------------
function checar(opts) {
  const quiet = opts && opts.quiet;
  const itens = [];
  const falhas = [];
  const avisos = [];

  // a) Node e npx
  const nodeVer = execSafe('node', ['-v']);
  if (!nodeVer.ok) {
    itens.push({ item: 'Node.js', status: 'FALHA', detalhe: 'Node.js nao encontrado.' });
    falhas.push('Node.js nao instalado -> Instale o Node 18+ de https://nodejs.org/');
  } else {
    const v = nodeVer.stdout;
    const major = parseInt((v.match(/v?(\d+)/) || [])[1] || '0', 10);
    if (major < 18) {
      itens.push({ item: 'Node.js', status: 'AVISO', detalhe: 'Node.js ' + v + ' (versao menor que 18)' });
      avisos.push('Node.js ' + v + ' (recomendado 18+)');
    } else {
      itens.push({ item: 'Node.js', status: 'OK', detalhe: 'Node.js ' + v });
    }
  }

  const npxPath = which('npx.cmd') || which('npx');
  if (!npxPath) {
    itens.push({ item: 'npx.cmd', status: 'FALHA', detalhe: 'npx / npx.cmd nao encontrado no PATH.' });
    falhas.push('npx nao encontrado -> Verifique a instalacao do Node.js e npm');
  } else {
    const npxVer = execSafe('npx', ['-v']);
    itens.push({ item: 'npx.cmd', status: 'OK', detalhe: 'npx ' + (npxVer.ok ? npxVer.stdout : '') });
  }

  // b) JDK
  const jdk = findJdk();
  itens.push({ item: 'JDK (Java/Javac)', status: jdk.status, detalhe: jdk.message });
  if (jdk.status === 'FALHA') falhas.push('JDK nao encontrado -> Instale o JDK 17+ ou o Android Studio com JBR');
  if (jdk.status === 'AVISO') avisos.push(jdk.message);

  // c) Flutter
  const flutterPath = which('flutter');
  if (!flutterPath) {
    itens.push({ item: 'Flutter SDK', status: 'FALHA', detalhe: 'Flutter nao encontrado no PATH.' });
    falhas.push('Flutter nao encontrado -> Baixe de https://docs.flutter.dev/ e configure o PATH');
  } else {
    const fv = execShellSafe('flutter --version');
    const verLine = fv.ok ? (fv.stdout.split(/\r?\n/)[0] || '').trim() : '';
    itens.push({ item: 'Flutter SDK', status: 'OK', detalhe: verLine || 'Flutter encontrado' });

    // flutter doctor resumido
    const doc = execShellSafe('flutter doctor');
    if (doc.ok) {
      const docStr = doc.stdout;
      if (docStr.includes('flutter doctor --android-licenses') || docStr.includes('Android license status unknown')) {
        const msg = 'Licencas do Android pendentes. Execute: flutter doctor --android-licenses';
        itens.push({ item: 'Flutter Doctor', status: 'AVISO', detalhe: msg });
        avisos.push(msg);
      } else {
        itens.push({ item: 'Flutter Doctor', status: 'OK', detalhe: 'Android toolchain e licencas verificadas' });
      }
    } else {
      itens.push({ item: 'Flutter Doctor', status: 'AVISO', detalhe: 'Nao foi possivel rodar flutter doctor' });
    }
  }

  // d) Dispositivos
  if (flutterPath) {
    const devR = execShellSafe('flutter devices --machine');
    let devs = [];
    try {
      if (devR.ok && devR.stdout) devs = JSON.parse(devR.stdout);
    } catch (_) { /* ignora parse error */ }
    if (!devs || devs.length === 0) {
      const msg = 'Nenhum dispositivo encontrado. Conecte um celular com depuracao USB ou abra um emulador.';
      itens.push({ item: 'Dispositivos', status: 'AVISO', detalhe: msg });
      avisos.push(msg);
    } else {
      const nomes = devs.map((d) => {
        const tipo = (d.emulator === true || d.isEmulator === true || d.category === 'emulator') ? 'emulador' : 'fisico';
        return d.name + ' [' + d.id + '] (' + tipo + ')';
      });
      itens.push({ item: 'Dispositivos', status: 'OK', detalhe: nomes.join('; ') });
    }
  } else {
    itens.push({ item: 'Dispositivos', status: 'AVISO', detalhe: 'Flutter ausente; consulta de dispositivos pulada' });
  }

  // e) servidor_java/lib (4 jars)
  const libDir = path.join(JAVA_DIR, 'lib');
  if (!fs.existsSync(libDir)) {
    itens.push({ item: 'Jars Servidor Java', status: 'FALHA', detalhe: 'servidor_java/lib nao encontrado.' });
    falhas.push('Jars do Servidor Java ausentes -> Execute: cd servidor_java && npm install');
  } else {
    const jarPatterns = ['gson', 'mongodb-driver-sync', 'mongodb-driver-core', 'bson'];
    const files = fs.readdirSync(libDir);
    const missing = jarPatterns.filter((p) => !files.some((f) => f.startsWith(p) && f.endsWith('.jar')));
    if (missing.length > 0) {
      itens.push({ item: 'Jars Servidor Java', status: 'FALHA', detalhe: 'Jars ausentes: ' + missing.join(', ') + '. Sugestao: cd servidor_java && npm install' });
      falhas.push('Jars do Servidor Java ausentes -> Execute: cd servidor_java && npm install');
    } else {
      itens.push({ item: 'Jars Servidor Java', status: 'OK', detalhe: 'Todos os 4 jars encontrados (gson, mongodb-driver-sync, mongodb-driver-core, bson)' });
    }
  }

  // f) backend/node_modules
  const nmDir = path.join(BACK_DIR, 'node_modules');
  if (!fs.existsSync(nmDir)) {
    itens.push({ item: 'backend node_modules', status: 'FALHA', detalhe: 'backend/node_modules nao encontrado. Sugestao: cd backend && npm install' });
    falhas.push('Dependencias do Backend ausentes -> Execute: cd backend && npm install');
  } else {
    const nmMissing = [];
    if (!fs.existsSync(path.join(nmDir, 'express'))) nmMissing.push('express');
    if (!fs.existsSync(path.join(nmDir, 'nodemailer', 'dist'))) nmMissing.push('nodemailer/dist');
    if (!fs.existsSync(path.join(nmDir, 'fontkit', 'dist'))) nmMissing.push('fontkit/dist');
    if (nmMissing.length > 0) {
      const msg = 'Dependencias ausentes em backend/node_modules: ' + nmMissing.join(', ') +
        '. Sugestao: cd backend && npm install. Aviso: se node_modules estiver versionado no Git, isso suja o git status e NADA disso deve ser commitado.';
      itens.push({ item: 'backend node_modules', status: 'FALHA', detalhe: msg });
      falhas.push('Dependencias do Backend ausentes -> Execute: cd backend && npm install');
    } else {
      itens.push({ item: 'backend node_modules', status: 'OK', detalhe: 'express, nodemailer/dist e fontkit/dist presentes' });
    }
  }

  // g) backend/.env
  const envPath = path.join(BACK_DIR, '.env');
  if (!fs.existsSync(envPath)) {
    itens.push({ item: 'backend .env', status: 'FALHA', detalhe: 'backend/.env nao encontrado.' });
    falhas.push('backend/.env ausente -> Crie a partir de .env.example');
  } else {
    // Verificar nomes de variaveis (somente os nomes, NUNCA valores)
    const required = ['MONGODB_URI', 'JWT_SECRET', 'SMTP_HOST', 'SMTP_PORT', 'SMTP_USER', 'SMTP_PASS', 'SMTP_FROM', 'FRONTEND_URL'];
    try {
      const lines = fs.readFileSync(envPath, 'utf8').split(/\r?\n/);
      const found = new Set();
      for (const line of lines) {
        const trimmed = line.trim();
        if (trimmed.startsWith('#') || !trimmed.includes('=')) continue;
        const varName = trimmed.substring(0, trimmed.indexOf('=')).trim();
        if (varName) found.add(varName);
      }
      const envMissing = required.filter((r) => !found.has(r));
      if (envMissing.length > 0) {
        itens.push({ item: 'backend .env', status: 'AVISO', detalhe: '.env presente, mas faltam variaveis: ' + envMissing.join(', ') });
        avisos.push('backend/.env: faltam ' + envMissing.join(', '));
      } else {
        itens.push({ item: 'backend .env', status: 'OK', detalhe: '.env presente com todas as variaveis requeridas' });
      }
    } catch (_) {
      itens.push({ item: 'backend .env', status: 'FALHA', detalhe: 'Falha ao verificar backend/.env' });
      falhas.push('Falha ao verificar backend/.env');
    }
  }

  // h) Portas 5000 e 3000
  for (const port of [PORTA_JAVA, PORTA_BACK]) {
    const label = port === PORTA_JAVA ? 'Porta 5000 (Java)' : 'Porta 3000 (Back)';
    const owners = getPortOwner(port);
    if (owners.length > 0) {
      const o = owners[0];
      itens.push({ item: label, status: 'AVISO', detalhe: 'Porta ' + port + ' ocupada pelo processo ' + o.name + ' (PID: ' + o.pid + '). Sugestao: execute a acao "parar".' });
      avisos.push('Porta ' + port + ' ocupada por ' + o.name + ' (PID ' + o.pid + ')');
    } else {
      itens.push({ item: label, status: 'OK', detalhe: 'Porta ' + port + ' livre' });
    }
  }

  // i) IPv4 local
  const ips = getLocalIPv4();
  if (ips.length === 0) {
    itens.push({ item: 'IPv4 Rede Local', status: 'AVISO', detalhe: 'Nenhum IPv4 valido detectado. Verifique a conexao de rede.' });
    avisos.push('Nenhum IPv4 local detectado');
  } else if (ips.length === 1) {
    itens.push({ item: 'IPv4 Rede Local', status: 'OK', detalhe: ips[0].ip + ' (' + ips[0].iface + ') - usar com --ip=' + ips[0].ip + ' para celular fisico' });
  } else {
    const lista = ips.map((x) => x.ip + ' (' + x.iface + ')').join('; ');
    itens.push({ item: 'IPv4 Rede Local', status: 'OK', detalhe: 'Candidatos: ' + lista });
  }

  // j) frontend/pubspec.yaml e .dart_tool
  const pubspec = path.join(FRONT_DIR, 'pubspec.yaml');
  if (!fs.existsSync(pubspec)) {
    itens.push({ item: 'frontend pubspec', status: 'FALHA', detalhe: 'frontend/pubspec.yaml nao encontrado.' });
    falhas.push('frontend/pubspec.yaml ausente');
  } else {
    const dartTool = path.join(FRONT_DIR, '.dart_tool');
    if (!fs.existsSync(dartTool)) {
      const msg = 'frontend/.dart_tool nao encontrado. Sugestao: cd frontend && flutter pub get';
      itens.push({ item: 'frontend pubspec', status: 'AVISO', detalhe: msg });
      avisos.push(msg);
    } else {
      itens.push({ item: 'frontend pubspec', status: 'OK', detalhe: 'pubspec.yaml e .dart_tool presentes' });
    }
  }

  // k) Lembrete git (sem executar git)
  itens.push({ item: 'Git (informativo)', status: 'OK', detalhe: 'Lembrete: arquivos em frontend/linux, macos e windows podem mudar ao rodar Flutter e nao devem ser commitados.' });

  // Impressao da tabela
  if (!quiet) {
    console.log('');
    console.log('================================================================================');
    console.log('                   PetCare - Checagem de Ambiente e Servicos                    ');
    console.log('================================================================================');
    const hdr = padRight('STATUS', 8) + ' | ' + padRight('ITEM', 24) + ' | DETALHES';
    console.log(hdr);
    console.log('-'.repeat(80));
    for (const it of itens) {
      const cor = corStatus(it.status);
      const statusTxt = '[' + padRight(it.status, 5) + ']';
      process.stdout.write(cor + statusTxt + COR.reset + ' | ' + padRight(it.item, 24) + ' | ' + it.detalhe + '\n');
    }
    console.log('='.repeat(80));
    console.log('RESUMO:');
    if (falhas.length === 0) {
      console.log(COR.green + 'Pronto para iniciar.' + COR.reset);
      if (avisos.length > 0) {
        console.log(COR.yellow + 'Avisos identificados (' + avisos.length + '). Podem nao impedir o inicio, mas requerem atencao.' + COR.reset);
      }
    } else {
      console.log(COR.red + 'Foram encontradas ' + falhas.length + ' falha(s) que impedem a execucao:' + COR.reset);
      falhas.forEach((f, i) => console.log(COR.red + '  ' + (i + 1) + '. ' + f + COR.reset));
    }
    console.log('='.repeat(80));
    console.log('');
  }

  return { falhas, avisos, itens, jdk };
}

function padRight(str, len) {
  if (str.length >= len) return str;
  return str + ' '.repeat(len - str.length);
}

// ---------------------------------------------------------------------------
// Pre-checagens parciais (retornam true se OK para prosseguir)
// ---------------------------------------------------------------------------
function preCheckJava() {
  const nodeVer = execSafe('node', ['-v']);
  if (!nodeVer.ok) { console.error(COR.red + 'FALHA: Node.js nao encontrado.' + COR.reset); return { ok: false }; }
  const jdk = findJdk();
  if (jdk.status === 'FALHA') { console.error(COR.red + 'FALHA: ' + jdk.message + COR.reset); return { ok: false }; }
  const libDir = path.join(JAVA_DIR, 'lib');
  const jarPatterns = ['gson', 'mongodb-driver-sync', 'mongodb-driver-core', 'bson'];
  if (!fs.existsSync(libDir)) { console.error(COR.red + 'FALHA: servidor_java/lib nao encontrado.' + COR.reset); return { ok: false }; }
  const files = fs.readdirSync(libDir);
  const missing = jarPatterns.filter((p) => !files.some((f) => f.startsWith(p) && f.endsWith('.jar')));
  if (missing.length > 0) { console.error(COR.red + 'FALHA: Jars ausentes: ' + missing.join(', ') + COR.reset); return { ok: false }; }
  return { ok: true, jdk };
}

function preCheckBack() {
  const nodeVer = execSafe('node', ['-v']);
  if (!nodeVer.ok) { console.error(COR.red + 'FALHA: Node.js nao encontrado.' + COR.reset); return false; }
  const npxPath = which('npx.cmd') || which('npx');
  if (!npxPath) { console.error(COR.red + 'FALHA: npx nao encontrado.' + COR.reset); return false; }
  const nmDir = path.join(BACK_DIR, 'node_modules');
  const nmMissing = [];
  if (!fs.existsSync(nmDir)) { console.error(COR.red + 'FALHA: backend/node_modules nao encontrado. Execute: cd backend && npm install' + COR.reset); return false; }
  if (!fs.existsSync(path.join(nmDir, 'express'))) nmMissing.push('express');
  if (!fs.existsSync(path.join(nmDir, 'nodemailer', 'dist'))) nmMissing.push('nodemailer/dist');
  if (!fs.existsSync(path.join(nmDir, 'fontkit', 'dist'))) nmMissing.push('fontkit/dist');
  if (nmMissing.length > 0) { console.error(COR.red + 'FALHA: Dependencias ausentes: ' + nmMissing.join(', ') + '. Execute: cd backend && npm install' + COR.reset); return false; }
  if (!fs.existsSync(path.join(BACK_DIR, '.env'))) { console.error(COR.red + 'FALHA: backend/.env nao encontrado.' + COR.reset); return false; }
  return true;
}

function preCheckFront() {
  const flutterPath = which('flutter');
  if (!flutterPath) { console.error(COR.red + 'FALHA: Flutter nao encontrado no PATH.' + COR.reset); return false; }
  if (!fs.existsSync(path.join(FRONT_DIR, 'pubspec.yaml'))) { console.error(COR.red + 'FALHA: frontend/pubspec.yaml nao encontrado.' + COR.reset); return false; }
  return true;
}

// ---------------------------------------------------------------------------
// Detectar se Windows Terminal existe
// ---------------------------------------------------------------------------
function hasWt() {
  return !!which('wt');
}

// ---------------------------------------------------------------------------
// Geradores de conteudo para arquivos de comando temporarios (.cmd)
// ---------------------------------------------------------------------------
function getJavaCmdContent(binPath) {
  const lines = ['@echo off'];
  if (binPath) {
    lines.push('set "PATH=' + binPath + ';%PATH%"');
  }
  lines.push('node scripts/compilar.js && node scripts/iniciar.js');
  return lines.join('\r\n');
}

function getBackCmdContent(comLembretes) {
  const lembretesVal = comLembretes ? 'true' : 'false';
  const lines = [
    '@echo off',
    'set "LEMBRETES_ATIVOS=' + lembretesVal + '"',
    'npx.cmd tsx src/index.ts',
  ];
  return lines.join('\r\n');
}

function getFrontCmdContent(chosenId, isEmulator, ip) {
  const lines = ['@echo off'];
  if (isEmulator) {
    lines.push('flutter run -d ' + chosenId);
  } else {
    lines.push('flutter run -d ' + chosenId + ' --dart-define=API_URL=http://' + ip + ':3000');
  }
  return lines.join('\r\n');
}

// ---------------------------------------------------------------------------
// Caminhos curtos e seguros para arquivos temporarios (.cmd)
// ---------------------------------------------------------------------------
function getSafeCmdPath(filePath) {
  if (!filePath.includes(' ')) return filePath;
  try {
    const res = execFileSync('cmd.exe', ['/c', 'for %I in ("' + filePath + '") do @echo %~sI'], {
      encoding: 'utf8',
      windowsHide: true,
    }).trim();
    if (res && !res.includes(' ')) return res;
  } catch (_) {}
  return null;
}

const createdTempFiles = [];

function cleanupTempFiles() {
  for (const f of createdTempFiles) {
    try {
      if (fs.existsSync(f)) {
        fs.unlinkSync(f);
      }
    } catch (_) {}
  }
}

process.on('exit', cleanupTempFiles);

// ---------------------------------------------------------------------------
// Montagem de argumentos para spawn
// ---------------------------------------------------------------------------
function buildWtArgs(tabs) {
  const args = [];
  tabs.forEach((tab, index) => {
    if (index > 0) {
      args.push(';');
    }
    args.push('new-tab', '--title', tab.title, '-d', tab.cwd, 'cmd', '/k', tab.cmdFile);
  });
  return args;
}

function buildFallbackArgs(tab) {
  return ['/c', 'start', tab.title, '/D', tab.cwd, 'cmd', '/k', tab.cmdFile];
}

// ---------------------------------------------------------------------------
// Disparo de terminais (wt ou fallback cmd.exe)
// ---------------------------------------------------------------------------
function launchTabs(tabs, useWt) {
  let effectiveUseWt = useWt;
  for (const tab of tabs) {
    const safe = getSafeCmdPath(tab.cmdFile);
    if (!safe) {
      effectiveUseWt = false;
      break;
    }
    tab.cmdFile = safe;
  }

  if (flags.dryRun) {
    console.log('[dry-run] Modo simulacao ativado (nenhum processo sera iniciado).');
    if (effectiveUseWt) {
      const wtArgs = buildWtArgs(tabs);
      console.log('[dry-run] Terminal: Windows Terminal (wt)');
      console.log('[dry-run] Executavel: wt');
      console.log('[dry-run] Argumentos (argv): ' + JSON.stringify(wtArgs, null, 2));
    } else {
      console.log('[dry-run] Terminal: Fallback cmd.exe (start)');
    }

    console.log('\n[dry-run] Conteudo dos arquivos .cmd temporarios:');
    tabs.forEach((tab) => {
      console.log('  Arquivo: ' + tab.cmdFile);
      console.log('  Conteudo:');
      tab.content.split('\r\n').forEach((line) => {
        console.log('    ' + line);
      });
      console.log('');
    });

    console.log('[dry-run] Detalhes por aba:');
    tabs.forEach((tab, i) => {
      const fbArgs = buildFallbackArgs(tab);
      console.log('  Aba ' + (i + 1) + ' [' + tab.title + ']:');
      console.log('    Diretorio: ' + tab.cwd);
      console.log('    Arquivo .cmd: ' + tab.cmdFile);
      console.log('    Fallback cmd.exe argv: ' + JSON.stringify(['cmd.exe', ...fbArgs]));
    });
    return;
  }

  // Grava os arquivos .cmd na pasta temporaria do sistema
  for (const tab of tabs) {
    fs.writeFileSync(tab.cmdFile, tab.content, 'utf8');
    createdTempFiles.push(tab.cmdFile);
  }

  if (effectiveUseWt) {
    const wtArgs = buildWtArgs(tabs);
    const child = spawn('wt', wtArgs, {
      detached: true,
      stdio: 'ignore',
      windowsVerbatimArguments: false,
    });
    child.unref();
  } else {
    for (const tab of tabs) {
      const fbArgs = buildFallbackArgs(tab);
      const child = spawn('cmd.exe', fbArgs, {
        detached: true,
        stdio: 'ignore',
        windowsVerbatimArguments: false,
      });
      child.unref();
    }
  }
}

// ---------------------------------------------------------------------------
// Acoes
// ---------------------------------------------------------------------------
async function acaoJava(useWt, waitForPort) {
  const pre = preCheckJava();
  if (!pre.ok && !flags.dryRun) process.exit(1);

  const owners = getPortOwner(PORTA_JAVA);
  if (owners.length > 0 && !flags.dryRun) {
    console.log(COR.yellow + 'AVISO: Porta 5000 ja esta em uso por ' + owners[0].name + ' (PID ' + owners[0].pid + '). Execute "parar" antes.' + COR.reset);
    return;
  }

  const jdk = pre.jdk || findJdk();
  const content = getJavaCmdContent(jdk.binPath);
  const tab = {
    id: 'java',
    title: 'PetCare - Java',
    cwd: JAVA_DIR,
    content,
    cmdFile: path.join(os.tmpdir(), 'petcare-java-' + process.pid + '.cmd'),
  };

  if (flags.dryRun) {
    launchTabs([tab], useWt);
    return;
  }

  console.log('Iniciando Servidor Java na porta 5000...');
  launchTabs([tab], useWt);

  if (waitForPort !== false) {
    console.log('Aguardando Servidor Java na porta 5000 (ate 30s)...');
    const up = await waitPort(PORTA_JAVA, 30);
    if (up) {
      console.log(COR.green + 'Servidor Java no ar na porta 5000 (OK).' + COR.reset);
    } else {
      console.log(COR.red + 'Servidor Java nao subiu na porta 5000 apos 30 segundos.' + COR.reset);
    }
  }
}

async function acaoBack(useWt, waitForPort) {
  if (!preCheckBack() && !flags.dryRun) process.exit(1);

  const javaUp = await testPort('127.0.0.1', PORTA_JAVA, 500);
  if (!javaUp && !flags.dryRun) {
    console.log(COR.yellow + 'Aviso: Servidor Java nao esta no ar na porta 5000. Cadastro e login dependem dele.' + COR.reset);
  }

  const owners = getPortOwner(PORTA_BACK);
  if (owners.length > 0 && !flags.dryRun) {
    console.log(COR.yellow + 'AVISO: Porta 3000 ja esta em uso por ' + owners[0].name + ' (PID ' + owners[0].pid + '). Execute "parar" antes.' + COR.reset);
    return;
  }

  const content = getBackCmdContent(flags.comLembretes);
  const tab = {
    id: 'back',
    title: 'PetCare - Back',
    cwd: BACK_DIR,
    content,
    cmdFile: path.join(os.tmpdir(), 'petcare-back-' + process.pid + '.cmd'),
  };

  if (flags.dryRun) {
    launchTabs([tab], useWt);
    return;
  }

  console.log('Iniciando Backend na porta 3000 (LEMBRETES_ATIVOS=' + (flags.comLembretes ? 'true' : 'false') + ')...');
  launchTabs([tab], useWt);

  if (waitForPort !== false) {
    console.log('Aguardando Backend na porta 3000 (ate 30s)...');
    const up = await waitPort(PORTA_BACK, 30);
    if (up) {
      console.log(COR.green + 'Backend no ar na porta 3000 (OK).' + COR.reset);
    } else {
      console.log(COR.red + 'Backend nao subiu na porta 3000 apos 30 segundos. Verifique a janela "PetCare - Back".' + COR.reset);
      console.log(COR.yellow + 'Causas comuns: .env ausente, MONGODB_URI recusada com "bad auth", node_modules incompleto.' + COR.reset);
    }
  }
}

async function resolveFrontCmd() {
  if (!flags.dryRun) {
    if (!preCheckFront()) return { ok: false };
  }

  let devs = [];
  const flutterPath = which('flutter');
  if (flutterPath) {
    console.log('Consultando dispositivos Flutter...');
    const devR = execShellSafe('flutter devices --machine');
    try {
      if (devR.ok && devR.stdout) devs = JSON.parse(devR.stdout);
    } catch (_) { /* ignora */ }
  }

  let chosen = null;

  if (flags.dispositivo) {
    chosen = devs.find((d) => d.id === flags.dispositivo);
    if (!chosen) {
      chosen = { id: flags.dispositivo, name: flags.dispositivo, emulator: flags.dispositivo.includes('emulator') };
    }
  } else {
    if (!devs || devs.length === 0) {
      if (flags.dryRun) {
        return { ok: true, chosenId: 'emulator-5554', isEmulator: true, targetIP: '' };
      }
      console.error(COR.red + 'Nenhum dispositivo encontrado. Abra um emulador ou conecte celular com depuracao USB.' + COR.reset);
      return { ok: false };
    } else if (devs.length === 1) {
      chosen = devs[0];
      console.log('Dispositivo selecionado automaticamente: ' + chosen.name + ' (ID: ' + chosen.id + ')');
    } else {
      console.log('Dispositivos encontrados:');
      devs.forEach((d, i) => {
        const tipo = (d.emulator === true || d.isEmulator === true || d.category === 'emulator') ? 'Emulador' : 'Fisico';
        console.log('  [' + (i + 1) + '] ' + d.name + ' (ID: ' + d.id + ', Tipo: ' + tipo + ')');
      });
      const rl = readline.createInterface({ input: process.stdin, output: process.stdout });
      const answer = await new Promise((resolve) => {
        rl.question('Selecione o numero do dispositivo [1-' + devs.length + ']: ', (ans) => {
          rl.close();
          resolve(ans.trim());
        });
      });
      const idx = parseInt(answer, 10);
      if (idx >= 1 && idx <= devs.length) {
        chosen = devs[idx - 1];
      } else {
        console.log('Selecao invalida. Usando o primeiro dispositivo.');
        chosen = devs[0];
      }
    }
  }

  const isEmulator = (chosen.emulator === true) || (chosen.isEmulator === true) || (chosen.category === 'emulator') || (chosen.id && chosen.id.includes('emulator'));

  let targetIP = flags.ip;
  if (!isEmulator) {
    if (!targetIP) {
      const ips = getLocalIPv4();
      if (ips.length > 0) {
        targetIP = ips[0].ip;
        console.log('IPv4 detectado automaticamente: ' + targetIP);
      }
    }
    if (!targetIP && !flags.dryRun) {
      const rl = readline.createInterface({ input: process.stdin, output: process.stdout });
      targetIP = await new Promise((resolve) => {
        rl.question('Informe o IPv4 do computador na rede local: ', (ans) => {
          rl.close();
          resolve(ans.trim());
        });
      });
    }
    if (!targetIP) targetIP = '192.168.1.100';
    if (!/^\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}$/.test(targetIP)) {
      console.error(COR.red + 'IP invalido: ' + targetIP + COR.reset);
      return { ok: false };
    }
    console.log('Dispositivo fisico detectado. API_URL=http://' + targetIP + ':3000');
    console.log(COR.yellow + 'AVISO: Celular e computador precisam estar na mesma rede Wi-Fi.' + COR.reset);
    console.log(COR.yellow + 'AVISO: O firewall do Windows deve permitir a porta 3000 em rede privada.' + COR.reset);
  } else {
    console.log('Dispositivo reconhecido como emulador Android (conexao padrao via 10.0.2.2).');
  }

  return { ok: true, chosenId: chosen.id, isEmulator, targetIP };
}

async function acaoFront(useWt) {
  const frontRes = await resolveFrontCmd();
  if (!frontRes.ok && !flags.dryRun) process.exit(1);

  const content = getFrontCmdContent(
    frontRes.chosenId || 'emulator-5554',
    frontRes.isEmulator !== false,
    frontRes.targetIP || '192.168.1.100'
  );
  const tab = {
    id: 'front',
    title: 'PetCare - Front',
    cwd: FRONT_DIR,
    content,
    cmdFile: path.join(os.tmpdir(), 'petcare-front-' + process.pid + '.cmd'),
  };

  if (flags.dryRun) {
    launchTabs([tab], useWt);
    return;
  }

  console.log('Iniciando Frontend Flutter...');
  launchTabs([tab], useWt);
}

async function acaoIniciar() {
  if (!flags.dryRun) {
    console.log('Executando checagem de ambiente antes de iniciar...');
    const result = checar({});
    if (result.falhas.length > 0) {
      console.error(COR.red + 'Nao e possivel iniciar devido a falhas no ambiente.' + COR.reset);
      console.error('Execute "node scripts/petcare.js checar" para ver as correcoes necessarias.');
      process.exit(1);
    }
  }

  const jdk = findJdk();
  const javaContent = getJavaCmdContent(jdk.binPath);
  const backContent = getBackCmdContent(flags.comLembretes);

  const tabJava = {
    id: 'java',
    title: 'PetCare - Java',
    cwd: JAVA_DIR,
    content: javaContent,
    cmdFile: path.join(os.tmpdir(), 'petcare-java-' + process.pid + '.cmd'),
  };

  const tabBack = {
    id: 'back',
    title: 'PetCare - Back',
    cwd: BACK_DIR,
    content: backContent,
    cmdFile: path.join(os.tmpdir(), 'petcare-back-' + process.pid + '.cmd'),
  };

  const tabs = [tabJava, tabBack];

  if (!flags.semFront) {
    const frontRes = await resolveFrontCmd();
    if (!frontRes.ok && !flags.dryRun) {
      process.exit(1);
    }
    const frontContent = getFrontCmdContent(
      frontRes.chosenId || 'emulator-5554',
      frontRes.isEmulator !== false,
      frontRes.targetIP || '192.168.1.100'
    );
    tabs.push({
      id: 'front',
      title: 'PetCare - Front',
      cwd: FRONT_DIR,
      content: frontContent,
      cmdFile: path.join(os.tmpdir(), 'petcare-front-' + process.pid + '.cmd'),
    });
  }

  const useWt = !flags.janelas && hasWt();

  if (flags.dryRun) {
    launchTabs(tabs, useWt);
    return;
  }

  if (useWt) {
    console.log('Iniciando servicos no Windows Terminal...');
    launchTabs(tabs, true);

    console.log('Aguardando Servidor Java na porta 5000 (ate 30s)...');
    const javaUp = await waitPort(PORTA_JAVA, 30);
    if (javaUp) {
      console.log(COR.green + 'Servidor Java no ar na porta 5000 (OK).' + COR.reset);
    } else {
      console.log(COR.red + 'Servidor Java nao subiu na porta 5000 apos 30 segundos.' + COR.reset);
    }

    console.log('Aguardando Backend na porta 3000 (ate 30s)...');
    const backUp = await waitPort(PORTA_BACK, 30);
    if (backUp) {
      console.log(COR.green + 'Backend no ar na porta 3000 (OK).' + COR.reset);
    } else {
      console.log(COR.red + 'Backend nao subiu na porta 3000 apos 30 segundos. Verifique a janela "PetCare - Back".' + COR.reset);
      console.log(COR.yellow + 'Causas comuns: .env ausente, MONGODB_URI recusada com "bad auth", node_modules incompleto.' + COR.reset);
    }
  } else {
    // Fallback: abre aba/janela por aba e aguarda
    console.log('Iniciando Servidor Java (janela independente)...');
    launchTabs([tabs[0]], false);
    console.log('Aguardando Servidor Java na porta 5000 (ate 30s)...');
    const javaUp = await waitPort(PORTA_JAVA, 30);
    if (javaUp) {
      console.log(COR.green + 'Servidor Java no ar na porta 5000 (OK).' + COR.reset);
    } else {
      console.log(COR.red + 'Servidor Java nao subiu na porta 5000 apos 30 segundos.' + COR.reset);
    }

    console.log('Iniciando Backend (janela independente)...');
    launchTabs([tabs[1]], false);
    console.log('Aguardando Backend na porta 3000 (ate 30s)...');
    const backUp = await waitPort(PORTA_BACK, 30);
    if (backUp) {
      console.log(COR.green + 'Backend no ar na porta 3000 (OK).' + COR.reset);
    } else {
      console.log(COR.red + 'Backend nao subiu na porta 3000 apos 30 segundos. Verifique a janela "PetCare - Back".' + COR.reset);
      console.log(COR.yellow + 'Causas comuns: .env ausente, MONGODB_URI recusada com "bad auth", node_modules incompleto.' + COR.reset);
    }

    if (!flags.semFront && tabs[2]) {
      console.log('Iniciando Frontend Flutter (janela independente)...');
      launchTabs([tabs[2]], false);
    }
  }

  console.log('Inicializacao concluida. Execute "node scripts/petcare.js status" para checar o estado.');
}

function acaoParar() {
  console.log('====================================================');
  console.log('              PetCare - Parar Servicos              ');
  console.log('====================================================');
  stopPortOwner(PORTA_JAVA);
  stopPortOwner(PORTA_BACK);
  console.log('Para encerrar o Frontend Flutter, va ate a janela "PetCare - Front" e pressione "q".');
  console.log('');
  return acaoStatus();
}

async function acaoReiniciar() {
  console.log('Reiniciando servicos PetCare...');
  acaoParar();
  console.log('Aguardando 2 segundos...');
  await new Promise((resolve) => setTimeout(resolve, 2000));
  await acaoIniciar();
}

async function acaoStatus() {
  console.log('====================================================');
  console.log('              PetCare - Status Geral                ');
  console.log('====================================================');

  // Java porta 5000
  const javaUp = await testPort('127.0.0.1', PORTA_JAVA, 1000);
  if (javaUp) {
    console.log(COR.green + 'Servidor Java (porta 5000): NO AR' + COR.reset);
  } else {
    console.log(COR.red + 'Servidor Java (porta 5000): PARADO' + COR.reset);
  }

  // Backend porta 3000
  const backUp = await testPort('127.0.0.1', PORTA_BACK, 1000);
  if (backUp) {
    const httpCode = await httpGet('http://localhost:3000/', 1500);
    if (httpCode !== null) {
      console.log(COR.green + 'Backend       (porta 3000): NO AR (HTTP ' + httpCode + ')' + COR.reset);
    } else {
      console.log(COR.green + 'Backend       (porta 3000): NO AR (Porta aberta)' + COR.reset);
    }
  } else {
    console.log(COR.red + 'Backend       (porta 3000): PARADO' + COR.reset);
  }

  // Frontend (procurar janela pelo titulo)
  const tl = execShellSafe('tasklist /FI "WINDOWTITLE eq PetCare - Front" /FO CSV /NH');
  if (tl.ok && tl.stdout && !tl.stdout.includes('Nenhuma tarefa') && !tl.stdout.includes('No tasks') && tl.stdout.includes('"')) {
    console.log(COR.green + 'Frontend      (Flutter)   : NO AR (Janela "PetCare - Front" detectada)' + COR.reset);
  } else {
    console.log(COR.yellow + 'Frontend      (Flutter)   : PARADO (Nenhuma janela "PetCare - Front" detectada)' + COR.reset);
  }

  console.log('====================================================');
}

async function acaoVerificar() {
  console.log('====================================================');
  console.log('       PetCare - Verificacao do Servidor Java       ');
  console.log('====================================================');

  const up = await testPort('127.0.0.1', PORTA_JAVA, 1000);
  if (!up) {
    console.error(COR.red + 'ERRO: Servidor Java nao responde na porta 5000. Inicie-o primeiro (acao: java ou iniciar).' + COR.reset);
    process.exit(1);
  }

  let falhas = 0;

  // 1. CALCULAR_PROGRESSO_CAMPANHA
  try {
    const p1 = JSON.stringify({ comando: 'CALCULAR_PROGRESSO_CAMPANHA', dados: { valorArrecadado: 100, metaValor: 1000 } });
    const r1Raw = await socketMessage('127.0.0.1', PORTA_JAVA, p1, 5000);
    const r1 = JSON.parse(r1Raw);
    if (r1.status === 'OK' && r1.dados && r1.dados.porcentagem === 10.0 && r1.dados.statusProgresso === 'EM_ANDAMENTO') {
      console.log(COR.green + '[PASSOU] 1. CALCULAR_PROGRESSO_CAMPANHA (status=OK, porcentagem=10.0, statusProgresso=EM_ANDAMENTO)' + COR.reset);
    } else {
      console.log(COR.red + '[FALHOU] 1. CALCULAR_PROGRESSO_CAMPANHA. Resposta: ' + r1Raw + COR.reset);
      falhas++;
    }
  } catch (e) {
    console.log(COR.red + '[FALHOU] 1. CALCULAR_PROGRESSO_CAMPANHA: ' + e.message + COR.reset);
    falhas++;
  }

  // 2. CALCULAR_STATUS_VACINA
  try {
    const p2 = JSON.stringify({ comando: 'CALCULAR_STATUS_VACINA', dados: { dataUltimaAplicacao: '2026-01-10', intervaloDias: 365, dataReferencia: '2026-10-09' } });
    const r2Raw = await socketMessage('127.0.0.1', PORTA_JAVA, p2, 5000);
    const r2 = JSON.parse(r2Raw);
    if (r2.status === 'OK' && r2.dados && r2.dados.statusVacina === 'EM_DIA' && r2.dados.dataProximaDose === '2027-01-10' && r2.dados.diasRestantes === 93) {
      console.log(COR.green + '[PASSOU] 2. CALCULAR_STATUS_VACINA (status=OK, statusVacina=EM_DIA, dataProximaDose=2027-01-10, diasRestantes=93)' + COR.reset);
    } else {
      console.log(COR.red + '[FALHOU] 2. CALCULAR_STATUS_VACINA. Resposta: ' + r2Raw + COR.reset);
      falhas++;
    }
  } catch (e) {
    console.log(COR.red + '[FALHOU] 2. CALCULAR_STATUS_VACINA: ' + e.message + COR.reset);
    falhas++;
  }

  // 3. GERAR_HASH_SENHA (NUNCA imprimir a linha enviada nem o hash completo)
  let hashGerado = null;
  try {
    const p3 = JSON.stringify({ comando: 'GERAR_HASH_SENHA', dados: { senha: 'senha-falsa-de-teste' } });
    const r3Raw = await socketMessage('127.0.0.1', PORTA_JAVA, p3, 5000);
    const r3 = JSON.parse(r3Raw);
    const prefixoEsperado = 'pbkdf2$120000$';
    if (r3.status === 'OK' && r3.dados && r3.dados.hash && r3.dados.hash.startsWith(prefixoEsperado)) {
      hashGerado = r3.dados.hash;
      console.log(COR.green + '[PASSOU] 3. GERAR_HASH_SENHA (status=OK, prefixo=' + prefixoEsperado + ')' + COR.reset);
    } else {
      console.log(COR.red + '[FALHOU] 3. GERAR_HASH_SENHA (hash ausente ou prefixo incorreto)' + COR.reset);
      falhas++;
    }
  } catch (e) {
    console.log(COR.red + '[FALHOU] 3. GERAR_HASH_SENHA: ' + e.message + COR.reset);
    falhas++;
  }

  // 4. VERIFICAR_SENHA (NUNCA imprimir o hash)
  try {
    if (hashGerado) {
      const p4 = JSON.stringify({ comando: 'VERIFICAR_SENHA', dados: { senha: 'senha-falsa-de-teste', hash: hashGerado } });
      const r4Raw = await socketMessage('127.0.0.1', PORTA_JAVA, p4, 5000);
      const r4 = JSON.parse(r4Raw);
      if (r4.status === 'OK' && r4.dados && r4.dados.valida === true) {
        console.log(COR.green + '[PASSOU] 4. VERIFICAR_SENHA (status=OK, valida=true)' + COR.reset);
      } else {
        console.log(COR.red + '[FALHOU] 4. VERIFICAR_SENHA (senha ou hash nao validado)' + COR.reset);
        falhas++;
      }
    } else {
      console.log(COR.red + '[FALHOU] 4. VERIFICAR_SENHA (pulado pois o passo 3 falhou)' + COR.reset);
      falhas++;
    }
  } catch (e) {
    console.log(COR.red + '[FALHOU] 4. VERIFICAR_SENHA: ' + e.message + COR.reset);
    falhas++;
  }

  // 5. VERIFICAR_CONFLITO_HORARIO
  try {
    const p5 = JSON.stringify({ comando: 'VERIFICAR_CONFLITO_HORARIO', dados: {} });
    const r5Raw = await socketMessage('127.0.0.1', PORTA_JAVA, p5, 5000);
    const r5 = JSON.parse(r5Raw);
    if (r5.status === 'ERRO' && r5.codigo === 'COMANDO_DESCONHECIDO') {
      console.log(COR.green + '[PASSOU] 5. VERIFICAR_CONFLITO_HORARIO (status=ERRO, codigo=COMANDO_DESCONHECIDO)' + COR.reset);
    } else {
      console.log(COR.red + '[FALHOU] 5. VERIFICAR_CONFLITO_HORARIO. Resposta: ' + r5Raw + COR.reset);
      falhas++;
    }
  } catch (e) {
    console.log(COR.red + '[FALHOU] 5. VERIFICAR_CONFLITO_HORARIO: ' + e.message + COR.reset);
    falhas++;
  }

  console.log('====================================================');
  if (falhas > 0) {
    console.log(COR.red + 'Resultado: ' + falhas + ' teste(s) falharam.' + COR.reset);
    process.exit(1);
  } else {
    console.log(COR.green + 'Resultado: Todos os testes passaram com sucesso!' + COR.reset);
  }
}

function acaoAjuda() {
  console.log('');
  console.log('====================================================');
  console.log('           PetCare - Ajuda e Instrucoes             ');
  console.log('====================================================');
  console.log('Uso:');
  console.log('  node scripts/petcare.js [acao] [flags]');
  console.log('');
  console.log('Acoes disponiveis:');
  console.log('  checar     - Checa dependencias e ambiente (somente leitura)');
  console.log('  iniciar    - Checa e sobe Java, Back e Front na ordem');
  console.log('  java       - Inicia apenas o Servidor Java (porta 5000)');
  console.log('  back       - Inicia apenas o Backend (porta 3000)');
  console.log('  front      - Inicia apenas o Frontend Flutter');
  console.log('  parar      - Encerra donos das portas 5000 e 3000 por PID');
  console.log('  reiniciar  - Executa parar, aguarda 2s e executa iniciar');
  console.log('  status     - Testa portas 5000, 3000 e HTTP do Backend');
  console.log('  verificar  - Testa protocolo socket TCP do Servidor Java');
  console.log('  ajuda      - Exibe esta mensagem');
  console.log('');
  console.log('Flags opcionais:');
  console.log('  --dispositivo=<id>  ID do dispositivo para flutter run');
  console.log('  --ip=<ipv4>         IPv4 do PC para celular fisico');
  console.log('  --com-lembretes     Backend com LEMBRETES_ATIVOS=true');
  console.log('  --sem-front         Sobe so Java e Back (sem Flutter)');
  console.log('  --janelas           Forca janelas CMD em vez de abas do Windows Terminal');
  console.log('  --dry-run           Modo simulacao: imprime os comandos/argv sem executar');
  console.log('');
  console.log('Exemplos:');
  console.log('  node scripts/petcare.js checar');
  console.log('  node scripts/petcare.js iniciar --sem-front');
  console.log('  node scripts/petcare.js iniciar --dispositivo=emulator-5554');
  console.log('  node scripts/petcare.js front --ip=192.168.1.100');
  console.log('  node scripts/petcare.js verificar');
  console.log('====================================================');
  console.log('');
}

async function menuInterativo() {
  console.log('');
  console.log('====================================================');
  console.log('            PetCare - Menu Principal                ');
  console.log('====================================================');
  console.log(' 1. checar     - Checar dependencias e ambiente');
  console.log(' 2. iniciar    - Iniciar Servidor Java, Backend e Frontend');
  console.log(' 3. java       - Iniciar apenas o Servidor Java (porta 5000)');
  console.log(' 4. back       - Iniciar apenas o Backend (porta 3000)');
  console.log(' 5. front      - Iniciar apenas o Frontend Flutter');
  console.log(' 6. parar      - Encerrar Servidor Java e Backend');
  console.log(' 7. reiniciar  - Reiniciar os servicos');
  console.log(' 8. status     - Verificar estado das portas e servicos');
  console.log(' 9. verificar  - Testar protocolo socket do Servidor Java');
  console.log('10. ajuda      - Exibir instrucoes de uso');
  console.log(' 0. sair       - Sair');
  console.log('====================================================');

  const rl = readline.createInterface({ input: process.stdin, output: process.stdout });
  const answer = await new Promise((resolve) => {
    rl.question('Escolha uma opcao [0-10]: ', (ans) => {
      rl.close();
      resolve(ans.trim());
    });
  });

  const useWt = !flags.janelas && hasWt();

  switch (answer) {
    case '1': checar({}); break;
    case '2': await acaoIniciar(); break;
    case '3': await acaoJava(useWt); break;
    case '4': await acaoBack(useWt); break;
    case '5': await acaoFront(useWt); break;
    case '6': acaoParar(); break;
    case '7': await acaoReiniciar(); break;
    case '8': await acaoStatus(); break;
    case '9': await acaoVerificar(); break;
    case '10': acaoAjuda(); break;
    case '0': console.log('Saindo...'); break;
    default: console.log(COR.red + 'Opcao invalida.' + COR.reset); process.exit(1);
  }
}

// ---------------------------------------------------------------------------
// Ponto de entrada
// ---------------------------------------------------------------------------
async function main() {
  const useWt = !flags.janelas && hasWt();
  try {
    switch (acao) {
      case 'checar': {
        const r = checar({});
        if (r.falhas.length > 0) process.exit(1);
        break;
      }
      case 'iniciar': await acaoIniciar(); break;
      case 'java': await acaoJava(useWt); break;
      case 'back': await acaoBack(useWt); break;
      case 'front': await acaoFront(useWt); break;
      case 'parar': acaoParar(); break;
      case 'reiniciar': await acaoReiniciar(); break;
      case 'status': await acaoStatus(); break;
      case 'verificar': await acaoVerificar(); break;
      case 'ajuda': acaoAjuda(); break;
      case '': await menuInterativo(); break;
      default:
        console.error(COR.red + 'Acao desconhecida: "' + acao + '". Execute "node scripts/petcare.js ajuda".' + COR.reset);
        process.exit(1);
    }
  } catch (e) {
    console.error(COR.red + 'ERRO INESPERADO: ' + e.message + COR.reset);
    process.exit(1);
  }
}

main();
