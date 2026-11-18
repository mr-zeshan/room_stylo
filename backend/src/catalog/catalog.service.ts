import {
  BadRequestException,
  Injectable,
  NotFoundException,
  OnModuleInit,
} from '@nestjs/common';

import {
  InjectRepository,
} from '@nestjs/typeorm';

import {
  ILike,
  In,
  Repository,
} from 'typeorm';

import {
  CreateProductDto,
} from './dto/create-product.dto.js';

import {
  UpdateProductDto,
} from './dto/update-product.dto.js';

import {
  ProductCategory,
} from './entities/product-category.entity.js';

import {
  Product,
} from './entities/product.entity.js';

const DEFAULT_CATEGORIES = [
  { name: 'Sofa', slug: 'sofa', iconKey: 'sofa' },
  { name: 'Chairs', slug: 'chair', iconKey: 'chair' },
  { name: 'Coffee Table', slug: 'coffee-table', iconKey: 'coffee_table' },
  { name: 'Side Table', slug: 'side-table', iconKey: 'side_table' },
  { name: 'Carpet', slug: 'carpet', iconKey: 'carpet' },
  { name: 'Rug', slug: 'rug', iconKey: 'rug' },
  { name: 'Curtains', slug: 'curtains', iconKey: 'curtains' },
  { name: 'Wallpaper', slug: 'wallpaper', iconKey: 'wallpaper' },
  { name: 'Lamp', slug: 'lamp', iconKey: 'lamp' },
  { name: 'Floor Lamp', slug: 'floor-lamp', iconKey: 'floor_lamp' },
  { name: 'Table Lamp', slug: 'table-lamp', iconKey: 'table_lamp' },
  { name: 'Artificial Plant', slug: 'artificial-plant', iconKey: 'plant' },
  { name: 'Wall Art', slug: 'wall-art', iconKey: 'wall_art' },
  { name: 'Mirror', slug: 'mirror', iconKey: 'mirror' },
  { name: 'Cushions', slug: 'cushions', iconKey: 'cushions' },
  { name: 'Decoration Pieces', slug: 'decoration-pieces', iconKey: 'decor' },
] as const;

@Injectable()
export class CatalogService implements OnModuleInit {
  constructor(
    @InjectRepository(ProductCategory)
    private readonly categoryRepository: Repository<ProductCategory>,

    @InjectRepository(Product)
    private readonly productRepository: Repository<Product>,
  ) {}

  async onModuleInit(): Promise<void> {
    await this.seedDefaultCategories();
  }

  async getCategories(): Promise<ProductCategory[]> {
    return this.categoryRepository.find({
      where: {
        isActive: true,
      },
      order: {
        sortOrder: 'ASC',
        name: 'ASC',
      },
    });
  }

  async getProducts(
    categoryIds?: string,
    search?: string,
  ): Promise<Product[]> {
    const ids = this.parseCategoryIds(categoryIds);
    const normalizedSearch = search?.trim();

    if (normalizedSearch) {
      const baseWhere = ids.length > 0
        ? {
            categoryId: In(ids),
            isActive: true,
          }
        : {
            isActive: true,
          };

      return this.productRepository.find({
        where: [
          {
            ...baseWhere,
            name: ILike(`%${normalizedSearch}%`),
          },
          {
            ...baseWhere,
            material: ILike(`%${normalizedSearch}%`),
          },
          {
            ...baseWhere,
            style: ILike(`%${normalizedSearch}%`),
          },
        ],
        relations: {
          category: true,
        },
        order: {
          sortOrder: 'ASC',
          name: 'ASC',
        },
      });
    }

    return this.productRepository.find({
      where:
        ids.length > 0
          ? {
              categoryId: In(ids),
              isActive: true,
            }
          : {
              isActive: true,
            },
      relations: {
        category: true,
      },
      order: {
        sortOrder: 'ASC',
        name: 'ASC',
      },
    });
  }

  async getProduct(productId: string): Promise<Product> {
    const product = await this.productRepository.findOne({
      where: {
        id: productId,
        isActive: true,
      },
      relations: {
        category: true,
      },
    });

    if (!product) {
      throw new NotFoundException('Product not found.');
    }

    return product;
  }

  async createProduct(dto: CreateProductDto): Promise<Product> {
    await this.requireActiveCategory(dto.categoryId);
    this.validatePriceRange(dto.priceMin, dto.priceMax);

    const product = this.productRepository.create({
      categoryId: dto.categoryId,
      name: this.requiredText(dto.name, 'Product name'),
      images: this.cleanImages(dto.images),
      color: this.optionalText(dto.color),
      style: this.optionalText(dto.style),
      widthCm: this.decimal(dto.widthCm),
      heightCm: this.decimal(dto.heightCm),
      depthCm: this.decimal(dto.depthCm),
      priceMin: this.decimal(dto.priceMin),
      priceMax: this.decimal(dto.priceMax),
      material: this.optionalText(dto.material),
      description: this.optionalText(dto.description),
      availability: dto.availability,
      isActive: dto.isActive ?? true,
      sortOrder: dto.sortOrder ?? 0,
    });

    const saved = await this.productRepository.save(product);
    return this.getProductIncludingInactive(saved.id);
  }

