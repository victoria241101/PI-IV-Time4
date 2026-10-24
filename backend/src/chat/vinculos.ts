import { ObjectId, type Db, type Filter, type Document } from "mongodb";
import { ehObjectIdHex } from "./validacao.js";
import { variantesDoPapel } from "./papeis.js";
import { PAPEL_TUTOR } from "./tipos.js";

/**
 * Função PURA: avalia se o status de uma consulta conta como vínculo ativo.
 * Falso somente quando o status, após trim e em minúsculas, for "cancelada" ou "cancelado".
 * Qualquer outro valor (concluida, finalizada, agendada, texto vazio, null, undefined, etc.) retorna verdadeiro.
 */
export function statusConta(status: unknown): boolean {
    if (typeof status !== "string") {
        return true;
    }

    const limpo = status.trim().toLowerCase();
    if (limpo === "cancelada" || limpo === "cancelado") {
        return false;
    }

    return true;
}

/**
 * Função PURA: monta as representações de referência do tutor (em formato texto e ObjectId)
 * a partir do usuarioId e opcionalmente do _id do documento em tutores.
 */
export function montarReferenciasTutor(
    tutorUsuarioId: ObjectId,
    tutorDocId?: ObjectId | string | null
): (string | ObjectId)[] {
    const refs: (string | ObjectId)[] = [
        tutorUsuarioId.toHexString(),
        tutorUsuarioId
    ];

    if (tutorDocId) {
        refs.push(tutorDocId);

        if (typeof tutorDocId === "string") {
            if (ehObjectIdHex(tutorDocId)) {
                refs.push(new ObjectId(tutorDocId));
            }
        } else if (tutorDocId instanceof ObjectId) {
            refs.push(tutorDocId.toHexString());
        }
    }

    // Deduplica referências
    const refsUnicas: (string | ObjectId)[] = [];
    const vistasTexto = new Set<string>();
    const vistasObj = new Set<string>();

    for (const ref of refs) {
        if (typeof ref === "string") {
            const min = ref.toLowerCase();
            if (!vistasTexto.has(min)) {
                vistasTexto.add(min);
                refsUnicas.push(ref);
            }
        } else if (ref instanceof ObjectId) {
            const hex = ref.toHexString().toLowerCase();
            if (!vistasObj.has(hex)) {
                vistasObj.add(hex);
                refsUnicas.push(ref);
            }
        }
    }

    return refsUnicas;
}

/**
 * Função PURA: extrai strings únicas de ID a partir de uma lista de documentos de pets.
 */
export function montarReferenciasPets(pets: Array<{ _id: ObjectId | string }>): string[] {
    const ids = new Set<string>();

    for (const pet of pets) {
        if (!pet || pet._id === undefined || pet._id === null) {
            continue;
        }

        if (pet._id instanceof ObjectId) {
            ids.add(pet._id.toHexString().toLowerCase());
        } else if (typeof pet._id === "string") {
            const limpo = pet._id.trim();
            if (limpo.length > 0) {
                ids.add(limpo);
            }
        }
    }

    return Array.from(ids);
}

/**
 * Função PURA: extrai e deduplica ObjectIds únicos a partir de uma lista de entradas
 * que podem ser ObjectIds, strings hexadecimais de 24 caracteres ou valores nulos/indefinidos.
 */
export function extrairObjectIdsUnicos(
    entradas: Array<ObjectId | string | undefined | null>
): ObjectId[] {
    const mapa = new Map<string, ObjectId>();

    for (const item of entradas) {
        if (!item) {
            continue;
        }

        if (item instanceof ObjectId) {
            const hex = item.toHexString().toLowerCase();
            if (!mapa.has(hex)) {
                mapa.set(hex, item);
            }
        } else if (typeof item === "string" && ehObjectIdHex(item)) {
            const hex = item.toLowerCase();
            if (!mapa.has(hex)) {
                mapa.set(hex, new ObjectId(hex));
            }
        }
    }

    return Array.from(mapa.values());
}

/**
 * Retorna os IDs de usuário (ObjectId em usuarios) dos veterinários que atendem o tutor.
 */
