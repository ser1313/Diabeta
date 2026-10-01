import type { Record, Store, User } from './types.js';
import { randomUUID } from 'node:crypto';
export const memoryStore = (): Store => ({users:new Map(),profiles:new Map(),entries:new Map(),contacts:new Map()});
export function add(store:Store, resource:string, userId:string, body:object):Record { const record={id:randomUUID(),userId,...body}; const all=store.entries.get(resource)??[]; all.unshift(record); store.entries.set(resource,all); return record; }
export function list(store:Store, resource:string, userId:string) { return (store.entries.get(resource)??[]).filter(x=>x.userId===userId); }
export function userByEmail(store:Store,email:string) { return [...store.users.values()].find(u=>u.email===email.toLowerCase()); }
export function createUser(store:Store,email:string,passwordHash:string):User { const user={id:randomUUID(),email:email.toLowerCase(),passwordHash}; store.users.set(user.id,user); return user; }
