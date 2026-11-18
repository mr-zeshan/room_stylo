import {
  Column,
  CreateDateColumn,
  Entity,
  Index,
  JoinColumn,
  ManyToOne,
  PrimaryGeneratedColumn,
  UpdateDateColumn,
} from 'typeorm';

import type {
  Relation,
} from 'typeorm';

import {
  Product,
} from '../../catalog/entities/product.entity.js';

import {
  Room,
} from './room.entity.js';

@Entity('room_product_selections')
@Index(['roomId', 'productId'], {
  unique: true,
})
export class RoomProductSelection {
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
  productId!: string;

  @ManyToOne(
    () => Product,
    {
      nullable: false,
      onDelete: 'RESTRICT',
    },
  )
  @JoinColumn({
    name: 'productId',
  })
  product!: Relation<Product>;

  @Column({
    type: 'uuid',
  })
  userId!: string;

  @CreateDateColumn()
  createdAt!: Date;

  @UpdateDateColumn()
  updatedAt!: Date;
}
