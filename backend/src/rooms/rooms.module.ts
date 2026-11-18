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
  Product,
} from '../catalog/entities/product.entity.js';

import {
  InteriorAdvisorProvider,
} from './advisor/interior-advisor.provider.js';

import {
  InteriorAdvisorService,
} from './advisor/interior-advisor.service.js';

import {
  OllamaInteriorAdvisorProvider,
} from './advisor/ollama-interior-advisor.provider.js';

import {
  RoomDesignSuggestionsController,
} from './advisor/room-design-suggestions.controller.js';

import {
  RoomDesignSuggestionsService,
} from './advisor/room-design-suggestions.service.js';

import {
  OllamaVisionProvider,
} from './analysis/ollama-vision.provider.js';

import {
  RoomAnalysisService,
} from './analysis/room-analysis.service.js';

import {
  VisionProvider,
} from './analysis/vision-provider.js';

import {
  RoomDesignSuggestion,
} from './entities/room-design-suggestion.entity.js';

import {
  RoomPlacementPlan,
} from './entities/room-placement-plan.entity.js';

import {
  RoomProductSelection,
} from './entities/room-product-selection.entity.js';

import {
  Room,
} from './entities/room.entity.js';

import {
  RoomPlacementController,
} from './placement/room-placement.controller.js';

import {
  RoomPlacementService,
} from './placement/room-placement.service.js';

import {
  RoomsController,
} from './rooms.controller.js';

import {
  RoomsService,
} from './rooms.service.js';

@Module({
  imports: [
    TypeOrmModule.forFeature([
      Room,
      RoomDesignSuggestion,
      Product,
      RoomProductSelection,
      RoomPlacementPlan,
    ]),

    PassportModule.register({
      defaultStrategy:
        'jwt',
    }),

    AuthModule,
  ],

  controllers: [
    RoomsController,
    RoomDesignSuggestionsController,
    RoomPlacementController,
  ],

  providers: [
    RoomsService,

    RoomAnalysisService,

    OllamaVisionProvider,

    {
      provide:
        VisionProvider,

      useExisting:
        OllamaVisionProvider,
    },

    InteriorAdvisorService,

    OllamaInteriorAdvisorProvider,

    {
      provide:
        InteriorAdvisorProvider,

      useExisting:
        OllamaInteriorAdvisorProvider,
    },

    RoomDesignSuggestionsService,
    RoomPlacementService,
  ],

  exports: [
    RoomsService,
    RoomAnalysisService,
    InteriorAdvisorService,
    RoomDesignSuggestionsService,
    RoomPlacementService,
  ],
})
export class RoomsModule {}