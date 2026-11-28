import { Equals, IsEmail, IsString, MaxLength, MinLength } from 'class-validator';

export const REGISTRATION_TERMS_VERSION = '2026-11-28-v1';

export class RegisterDto {
  @IsEmail()
  @MaxLength(320)
  email!: string;

  @IsString()
  @MinLength(8)
  @MaxLength(128)
  password!: string;

  @IsString()
  @MinLength(1)
  @MaxLength(80)
  firstName!: string;

  @Equals(REGISTRATION_TERMS_VERSION, { message: 'The current registration terms must be accepted' })
  acceptedTermsVersion!: string;
}

export class LoginDto {
  @IsEmail()
  @MaxLength(320)
  email!: string;

  @IsString()
  @MinLength(1)
  @MaxLength(128)
  password!: string;
}
