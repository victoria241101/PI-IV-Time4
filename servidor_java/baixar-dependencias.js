/**
 * Script de automação para download de dependências .jar do PetCare Backend.
 * Utiliza exclusivamente módulos nativos do Node.js (https, fs, path).
 */

const https = require('https');
const fs = require('fs');
const path = require('path');

// Diretório de destino para os arquivos .jar
const LIB_DIR = path.join(__dirname, 'lib');

// Lista oficial de dependências necessárias para o backend Java
const DEPENDENCIAS = [
  {
    nome: 'gson-2.10.1.jar',
    url: 'https://repo1.maven.org/maven2/com/google/code/gson/gson/2.10.1/gson-2.10.1.jar'
  },
  {
    nome: 'mongodb-driver-sync-4.11.1.jar',
    url: 'https://repo1.maven.org/maven2/org/mongodb/mongodb-driver-sync/4.11.1/mongodb-driver-sync-4.11.1.jar'
  },
  {
    nome: 'mongodb-driver-core-4.11.1.jar',
    url: 'https://repo1.maven.org/maven2/org/mongodb/mongodb-driver-core/4.11.1/mongodb-driver-core-4.11.1.jar'
  },
  {
    nome: 'bson-4.11.1.jar',
    url: 'https://repo1.maven.org/maven2/org/mongodb/bson/4.11.1/bson-4.11.1.jar'
  }
];

/**
 * Realiza o download de um arquivo via HTTPS, tratando redirecionamentos (301/302).
 *
 * @param {string} url - URL do arquivo a ser baixado
 * @param {string} destino - Caminho local onde o arquivo será salvo
 * @returns {Promise<void>}
 */
function baixarArquivo(url, destino) {
  return new Promise((resolve, reject) => {
    const requisicao = https.get(url, (resposta) => {
      // Trata redirecionamentos HTTP (301, 302, 307, 308)
      if (resposta.statusCode >= 300 && resposta.statusCode < 400 && resposta.headers.location) {
        return baixarArquivo(resposta.headers.location, destino).then(resolve).catch(reject);
      }

      if (resposta.statusCode !== 200) {
        return reject(
          new Error(`Falha no download (HTTP ${resposta.statusCode}): ${resposta.statusMessage}`)
        );
      }

      const arquivoStream = fs.createWriteStream(destino);

      resposta.pipe(arquivoStream);

      arquivoStream.on('finish', () => {
        arquivoStream.close(() => resolve());
      });

      arquivoStream.on('error', (err) => {
        fs.unlink(destino, () => {}); // Remove arquivo incompleto se houver erro de escrita
        reject(err);
      });
    });

    requisicao.on('error', (err) => {
      fs.unlink(destino, () => {}); // Remove arquivo incompleto se houver erro de conexão
      reject(
        new Error(
          `Erro de rede ao tentar conectar com ${url}.\nVerifique sua conexão com a internet. Detalhes: ${err.message}`
        )
      );
    });

    requisicao.setTimeout(30000, () => {
      requisicao.destroy();
      fs.unlink(destino, () => {});
      reject(new Error(`Tempo limite de download esgotado (timeout) para ${url}`));
    });
  });
}

/**
 * Função principal assíncrona que gerencia a verificação e o download de cada dependência.
 */
async function executar() {
  console.log('====================================================');
  console.log('    PetCare Backend - Verificação de Dependências   ');
  console.log('====================================================');

  // Garante que a pasta lib/ existe
  if (!fs.existsSync(LIB_DIR)) {
    console.log(`[CRIANDO DIRETÓRIO] Pasta 'lib/' criada em: ${LIB_DIR}`);
    fs.mkdirSync(LIB_DIR, { recursive: true });
  }

  let totalBaixados = 0;
  let totalExistentes = 0;

  for (const dep of DEPENDENCIAS) {
    const destinoArquivo = path.join(LIB_DIR, dep.nome);

    // Verifica se o arquivo já existe e tem tamanho maior que zero
    if (fs.existsSync(destinoArquivo)) {
      const stats = fs.statSync(destinoArquivo);
      if (stats.size > 0) {
        console.log(`[PULANDO] ${dep.nome} já existe na pasta lib/, pulando download.`);
        totalExistentes++;
        continue;
      }
    }

    console.log(`[BAIXANDO] Baixando ${dep.nome}...`);
    try {
      await baixarArquivo(dep.url, destinoArquivo);
      console.log(`[CONCLUÍDO] ${dep.nome} baixado com sucesso.`);
      totalBaixados++;
    } catch (erro) {
      console.error(`\n[ERRO FATAL] Falha ao baixar ${dep.nome}:`);
      console.error(erro.message);
      process.exit(1);
    }
  }

  console.log('====================================================');
  console.log(`Resumo: ${totalBaixados} baixado(s), ${totalExistentes} já existente(s).`);
  console.log('Todas as dependências Java estão prontas na pasta lib/.');
  console.log('====================================================\n');
}

executar();