  async updateProduct(
    productId: string,
    dto: UpdateProductDto,
  ): Promise<Product> {
    const product = await this.getProductIncludingInactive(productId);

    if (dto.categoryId !== undefined) {
      await this.requireActiveCategory(dto.categoryId);
      product.categoryId = dto.categoryId;
    }

    if (dto.name !== undefined) {
      product.name = this.requiredText(dto.name, 'Product name');
    }

    if (dto.images !== undefined) {
      product.images = this.cleanImages(dto.images);
    }

    if (dto.color !== undefined) {
      product.color = this.optionalText(dto.color);
    }

    if (dto.style !== undefined) {
      product.style = this.optionalText(dto.style);
    }

    if (dto.widthCm !== undefined) {
      product.widthCm = this.decimal(dto.widthCm);
    }

    if (dto.heightCm !== undefined) {
      product.heightCm = this.decimal(dto.heightCm);
    }

    if (dto.depthCm !== undefined) {
      product.depthCm = this.decimal(dto.depthCm);
    }

    if (dto.priceMin !== undefined) {
      product.priceMin = this.decimal(dto.priceMin);
    }

    if (dto.priceMax !== undefined) {
      product.priceMax = this.decimal(dto.priceMax);
    }

    const nextPriceMin = dto.priceMin ?? this.numberOrUndefined(product.priceMin);
    const nextPriceMax = dto.priceMax ?? this.numberOrUndefined(product.priceMax);
    this.validatePriceRange(nextPriceMin, nextPriceMax);

    if (dto.material !== undefined) {
      product.material = this.optionalText(dto.material);
    }

    if (dto.description !== undefined) {
      product.description = this.optionalText(dto.description);
    }

    if (dto.availability !== undefined) {
      product.availability = dto.availability;
    }

    if (dto.isActive !== undefined) {
      product.isActive = dto.isActive;
    }

    if (dto.sortOrder !== undefined) {
      product.sortOrder = dto.sortOrder;
    }

    await this.productRepository.save(product);
    return this.getProductIncludingInactive(product.id);
  }

  async deactivateProduct(productId: string): Promise<{
    id: string;
    isActive: boolean;
    message: string;
  }> {
    const product = await this.getProductIncludingInactive(productId);

    product.isActive = false;
    await this.productRepository.save(product);

    return {
      id: product.id,
      isActive: false,
      message: 'Product deactivated.',
    };
  }

  private async getProductIncludingInactive(
    productId: string,
  ): Promise<Product> {
    const product = await this.productRepository.findOne({
      where: {
        id: productId,
      },
      relations: {
        category: true,
      },
    });

    if (!product) {
      throw new NotFoundException('Product not found.');
    }

    return product;
  }

  private async requireActiveCategory(
    categoryId: string,
  ): Promise<ProductCategory> {
    const category = await this.categoryRepository.findOne({
      where: {
        id: categoryId,
        isActive: true,
      },
    });

    if (!category) {
      throw new BadRequestException(
        'Selected product category does not exist or is inactive.',
      );
    }

    return category;
  }

  private validatePriceRange(
    priceMin?: number,
    priceMax?: number,
  ): void {
    if (
      priceMin !== undefined &&
      priceMax !== undefined &&
      priceMax < priceMin
    ) {
      throw new BadRequestException(
        'priceMax must be greater than or equal to priceMin.',
      );
    }
  }

  private requiredText(value: string, label: string): string {
    const cleaned = value.trim();

    if (!cleaned) {
      throw new BadRequestException(`${label} cannot be empty.`);
    }

    return cleaned;
  }

  private optionalText(value?: string): string | null {
    if (value === undefined) {
      return null;
    }

    const cleaned = value.trim();
    return cleaned.length > 0 ? cleaned : null;
  }

  private cleanImages(images?: string[]): string[] {
    if (!images) {
      return [];
    }

    return [
      ...new Set(
        images
          .map((image) => image.trim())
          .filter((image) => image.length > 0),
      ),
    ];
  }

  private decimal(value?: number): string | null {
    return value === undefined ? null : value.toFixed(2);
  }

  private numberOrUndefined(
    value: string | null,
  ): number | undefined {
    if (value === null) {
      return undefined;
    }

    const parsed = Number(value);
    return Number.isFinite(parsed) ? parsed : undefined;
  }

  private parseCategoryIds(value?: string): string[] {
    if (!value) {
      return [];
    }

    return [
      ...new Set(
        value
          .split(',')
          .map((item) => item.trim())
          .filter((item) => item.length > 0),
      ),
    ];
  }

  private async seedDefaultCategories(): Promise<void> {
    const existing = await this.categoryRepository.find({
      select: {
        slug: true,
      },
    });

    const existingSlugs = new Set(
      existing.map((category) => category.slug),
    );

    const missing = DEFAULT_CATEGORIES
      .filter((category) => !existingSlugs.has(category.slug))
      .map((category, index) =>
        this.categoryRepository.create({
          name: category.name,
          slug: category.slug,
          iconKey: category.iconKey,
          description: null,
          imageUrl: null,
          isActive: true,
          sortOrder: index + 1,
        }),
      );

    if (missing.length > 0) {
      await this.categoryRepository.save(missing);
    }
  }
}