export async function veterinariosDoTutor(
    db: Db,
    tutorUsuarioId: ObjectId
): Promise<ObjectId[]> {
    // 1. Busca documento do tutor em tutores
    const tutorDoc = await db.collection("tutores").findOne(
        { usuarioId: tutorUsuarioId },
        { projection: { _id: 1 } }
    );

    const refsTutor = montarReferenciasTutor(tutorUsuarioId, tutorDoc?._id);

    // 2. Busca pets ativos do tutor
    const pets = await db.collection("pets").find(
        { tutorId: { $in: refsTutor }, ativo: { $ne: false } },
        { projection: { _id: 1 } }
    ).toArray();

    const petIds = montarReferenciasPets(pets as Array<{ _id: ObjectId | string }>);

    // 3. Monta condições OR para identificar o tutor ou seus pets
    const condicoesTutor: Array<Record<string, unknown>> = [
        { tutorId: { $in: refsTutor.map(r => (typeof r === "string" ? r : r.toHexString())) } }
    ];

    if (petIds.length > 0) {
        condicoesTutor.push({ petId: { $in: petIds } });
    }

    // 4. Busca consultas ligadas ao tutor ou seus pets
    const consultas = await db.collection("consultas").find(
        { $or: condicoesTutor },
        { projection: { veterinarioId: 1, status: 1 } }
    ).toArray();

    // 5. Filtra pelo status que conta e extrai os IDs de veterinários
    const vetIdsTexto = Array.from(
        new Set(
            consultas
                .filter(c => statusConta(c.status) && typeof c.veterinarioId === "string" && c.veterinarioId.trim().length > 0)
                .map(c => c.veterinarioId.trim())
        )
    );

    if (vetIdsTexto.length === 0) {
        return [];
    }

    // 6. Busca os veterinários ativos para obter o usuarioId
    const vets = await db.collection("veterinarios").find(
        {
            _id: { $in: vetIdsTexto },
            ativo: { $ne: false },
            usuarioId: { $type: "objectId" }
        },
        { projection: { usuarioId: 1 } }
    ).toArray();

    return extrairObjectIdsUnicos(vets.map(v => v.usuarioId));
}

/**
 * Retorna os IDs de usuário (ObjectId em usuarios) dos tutores atendidos pelo veterinário.
 */
