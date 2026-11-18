import {
  Module,
} from '@nestjs/common';

import {
  PassportModule,
} from '@nestjs/passport';

import {
  TypeOrmModule,
} from '@nestjs/typeorm';

import {
  AuthModule,
} from '../auth/auth.module.js';

import {
  CatalogController,
} from './catalog.controller.js';

import {
  CatalogService,
} from './catalog.service.js';

import {
  ProductCategory,
} from './entities/product-category.entity.js';

import {
  Product,
} from './entities/product.entity.js';

@Module({
  imports: [
    TypeOrmModule.forFeature([
      ProductCategory,
      Product,
    ]),

    PassportModule.register({
      defaultStrategy:
        'jwt',
    }),

    AuthModule,
  ],

  controllers: [
    CatalogController,
  ],

  providers: [
    CatalogService,
  ],

  exports: [
    CatalogService,
  ],
})
export class CatalogModule {}
