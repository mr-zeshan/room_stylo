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

import type { Relation } from 'typeorm';
import { ProductCategory } from './product-category.entity.js';

export enum ProductAvailability {
  COMMON = 'COMMON',
  MODERATE = 'MODERATE',
  SPECIAL_ORDER = 'SPECIAL_ORDER',
}

@Entity('products')
@Index(['categoryId', 'isActive'])
export class Product {
  @PrimaryGeneratedColumn('uuid')
  id!: string;

  @Column({
    type: 'uuid',
  })
  categoryId!: string;

  @ManyToOne(
    () => ProductCategory,
    (category) => category.products,
    {
      onDelete: 'RESTRICT',
    },
  )
  @JoinColumn({
    name: 'categoryId',
  })
  category!: Relation<ProductCategory>;

  @Column({
    type: 'varchar',
    length: 180,
  })
  name!: string;

  @Column({
    type: 'text',
    array: true,
    default: () => "'{}'",
  })
  images!: string[];

  @Column({
    type: 'varchar',
    length: 100,
    nullable: true,
  })
  color!: string | null;

  @Column({
    type: 'varchar',
    length: 100,
    nullable: true,
  })
  style!: string | null;

  @Column({
    type: 'decimal',
    precision: 10,
    scale: 2,
    nullable: true,
  })
  widthCm!: string | null;

  @Column({
    type: 'decimal',
    precision: 10,
    scale: 2,
    nullable: true,
  })
  heightCm!: string | null;

  @Column({
    type: 'decimal',
    precision: 10,
    scale: 2,
    nullable: true,
  })
  depthCm!: string | null;

  @Column({
    type: 'decimal',
    precision: 12,
    scale: 2,
    nullable: true,
  })
  priceMin!: string | null;

  @Column({
    type: 'decimal',
    precision: 12,
    scale: 2,
    nullable: true,
  })
  priceMax!: string | null;

  @Column({
    type: 'varchar',
    length: 140,
    nullable: true,
  })
  material!: string | null;

  @Column({
    type: 'text',
    nullable: true,
  })
  description!: string | null;

  @Column({
    type: 'enum',
    enum: ProductAvailability,
    default: ProductAvailability.COMMON,
  })
  availability!: ProductAvailability;

  @Column({
    type: 'boolean',
    default: true,
  })
  isActive!: boolean;

  @Column({
    type: 'integer',
    default: 0,
  })
  sortOrder!: number;

  @CreateDateColumn()
  createdAt!: Date;

  @UpdateDateColumn()
  updatedAt!: Date;
}
