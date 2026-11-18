import {
  Column,
  CreateDateColumn,
  Entity,
  JoinColumn,
  ManyToOne,
  PrimaryGeneratedColumn,
  UpdateDateColumn,
} from 'typeorm';

import { User } from '../../users/entities/user.entity.js';

export enum RoomStatus {
  UPLOADED = 'uploaded',
  ANALYZING = 'analyzing',
  ANALYZED = 'analyzed',
  FAILED = 'failed',
}

@Entity('rooms')
export class Room {
  @PrimaryGeneratedColumn('uuid')
  id!: string;

  @ManyToOne(() => User, {
    nullable: false,
    onDelete: 'CASCADE',
  })
  @JoinColumn({
    name: 'userId',
  })
  user!: User;

  @Column({
    type: 'uuid',
  })
  userId!: string;

  @Column({
    type: 'text',
  })
  originalImagePath!: string;

  @Column({
    type: 'varchar',
    length: 100,
  })
  mimeType!: string;

  @Column({
    type: 'bigint',
  })
  fileSize!: string;

  @Column({
    type: 'int',
    nullable: true,
  })
  imageWidth!: number | null;

  @Column({
    type: 'int',
    nullable: true,
  })
  imageHeight!: number | null;

  @Column({
    type: 'enum',
    enum: RoomStatus,
    default: RoomStatus.UPLOADED,
  })
  status!: RoomStatus;

  @Column({
    type: 'jsonb',
    nullable: true,
  })
  analysis!: {
    roomType: string;
    walls: string[];
    floor: string;
    windows: string[];
    doors: string[];
    furniture: string[];
    colors: string[];
    lighting: string[];
    usableAreas: string[];
    observations: string[];
  } | null;

  @Column({
    type: 'text',
    nullable: true,
  })
  analysisError!: string | null;

  @Column({
    type: 'timestamptz',
    nullable: true,
  })
  analyzedAt!: Date | null;

  @CreateDateColumn()
  createdAt!: Date;

  @UpdateDateColumn()
  updatedAt!: Date;
}