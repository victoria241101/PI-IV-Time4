import { ObjectId, type Db } from "mongodb";
import { ehObjectIdHex } from "../chat/validacao.js";
import { normalizarTipoUsuario, variantesDoPapel } from "../chat/papeis.js";
import type { PapelChat } from "../chat/tipos.js";

type DocLegado = { _id: string | ObjectId; [chave: string]: any };

/**
 * Função PURA: extrai as variantes possíveis de um ID (em formato string e ObjectId).
 * Permite que consultas de banco combinem identificadores antigos em texto ("V001")
 * ou novos em ObjectId ({ $in: variantesId(...) }).
 */
export function variantesId(valor: unknown): (string | ObjectId)[] {
    if (valor === undefined || valor === null) {
        return [];
    }

    const resultado: (string | ObjectId)[] = [];
    const chaves = new Set<string>();

    function adicionar(item: string | ObjectId) {
        const chave = typeof item === "string"
            ? `str:${item.toLowerCase()}`
            : `obj:${item.toHexString().toLowerCase()}`;

        if (!chaves.has(chave)) {
            chaves.add(chave);
            resultado.push(item);
        }
    }

    if (valor instanceof ObjectId) {
        adicionar(valor);
        adicionar(valor.toHexString().toLowerCase());
    } else if (typeof valor === "string") {
        const aparado = valor.trim();
        if (aparado.length > 0) {
            adicionar(aparado);
            if (ehObjectIdHex(aparado)) {
                adicionar(aparado.toLowerCase());
                adicionar(new ObjectId(aparado.toLowerCase()));
            }
        }
    }

    return resultado;
}

/**
 * Função PURA: valida e seleciona o ID do usuário apenas se ele for elegível:
 * - Deve ser um objeto válido
 * - O campo 'ativo' DEVE ser estritamente true (inativos ou ausentes retornam null)
 * - O campo '_id' DEVE ser uma instância de ObjectId (usuários com _id em texto são ignorados)
 */
export function extrairUsuarioIdValido(usuario: unknown): ObjectId | null {
    if (!usuario || typeof usuario !== "object") {
        return null;
    }

    const u = usuario as { _id?: unknown; ativo?: unknown };

    if (u.ativo !== true) {
        return null;
    }

    if (!(u._id instanceof ObjectId)) {
        return null;
    }

    return u._id;
}

/**
 * Resolve o usuarioId (ObjectId na coleção 'usuarios') de um veterinário.
 * - Aceita ID em formato texto ("V001") ou ObjectId.
 * - Consulta 'veterinarios' por _id (ativo != false).
 * - Valida se o usuário correspondente em 'usuarios' está ativo e possui _id do tipo ObjectId.
 * - Nunca lança erro (retorna null em falhas).
 */
export async function resolverUsuarioDoVeterinario(
    db: Db,
    veterinarioId: unknown
): Promise<ObjectId | null> {
    try {
        const vars = variantesId(veterinarioId);
        if (vars.length === 0) {
            return null;
        }

        const vet = await db.collection<DocLegado>("veterinarios").findOne(
            { _id: { $in: vars }, ativo: { $ne: false } },
            { projection: { usuarioId: 1 } }
        );

        if (!vet || vet.usuarioId === undefined || vet.usuarioId === null) {
            return null;
        }

        const usuario = await db.collection<DocLegado>("usuarios").findOne(
            { _id: { $in: variantesId(vet.usuarioId) } },
            { projection: { _id: 1, ativo: 1 } }
        );

        return extrairUsuarioIdValido(usuario);
    } catch {
        return null;
    }
}

/**
 * Resolve o usuarioId (ObjectId na coleção 'usuarios') de um enfermeiro.
 * - Aceita ID em formato texto ("E001") ou ObjectId.
 * - Consulta 'enfermeiros' por _id (ativo != false).
 * - Valida se o usuário correspondente em 'usuarios' está ativo e possui _id do tipo ObjectId.
 * - Nunca lança erro (retorna null em falhas).
 */
export async function resolverUsuarioDoEnfermeiro(
    db: Db,
    enfermeiroId: unknown
): Promise<ObjectId | null> {
    try {
        const vars = variantesId(enfermeiroId);
        if (vars.length === 0) {
            return null;
        }

        const enf = await db.collection<DocLegado>("enfermeiros").findOne(
            { _id: { $in: vars }, ativo: { $ne: false } },
            { projection: { usuarioId: 1 } }
        );

        if (!enf || enf.usuarioId === undefined || enf.usuarioId === null) {
            return null;
        }

        const usuario = await db.collection<DocLegado>("usuarios").findOne(
            { _id: { $in: variantesId(enf.usuarioId) } },
            { projection: { _id: 1, ativo: 1 } }
        );

        return extrairUsuarioIdValido(usuario);
    } catch {
        return null;
    }
}

/**
 * Resolve o usuarioId (ObjectId na coleção 'usuarios') de um tutor.
 * Ordem estrita de busca:
 * 1. Tenta tutores._id -> usuarioId correspondente
 * 2. Tenta tutores.usuarioId -> usuarioId correspondente
 * 3. Tenta usuarios._id diretamente (para casos em que tutorId já é o _id de usuarios)
 * - Retorna apenas se o usuário for ativo e com _id ObjectId.
 * - Nunca lança erro (retorna null em falhas).
 */
