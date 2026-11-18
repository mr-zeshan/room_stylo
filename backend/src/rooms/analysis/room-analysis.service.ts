import {
  Injectable,
} from '@nestjs/common';

import {
  RoomVisionAnalysis,
  VisionProvider,
} from './vision-provider.js';

@Injectable()
export class RoomAnalysisService {
  constructor(
    private readonly visionProvider:
      VisionProvider,
  ) {}

  async analyze(
    imagePath: string,
  ): Promise<RoomVisionAnalysis> {
    return this.visionProvider
      .analyzeRoom(
        imagePath,
      );
  }
}