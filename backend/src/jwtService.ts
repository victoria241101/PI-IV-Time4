import { SignJWT, jwtVerify } from "jose";

const chaveSecreta = process.env.JWT_SECRET;

if (!chaveSecreta || !/^[0-9a-fA-F]{64}$/.test(chaveSecreta)) {
    throw new Error("JWT_SECRET não foi configurada corretamente.");
}

const chave = Buffer.from(chaveSecreta, "hex");

export async function gerarToken(usuarioId: string): Promise<string> {
    return new SignJWT({})
        .setProtectedHeader({ alg: "HS256" })
        .setSubject(usuarioId)
        .setIssuedAt()
        .setExpirationTime("2h")
        .sign(chave);
}

export async function verificarToken(token: string): Promise<string> {
    const { payload } = await jwtVerify(token, chave, {
        algorithms: ["HS256"]
    });

    if (typeof payload.sub !== "string" || !payload.sub) {
        throw new Error("Token sem identificador de usuário.");
    }

    return payload.sub;
}
