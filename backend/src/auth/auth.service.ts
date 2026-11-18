import {
  ConflictException,
  Injectable,
  NotFoundException,
  HttpException,
HttpStatus,
  UnauthorizedException,
} from '@nestjs/common';

import {
  ConfigService,
} from '@nestjs/config';

import {
  JwtService,
} from '@nestjs/jwt';

import * as bcrypt from 'bcrypt';

import { OAuth2Client } from 'google-auth-library';

import {
  createHash,
  randomInt,
  randomUUID,
  timingSafeEqual,
} from 'node:crypto';

import type {
  StringValue,
} from 'ms';

import {
  UsersService,
} from '../users/users.service.js';

import {
  LoginDto,
} from './dto/login.dto.js';

import {
  RegisterDto,
} from './dto/register.dto.js';

type RefreshPayload = {
  sub: string;
  email: string;
  role: string;
  type: 'refresh';
  jti: string;
  sv: number;
};

type PasswordResetPayload = {
  sub: string;
  email: string;
  type: 'password_reset';
  nonce: string;
};

const RESET_OTP_EXPIRY_MINUTES = 10;
const RESET_OTP_MAX_ATTEMPTS = 5;
const RESET_OTP_RESEND_SECONDS = 60;
const RESET_TOKEN_EXPIRY = '10m';

@Injectable()
export class AuthService {
  constructor(
    private readonly usersService:
      UsersService,

    private readonly jwtService:
      JwtService,

    private readonly configService:
      ConfigService,
  ) {}

  async register(
    dto: RegisterDto,
  ) {
    const email =
      dto.email
        .trim()
        .toLowerCase();

    const existingUser =
      await this.usersService.findByEmail(
        email,
      );

    if (existingUser) {
      throw new ConflictException(
        'Email is already registered',
      );
    }

    const passwordHash =
      await bcrypt.hash(
        dto.password,
        12,
      );

    const user =
      await this.usersService.create({
        name:
          dto.name.trim(),

        email,

        passwordHash,
      });

    return {
      message:
        'Registration successful',

      user: {
        id: user.id,
        name: user.name,
        email: user.email,
        role: user.role,
      },
    };
  }

  async login(
    dto: LoginDto,
  ) {
    const email =
      dto.email
        .trim()
        .toLowerCase();

    const user =
      await this.usersService.findByEmail(
        email,
      );

    if (!user) {
      throw new UnauthorizedException(
        'Invalid email or password',
      );
    }

    if (!user.isActive) {
      throw new UnauthorizedException(
        'Account is inactive',
      );
    }

    if (!user.passwordHash) {
      throw new UnauthorizedException(
        'This account uses Google Sign-In',
      );
    }

    const passwordMatched =
      await bcrypt.compare(
        dto.password,
        user.passwordHash,
      );

    if (!passwordMatched) {
      throw new UnauthorizedException(
        'Invalid email or password',
      );
    }

    const tokens =
      await this.generateTokens(
        user.id,
        user.email,
        user.role,
        user.sessionVersion,
      );

    const refreshTokenHash =
      this.hashToken(
        tokens.refreshToken,
      );

    await this.usersService
      .updateRefreshTokenHash(
        user.id,
        refreshTokenHash,
      );

    return {
      message:
        'Login successful',

      ...tokens,

      user: {
        id: user.id,
        name: user.name,
        email: user.email,
        role: user.role,
      },
    };
  }

