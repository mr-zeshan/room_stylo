import {
  BadRequestException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';

import {
  InjectRepository,
} from '@nestjs/typeorm';

import {
  Repository,
} from 'typeorm';

import {
  Room,
  RoomStatus,
} from '../entities/room.entity.js';

import {
  RoomDesignSuggestion,
  RoomDesignSuggestionStatus,
} from '../entities/room-design-suggestion.entity.js';

import {
  InteriorAdvisorService,
} from './interior-advisor.service.js';

interface StartSuggestionResult {
  suggestion:
    RoomDesignSuggestion;

  shouldGenerate:
    boolean;

  cached:
    boolean;
}

@Injectable()
export class RoomDesignSuggestionsService {
  constructor(
    @InjectRepository(
      RoomDesignSuggestion,
    )
    private readonly suggestionsRepository:
      Repository<RoomDesignSuggestion>,

    @InjectRepository(
      Room,
    )
    private readonly roomsRepository:
      Repository<Room>,

    private readonly interiorAdvisorService:
      InteriorAdvisorService,
  ) {}

  async startSuggestions(
    roomId: string,
    userId: string,
    forceRegenerate = false,
  ): Promise<StartSuggestionResult> {
    const room =
      await this.roomsRepository.findOne({
        where: {
          id:
            roomId,

          userId,
        },
      });

    if (!room) {
      throw new NotFoundException(
        'Room not found',
      );
    }

    if (
      room.status !==
        RoomStatus.ANALYZED ||
      !room.analysis
    ) {
      throw new BadRequestException(
        'Room analysis must be completed before generating design suggestions',
      );
    }

    const latest =
      await this.suggestionsRepository.findOne({
        where: {
          roomId,
          userId,
        },

        order: {
          createdAt:
            'DESC',
        },
      });

    if (
      latest?.status ===
      RoomDesignSuggestionStatus.GENERATING
    ) {
      return {
        suggestion:
          latest,

        shouldGenerate:
          false,

        cached:
          false,
      };
    }

    if (
      !forceRegenerate &&
      latest?.status ===
        RoomDesignSuggestionStatus.COMPLETED &&
      latest.advice !== null
    ) {
      return {
        suggestion:
          latest,

        shouldGenerate:
          false,

        cached:
          true,
      };
    }

    const suggestion =
      this.suggestionsRepository.create({
        roomId,
        userId,

        status:
          RoomDesignSuggestionStatus.GENERATING,

        advice:
          null,

        error:
          null,

        completedAt:
          null,
      });

    const saved =
      await this.suggestionsRepository.save(
        suggestion,
      );

    return {
      suggestion:
        saved,

      shouldGenerate:
        true,

      cached:
        false,
    };
  }

  async generateSuggestion(
    suggestionId: string,
    userId: string,
  ): Promise<void> {
    const suggestion =
      await this.suggestionsRepository.findOne({
        where: {
          id:
            suggestionId,

          userId,
        },
      });

    if (!suggestion) {
      throw new NotFoundException(
        'Design suggestion request not found',
      );
    }

    const room =
      await this.roomsRepository.findOne({
        where: {
          id:
            suggestion.roomId,

          userId,
        },
      });

    if (!room) {
      throw new NotFoundException(
        'Room not found',
      );
    }

    if (!room.analysis) {
      suggestion.status =
        RoomDesignSuggestionStatus.FAILED;

      suggestion.advice =
        null;

      suggestion.error =
        'Room analysis is not available';

      suggestion.completedAt =
        null;

      await this.suggestionsRepository.save(
        suggestion,
      );

      throw new BadRequestException(
        'Room analysis is not available',
      );
    }

    try {
      const advice =
        await this.interiorAdvisorService
          .generate(
            room.analysis,
          );

      suggestion.status =
        RoomDesignSuggestionStatus.COMPLETED;

      suggestion.advice =
        advice;

      suggestion.error =
        null;

      suggestion.completedAt =
        new Date();

      await this.suggestionsRepository.save(
        suggestion,
      );
    } catch (error) {
      const message =
        error instanceof Error
          ? error.message
          : 'Unknown Interior Advisor error';

      suggestion.status =
        RoomDesignSuggestionStatus.FAILED;

      suggestion.advice =
        null;

      suggestion.error =
        message;

      suggestion.completedAt =
        null;

      await this.suggestionsRepository.save(
        suggestion,
      );

      throw error;
    }
  }

  async getLatestSuggestion(
    roomId: string,
    userId: string,
  ): Promise<RoomDesignSuggestion | null> {
    await this.ensureRoomOwnership(
      roomId,
      userId,
    );

    return this.suggestionsRepository.findOne({
      where: {
        roomId,
        userId,
      },

      order: {
        createdAt:
          'DESC',
      },
    });
  }

  async getSuggestionHistory(
    roomId: string,
    userId: string,
  ): Promise<RoomDesignSuggestion[]> {
    await this.ensureRoomOwnership(
      roomId,
      userId,
    );

    return this.suggestionsRepository.find({
      where: {
        roomId,
        userId,
      },

      order: {
        createdAt:
          'DESC',
      },

      take:
        20,
    });
  }

  private async ensureRoomOwnership(
    roomId: string,
    userId: string,
  ): Promise<void> {
    const room =
      await this.roomsRepository.findOne({
        where: {
          id:
            roomId,

          userId,
        },

        select: {
          id:
            true,
        },
      });

    if (!room) {
      throw new NotFoundException(
        'Room not found',
      );
    }
  }
}