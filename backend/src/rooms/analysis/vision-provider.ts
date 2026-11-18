export interface RoomVisionAnalysis {
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

export abstract class VisionProvider {
  abstract analyzeRoom(
    imagePath: string,
  ): Promise<RoomVisionAnalysis>;
}