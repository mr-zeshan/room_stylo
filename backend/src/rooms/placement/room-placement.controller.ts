import {
  Body,
  Controller,
  Get,
  Param,
  ParseUUIDPipe,
  Post,
  Put,
  Req,
  UseGuards,
} from '@nestjs/common';

import {
  JwtAuthGuard,
} from '../../auth/guards/jwt-auth.guard.js';

import {
  SaveSelectedProductsDto,
} from '../dto/save-selected-products.dto.js';

import {
  RoomPlacementService,
} from './room-placement.service.js';

interface AuthenticatedRequest {
  user: {
    userId: string;
  };
}

@Controller('rooms')
@UseGuards(JwtAuthGuard)
export class RoomPlacementController {
  constructor(
    private readonly roomPlacementService: RoomPlacementService,
  ) {}

  @Put(':roomId/selected-products')
  saveSelectedProducts(
    @Param('roomId', ParseUUIDPipe) roomId: string,
    @Req() request: AuthenticatedRequest,
    @Body() dto: SaveSelectedProductsDto,
  ) {
    return this.roomPlacementService.saveSelectedProducts(
      roomId,
      request.user.userId,
      dto,
    );
  }

  @Get(':roomId/selected-products')
  getSelectedProducts(
    @Param('roomId', ParseUUIDPipe) roomId: string,
    @Req() request: AuthenticatedRequest,
  ) {
    return this.roomPlacementService.getSelectedProducts(
      roomId,
      request.user.userId,
    );
  }

  @Post(':roomId/placement/start')
  generatePlacementPlan(
    @Param('roomId', ParseUUIDPipe) roomId: string,
    @Req() request: AuthenticatedRequest,
  ) {
    return this.roomPlacementService.generatePlacementPlan(
      roomId,
      request.user.userId,
    );
  }

  @Post(':roomId/placement/regenerate')
  regeneratePlacementPlan(
    @Param('roomId', ParseUUIDPipe) roomId: string,
    @Req() request: AuthenticatedRequest,
  ) {
    return this.roomPlacementService.regeneratePlacementPlan(
      roomId,
      request.user.userId,
    );
  }

  @Get(':roomId/placement')
  getLatestPlacementPlan(
    @Param('roomId', ParseUUIDPipe) roomId: string,
    @Req() request: AuthenticatedRequest,
  ) {
    return this.roomPlacementService.getLatestPlacementPlan(
      roomId,
      request.user.userId,
    );
  }
}
