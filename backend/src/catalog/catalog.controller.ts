import {
  Body,
  Controller,
  Delete,
  Get,
  Param,
  ParseUUIDPipe,
  Patch,
  Post,
  Query,
  UseGuards,
} from '@nestjs/common';

import {
  JwtAuthGuard,
} from '../auth/guards/jwt-auth.guard.js';

import {
  CatalogService,
} from './catalog.service.js';

import {
  CreateProductDto,
} from './dto/create-product.dto.js';

import {
  ProductQueryDto,
} from './dto/product-query.dto.js';

import {
  UpdateProductDto,
} from './dto/update-product.dto.js';

@Controller('catalog')
@UseGuards(JwtAuthGuard)
export class CatalogController {
  constructor(
    private readonly catalogService: CatalogService,
  ) {}

  @Get('categories')
  getCategories() {
    return this.catalogService.getCategories();
  }

  @Get('products')
  getProducts(
    @Query() query: ProductQueryDto,
  ) {
    return this.catalogService.getProducts(
      query.categoryIds,
      query.search,
    );
  }

  @Get('products/:productId')
  getProduct(
    @Param('productId', ParseUUIDPipe) productId: string,
  ) {
    return this.catalogService.getProduct(productId);
  }

  @Post('products')
  createProduct(
    @Body() dto: CreateProductDto,
  ) {
    return this.catalogService.createProduct(dto);
  }

  @Patch('products/:productId')
  updateProduct(
    @Param('productId', ParseUUIDPipe) productId: string,
    @Body() dto: UpdateProductDto,
  ) {
    return this.catalogService.updateProduct(
      productId,
      dto,
    );
  }

  @Delete('products/:productId')
  deactivateProduct(
    @Param('productId', ParseUUIDPipe) productId: string,
  ) {
    return this.catalogService.deactivateProduct(productId);
  }
}
