import {
  Controller,
  Get,
  Param,
  ParseUUIDPipe,
  Post,
  Req,
  UseGuards,
} from '@nestjs/common';

import {
  JwtAuthGuard,
} from '../../auth/guards/jwt-auth.guard.js';

import {
  RoomDesignSuggestionsService,
} from './room-design-suggestions.service.js';

@Controller('rooms')
export class RoomDesignSuggestionsController {
  constructor(
    private readonly suggestionsService:
      RoomDesignSuggestionsService,
  ) {}

  @UseGuards(
    JwtAuthGuard,
  )
  @Post(
    ':roomId/suggestions/start',
  )
  async startSuggestions(
    @Req()
    req: any,

    @Param(
      'roomId',
      ParseUUIDPipe,
    )
    roomId: string,
  ) {
    const result =
      await this.suggestionsService
        .startSuggestions(
          roomId,
          req.user.userId,
          false,
        );

    if (
      result.shouldGenerate
    ) {
      void this.suggestionsService
        .generateSuggestion(
          result.suggestion.id,
          req.user.userId,
        )
        .catch(
          (
            error: unknown,
          ) => {
            const message =
              error instanceof Error
                ? error.message
                : String(
                    error,
                  );

            console.error(
              `[RoomDesignSuggestionsController] Background suggestion generation failed for suggestion ${result.suggestion.id}: ${message}`,
            );
          },
        );
    }

    return {
      message:
        result.cached
          ? 'Design suggestions already available'
          : result.shouldGenerate
            ? 'Design suggestions started'
            : 'Design suggestions already in progress',

      roomId,

      suggestionId:
        result.suggestion.id,

      status:
        result.suggestion.status,

      advice:
        result.suggestion.advice,

      error:
        result.suggestion.error,

      completedAt:
        result.suggestion.completedAt,

      cached:
        result.cached,
    };
  }

  @UseGuards(
    JwtAuthGuard,
  )
  @Get(
    ':roomId/suggestions',
  )
  async getSuggestions(
    @Req()
    req: any,

    @Param(
      'roomId',
      ParseUUIDPipe,
    )
    roomId: string,
  ) {
    const suggestion =
      await this.suggestionsService
        .getLatestSuggestion(
          roomId,
          req.user.userId,
        );

    if (!suggestion) {
      return {
        roomId,

        status:
          'not_started',

        suggestionId:
          null,

        advice:
          null,

        error:
          null,

        completedAt:
          null,
      };
    }

    return {
      roomId,

      suggestionId:
        suggestion.id,

      status:
        suggestion.status,

      advice:
        suggestion.advice,

      error:
        suggestion.error,

      completedAt:
        suggestion.completedAt,

      createdAt:
        suggestion.createdAt,
    };
  }

  @UseGuards(
    JwtAuthGuard,
  )
  @Post(
    ':roomId/suggestions/regenerate',
  )
  async regenerateSuggestions(
    @Req()
    req: any,

    @Param(
      'roomId',
      ParseUUIDPipe,
    )
    roomId: string,
  ) {
    const result =
      await this.suggestionsService
        .startSuggestions(
          roomId,
          req.user.userId,
          true,
        );

    if (
      result.shouldGenerate
    ) {
      void this.suggestionsService
        .generateSuggestion(
          result.suggestion.id,
          req.user.userId,
        )
        .catch(
          (
            error: unknown,
          ) => {
            const message =
              error instanceof Error
                ? error.message
                : String(
                    error,
                  );

            console.error(
              `[RoomDesignSuggestionsController] Background suggestion regeneration failed for suggestion ${result.suggestion.id}: ${message}`,
            );
          },
        );
    }

    return {
      message:
        result.shouldGenerate
          ? 'Design suggestion regeneration started'
          : 'Design suggestions already in progress',

      roomId,

      suggestionId:
        result.suggestion.id,

      status:
        result.suggestion.status,

      advice:
        result.suggestion.advice,

      error:
        result.suggestion.error,

      completedAt:
        result.suggestion.completedAt,

      cached:
        false,
    };
  }

  @UseGuards(
    JwtAuthGuard,
  )
  @Get(
    ':roomId/suggestions/history',
  )
  async getSuggestionHistory(
    @Req()
    req: any,

    @Param(
      'roomId',
      ParseUUIDPipe,
    )
    roomId: string,
  ) {
    const history =
      await this.suggestionsService
        .getSuggestionHistory(
          roomId,
          req.user.userId,
        );

    return {
      roomId,

      total:
        history.length,

      suggestions:
        history.map(
          (
            suggestion,
          ) => ({
            suggestionId:
              suggestion.id,

            status:
              suggestion.status,

            advice:
              suggestion.advice,

            error:
              suggestion.error,

            completedAt:
              suggestion.completedAt,

            createdAt:
              suggestion.createdAt,
          }),
        ),
    };
  }
}