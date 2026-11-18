import {
  BadGatewayException,
  Injectable,
} from '@nestjs/common';

import {
  readFile,
} from 'node:fs/promises';

import {
  request as httpRequest,
} from 'node:http';

import {
  request as httpsRequest,
} from 'node:https';

import {
  RoomVisionAnalysis,
  VisionProvider,
} from './vision-provider.js';

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
export class OllamaVisionProvider
  implements VisionProvider
{
  private readonly ollamaUrl =
    process.env.OLLAMA_URL ??
    'http://127.0.0.1:11434';

  private readonly model =
    process.env.OLLAMA_VISION_MODEL ??
    'qwen3-vl:4b';

  /*
   * Local vision inference is currently
   * very slow on the development machine.
   *
   * The previous Qwen3-VL 4B room analysis
   * took around 13 minutes.
   *
   * This timeout applies only to the
   * backend -> Ollama request.
   */
  private readonly inferenceTimeoutMs =
    20 * 60 * 1000;

  async analyzeRoom(
    imagePath: string,
  ): Promise<RoomVisionAnalysis> {
    try {
      const imageBuffer =
        await readFile(
          imagePath,
        );

      const imageBase64 =
        imageBuffer.toString(
          'base64',
        );

      const requestBody =
        JSON.stringify({
          model:
            this.model,

          prompt:
            this.buildPrompt(),

          images: [
            imageBase64,
          ],

          stream:
            false,

          think:
            false,

          options: {
            temperature:
              0.1,
          },
        });

      console.log(
        `[OllamaVisionProvider] Starting room analysis with model ${this.model}`,
      );

      const startedAt =
        Date.now();

      const result =
        await this.postJson(
          `${this.ollamaUrl}/api/generate`,
          requestBody,
        );

      const durationSeconds =
        Math.round(
          (
            Date.now() -
            startedAt
          ) / 1000,
        );

      console.log(
        `[OllamaVisionProvider] Ollama HTTP response received after ${durationSeconds}s`,
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
        !result.body ||
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
        ollamaResult.response?.trim();

      if (!modelOutput) {
        throw new Error(
          `Ollama returned no model response. done=${String(
            ollamaResult.done,
          )}, done_reason=${String(
            ollamaResult.done_reason,
          )}`,
        );
      }

      const cleanedOutput =
        this.cleanJsonOutput(
          modelOutput,
        );

      let parsed:
        unknown;

      try {
        parsed =
          JSON.parse(
            cleanedOutput,
          );
      } catch {
        throw new Error(
          `Ollama model output was not valid JSON: ${cleanedOutput.slice(
            0,
            500,
          )}`,
        );
      }

      const analysis =
        this.validateAnalysis(
          parsed,
        );

      console.log(
        '[OllamaVisionProvider] Room analysis validated successfully',
      );

      return analysis;
    } catch (error) {
      const message =
        this.getErrorMessage(
          error,
        );

      console.error(
        '[OllamaVisionProvider]',
        message,
      );

      throw new BadGatewayException(
        `Room vision analysis failed: ${message}`,
      );
    }
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
            (response) => {
              const chunks:
                Buffer[] = [];

              response.on(
                'data',
                (
                  chunk:
                    Buffer | string,
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
                  const responseBody =
                    Buffer.concat(
                      chunks,
                    ).toString(
                      'utf8',
                    );

                  resolve({
                    statusCode:
                      response.statusCode ??
                      0,

                    body:
                      responseBody,
                  });
                },
              );

              response.on(
                'error',
                (error) => {
                  reject(
                    error,
                  );
                },
              );
            },
          );

        request.setTimeout(
          this.inferenceTimeoutMs,
          () => {
            request.destroy(
              new Error(
                `Ollama inference timed out after ${Math.round(
                  this.inferenceTimeoutMs /
                    60000,
                )} minutes`,
              ),
            );
          },
        );

        request.on(
          'error',
          (error) => {
            reject(
              error,
            );
          },
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
      !(error instanceof Error)
    ) {
      return 'Unknown Ollama error';
    }

    let message =
      error.message;

    const errorWithCause =
      error as Error & {
        cause?: unknown;
        code?: unknown;
      };

    if (
      typeof errorWithCause.code ===
        'string' &&
      errorWithCause.code
    ) {
      message +=
        ` | code=${errorWithCause.code}`;
    }

    const cause =
      errorWithCause.cause;

    if (
      typeof cause ===
        'object' &&
      cause !== null
    ) {
      const causeData =
        cause as Record<
          string,
          unknown
        >;

      const causeCode =
        typeof causeData.code ===
        'string'
          ? causeData.code
          : '';

      const causeMessage =
        typeof causeData.message ===
        'string'
          ? causeData.message
          : '';

      if (
        causeCode ||
        causeMessage
      ) {
        message +=
          ` | cause=${causeCode || 'unknown'}: ${causeMessage || 'No cause message'}`;
      }
    }

    return message;
  }

  private cleanJsonOutput(
    value: string,
  ): string {
    let cleaned =
      value.trim();

    if (
      cleaned.startsWith(
        '```json',
      )
    ) {
      cleaned =
        cleaned.slice(
          7,
        );
    } else if (
      cleaned.startsWith(
        '```',
      )
    ) {
      cleaned =
        cleaned.slice(
          3,
        );
    }

    if (
      cleaned.endsWith(
        '```',
      )
    ) {
      cleaned =
        cleaned.slice(
          0,
          -3,
        );
    }

    return cleaned.trim();
  }

  private buildPrompt(): string {
    return `
Analyze this room image for the RoomStylo interior design application.

Return ONLY one valid JSON object.

Do not include markdown.
Do not include code fences.
Do not explain your reasoning.
Do not include any text before or after the JSON.

Use exactly this structure:

{
  "roomType": "",
  "walls": [],
  "floor": "",
  "windows": [],
  "doors": [],
  "furniture": [],
  "colors": [],
  "lighting": [],
  "usableAreas": [],
  "observations": []
}

Rules:

1. Describe only architectural features and objects actually visible in the image.

2. Never invent anything outside the camera view.

3. roomType:
Identify the most likely room type.

4. walls:
Describe visible wall materials, finishes, panels and important wall features.

5. floor:
Describe visible floor materials and dominant floor colours.

6. windows:
Include ONLY actual architectural windows.
A glass partition is NOT a window.
A glass wall is NOT automatically a window.
A glass door is NOT a window.
If no actual window is clearly visible, return [].

7. doors:
Include only clearly visible doors.
Glass doors should be listed here, not under windows.

8. furniture:
List visible furniture and important movable objects.

9. colors:
List dominant visible interior colours.

10. lighting:
Describe visible artificial light sources and clearly visible natural lighting.

11. usableAreas:
Include ONLY genuinely free areas where new furniture or decoration could reasonably be placed.

Do NOT list:
- areas underneath existing furniture
- occupied seating areas
- areas already being used
- rugs underneath existing furniture
- circulation paths that would be blocked

12. observations:
Include other useful visible interior-design observations.

13. If an object cannot be identified confidently, describe it as uncertain rather than guessing.

14. Keep descriptions concise and practical.

15. Do not recommend products.

16. Do not redesign the room.

17. Do not suggest structural modifications.

18. Preserve the distinction between:
- windows
- doors
- glass partitions
- glass walls

19. Return JSON only.
`.trim();
  }

  private validateAnalysis(
    value: unknown,
  ): RoomVisionAnalysis {
    if (
      typeof value !== 'object' ||
      value === null ||
      Array.isArray(value)
    ) {
      throw new Error(
        'AI analysis is not a JSON object',
      );
    }

    const data =
      value as Record<
        string,
        unknown
      >;

    return {
      roomType:
        this.requireString(
          data.roomType,
          'roomType',
        ),

      walls:
        this.requireStringArray(
          data.walls,
          'walls',
        ),

      floor:
        this.requireString(
          data.floor,
          'floor',
        ),

      windows:
        this.requireStringArray(
          data.windows,
          'windows',
        ),

      doors:
        this.requireStringArray(
          data.doors,
          'doors',
        ),

      furniture:
        this.requireStringArray(
          data.furniture,
          'furniture',
        ),

      colors:
        this.requireStringArray(
          data.colors,
          'colors',
        ),

      lighting:
        this.requireStringArray(
          data.lighting,
          'lighting',
        ),

      usableAreas:
        this.requireStringArray(
          data.usableAreas,
          'usableAreas',
        ),

      observations:
        this.requireStringArray(
          data.observations,
          'observations',
        ),
    };
  }

  private requireString(
    value: unknown,
    fieldName: string,
  ): string {
    if (
      typeof value !==
      'string'
    ) {
      throw new Error(
        `AI field "${fieldName}" must be a string`,
      );
    }

    const cleaned =
      value.trim();

    if (!cleaned) {
      throw new Error(
        `AI field "${fieldName}" cannot be empty`,
      );
    }

    return cleaned;
  }

  private requireStringArray(
    value: unknown,
    fieldName: string,
  ): string[] {
    if (
      !Array.isArray(
        value,
      )
    ) {
      throw new Error(
        `AI field "${fieldName}" must be an array`,
      );
    }

    const cleaned =
      value
        .filter(
          (
            item,
          ): item is string =>
            typeof item ===
            'string',
        )
        .map(
          (item) =>
            item.trim(),
        )
        .filter(
          (item) =>
            item.length > 0,
        );

    if (
      cleaned.length !==
      value.length
    ) {
      throw new Error(
        `AI field "${fieldName}" must contain only strings`,
      );
    }

    return cleaned;
  }
}