export async function tutoresDoVeterinario(
    db: Db,
    vetUsuarioId: ObjectId
): Promise<ObjectId[]> {
    // 1. Busca documento do veterinário pelo seu usuarioId
    const vetDoc = await db.collection("veterinarios").findOne(
        { usuarioId: vetUsuarioId, ativo: { $ne: false } },
        { projection: { _id: 1 } }
    );

    if (!vetDoc || typeof vetDoc._id !== "string") {
        return [];
    }

    // 2. Busca consultas deste veterinário
    const consultas = await db.collection("consultas").find(
        { veterinarioId: vetDoc._id },
        { projection: { tutorId: 1, petId: 1, status: 1 } }
    ).toArray();

    const consultasValidas = consultas.filter(c => statusConta(c.status));
    if (consultasValidas.length === 0) {
        return [];
    }

    // 3. Coleta os tutorId e petId das consultas válidas
    const tutorIdsConsulta = consultasValidas
        .map(c => c.tutorId)
        .filter((t): t is string | ObjectId => (typeof t === "string" && t.trim().length > 0) || t instanceof ObjectId);

    const petIdsTexto = Array.from(
        new Set(
            consultasValidas
                .map(c => (typeof c.petId === "string" ? c.petId.trim() : ""))
                .filter(p => p.length > 0)
        )
    );

    // 4. Se houver pets, busca os documentos dos pets para descobrir o tutorId
    let tutorIdsPets: Array<string | ObjectId> = [];
    if (petIdsTexto.length > 0) {
        const petIdsFiltro: Array<string | ObjectId> = [];
        for (const p of petIdsTexto) {
            petIdsFiltro.push(p);
            if (ehObjectIdHex(p)) {
                petIdsFiltro.push(new ObjectId(p));
            }
        }

        const pets = await db.collection("pets").find(
            { _id: { $in: petIdsFiltro } } as Filter<Document>,
            { projection: { tutorId: 1 } }
        ).toArray();

        tutorIdsPets = pets
            .map(p => p.tutorId)
            .filter((t): t is string | ObjectId => (typeof t === "string" && t.trim().length > 0) || t instanceof ObjectId);
    }

    // 5. Unifica todas as referências encontradas
    const todasReferencias = [...tutorIdsConsulta, ...tutorIdsPets];
    if (todasReferencias.length === 0) {
        return [];
    }

    const refsParaTutores: Array<string | ObjectId> = [];
    const idsParaUsuarios: ObjectId[] = [];

    for (const ref of todasReferencias) {
        refsParaTutores.push(ref);
        if (typeof ref === "string" && ehObjectIdHex(ref)) {
            const objId = new ObjectId(ref);
            refsParaTutores.push(objId);
            idsParaUsuarios.push(objId);
        } else if (ref instanceof ObjectId) {
            refsParaTutores.push(ref.toHexString());
            idsParaUsuarios.push(ref);
        }
    }

    // 6. Busca documentos em tutores para obter usuarioId
    const tutoresDocs = await db.collection("tutores").find(
        { _id: { $in: refsParaTutores }, usuarioId: { $type: "objectId" } } as Filter<Document>,
        { projection: { usuarioId: 1 } }
    ).toArray();

    // 7. Busca também diretamente em usuarios caso consultas.tutorId aponte para usuarios._id
    let usuariosDocs: Array<{ _id: ObjectId }> = [];
    if (idsParaUsuarios.length > 0) {
        usuariosDocs = await db.collection<{ _id: ObjectId }>("usuarios").find(
            {
                _id: { $in: idsParaUsuarios },
                tipo: { $in: variantesDoPapel(PAPEL_TUTOR) },
                ativo: true
            },
            { projection: { _id: 1 } }
        ).toArray();
    }

    const todosUsuarioIds = [
        ...tutoresDocs.map(t => t.usuarioId),
        ...usuariosDocs.map(u => u._id)
    ];

    return extrairObjectIdsUnicos(todosUsuarioIds);
}

/**
 * Verifica se existe vínculo ativo de atendimento entre um tutor e um veterinário.
 */
export async function temVinculo(
    db: Db,
    tutorUsuarioId: ObjectId,
    vetUsuarioId: ObjectId
): Promise<boolean> {
    // 1. Busca documento do veterinário
    const vetDoc = await db.collection("veterinarios").findOne(
        { usuarioId: vetUsuarioId, ativo: { $ne: false } },
        { projection: { _id: 1 } }
    );

    if (!vetDoc || typeof vetDoc._id !== "string") {
        return false;
    }

    // 2. Busca documento do tutor em tutores
    const tutorDoc = await db.collection("tutores").findOne(
        { usuarioId: tutorUsuarioId },
        { projection: { _id: 1 } }
    );

    const refsTutor = montarReferenciasTutor(tutorUsuarioId, tutorDoc?._id);

    // 3. Busca pets ativos do tutor
    const pets = await db.collection("pets").find(
        { tutorId: { $in: refsTutor }, ativo: { $ne: false } },
        { projection: { _id: 1 } }
    ).toArray();

    const petIds = montarReferenciasPets(pets as Array<{ _id: ObjectId | string }>);

    // 4. Monta condições OR para tutor ou seus pets
    const condicoesTutor: Array<Record<string, unknown>> = [
        { tutorId: { $in: refsTutor.map(r => (typeof r === "string" ? r : r.toHexString())) } }
    ];

    if (petIds.length > 0) {
        condicoesTutor.push({ petId: { $in: petIds } });
    }

    // 5. Busca consultas que liguem o tutor/pets a este veterinário
    const consultas = await db.collection("consultas").find(
        {
            veterinarioId: vetDoc._id,
            $or: condicoesTutor
        },
        { projection: { status: 1 } }
    ).toArray();

    // 6. Retorna verdadeiro se ao menos uma consulta tiver status que conta
    return consultas.some(c => statusConta(c.status));
}
