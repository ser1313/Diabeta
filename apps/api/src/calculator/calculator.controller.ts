import { Body, Controller, Header, Post, Req, UseGuards } from '@nestjs/common';
import { JwtGuard } from '../auth/jwt.guard';
import { CalculatorService } from './calculator.service';
import { CalculateDoseDto } from './calculator.dto';

@Controller('calculator')
@UseGuards(JwtGuard)
export class CalculatorController {
  constructor(private readonly calculator: CalculatorService) {}

  @Post('insulin')
  @Header('Cache-Control', 'no-store, no-cache, must-revalidate, private')
  calculate(@Req() req: any, @Body() dto: CalculateDoseDto) {
    void req;
    return this.calculator.calculate(dto);
  }
}