  async googleSignIn(
    idToken: string,
  ) {
    const googleClientId =
      this.configService.getOrThrow<string>(
        'GOOGLE_CLIENT_ID',
      );

    const googleClient =
      new OAuth2Client(googleClientId);

    let googlePayload;

    try {
      const ticket =
        await googleClient.verifyIdToken({
          idToken,
          audience: googleClientId,
        });

      googlePayload = ticket.getPayload();
    } catch {
      throw new UnauthorizedException(
        'Invalid Google ID token',
      );
    }

    if (
      !googlePayload?.sub ||
      !googlePayload.email ||
      googlePayload.email_verified !== true
    ) {
      throw new UnauthorizedException(
        'Google account email is not verified',
      );
    }

    const googleId = googlePayload.sub;
    const email = googlePayload.email.trim().toLowerCase();
    const name =
      googlePayload.name?.trim() ||
      email.split('@')[0] ||
      'RoomStylo User';

    let user =
      await this.usersService.findByGoogleId(
        googleId,
      );

    if (!user) {
      const existingUser =
        await this.usersService.findByEmail(
          email,
        );

      if (existingUser) {
        if (!existingUser.isActive) {
          throw new UnauthorizedException(
            'Account is inactive',
          );
        }

        if (
          existingUser.googleId &&
          existingUser.googleId !== googleId
        ) {
          throw new ConflictException(
            'This email is already linked to another Google account',
          );
        }

        await this.usersService.linkGoogleId(
          existingUser.id,
          googleId,
        );

        user = existingUser;
      } else {
        user =
          await this.usersService.createGoogleUser({
            name,
            email,
            googleId,
          });
      }
    }

    if (!user.isActive) {
      throw new UnauthorizedException(
        'Account is inactive',
      );
    }

    const tokens =
      await this.generateTokens(
        user.id,
        user.email,
        user.role,
        user.sessionVersion,
      );

    await this.usersService.updateRefreshTokenHash(
      user.id,
      this.hashToken(tokens.refreshToken),
    );

    return {
      message: 'Google sign-in successful',
      ...tokens,
      user: {
        id: user.id,
        name: user.name,
        email: user.email,
        role: user.role,
      },
    };
  }

  async refresh(
    refreshToken: string,
  ) {
    let payload:
      RefreshPayload;

    try {
      payload =
        await this.jwtService
          .verifyAsync<RefreshPayload>(
            refreshToken,
            {
              secret:
                this.configService
                  .getOrThrow<string>(
                    'JWT_REFRESH_SECRET',
                  ),
            },
          );
    } catch {
      throw new UnauthorizedException(
        'Invalid or expired refresh token',
      );
    }

    if (
      payload.type !== 'refresh'
    ) {
      throw new UnauthorizedException(
        'Invalid refresh token',
      );
    }

    const user =
      await this.usersService
        .findByIdWithRefreshToken(
          payload.sub,
        );

    if (
      !user ||
      !user.isActive ||
      !user.refreshTokenHash
    ) {
      throw new UnauthorizedException(
        'Invalid refresh token',
      );
    }

    if (
      payload.sv !==
      user.sessionVersion
    ) {
      throw new UnauthorizedException(
        'Session expired',
      );
    }

    const incomingHash =
      this.hashToken(
        refreshToken,
      );

    if (
      !this.safeHashCompare(
        incomingHash,
        user.refreshTokenHash,
      )
    ) {
      throw new UnauthorizedException(
        'Invalid refresh token',
      );
    }

    const tokens =
      await this.generateTokens(
        user.id,
        user.email,
        user.role,
        user.sessionVersion,
      );

    const newRefreshTokenHash =
      this.hashToken(
        tokens.refreshToken,
      );

    await this.usersService
      .updateRefreshTokenHash(
        user.id,
        newRefreshTokenHash,
      );

    return tokens;
  }

  async logout(
    userId: string,
  ) {
    await this.usersService
      .invalidateSession(
        userId,
      );

    return {
      message:
        'Logout successful',
    };
  }

