export interface InteriorCategoryRecommendation {
  category: string;
  reason: string;
  priority: 'high' | 'medium' | 'low';
  suggestedCharacteristics: string[];
}

export interface InteriorAdvisorResult {
  designDirection: string;
  recommendedStyle: string;
  styleReason: string;

  colorPalette: string[];

  categoryRecommendations:
    InteriorCategoryRecommendation[];

  layoutSuggestions: string[];

  keepItems: string[];

  improveItems: string[];

  notes: string[];
}

export interface RoomAnalysisInput {
  roomType: string;
  walls: string[];
  floor: string;
  windows: string[];
  doors: string[];
  furniture: string[];
  colors: string[];
  lighting: string[];
  usableAreas: string[];
  observations: string[];
}

export abstract class InteriorAdvisorProvider {
  abstract generateSuggestions(
    analysis: RoomAnalysisInput,
  ): Promise<InteriorAdvisorResult>;
}