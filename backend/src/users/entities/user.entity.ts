import {
  Column,
  CreateDateColumn,
  Entity,
  PrimaryGeneratedColumn,
  UpdateDateColumn,
} from 'typeorm';

export enum UserRole {
  USER = 'user',
  ADMIN = 'admin',
}

@Entity('users')
export class User {
  @PrimaryGeneratedColumn('uuid')
  id!: string;

  @Column({ length: 100 })
  name!: string;

  @Column({
    unique: true,
    length: 255,
  })
  email!: string;

  @Column({
  type: 'text',
  nullable: true,
  select: false,
})
passwordHash!: string | null;

  @Column({
    type: 'text',
    nullable: true,
    unique: true,
    select: false,
  })
  googleId!: string | null;

  @Column({
    type: 'text',
    nullable: true,
    select: false,
  })
  refreshTokenHash!: string | null;

  @Column({
    type: 'text',
    nullable: true,
    select: false,
  })
  passwordResetOtpHash!: string | null;

  @Column({
    type: 'timestamptz',
    nullable: true,
    select: false,
  })
  passwordResetOtpExpiresAt!: Date | null;

  @Column({
    type: 'integer',
    default: 0,
    select: false,
  })
  passwordResetOtpAttempts!: number;

  @Column({
    type: 'timestamptz',
    nullable: true,
    select: false,
  })
  passwordResetOtpLastSentAt!: Date | null;

  @Column({
    type: 'text',
    nullable: true,
    select: false,
  })
  passwordResetNonce!: string | null;

  @Column({
    type: 'integer',
    default: 0,
  })
  sessionVersion!: number;

  @Column({
    type: 'enum',
    enum: UserRole,
    default: UserRole.USER,
  })
  role!: UserRole;

  @Column({
    default: true,
  })
  isActive!: boolean;

  @CreateDateColumn()
  createdAt!: Date;

  @UpdateDateColumn()
  updatedAt!: Date;
}