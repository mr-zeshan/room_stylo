import {
  BadGatewayException,
  Injectable,
} from '@nestjs/common';

import {
  request as httpRequest,
} from 'node:http';

import {
  request as httpsRequest,
} from 'node:https';

import {
  InteriorAdvisorProvider,
  InteriorAdvisorResult,
  RoomAnalysisInput,
} from './interior-advisor.provider.js';

interface OllamaGenerateResponse {
  response?: string;
  thinking?: string;
  done?: boolean;
  done_reason?: string;
  error?: string;
}

interface HttpResult {
  statusCode: number;
  body: string;
}

@Injectable()
export class OllamaInteriorAdvisorProvider
  implements InteriorAdvisorProvider
{
  private readonly ollamaUrl =
    process.env.OLLAMA_URL ??
    'http://127.0.0.1:11434';

  private readonly model =
    process.env.OLLAMA_ADVISOR_MODEL ??
    'qwen3:1.7b';

  // Advisor is text-only and should not be allowed
  // to run for 10+ minutes.
  private readonly inferenceTimeoutMs =
    3 * 60 * 1000;

  async generateSuggestions(
    analysis: RoomAnalysisInput,
  ): Promise<InteriorAdvisorResult> {
    try {
      const requestBody =
        JSON.stringify({
          model:
            this.model,

          prompt:
            this.buildPrompt(
              analysis,
            ),

          stream:
            false,

          // Critical for Qwen3 speed.
          think:
            false,

          // Forces JSON output.
          format:
            'json',

          keep_alive:
            '5m',

          options: {
            temperature:
              0.2,

            // Enough for our structured result,
            // but prevents runaway generation.
            num_predict:
              700,

            num_ctx:
              4096,
          },
        });

      console.log(
        `[OllamaInteriorAdvisorProvider] Starting interior suggestions with model ${this.model}`,
      );

      const startedAt =
        Date.now();

      const result =
        await this.postJson(
          `${this.ollamaUrl}/api/generate`,
          requestBody,
        );

      const durationSeconds =
        (
          Date.now() -
          startedAt
        ) /
        1000;

      console.log(
        `[OllamaInteriorAdvisorProvider] Ollama response received after ${durationSeconds.toFixed(
          1,
        )}s`,
      );

      if (
        result.statusCode < 200 ||
        result.statusCode >= 300
      ) {
        throw new Error(
          `Ollama returned HTTP ${result.statusCode}: ${result.body.slice(
            0,
            1000,
          )}`,
        );
      }

      if (
        result.body.trim()
          .length === 0
      ) {
        throw new Error(
          'Ollama returned an empty HTTP response',
        );
      }

      let ollamaResult:
        OllamaGenerateResponse;

      try {
        ollamaResult =
          JSON.parse(
            result.body,
          ) as OllamaGenerateResponse;
      } catch {
        throw new Error(
          `Ollama returned invalid response JSON: ${result.body.slice(
            0,
            500,
          )}`,
        );
      }

      if (
        ollamaResult.error
      ) {
        throw new Error(
          `Ollama error: ${ollamaResult.error}`,
        );
      }

      const modelOutput =
        ollamaResult.response
          ?.trim();

      if (!modelOutput) {
        throw new Error(
          'Ollama returned no interior advisor response',
        );
      }

      let parsed:
        unknown;

      try {
        parsed =
          JSON.parse(
            modelOutput,
          );
      } catch {
        throw new Error(
          `Interior advisor output was not valid JSON: ${modelOutput.slice(
            0,
            700,
          )}`,
        );
      }

      const suggestions =
        this.validateResult(
          parsed,
        );

      console.log(
        '[OllamaInteriorAdvisorProvider] Interior suggestions validated successfully',
      );

      return suggestions;
    } catch (error) {
      const message =
        this.getErrorMessage(
          error,
        );

      console.error(
        '[OllamaInteriorAdvisorProvider]',
        message,
      );

      throw new BadGatewayException(
        `Interior advisor failed: ${message}`,
      );
    }
  }

  private buildPrompt(
    analysis: RoomAnalysisInput,
  ): string {
    return `
You are RoomStylo's interior design advisor.

Create practical interior decoration recommendations from the room analysis below.

RULES:
- Do not change walls, windows, doors, ceiling or structural layout.
- Do not invent exact branded products.
- Recommend practical products commonly available in Pakistan.
- Avoid overcrowding.
- Keep useful existing furniture where appropriate.
- Recommend only categories that actually improve this room.
- Keep every sentence short.
- Return ONLY JSON.
- No markdown.
- No commentary outside JSON.

ROOM:
${JSON.stringify(analysis)}

Return exactly:

{
  "designDirection": "short overall design direction",
  "recommendedStyle": "one interior style",
  "styleReason": "short reason",
  "colorPalette": [
    "color",
    "color",
    "color"
  ],
  "categoryRecommendations": [
    {
      "category": "category name",
      "reason": "short reason",
      "priority": "high",
      "suggestedCharacteristics": [
        "short characteristic",
        "short characteristic"
      ]
    }
  ],
  "layoutSuggestions": [
    "short suggestion"
  ],
  "keepItems": [
    "item"
  ],
  "improveItems": [
    "item or area"
  ],
  "notes": [
    "short note"
  ]
}

priority must be:
"high", "medium", or "low"

Allowed product categories when relevant:
sofa
chair
coffee table
side table
carpet
rug
curtains
wallpaper
lamp
floor lamp
table lamp
artificial plant
wall art
mirror
cushions
decoration pieces

Use maximum:
- 5 category recommendations
- 4 layout suggestions
- 4 keep items
- 4 improve items
- 4 notes
- 3 suggested characteristics per category

Do not recommend all categories.
`;
  }

  private validateResult(
    value: unknown,
  ): InteriorAdvisorResult {
    if (
      typeof value !==
        'object' ||
      value === null ||
      Array.isArray(
        value,
      )
    ) {
      throw new Error(
        'Interior advisor result must be a JSON object',
      );
    }

    const data =
      value as Record<
        string,
        unknown
      >;

    const designDirection =
      this.requireString(
        data,
        'designDirection',
      );

    const recommendedStyle =
      this.requireString(
        data,
        'recommendedStyle',
      );

    const styleReason =
      this.requireString(
        data,
        'styleReason',
      );

    const colorPalette =
      this.requireStringArray(
        data,
        'colorPalette',
      );

    const layoutSuggestions =
      this.requireStringArray(
        data,
        'layoutSuggestions',
      );

    const keepItems =
      this.requireStringArray(
        data,
        'keepItems',
      );

    const improveItems =
      this.requireStringArray(
        data,
        'improveItems',
      );

    const notes =
      this.requireStringArray(
        data,
        'notes',
      );

    const rawCategories =
      data[
        'categoryRecommendations'
      ];

    if (
      !Array.isArray(
        rawCategories,
      )
    ) {
      throw new Error(
        'categoryRecommendations must be an array',
      );
    }

    const categoryRecommendations =
      rawCategories.map(
        (
          item,
          index,
        ) => {
          if (
            typeof item !==
              'object' ||
            item === null ||
            Array.isArray(
              item,
            )
          ) {
            throw new Error(
              `categoryRecommendations[${index}] must be an object`,
            );
          }

          const categoryData =
            item as Record<
              string,
              unknown
            >;

          const category =
            this.requireString(
              categoryData,
              'category',
            );

          const reason =
            this.requireString(
              categoryData,
              'reason',
            );

          const priorityValue =
            this.requireString(
              categoryData,
              'priority',
            );

          if (
            priorityValue !==
              'high' &&
            priorityValue !==
              'medium' &&
            priorityValue !==
              'low'
          ) {
            throw new Error(
              `Invalid priority in categoryRecommendations[${index}]`,
            );
          }

          const priority:
            'high' |
            'medium' |
            'low' =
              priorityValue;

          const suggestedCharacteristics =
            this.requireStringArray(
              categoryData,
              'suggestedCharacteristics',
            );

          return {
            category,
            reason,
            priority,
            suggestedCharacteristics,
          };
        },
      );

    return {
      designDirection,
      recommendedStyle,
      styleReason,
      colorPalette,
      categoryRecommendations,
      layoutSuggestions,
      keepItems,
      improveItems,
      notes,
    };
  }

  private requireString(
    data: Record<
      string,
      unknown
    >,
    key: string,
  ): string {
    const value =
      data[key];

    if (
      typeof value !==
        'string' ||
      value.trim()
        .length === 0
    ) {
      throw new Error(
        `${key} must be a non-empty string`,
      );
    }

    return value.trim();
  }

  private requireStringArray(
    data: Record<
      string,
      unknown
    >,
    key: string,
  ): string[] {
    const value =
      data[key];

    if (
      !Array.isArray(
        value,
      )
    ) {
      throw new Error(
        `${key} must be an array`,
      );
    }

    return value.map(
      (
        item,
        index,
      ) => {
        if (
          typeof item !==
            'string' ||
          item.trim()
            .length === 0
        ) {
          throw new Error(
            `${key}[${index}] must be a non-empty string`,
          );
        }

        return item.trim();
      },
    );
  }

  private postJson(
    urlString: string,
    body: string,
  ): Promise<HttpResult> {
    return new Promise(
      (
        resolve,
        reject,
      ) => {
        let url:
          URL;

        try {
          url =
            new URL(
              urlString,
            );
        } catch {
          reject(
            new Error(
              `Invalid Ollama URL: ${urlString}`,
            ),
          );

          return;
        }

        const requestFunction =
          url.protocol ===
          'https:'
            ? httpsRequest
            : httpRequest;

        const request =
          requestFunction(
            {
              protocol:
                url.protocol,

              hostname:
                url.hostname,

              port:
                url.port
                  ? Number(
                      url.port,
                    )
                  : undefined,

              path:
                `${url.pathname}${url.search}`,

              method:
                'POST',

              headers: {
                'Content-Type':
                  'application/json',

                'Content-Length':
                  Buffer.byteLength(
                    body,
                  ),
              },
            },
            (
              response,
            ) => {
              const chunks:
                Buffer[] = [];

              response.on(
                'data',
                (
                  chunk:
                    Buffer |
                    string,
                ) => {
                  chunks.push(
                    Buffer.isBuffer(
                      chunk,
                    )
                      ? chunk
                      : Buffer.from(
                          chunk,
                        ),
                  );
                },
              );

              response.on(
                'end',
                () => {
                  resolve({
                    statusCode:
                      response
                        .statusCode ??
                      0,

                    body:
                      Buffer.concat(
                        chunks,
                      ).toString(
                        'utf8',
                      ),
                  });
                },
              );

              response.on(
                'error',
                reject,
              );
            },
          );

        request.setTimeout(
          this.inferenceTimeoutMs,
          () => {
            request.destroy(
              new Error(
                `Ollama interior advisor timed out after ${this.inferenceTimeoutMs}ms`,
              ),
            );
          },
        );

        request.on(
          'error',
          reject,
        );

        request.write(
          body,
        );

        request.end();
      },
    );
  }

  private getErrorMessage(
    error: unknown,
  ): string {
    if (
      error instanceof Error
    ) {
      const cause =
        error.cause;

      if (
        cause instanceof Error
      ) {
        return `${error.message} | cause=${cause.name}: ${cause.message}`;
      }

      return error.message;
    }

    return String(
      error,
    );
  }
}