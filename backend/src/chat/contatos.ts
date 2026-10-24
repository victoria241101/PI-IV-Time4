import { ObjectId, type Db, type Filter, type Document } from "mongodb";
import {
    LIMITE_CONTATOS,
    PAPEL_TUTOR,
    PAPEL_VETERINARIO,
    PAPEL_ENFERMEIRO,
    PAPEL_SECRETARIA,
    type PapelChat,
    type UsuarioAutenticado
} from "./tipos.js";
import { variantesDoPapel, normalizarTipoUsuario } from "./papeis.js";
import { veterinariosDoTutor, tutoresDoVeterinario } from "./vinculos.js";
import { validarBusca, escaparRegex } from "./paginacao.js";

export type ContatoSecretaria = {
    tipo: "secretaria";
    nome: "Secretaria";
};

export type ContatoUsuario = {
    tipo: "usuario";
    usuarioId: string;
    nome: string;
    papel: PapelChat;
};

export type Contato = ContatoSecretaria | ContatoUsuario;

interface UsuarioContatoDoc {
    _id: ObjectId;
    nome?: string;
    tipo?: string;
}

/**
 * Lista os contatos permitidos para o usuário autenticado de acordo com as regras de negócio:
 * - Tutor: Secretaria + veterinários vinculados por consultas não canceladas
 * - Veterinário: Secretaria + todos os enfermeiros + tutores atendidos por consultas não canceladas
 * - Enfermeiro: Secretaria + todos os veterinários
 * - Secretária: todos os tutores, veterinários e enfermeiros (sem o item Secretaria), até LIMITE_CONTATOS
 *
 * Regras:
 * - Apenas usuários com ativo: true e _id ObjectId
 * - Nunca inclui o próprio usuário
 * - A busca por nome não afeta o item "Secretaria"
 * - Ordem alfabética por nome
 * - Projeção apenas de _id, nome e tipo
 */
export async function listarContatos(
    db: Db,
    usuario: UsuarioAutenticado,
    busca?: string | null
): Promise<Contato[]> {
    if (!usuario || !usuario.id || !usuario.papel) {
        return [];
    }

    const usuarioObjectId = new ObjectId(usuario.id);

    // Valida e extrai o termo de busca limpo
    const validacaoBusca = validarBusca(busca);
    const termoBusca = validacaoBusca.ok ? validacaoBusca.valor : null;

    const contatos: Contato[] = [];

    // O item Secretaria é incluído para todos os papéis exceto SECRETARIA,
    // e não é afetado pelo filtro de busca.
    if (usuario.papel !== PAPEL_SECRETARIA) {
        contatos.push({
            tipo: "secretaria",
            nome: "Secretaria"
        });
    }

    let filtro: Filter<Document> | null = null;
    let limite: number | null = null;

    if (usuario.papel === PAPEL_TUTOR) {
        const vetIds = await veterinariosDoTutor(db, usuarioObjectId);
        if (vetIds.length === 0) {
            return contatos;
        }

        filtro = {
            _id: { $in: vetIds, $type: "objectId", $ne: usuarioObjectId },
            tipo: { $in: variantesDoPapel(PAPEL_VETERINARIO) },
            ativo: true
        };
    } else if (usuario.papel === PAPEL_VETERINARIO) {
        const tutorIds = await tutoresDoVeterinario(db, usuarioObjectId);

        const condicoesOr: Filter<Document>[] = [
            { tipo: { $in: variantesDoPapel(PAPEL_ENFERMEIRO) } }
        ];

        if (tutorIds.length > 0) {
            condicoesOr.push({
                _id: { $in: tutorIds },
                tipo: { $in: variantesDoPapel(PAPEL_TUTOR) }
            });
        }

        filtro = {
            $or: condicoesOr,
            _id: { $type: "objectId", $ne: usuarioObjectId },
            ativo: true
        };
    } else if (usuario.papel === PAPEL_ENFERMEIRO) {
        filtro = {
            tipo: { $in: variantesDoPapel(PAPEL_VETERINARIO) },
            _id: { $type: "objectId", $ne: usuarioObjectId },
            ativo: true
        };
    } else if (usuario.papel === PAPEL_SECRETARIA) {
        filtro = {
            tipo: {
                $in: [
                    ...variantesDoPapel(PAPEL_TUTOR),
                    ...variantesDoPapel(PAPEL_VETERINARIO),
                    ...variantesDoPapel(PAPEL_ENFERMEIRO)
                ]
            },
            _id: { $type: "objectId", $ne: usuarioObjectId },
            ativo: true
        };
        limite = LIMITE_CONTATOS;
    } else {
        return [];
    }

    if (termoBusca) {
        filtro.nome = { $regex: escaparRegex(termoBusca), $options: "i" };
    }

    let cursor = db.collection<UsuarioContatoDoc>("usuarios")
        .find(filtro, { projection: { _id: 1, nome: 1, tipo: 1 } })
        .sort({ nome: 1 });

    if (limite !== null) {
        cursor = cursor.limit(limite);
    }

    const docs = await cursor.toArray();

    for (const doc of docs) {
        const papelNorm = normalizarTipoUsuario(doc.tipo);
        if (!papelNorm) {
            continue;
        }

        contatos.push({
            tipo: "usuario",
            usuarioId: doc._id.toHexString(),
            nome: typeof doc.nome === "string" ? doc.nome : "",
            papel: papelNorm
        });
    }

    return contatos;
}
