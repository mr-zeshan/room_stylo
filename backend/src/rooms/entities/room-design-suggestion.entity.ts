import {
  Column,
  CreateDateColumn,
  Entity,
  JoinColumn,
  ManyToOne,
  PrimaryGeneratedColumn,
  UpdateDateColumn,
} from 'typeorm';

import {
  InteriorAdvisorResult,
} from '../advisor/interior-advisor.provider.js';

import {
  Room,
} from './room.entity.js';

export enum RoomDesignSuggestionStatus {
  GENERATING = 'generating',
  COMPLETED = 'completed',
  FAILED = 'failed',
}

@Entity('room_design_suggestions')
export class RoomDesignSuggestion {
  @PrimaryGeneratedColumn('uuid')
  id!: string;

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
  room!: Room;

  @Column({
    type: 'uuid',
  })
  roomId!: string;

  @Column({
    type: 'uuid',
  })
  userId!: string;

  @Column({
    type: 'enum',
    enum: RoomDesignSuggestionStatus,
    default:
      RoomDesignSuggestionStatus.GENERATING,
  })
  status!: RoomDesignSuggestionStatus;

  @Column({
    type: 'jsonb',
    nullable: true,
  })
  advice!: InteriorAdvisorResult | null;

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