export function glucoseStatus(value:number|null){if(value===null)return 'none';if(value<70)return 'low';if(value>180)return 'high';return 'in-range';}
