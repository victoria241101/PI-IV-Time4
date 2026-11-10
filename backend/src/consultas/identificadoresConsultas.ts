import { ObjectId, type Document, type Filter } from "mongodb";

// Os agendamentos novos usam texto; registros antigos também podem usar ObjectId.
export function obterFiltroConsulta(id: string): Filter<Document> {
    return { _id: { $in: ObjectId.isValid(id) ? [id, new ObjectId(id)] : [id] } } as Filter<Document>;
}
