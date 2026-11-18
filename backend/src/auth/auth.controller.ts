import {
  Body,
  Controller,
  Get,
  Post,
  Req,
  UseGuards,
} from '@nestjs/common';

import {
  UserRole,
} from '../users/entities/user.entity.js';

import {
  AuthService,
} from './auth.service.js';

import {
  Roles,
} from './decorators/roles.decorator.js';

import {
  ForgotPasswordDto,
} from './dto/forgot-password.dto.js';

import {
  LoginDto,
} from './dto/login.dto.js';

import {
  GoogleSignInDto,
} from './dto/google-sign-in.dto.js';

import {
  RefreshTokenDto,
} from './dto/refresh-token.dto.js';

import {
  RegisterDto,
} from './dto/register.dto.js';

import {
  ResetPasswordDto,
} from './dto/reset-password.dto.js';

import {
  VerifyResetOtpDto,
} from './dto/verify-reset-otp.dto.js';

import {
  JwtAuthGuard,
} from './guards/jwt-auth.guard.js';

import {
  RolesGuard,
} from './guards/roles.guard.js';

@Controller('auth')
export class AuthController {
  constructor(
    private readonly authService:
      AuthService,
  ) {}

  @Post('register')
  register(
    @Body()
    dto: RegisterDto,
  ) {
    return this.authService.register(
      dto,
    );
  }

  @Post('login')
  login(
    @Body()
    dto: LoginDto,
  ) {
    return this.authService.login(
      dto,
    );
  }

  @Post('google')
  googleSignIn(
    @Body()
    dto: GoogleSignInDto,
  ) {
    return this.authService.googleSignIn(
      dto.idToken,
    );
  }

  @Post('refresh')
  refresh(
    @Body()
    dto: RefreshTokenDto,
  ) {
    return this.authService.refresh(
      dto.refreshToken,
    );
  }

  @Post('forgot-password')
  forgotPassword(
    @Body()
    dto: ForgotPasswordDto,
  ) {
    return this.authService
      .forgotPassword(
        dto.email,
      );
  }

  @Post('verify-reset-otp')
  verifyResetOtp(
    @Body()
    dto: VerifyResetOtpDto,
  ) {
    return this.authService
      .verifyResetOtp(
        dto.email,
        dto.otp,
      );
  }

  @Post('reset-password')
  resetPassword(
    @Body()
    dto: ResetPasswordDto,
  ) {
    return this.authService
      .resetPassword(
        dto.resetToken,
        dto.newPassword,
      );
  }

  @UseGuards(
    JwtAuthGuard,
  )
  @Get('me')
  getProfile(
    @Req()
    req: any,
  ) {
    return req.user;
  }

  @UseGuards(
    JwtAuthGuard,
  )
  @Post('logout')
  logout(
    @Req()
    req: any,
  ) {
    return this.authService.logout(
      req.user.userId,
    );
  }

  @UseGuards(
    JwtAuthGuard,
    RolesGuard,
  )
  @Roles(
    UserRole.ADMIN,
  )
  @Get('admin-test')
  adminTest(
    @Req()
    req: any,
  ) {
    return {
      message:
        'Admin access granted',

      user:
        req.user,
    };
  }
}