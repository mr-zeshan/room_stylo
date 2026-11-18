import {
  Injectable,
} from '@nestjs/common';

import {
  InteriorAdvisorProvider,
  InteriorAdvisorResult,
  RoomAnalysisInput,
} from './interior-advisor.provider.js';

@Injectable()
export class InteriorAdvisorService {
  constructor(
    private readonly advisorProvider:
      InteriorAdvisorProvider,
  ) {}

  async generate(
    analysis: RoomAnalysisInput,
  ): Promise<InteriorAdvisorResult> {
    return this.advisorProvider
      .generateSuggestions(
        analysis,
      );
  }
}