export async function resolverUsuarioDoTutor(
    db: Db,
    tutorId: unknown
): Promise<ObjectId | null> {
    try {
        const vars = variantesId(tutorId);
        if (vars.length === 0) {
            return null;
        }

        // 1. Tenta tutores por _id
        const tutorPorId = await db.collection<DocLegado>("tutores").findOne(
            { _id: { $in: vars } },
            { projection: { usuarioId: 1 } }
        );

        if (tutorPorId && tutorPorId.usuarioId !== undefined && tutorPorId.usuarioId !== null) {
            const usuario = await db.collection<DocLegado>("usuarios").findOne(
                { _id: { $in: variantesId(tutorPorId.usuarioId) } },
                { projection: { _id: 1, ativo: 1 } }
            );
            const idValido = extrairUsuarioIdValido(usuario);
            if (idValido) {
                return idValido;
            }
        }

        // 2. Tenta tutores por usuarioId
        const tutorPorUsuario = await db.collection<DocLegado>("tutores").findOne(
            { usuarioId: { $in: vars } },
            { projection: { usuarioId: 1 } }
        );

        if (tutorPorUsuario && tutorPorUsuario.usuarioId !== undefined && tutorPorUsuario.usuarioId !== null) {
            const usuario = await db.collection<DocLegado>("usuarios").findOne(
                { _id: { $in: variantesId(tutorPorUsuario.usuarioId) } },
                { projection: { _id: 1, ativo: 1 } }
            );
            const idValido = extrairUsuarioIdValido(usuario);
            if (idValido) {
                return idValido;
            }
        }

        // 3. Tenta usuarios diretamente por _id
        const usuarioDireto = await db.collection<DocLegado>("usuarios").findOne(
            { _id: { $in: vars } },
            { projection: { _id: 1, ativo: 1 } }
        );

        return extrairUsuarioIdValido(usuarioDireto);
    } catch {
        return null;
    }
}

/**
 * Resolve o usuarioId do tutor responsável por um pet.
 * - Aceita petId em texto ou ObjectId.
 * - Busca pet ativo em 'pets' para obter pet.tutorId.
 * - Delega para resolverUsuarioDoTutor.
 * - Nunca lança erro (retorna null em falhas).
 */
export async function resolverUsuarioDoTutorDoPet(
    db: Db,
    petId: unknown
): Promise<ObjectId | null> {
    try {
        const vars = variantesId(petId);
        if (vars.length === 0) {
            return null;
        }

        const pet = await db.collection<DocLegado>("pets").findOne(
            { _id: { $in: vars }, ativo: { $ne: false } },
            { projection: { tutorId: 1 } }
        );

        if (!pet || pet.tutorId === undefined || pet.tutorId === null) {
            return null;
        }

        return resolverUsuarioDoTutor(db, pet.tutorId);
    } catch {
        return null;
    }
}

/**
 * Lista IDs de usuários ativos a partir de uma lista de tipos ("secretaria", "enfermeiro", etc.).
 * - Normaliza os tipos usando normalizarTipoUsuario e variantesDoPapel de chat/papeis.ts.
 * - Retorna exclusivamente ObjectIds de usuários ativos na coleção 'usuarios'.
 * - Deduplica a lista retornada.
 * - Nunca lança erro (retorna lista vazia em falhas).
 */
export async function listarUsuariosPorTipo(
    db: Db,
    tipos: string[]
): Promise<ObjectId[]> {
    try {
        if (!Array.isArray(tipos) || tipos.length === 0) {
            return [];
        }

        const papeisReconhecidos = new Set<PapelChat>();
        for (const tipo of tipos) {
            const papel = normalizarTipoUsuario(tipo);
            if (papel) {
                papeisReconhecidos.add(papel);
            }
        }

        if (papeisReconhecidos.size === 0) {
            return [];
        }

        const variantesTipo = new Set<string>();
        for (const papel of papeisReconhecidos) {
            for (const variante of variantesDoPapel(papel)) {
                variantesTipo.add(variante);
            }
        }

        const usuarios = await db.collection<DocLegado>("usuarios").find(
            {
                tipo: { $in: Array.from(variantesTipo) },
                ativo: true
            },
            { projection: { _id: 1, ativo: 1 } }
        ).toArray();

        const mapa = new Map<string, ObjectId>();
        for (const doc of usuarios) {
            const idValido = extrairUsuarioIdValido(doc);
            if (idValido) {
                mapa.set(idValido.toHexString().toLowerCase(), idValido);
            }
        }

        return Array.from(mapa.values());
    } catch {
        return [];
    }
}

/**
 * Busca o nome e o e-mail cadastrado de um usuário ativo para fins de notificação.
 * - Retorna null caso o usuário não exista, esteja inativo, não possua e-mail ou seu _id não seja ObjectId.
 * - Nunca lança erro.
 */
export async function buscarContatoEmail(
    db: Db,
    usuarioId: unknown
): Promise<{ email: string; nome: string } | null> {
    try {
        const vars = variantesId(usuarioId);
        if (vars.length === 0) {
            return null;
        }

        const usuario = await db.collection<DocLegado>("usuarios").findOne(
            { _id: { $in: vars } },
            { projection: { _id: 1, ativo: 1, email: 1, nome: 1 } }
        );

        const idValido = extrairUsuarioIdValido(usuario);
        if (!idValido || !usuario) {
            return null;
        }

        if (typeof usuario.email !== "string" || !usuario.email.trim()) {
            return null;
        }

        const nome = typeof usuario.nome === "string" && usuario.nome.trim()
            ? usuario.nome.trim()
            : "Tutor(a)";

        return {
            email: usuario.email.trim().toLowerCase(),
            nome
        };
    } catch {
        return null;
    }
}
