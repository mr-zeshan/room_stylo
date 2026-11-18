import {
  ArrayMaxSize,
  ArrayNotEmpty,
  IsArray,
  IsUUID,
} from 'class-validator';

export class SaveSelectedProductsDto {
  @IsArray()
  @ArrayNotEmpty()
  @ArrayMaxSize(50)
  @IsUUID('4', { each: true })
  productIds!: string[];
}
