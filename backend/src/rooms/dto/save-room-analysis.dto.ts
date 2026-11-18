import {
  ArrayMaxSize,
  IsArray,
  IsString,
  MaxLength,
} from 'class-validator';

export class SaveRoomAnalysisDto {
  @IsString()
  @MaxLength(100)
  roomType!: string;

  @IsArray()
  @ArrayMaxSize(20)
  @IsString({
    each: true,
  })
  walls!: string[];

  @IsString()
  @MaxLength(500)
  floor!: string;

  @IsArray()
  @ArrayMaxSize(20)
  @IsString({
    each: true,
  })
  windows!: string[];

  @IsArray()
  @ArrayMaxSize(20)
  @IsString({
    each: true,
  })
  doors!: string[];

  @IsArray()
  @ArrayMaxSize(50)
  @IsString({
    each: true,
  })
  furniture!: string[];

  @IsArray()
  @ArrayMaxSize(20)
  @IsString({
    each: true,
  })
  colors!: string[];

  @IsArray()
  @ArrayMaxSize(20)
  @IsString({
    each: true,
  })
  lighting!: string[];

  @IsArray()
  @ArrayMaxSize(30)
  @IsString({
    each: true,
  })
  usableAreas!: string[];

  @IsArray()
  @ArrayMaxSize(30)
  @IsString({
    each: true,
  })
  observations!: string[];
}