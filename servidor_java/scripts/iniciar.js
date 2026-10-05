/**
 * Script de inicialização do backend PetCare em Java puro.
 * Monta o classpath dinamicamente com path.delimiter e executa petcare.servidor.Servidor.
 */

const path = require('path');
const { spawn } = require('child_process');

const ROOT_DIR = path.resolve(__dirname, '..');
const OUT_DIR = path.join(ROOT_DIR, 'out');
const LIB_DIR = path.join(ROOT_DIR, 'lib', '*');

// Classpath multiplataforma: out + lib/* unidos pelo separador do sistema (; no Windows, : no Linux/Mac)
const classpath = [OUT_DIR, LIB_DIR].join(path.delimiter);
const MAIN_CLASS = 'petcare.servidor.Servidor';

const args = ['-cp', classpath, MAIN_CLASS, ...process.argv.slice(2)];

const processoJava = spawn('java', args, {
  stdio: 'inherit',
  cwd: ROOT_DIR
});

processoJava.on('error', (err) => {
  console.error(`[ERRO FATAL] Falha ao iniciar a JVM (java): ${err.message}`);
  process.exit(1);
});

processoJava.on('exit', (codigo) => {
  process.exit(codigo || 0);
});

// Repassa sinais de terminação para o processo filho
process.on('SIGINT', () => {
  processoJava.kill('SIGINT');
});

process.on('SIGTERM', () => {
  processoJava.kill('SIGTERM');
});
