export type CalculatorInput={carbs:number; ratio:number; glucose:number; target:number; correctionFactor:number; activeInsulin?:number};
export function calculateSupportDose(input:CalculatorInput) { const food=input.carbs/input.ratio; const correction=Math.max(0,(input.glucose-input.target)/input.correctionFactor); return {foodDose:round(food),correctionDose:round(correction),activeInsulin:round(input.activeInsulin??0),estimatedDose:round(Math.max(0,food+correction-(input.activeInsulin??0)))}; }
const round=(n:number)=>Math.round(n*10)/10;
