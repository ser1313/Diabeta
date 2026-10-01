export type User = { id:string; email:string; passwordHash:string };
export type Record = { id:string; userId:string; [key:string]: unknown };
export type Store = { users: Map<string,User>; profiles: Map<string,Record>; entries: Map<string,Record[]>; contacts: Map<string,Record[]> };
declare module '@fastify/jwt' { interface FastifyJWT { user: { id:string; email:string } } }
