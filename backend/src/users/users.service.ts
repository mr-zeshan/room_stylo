import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { User } from './entities/user.entity.js';

@Injectable()
export class UsersService {
  constructor(
    @InjectRepository(User)
    private readonly usersRepository: Repository<User>,
  ) {}

  async findByEmail(email: string): Promise<User | null> {
    return this.usersRepository.findOne({
      where: { email },
      select: {
        id: true, name: true, email: true, passwordHash: true,
        googleId: true, role: true, isActive: true, sessionVersion: true,
        passwordResetOtpHash: true, passwordResetOtpExpiresAt: true,
        passwordResetOtpAttempts: true, passwordResetOtpLastSentAt: true,
        passwordResetNonce: true, createdAt: true, updatedAt: true,
      },
    });
  }

  async findByGoogleId(googleId: string): Promise<User | null> {
    return this.usersRepository.findOne({
      where: { googleId },
      select: {
        id: true, name: true, email: true, googleId: true,
        role: true, isActive: true, sessionVersion: true,
      },
    });
  }

  async findByIdForAuth(userId: string): Promise<User | null> {
    return this.usersRepository.findOne({
      where: { id: userId },
      select: { id: true, name: true, email: true, role: true, isActive: true, sessionVersion: true },
    });
  }

  async create(data: { name: string; email: string; passwordHash: string }): Promise<User> {
    return this.usersRepository.save(this.usersRepository.create(data));
  }

  async createGoogleUser(data: { name: string; email: string; googleId: string }): Promise<User> {
    return this.usersRepository.save(
      this.usersRepository.create({ ...data, passwordHash: null }),
    );
  }

  async linkGoogleId(userId: string, googleId: string): Promise<void> {
    await this.usersRepository.update(userId, { googleId });
  }

  async updateRefreshTokenHash(userId: string, refreshTokenHash: string | null): Promise<void> {
    await this.usersRepository.update(userId, { refreshTokenHash });
  }

  async findByIdWithRefreshToken(userId: string): Promise<User | null> {
    return this.usersRepository.findOne({
      where: { id: userId },
      select: { id: true, name: true, email: true, role: true, isActive: true, refreshTokenHash: true, sessionVersion: true },
    });
  }

  async savePasswordResetOtp(userId: string, data: { otpHash: string; expiresAt: Date; lastSentAt: Date; nonce: string }): Promise<void> {
    await this.usersRepository.update(userId, {
      passwordResetOtpHash: data.otpHash,
      passwordResetOtpExpiresAt: data.expiresAt,
      passwordResetOtpAttempts: 0,
      passwordResetOtpLastSentAt: data.lastSentAt,
      passwordResetNonce: data.nonce,
    });
  }

  async incrementPasswordResetAttempts(userId: string): Promise<void> {
    await this.usersRepository.createQueryBuilder().update(User).set({
      passwordResetOtpAttempts: () => '"passwordResetOtpAttempts" + 1',
    }).where('id = :userId', { userId }).execute();
  }

  async markPasswordResetOtpVerified(userId: string): Promise<void> {
    await this.usersRepository.update(userId, {
      passwordResetOtpHash: null,
      passwordResetOtpExpiresAt: null,
      passwordResetOtpAttempts: 0,
    });
  }

  async clearPasswordResetState(userId: string): Promise<void> {
    await this.usersRepository.update(userId, {
      passwordResetOtpHash: null,
      passwordResetOtpExpiresAt: null,
      passwordResetOtpAttempts: 0,
      passwordResetOtpLastSentAt: null,
      passwordResetNonce: null,
    });
  }

  async completePasswordReset(userId: string, passwordHash: string): Promise<void> {
    await this.usersRepository.createQueryBuilder().update(User).set({
      passwordHash,
      refreshTokenHash: null,
      passwordResetOtpHash: null,
      passwordResetOtpExpiresAt: null,
      passwordResetOtpAttempts: 0,
      passwordResetOtpLastSentAt: null,
      passwordResetNonce: null,
      sessionVersion: () => '"sessionVersion" + 1',
    }).where('id = :userId', { userId }).execute();
  }

  async invalidateSession(userId: string): Promise<void> {
    await this.usersRepository.createQueryBuilder().update(User).set({
      refreshTokenHash: null,
      sessionVersion: () => '"sessionVersion" + 1',
    }).where('id = :userId', { userId }).execute();
  }
}
