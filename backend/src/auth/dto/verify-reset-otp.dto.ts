import {
  IsEmail,
  IsString,
  Length,
  Matches,
} from 'class-validator';

export class VerifyResetOtpDto {
  @IsEmail()
  email!: string;

  @IsString()
  @Length(6, 6)
  @Matches(/^\d{6}$/)
  otp!: string;
}