// Autoria: Alycia Santos Bond — RA: 25016465
// Responsabilidade: compatibiliza filtros de consulta com IDs textuais e Mongo ObjectId.
import { ObjectId, type Document, type Filter } from "mongodb";

// Os agendamentos novos usam texto; registros antigos também podem usar ObjectId.
export function obterFiltroConsulta(id: string): Filter<Document> {
    return { _id: { $in: ObjectId.isValid(id) ? [id, new ObjectId(id)] : [id] } } as Filter<Document>;
}
