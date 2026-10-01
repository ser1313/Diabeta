import { describe,expect,it } from 'vitest'; import { glucoseStatus } from './support';
describe('glucose status',()=>{it('identifies safe and unsafe values',()=>{expect(glucoseStatus(69)).toBe('low');expect(glucoseStatus(110)).toBe('in-range');expect(glucoseStatus(181)).toBe('high')})});