  async forgotPassword(
    emailInput: string,
  ) {
    const email =
      emailInput
        .trim()
        .toLowerCase();

    const user =
      await this.usersService
        .findByEmail(
          email,
        );

    if (!user) {
      throw new NotFoundException(
        'Email is not registered',
      );
    }

    if (!user.isActive) {
      throw new UnauthorizedException(
        'Account is inactive',
      );
    }

    if (
      user.passwordResetOtpLastSentAt
    ) {
      const elapsedMs =
        Date.now() -
        user
          .passwordResetOtpLastSentAt
          .getTime();

      const cooldownMs =
        RESET_OTP_RESEND_SECONDS *
        1000;

      if (
        elapsedMs <
        cooldownMs
      ) {
        const secondsLeft =
          Math.ceil(
            (
              cooldownMs -
              elapsedMs
            ) /
              1000,
          );

        throw new HttpException(
  `Please wait ${secondsLeft} seconds before requesting another code`,
  HttpStatus.TOO_MANY_REQUESTS,
);
      }
    }

    const otp =
      randomInt(
        100000,
        1000000,
      ).toString();

    const nonce =
      randomUUID();

    const otpHash =
      this.hashResetOtp(
        email,
        otp,
        nonce,
      );

    const expiresAt =
      new Date(
        Date.now() +
          RESET_OTP_EXPIRY_MINUTES *
            60 *
            1000,
      );

    await this.usersService
      .savePasswordResetOtp(
        user.id,
        {
          otpHash,
          expiresAt,
          lastSentAt:
            new Date(),
          nonce,
        },
      );

    const response: {
      message: string;
      devOtp?: string;
    } = {
      message:
        'Password reset code sent',
    };

    const nodeEnv =
      this.configService
        .get<string>(
          'NODE_ENV',
        ) ?? 'development';

    if (
      nodeEnv !== 'production'
    ) {
      response.devOtp = otp;
    }

    return response;
  }

  async verifyResetOtp(
    emailInput: string,
    otp: string,
  ) {
    const email =
      emailInput
        .trim()
        .toLowerCase();

    const user =
      await this.usersService
        .findByEmail(
          email,
        );

    if (
      !user ||
      !user.isActive
    ) {
      throw new UnauthorizedException(
        'Invalid or expired reset code',
      );
    }

    if (
      !user.passwordResetOtpHash ||
      !user.passwordResetOtpExpiresAt ||
      !user.passwordResetNonce
    ) {
      throw new UnauthorizedException(
        'Invalid or expired reset code',
      );
    }

    if (
      user.passwordResetOtpAttempts >=
      RESET_OTP_MAX_ATTEMPTS
    ) {
      await this.usersService
        .clearPasswordResetState(
          user.id,
        );

      throw new UnauthorizedException(
        'Too many incorrect attempts. Request a new code.',
      );
    }

    if (
      user.passwordResetOtpExpiresAt
        .getTime() <
      Date.now()
    ) {
      await this.usersService
        .clearPasswordResetState(
          user.id,
        );

      throw new UnauthorizedException(
        'Reset code has expired. Request a new code.',
      );
    }

    const incomingHash =
      this.hashResetOtp(
        email,
        otp,
        user.passwordResetNonce,
      );

    if (
      !this.safeHashCompare(
        incomingHash,
        user.passwordResetOtpHash,
      )
    ) {
      await this.usersService
        .incrementPasswordResetAttempts(
          user.id,
        );

      const attemptsLeft =
        RESET_OTP_MAX_ATTEMPTS -
        (
          user.passwordResetOtpAttempts +
          1
        );

      if (
        attemptsLeft <= 0
      ) {
        await this.usersService
          .clearPasswordResetState(
            user.id,
          );

        throw new UnauthorizedException(
          'Too many incorrect attempts. Request a new code.',
        );
      }

      throw new UnauthorizedException(
        `Invalid reset code. ${attemptsLeft} attempt(s) remaining.`,
      );
    }

    const nonce =
      user.passwordResetNonce;

    await this.usersService
      .markPasswordResetOtpVerified(
        user.id,
      );

    const resetToken =
      await this.jwtService.signAsync(
        {
          sub: user.id,
          email: user.email,
          type:
            'password_reset',
          nonce,
        },
        {
          secret:
            this.configService
              .getOrThrow<string>(
                'JWT_RESET_SECRET',
              ),

          expiresIn:
            RESET_TOKEN_EXPIRY,
        },
      );

    return {
      message:
        'Reset code verified',

      resetToken,
    };
  }

