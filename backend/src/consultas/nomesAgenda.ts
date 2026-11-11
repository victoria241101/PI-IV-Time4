import { ObjectId, type Db, type Document, type Filter } from 'mongodb';

// Busca apenas os vínculos das consultas que o perfil já pode visualizar.
export async function completarNomesAgenda(banco: Db, consultas: Document[]): Promise<Document[]> {
    async function buscar(colecao: string, ids: unknown[], campos: Document) {
        const valores = [...new Set(ids.filter(id => id != null).map(String))];
        if (!valores.length) return new Map<string, Document>();
        const filtro = valores.flatMap<string | ObjectId>(id => ObjectId.isValid(id) ? [id, new ObjectId(id)] : [id]);
        const documentos = await banco.collection<Document>(colecao).find(
            { _id: { $in: filtro } } as Filter<Document>, { projection: campos }
        ).toArray();
        return new Map(documentos.map(d => [String(d._id), d]));
    }
    const [pets, tutores, veterinarios] = await Promise.all([
        buscar('pets', consultas.map(c => c.petId), { nome: 1, especie: 1 }),
        buscar('tutores', consultas.map(c => c.tutorId), { nome: 1, usuarioId: 1 }),
        buscar('veterinarios', consultas.map(c => c.veterinarioId), { nome: 1 })
    ]);
    const usuarios = await buscar('usuarios', [...tutores.values()].map(t => t.usuarioId), { nome: 1 });
    const texto = (valor: unknown) => typeof valor === 'string' && valor.trim() ? valor : null;
    return consultas.map(c => {
        const pet = pets.get(String(c.petId));
        const tutor = tutores.get(String(c.tutorId));
        const usuario = usuarios.get(String(tutor?.usuarioId));
        return {
            ...c,
            petNome: texto(pet?.nome), especie: texto(pet?.especie),
            tutorNome: texto(usuario?.nome) ?? texto(tutor?.nome),
            veterinarioNome: texto(veterinarios.get(String(c.veterinarioId))?.nome)
        };
    });
}
