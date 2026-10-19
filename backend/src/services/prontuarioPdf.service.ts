import PDFDocument from "pdfkit";
import type { Response } from "express";

export interface DadosProntuario {
    consultaId: string;
    dataConsulta?: string | Date;
    status: string;
    pet: {
        nome: string;
        especie?: string;
        raca?: string;
        sexo?: string;
    };
    tutorNome?: string;
    veterinarioNome?: string;
    triagem?: {
        peso?: number;
        temperatura?: number;
        sintomas?: string;
        observacoes?: string;
        dataHora?: string | Date;
    } | null;
    atendimento?: {
        anamnese?: string;
        exameFisico?: string;
        diagnostico?: string;
        prognostico?: string;
        codigoICDVet?: string;
        tratamento?: string;
        observacoes?: string;
        dataHora?: string | Date;
    } | null;
}

function texto(valor: unknown): string {
    if (valor === null || valor === undefined || valor === "") {
        return "Não informado";
    }
    return String(valor);
}

function dataFormatada(valor?: string | Date): string {
    if (!valor) return "Não informada";
    const data = new Date(valor);
    if (Number.isNaN(data.getTime())) return texto(valor);
    return data.toLocaleString("pt-BR", { timeZone: "America/Sao_Paulo" });
}

export function gerarProntuarioPdf(res: Response, dados: DadosProntuario): void {
    const pdf = new PDFDocument({ size: "A4", margin: 48, bufferPages: true });
    pdf.on("error", (erro) => {
        console.error("Erro ao gerar PDF do prontuário:", erro);
        res.destroy(erro);
    });
    pdf.pipe(res);

    const azul = "#17365D";
    const cinza = "#526070";

    const tituloSecao = (titulo: string): void => {
        pdf.moveDown(0.7);
        pdf.font("Helvetica-Bold").fontSize(12).fillColor(azul).text(titulo);
        pdf.moveDown(0.35);
        pdf.strokeColor("#D9E3ED").lineWidth(0.7)
            .moveTo(48, pdf.y).lineTo(547, pdf.y).stroke();
        pdf.moveDown(0.4);
    };

    const campo = (rotulo: string, valor: unknown): void => {
        pdf.font("Helvetica-Bold").fontSize(9.5).fillColor(cinza)
            .text(`${rotulo}: `, { continued: true });
        pdf.font("Helvetica").fillColor("#182330").text(texto(valor));
        pdf.moveDown(0.3);
    };

    pdf.font("Helvetica-Bold").fontSize(20).fillColor(azul)
        .text("PetCare | Prontuário Clínico");
    pdf.font("Helvetica").fontSize(9).fillColor(cinza)
        .text("Documento gerado a partir dos registros do sistema PetCare.");
    pdf.moveDown(0.7);

    tituloSecao("Identificação do paciente");
    campo("Nome", dados.pet.nome);
    campo("Espécie", dados.pet.especie);
    campo("Raça", dados.pet.raca);
    campo("Sexo", dados.pet.sexo);
    campo("Tutor", dados.tutorNome);

    tituloSecao("Dados da consulta");
    campo("Identificador", dados.consultaId);
    campo("Data e horário", dataFormatada(dados.dataConsulta));
    campo("Status", dados.status);
    campo("Veterinária(o)", dados.veterinarioNome);

    tituloSecao("Triagem de enfermagem");
    if (dados.triagem) {
        campo("Data da triagem", dataFormatada(dados.triagem.dataHora));
        campo("Peso", dados.triagem.peso === undefined ? undefined : `${dados.triagem.peso} kg`);
        campo("Temperatura", dados.triagem.temperatura === undefined ? undefined : `${dados.triagem.temperatura} °C`);
        campo("Sintomas", dados.triagem.sintomas);
        campo("Observações", dados.triagem.observacoes);
    } else {
        campo("Triagem", "Não registrada");
    }

    tituloSecao("Atendimento veterinário");
    if (dados.atendimento) {
        campo("Data do atendimento", dataFormatada(dados.atendimento.dataHora));
        campo("Anamnese", dados.atendimento.anamnese);
        campo("Exame físico", dados.atendimento.exameFisico);
        campo("Diagnóstico", dados.atendimento.diagnostico);
        campo("Prognóstico", dados.atendimento.prognostico);
        campo("Código ICD-Vet", dados.atendimento.codigoICDVet);
        campo("Tratamento", dados.atendimento.tratamento);
        campo("Observações", dados.atendimento.observacoes);
    } else {
        campo("Atendimento", "Não registrado");
    }

    pdf.moveDown(1);
    pdf.font("Helvetica-Oblique").fontSize(8).fillColor(cinza)
        .text("Documento eletrônico de consulta. Não contém assinatura digital ou validação de conselho profissional.");

    const paginas = pdf.bufferedPageRange();
    for (let indice = paginas.start; indice < paginas.start + paginas.count; indice++) {
        pdf.switchToPage(indice);
        pdf.font("Helvetica").fontSize(8).fillColor(cinza)
            .text(`Página ${indice + 1} de ${paginas.count}`, 48, 785, {
                width: 499,
                align: "right"
            });
    }

    pdf.end();
}
