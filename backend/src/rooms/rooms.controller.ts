import {
  BadRequestException,
  Body,
  Controller,
  Get,
  Param,
  ParseUUIDPipe,
  Post,
  Req,
  UploadedFile,
  UseGuards,
  UseInterceptors,
} from '@nestjs/common';

import {
  FileInterceptor,
} from '@nestjs/platform-express';

import {
  randomUUID,
} from 'node:crypto';

import {
  mkdirSync,
} from 'node:fs';

import {
  extname,
  join,
} from 'node:path';

import {
  diskStorage,
} from 'multer';

import {
  JwtAuthGuard,
} from '../auth/guards/jwt-auth.guard.js';

import {
  SaveRoomAnalysisDto,
} from './dto/save-room-analysis.dto.js';

import {
  RoomsService,
} from './rooms.service.js';

const uploadDirectory =
  join(
    process.cwd(),
    'uploads',
    'rooms',
  );

mkdirSync(
  uploadDirectory,
  {
    recursive: true,
  },
);

const allowedMimeTypes =
  new Set([
    'image/jpeg',
    'image/png',
    'image/webp',
  ]);

@Controller('rooms')
export class RoomsController {
  constructor(
    private readonly roomsService:
      RoomsService,
  ) {}

  @UseGuards(
    JwtAuthGuard,
  )
  @Post('upload')
  @UseInterceptors(
    FileInterceptor(
      'image',
      {
        storage:
          diskStorage({
            destination:
              uploadDirectory,

            filename: (
              _req,
              file,
              callback,
            ) => {
              const extension =
                extname(
                  file.originalname,
                ).toLowerCase();

              const filename =
                `${randomUUID()}${extension}`;

              callback(
                null,
                filename,
              );
            },
          }),

        limits: {
          fileSize:
            10 *
            1024 *
            1024,

          files: 1,
        },

        fileFilter: (
          _req,
          file,
          callback,
        ) => {
          if (
            !allowedMimeTypes.has(
              file.mimetype,
            )
          ) {
            return callback(
              new BadRequestException(
                'Only JPG, JPEG, PNG and WebP images are allowed',
              ),
              false,
            );
          }

          callback(
            null,
            true,
          );
        },
      },
    ),
  )
  async uploadRoomImage(
    @Req()
    req: any,

    @UploadedFile()
    file?: Express.Multer.File,
  ) {
    if (!file) {
      throw new BadRequestException(
        'Room image is required',
      );
    }

    const room =
      await this.roomsService
        .createFromUpload(
          req.user.userId,
          file,
        );

    return {
      message:
        'Room image uploaded successfully',

      room: {
        id:
          room.id,

        originalImagePath:
          room.originalImagePath,

        mimeType:
          room.mimeType,

        fileSize:
          room.fileSize,

        status:
          room.status,

        createdAt:
          room.createdAt,
      },
    };
  }

  @UseGuards(
    JwtAuthGuard,
  )
  @Get(':roomId/analysis')
  async getAnalysis(
    @Req()
    req: any,

    @Param(
      'roomId',
      ParseUUIDPipe,
    )
    roomId: string,
  ) {
    const room =
      await this.roomsService
        .getRoomAnalysis(
          roomId,
          req.user.userId,
        );

    return {
      roomId:
        room.id,

      status:
        room.status,

      analysis:
        room.analysis,

      analysisError:
        room.analysisError,

      analyzedAt:
        room.analyzedAt,
    };
  }

  @UseGuards(
    JwtAuthGuard,
  )
  @Post(':roomId/analysis/start')
  async startAnalysis(
    @Req()
    req: any,

    @Param(
      'roomId',
      ParseUUIDPipe,
    )
    roomId: string,
  ) {
    const result =
      await this.roomsService
        .shouldStartAnalysis(
          roomId,
          req.user.userId,
        );

    if (
      result.room.status ===
        'analyzed' &&
      result.room.analysis !== null
    ) {
      return {
        message:
          'Room analysis already available',

        roomId:
          result.room.id,

        status:
          result.room.status,

        analysis:
          result.room.analysis,

        analyzedAt:
          result.room.analyzedAt,

        cached:
          true,
      };
    }

    if (
      result.room.status ===
      'analyzing'
    ) {
      return {
        message:
          'Room analysis already in progress',

        roomId:
          result.room.id,

        status:
          result.room.status,

        cached:
          false,
      };
    }

    void this.roomsService
      .analyzeRoom(
        roomId,
        req.user.userId,
      )
      .catch(
        (error: unknown) => {
          const message =
            error instanceof Error
              ? error.message
              : String(error);

          console.error(
            `[RoomsController] Background room analysis failed for room ${roomId}: ${message}`,
          );
        },
      );

    return {
      message:
        'Room analysis started',

      roomId,

      status:
        'analyzing',

      cached:
        false,
    };
  }

  @UseGuards(
    JwtAuthGuard,
  )
  @Post(':roomId/analysis/reanalyze')
  async reanalyzeRoom(
    @Req()
    req: any,

    @Param(
      'roomId',
      ParseUUIDPipe,
    )
    roomId: string,
  ) {
    const room =
      await this.roomsService
        .findOwnedRoom(
          roomId,
          req.user.userId,
        );

    if (
      room.status ===
      'analyzing'
    ) {
      return {
        message:
          'Room analysis already in progress',

        roomId:
          room.id,

        status:
          room.status,
      };
    }

    void this.roomsService
      .analyzeRoom(
        roomId,
        req.user.userId,
      )
      .catch(
        (error: unknown) => {
          const message =
            error instanceof Error
              ? error.message
              : String(error);

          console.error(
            `[RoomsController] Background room re-analysis failed for room ${roomId}: ${message}`,
          );
        },
      );

    return {
      message:
        'Room re-analysis started',

      roomId,

      status:
        'analyzing',
    };
  }

  @UseGuards(
    JwtAuthGuard,
  )
  @Post(':roomId/analysis/result')
  async saveAnalysisResult(
    @Req()
    req: any,

    @Param(
      'roomId',
      ParseUUIDPipe,
    )
    roomId: string,

    @Body()
    dto: SaveRoomAnalysisDto,
  ) {
    const room =
      await this.roomsService
        .saveAnalysis(
          roomId,
          req.user.userId,
          dto,
        );

    return {
      message:
        'Room analysis saved',

      roomId:
        room.id,

      status:
        room.status,

      analysis:
        room.analysis,

      analyzedAt:
        room.analyzedAt,
    };
  }
}