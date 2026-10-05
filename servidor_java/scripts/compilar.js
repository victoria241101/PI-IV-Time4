/**
 * Script de compilação do backend PetCare em Java puro.
 * Varre recursivamente a pasta src/, coleta os arquivos .java e invoca o javac.
 */

const fs = require('fs');
const path = require('path');
const { spawnSync } = require('child_process');

const ROOT_DIR = path.resolve(__dirname, '..');
const SRC_DIR = path.join(ROOT_DIR, 'src');
const OUT_DIR = path.join(ROOT_DIR, 'out');
const LIB_DIR = path.join(ROOT_DIR, 'lib');

function coletarArquivosJava(dir, lista = []) {
  if (!fs.existsSync(dir)) {
    return lista;
  }
  const itens = fs.readdirSync(dir, { withFileTypes: true });
  for (const item of itens) {
    const caminhoCompleto = path.join(dir, item.name);
    if (item.isDirectory()) {
      coletarArquivosJava(caminhoCompleto, lista);
    } else if (item.isFile() && item.name.endsWith('.java')) {
      lista.push(caminhoCompleto);
    }
  }
  return lista;
}

function compilar() {
  console.log('====================================================');
  console.log('          PetCare Backend - Compilação Java         ');
  console.log('====================================================');

  if (!fs.existsSync(SRC_DIR)) {
    console.error(`[ERRO] Diretório de fontes não encontrado: ${SRC_DIR}`);
    process.exit(1);
  }

  const arquivosJava = coletarArquivosJava(SRC_DIR);
  if (arquivosJava.length === 0) {
    console.error('[ERRO] Nenhum arquivo .java encontrado em src/.');
    process.exit(1);
  }

  if (!fs.existsSync(OUT_DIR)) {
    fs.mkdirSync(OUT_DIR, { recursive: true });
  }

  // Classpath: lib/* (caminho absoluto multiplataforma)
  const classpath = path.join(LIB_DIR, '*');

  console.log(`[COMPILANDO] ${arquivosJava.length} arquivos .java encontrados.`);
  console.log(`[DESTINO] Diretório de saída: ${OUT_DIR}`);

  const args = [
    '-Xlint:all',
    '-encoding',
    'UTF-8',
    '-cp',
    classpath,
    '-d',
    OUT_DIR,
    ...arquivosJava
  ];

  const resultado = spawnSync('javac', args, {
    stdio: 'inherit',
    cwd: ROOT_DIR
  });

  if (resultado.error) {
    console.error(`[ERRO FATAL] Falha ao invocar o compilador javac: ${resultado.error.message}`);
    process.exit(1);
  }

  if (resultado.status !== 0) {
    console.error(`\n[ERRO] Compilação falhou com código de saída ${resultado.status}.`);
    process.exit(resultado.status || 1);
  }

  console.log('====================================================');
  console.log('[SUCESSO] Compilação concluída.');
  console.log('====================================================\n');
}

compilar();