  async resetPassword(
    resetToken: string,
    newPassword: string,
  ) {
    let payload:
      PasswordResetPayload;

    try {
      payload =
        await this.jwtService
          .verifyAsync<PasswordResetPayload>(
            resetToken,
            {
              secret:
                this.configService
                  .getOrThrow<string>(
                    'JWT_RESET_SECRET',
                  ),
            },
          );
    } catch {
      throw new UnauthorizedException(
        'Invalid or expired reset token',
      );
    }

    if (
      payload.type !==
      'password_reset'
    ) {
      throw new UnauthorizedException(
        'Invalid reset token',
      );
    }

    const user =
      await this.usersService
        .findByEmail(
          payload.email
            .trim()
            .toLowerCase(),
        );

    if (
      !user ||
      !user.isActive ||
      user.id !== payload.sub ||
      !user.passwordResetNonce
    ) {
      throw new UnauthorizedException(
        'Invalid or expired reset token',
      );
    }

    if (
      user.passwordResetNonce !==
      payload.nonce
    ) {
      throw new UnauthorizedException(
        'Invalid or expired reset token',
      );
    }

    const samePassword =
      user.passwordHash
        ? await bcrypt.compare(
            newPassword,
            user.passwordHash,
          )
        : false;

    if (samePassword) {
      throw new ConflictException(
        'New password must be different from your current password',
      );
    }

    const passwordHash =
      await bcrypt.hash(
        newPassword,
        12,
      );

    await this.usersService
      .completePasswordReset(
        user.id,
        passwordHash,
      );

    return {
      message:
        'Password reset successful',
    };
  }

  private async generateTokens(
    userId: string,
    email: string,
    role: string,
    sessionVersion: number,
  ) {
    const accessExpiresIn =
      (
        this.configService
          .get<string>(
            'JWT_ACCESS_EXPIRES_IN',
          ) ??
        '15m'
      ) as StringValue;

    const refreshExpiresIn =
      (
        this.configService
          .get<string>(
            'JWT_REFRESH_EXPIRES_IN',
          ) ??
        '30d'
      ) as StringValue;

    const [
      accessToken,
      refreshToken,
    ] =
      await Promise.all([
        this.jwtService.signAsync(
          {
            sub:
              userId,

            email,

            role,

            type:
              'access',

            sv:
              sessionVersion,

            jti:
              randomUUID(),
          },
          {
            secret:
              this.configService
                .getOrThrow<string>(
                  'JWT_ACCESS_SECRET',
                ),

            expiresIn:
              accessExpiresIn,
          },
        ),

        this.jwtService.signAsync(
          {
            sub:
              userId,

            email,

            role,

            type:
              'refresh',

            sv:
              sessionVersion,

            jti:
              randomUUID(),
          },
          {
            secret:
              this.configService
                .getOrThrow<string>(
                  'JWT_REFRESH_SECRET',
                ),

            expiresIn:
              refreshExpiresIn,
          },
        ),
      ]);

    return {
      accessToken,
      refreshToken,
    };
  }

  private hashToken(
    token: string,
  ): string {
    return createHash(
      'sha256',
    )
      .update(token)
      .digest('hex');
  }

  private hashResetOtp(
    email: string,
    otp: string,
    nonce: string,
  ): string {
    const secret =
      this.configService
        .getOrThrow<string>(
          'JWT_RESET_SECRET',
        );

    return createHash(
      'sha256',
    )
      .update(
        `${secret}:${email}:${otp}:${nonce}`,
      )
      .digest('hex');
  }

  private safeHashCompare(
    firstHash: string,
    secondHash: string,
  ): boolean {
    const first =
      Buffer.from(
        firstHash,
        'hex',
      );

    const second =
      Buffer.from(
        secondHash,
        'hex',
      );

    if (
      first.length !==
      second.length
    ) {
      return false;
    }

    return timingSafeEqual(
      first,
      second,
    );
  }
}