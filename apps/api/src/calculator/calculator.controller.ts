import { Body, Controller, ForbiddenException, Post, Req, UseGuards } from '@nestjs/common';
import { JwtGuard } from '../auth/jwt.guard';
import { CalculatorService } from './calculator.service';
import { CalculateDoseDto } from './calculator.dto';

// La calculadora de bolo está deshabilitada salvo que se active de forma
// explícita (solo entornos de desarrollo o validación clínica). No debe
// habilitarse para uso real hasta su revisión profesional (issue #52).
export function isClinicalCalculatorEnabled(env: NodeJS.ProcessEnv = process.env): boolean {
  return env.CLINICAL_CALCULATOR_ENABLED === 'true';
}

@Controller('calculator')
@UseGuards(JwtGuard)
export class CalculatorController {
  constructor(private readonly calculator: CalculatorService) {}

  @Post('insulin')
  calculate(@Req() req: any, @Body() dto: CalculateDoseDto) {
    void req;
    if (!isClinicalCalculatorEnabled()) {
      throw new ForbiddenException(
        'La calculadora está deshabilitada hasta su revisión por profesionales sanitarios.',
      );
    }
    return this.calculator.calculate(dto);
  }
}
