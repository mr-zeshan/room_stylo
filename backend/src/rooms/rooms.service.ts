import {
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
  RoomAnalysisService,
} from './analysis/room-analysis.service.js';

import {
  SaveRoomAnalysisDto,
} from './dto/save-room-analysis.dto.js';

import {
  Room,
  RoomStatus,
} from './entities/room.entity.js';

@Injectable()
export class RoomsService {
  constructor(
    @InjectRepository(Room)
    private readonly roomsRepository:
      Repository<Room>,

    private readonly roomAnalysisService:
      RoomAnalysisService,
  ) {}

  async createFromUpload(
    userId: string,
    file: Express.Multer.File,
  ): Promise<Room> {
    const room =
      this.roomsRepository.create({
        userId,

        originalImagePath:
          file.path.replace(
            /\\/g,
            '/',
          ),

        mimeType:
          file.mimetype,

        fileSize:
          file.size.toString(),

        imageWidth: null,
        imageHeight: null,

        status:
          RoomStatus.UPLOADED,

        analysis: null,
        analysisError: null,
        analyzedAt: null,
      });

    return this.roomsRepository.save(
      room,
    );
  }

  async findOwnedRoom(
    roomId: string,
    userId: string,
  ): Promise<Room> {
    const room =
      await this.roomsRepository.findOne({
        where: {
          id: roomId,
          userId,
        },
      });

    if (!room) {
      throw new NotFoundException(
        'Room not found',
      );
    }

    return room;
  }

  async getRoomAnalysis(
    roomId: string,
    userId: string,
  ): Promise<Room> {
    return this.findOwnedRoom(
      roomId,
      userId,
    );
  }

  async shouldStartAnalysis(
    roomId: string,
    userId: string,
  ): Promise<{
    room: Room;
    shouldStart: boolean;
  }> {
    const room =
      await this.findOwnedRoom(
        roomId,
        userId,
      );

    if (
      room.status ===
        RoomStatus.ANALYZED &&
      room.analysis !== null
    ) {
      return {
        room,
        shouldStart: false,
      };
    }

    if (
      room.status ===
      RoomStatus.ANALYZING
    ) {
      return {
        room,
        shouldStart: false,
      };
    }

    return {
      room,
      shouldStart: true,
    };
  }

  async markAnalyzing(
    roomId: string,
    userId: string,
  ): Promise<Room> {
    const room =
      await this.findOwnedRoom(
        roomId,
        userId,
      );

    room.status =
      RoomStatus.ANALYZING;

    room.analysis =
      null;

    room.analysisError =
      null;

    room.analyzedAt =
      null;

    return this.roomsRepository.save(
      room,
    );
  }

  async analyzeRoom(
    roomId: string,
    userId: string,
  ): Promise<Room> {
    const room =
      await this.markAnalyzing(
        roomId,
        userId,
      );

    try {
      const analysis =
        await this.roomAnalysisService
          .analyze(
            room.originalImagePath,
          );

      room.analysis = {
        roomType:
          analysis.roomType.trim(),

        walls:
          this.cleanStringArray(
            analysis.walls,
          ),

        floor:
          analysis.floor.trim(),

        windows:
          this.cleanStringArray(
            analysis.windows,
          ),

        doors:
          this.cleanStringArray(
            analysis.doors,
          ),

        furniture:
          this.cleanStringArray(
            analysis.furniture,
          ),

        colors:
          this.cleanStringArray(
            analysis.colors,
          ),

        lighting:
          this.cleanStringArray(
            analysis.lighting,
          ),

        usableAreas:
          this.cleanStringArray(
            analysis.usableAreas,
          ),

        observations:
          this.cleanStringArray(
            analysis.observations,
          ),
      };

      room.status =
        RoomStatus.ANALYZED;

      room.analysisError =
        null;

      room.analyzedAt =
        new Date();

      return await this.roomsRepository.save(
        room,
      );
    } catch (error) {
      const errorMessage =
        error instanceof Error
          ? error.message
          : 'Unknown room analysis error';

      room.status =
        RoomStatus.FAILED;

      room.analysis =
        null;

      room.analysisError =
        errorMessage;

      room.analyzedAt =
        null;

      await this.roomsRepository.save(
        room,
      );

      throw error;
    }
  }

  async saveAnalysis(
    roomId: string,
    userId: string,
    dto: SaveRoomAnalysisDto,
  ): Promise<Room> {
    const room =
      await this.findOwnedRoom(
        roomId,
        userId,
      );

    room.analysis = {
      roomType:
        dto.roomType.trim(),

      walls:
        this.cleanStringArray(
          dto.walls,
        ),

      floor:
        dto.floor.trim(),

      windows:
        this.cleanStringArray(
          dto.windows,
        ),

      doors:
        this.cleanStringArray(
          dto.doors,
        ),

      furniture:
        this.cleanStringArray(
          dto.furniture,
        ),

      colors:
        this.cleanStringArray(
          dto.colors,
        ),

      lighting:
        this.cleanStringArray(
          dto.lighting,
        ),

      usableAreas:
        this.cleanStringArray(
          dto.usableAreas,
        ),

      observations:
        this.cleanStringArray(
          dto.observations,
        ),
    };

    room.status =
      RoomStatus.ANALYZED;

    room.analysisError =
      null;

    room.analyzedAt =
      new Date();

    return this.roomsRepository.save(
      room,
    );
  }

  async markAnalysisFailed(
    roomId: string,
    userId: string,
    errorMessage: string,
  ): Promise<Room> {
    const room =
      await this.findOwnedRoom(
        roomId,
        userId,
      );

    room.status =
      RoomStatus.FAILED;

    room.analysis =
      null;

    room.analysisError =
      errorMessage.trim();

    room.analyzedAt =
      null;

    return this.roomsRepository.save(
      room,
    );
  }

  private cleanStringArray(
    values: string[],
  ): string[] {
    return values
      .map(
        (value) =>
          value.trim(),
      )
      .filter(
        (value) =>
          value.length > 0,
      );
  }
}