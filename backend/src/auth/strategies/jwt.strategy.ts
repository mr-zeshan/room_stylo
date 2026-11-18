import {
  Injectable,
  UnauthorizedException,
} from '@nestjs/common';

import {
  ConfigService,
} from '@nestjs/config';

import {
  PassportStrategy,
} from '@nestjs/passport';

import {
  ExtractJwt,
  Strategy,
} from 'passport-jwt';

import {
  UsersService,
} from '../../users/users.service.js';

@Injectable()
export class JwtStrategy
  extends PassportStrategy(Strategy) {
  constructor(
    configService: ConfigService,
    private readonly usersService:
      UsersService,
  ) {
    super({
      jwtFromRequest:
        ExtractJwt.fromAuthHeaderAsBearerToken(),

      ignoreExpiration: false,

      secretOrKey:
        configService.getOrThrow<string>(
          'JWT_ACCESS_SECRET',
        ),
    });
  }

  async validate(
    payload: {
      sub: string;
      email: string;
      role: string;
      type: string;
      sv: number;
    },
  ) {
    if (
      payload.type !== 'access'
    ) {
      throw new UnauthorizedException(
        'Invalid access token',
      );
    }

    const user =
      await this.usersService.findByIdForAuth(
        payload.sub,
      );

    if (
      !user ||
      !user.isActive
    ) {
      throw new UnauthorizedException(
        'Invalid access token',
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

    return {
      userId: user.id,
      email: user.email,
      role: user.role,
    };
  }
}