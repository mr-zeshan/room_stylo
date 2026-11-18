import {
  IsOptional,
  IsString,
  MaxLength,
} from 'class-validator';

export class ProductQueryDto {
  @IsOptional()
  @IsString()
  @MaxLength(1000)
  categoryIds?: string;

  @IsOptional()
  @IsString()
  @MaxLength(500)
  search?: string;
}
