import {
  Column,
  CreateDateColumn,
  Entity,
  JoinColumn,
  ManyToOne,
  PrimaryGeneratedColumn,
  UpdateDateColumn,
} from 'typeorm';

import type {
  Relation,
} from 'typeorm';

import {
  Room,
} from './room.entity.js';

export enum RoomPlacementPlanStatus {
  PENDING = 'pending',
  COMPLETED = 'completed',
  FAILED = 'failed',
}

export interface PlacementPlanItem {
  productId: string;
  productName: string;
  category: string;
  placement: string;
  orientation: string;
  scaleGuidance: string;
  reason: string;
}

export interface PlacementPlanResult {
  summary: string;
  items: PlacementPlanItem[];
  circulationNotes: string[];
  lightingNotes: string[];
  warnings: string[];
}

@Entity('room_placement_plans')
export class RoomPlacementPlan {
  @PrimaryGeneratedColumn('uuid')
  id!: string;

  @Column({
    type: 'uuid',
  })
  roomId!: string;

  @ManyToOne(
    () => Room,
    {
      nullable: false,
      onDelete: 'CASCADE',
    },
  )
  @JoinColumn({
    name: 'roomId',
  })
  room!: Relation<Room>;

  @Column({
    type: 'uuid',
  })
  userId!: string;

  @Column({
    type: 'enum',
    enum: RoomPlacementPlanStatus,
    default: RoomPlacementPlanStatus.PENDING,
  })
  status!: RoomPlacementPlanStatus;

  @Column({
    type: 'jsonb',
    nullable: true,
  })
  plan!: PlacementPlanResult | null;

  @Column({
    type: 'text',
    nullable: true,
  })
  error!: string | null;

  @Column({
    type: 'timestamptz',
    nullable: true,
  })
  completedAt!: Date | null;

  @CreateDateColumn()
  createdAt!: Date;

  @UpdateDateColumn()
  updatedAt!: Date;
}
