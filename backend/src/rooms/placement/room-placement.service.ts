import {
  BadRequestException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';

import {
  InjectRepository,
} from '@nestjs/typeorm';

import {
  In,
  Repository,
} from 'typeorm';

import {
  Product,
} from '../../catalog/entities/product.entity.js';

import {
  SaveSelectedProductsDto,
} from '../dto/save-selected-products.dto.js';

import {
  RoomPlacementPlan,
  PlacementPlanResult,
  RoomPlacementPlanStatus,
} from '../entities/room-placement-plan.entity.js';

import {
  RoomProductSelection,
} from '../entities/room-product-selection.entity.js';

import {
  Room,
  RoomStatus,
} from '../entities/room.entity.js';

@Injectable()
export class RoomPlacementService {
  constructor(
    @InjectRepository(Room)
    private readonly roomRepository: Repository<Room>,

    @InjectRepository(Product)
    private readonly productRepository: Repository<Product>,

    @InjectRepository(RoomProductSelection)
    private readonly selectionRepository: Repository<RoomProductSelection>,

    @InjectRepository(RoomPlacementPlan)
    private readonly placementRepository: Repository<RoomPlacementPlan>,
  ) {}

  async saveSelectedProducts(
    roomId: string,
    userId: string,
    dto: SaveSelectedProductsDto,
  ) {
    const room = await this.requireAnalyzedRoom(roomId, userId);

    const productIds = [
      ...new Set(dto.productIds),
    ];

    const products = await this.productRepository.find({
      where: {
        id: In(productIds),
        isActive: true,
      },
      relations: {
        category: true,
      },
    });

    if (products.length !== productIds.length) {
      throw new BadRequestException(
        'One or more selected products do not exist or are inactive.',
      );
    }

    await this.selectionRepository.delete({
      roomId,
      userId,
    });

    const selections = products.map((product) =>
      this.selectionRepository.create({
        roomId: room.id,
        userId,
        productId: product.id,
      }),
    );

    await this.selectionRepository.save(selections);

    return this.getSelectedProducts(roomId, userId);
  }

  async getSelectedProducts(
    roomId: string,
    userId: string,
  ) {
    await this.requireOwnedRoom(roomId, userId);

    const selections = await this.selectionRepository.find({
      where: {
        roomId,
        userId,
      },
      relations: {
        product: {
          category: true,
        },
      },
      order: {
        createdAt: 'ASC',
      },
    });

    return selections.map((selection) => selection.product);
  }

  async generatePlacementPlan(
    roomId: string,
    userId: string,
  ): Promise<RoomPlacementPlan> {
    const room = await this.requireAnalyzedRoom(roomId, userId);
    const products = await this.getSelectedProducts(roomId, userId);

    if (products.length === 0) {
      throw new BadRequestException(
        'Select at least one product before generating a placement plan.',
      );
    }

    const latest = await this.placementRepository.findOne({
      where: {
        roomId,
        userId,
      },
      order: {
        createdAt: 'DESC',
      },
    });

    if (
      latest?.status === RoomPlacementPlanStatus.COMPLETED &&
      latest.plan
    ) {
      return latest;
    }

    const placement = this.placementRepository.create({
      roomId,
      userId,
      status: RoomPlacementPlanStatus.PENDING,
      plan: null,
      error: null,
      completedAt: null,
    });

    const saved = await this.placementRepository.save(placement);

    try {
      const plan = this.buildFoundationPlan(room, products);

      saved.status = RoomPlacementPlanStatus.COMPLETED;
      saved.plan = plan;
      saved.error = null;
      saved.completedAt = new Date();

      return await this.placementRepository.save(saved);
    } catch (error) {
      saved.status = RoomPlacementPlanStatus.FAILED;
      saved.plan = null;
      saved.error =
        error instanceof Error
          ? error.message
          : 'Unable to generate placement plan.';
      saved.completedAt = null;

      await this.placementRepository.save(saved);
      throw error;
    }
  }

  async regeneratePlacementPlan(
    roomId: string,
    userId: string,
  ): Promise<RoomPlacementPlan> {
    await this.requireAnalyzedRoom(roomId, userId);

    await this.placementRepository.delete({
      roomId,
      userId,
    });

    return this.generatePlacementPlan(roomId, userId);
  }

  async getLatestPlacementPlan(
    roomId: string,
    userId: string,
  ): Promise<RoomPlacementPlan | null> {
    await this.requireOwnedRoom(roomId, userId);

    return this.placementRepository.findOne({
      where: {
        roomId,
        userId,
      },
      order: {
        createdAt: 'DESC',
      },
    });
  }

  private buildFoundationPlan(
    room: Room,
    products: Product[],
  ): PlacementPlanResult {
    const analysis = room.analysis;

    if (!analysis) {
      throw new BadRequestException(
        'Room analysis is required before placement planning.',
      );
    }

    const usableAreas = analysis.usableAreas.length > 0
      ? analysis.usableAreas
      : ['the clearest usable area identified in the room'];

    const items = products.map((product, index) => {
      const category =
        product.category?.name ?? 'Product';

      const placement =
        usableAreas[index % usableAreas.length];

      const dimensions = [
        product.widthCm ? `W ${product.widthCm} cm` : null,
        product.heightCm ? `H ${product.heightCm} cm` : null,
        product.depthCm ? `D ${product.depthCm} cm` : null,
      ]
        .filter((value): value is string => value !== null)
        .join(' × ');

      return {
        productId: product.id,
        productName: product.name,
        category,
        placement,
        orientation:
          'Align with the dominant room geometry and keep doors/windows unobstructed.',
        scaleGuidance: dimensions.length > 0
          ? `Use catalog dimensions: ${dimensions}. Confirm visual scale before final rendering.`
          : 'Catalog dimensions are incomplete; final scale must be confirmed before rendering.',
        reason:
          `Selected ${category.toLowerCase()} should use an analyzed usable area without changing the room structure.`,
      };
    });

    return {
      summary:
        `Foundation placement plan for ${analysis.roomType}. It preserves walls, doors, windows, floor and ceiling geometry and uses the selected catalog products.`,
      items,
      circulationNotes: [
        'Keep primary walking paths clear.',
        'Do not block doors, windows or access points.',
        'Maintain practical spacing between furniture pieces.',
      ],
      lightingNotes: analysis.lighting.length > 0
        ? [
            ...analysis.lighting.map(
              (item) =>
                `Respect detected lighting condition: ${item}`,
            ),
          ]
        : [
            'Match product lighting and shadows to the original room image.',
          ],
      warnings: [
        'This is the placement-engine foundation. Exact coordinates, depth and occlusion will be refined by the visual placement stage.',
        'Do not alter structural room geometry unless the user explicitly requests a structural change.',
      ],
    };
  }

  private async requireOwnedRoom(
    roomId: string,
    userId: string,
  ): Promise<Room> {
    const room = await this.roomRepository.findOne({
      where: {
        id: roomId,
        userId,
      },
    });

    if (!room) {
      throw new NotFoundException('Room not found.');
    }

    return room;
  }

  private async requireAnalyzedRoom(
    roomId: string,
    userId: string,
  ): Promise<Room> {
    const room = await this.requireOwnedRoom(roomId, userId);

    if (
      room.status !== RoomStatus.ANALYZED ||
      !room.analysis
    ) {
      throw new BadRequestException(
        'Room analysis must be completed first.',
      );
    }

    return room;
  }
}
