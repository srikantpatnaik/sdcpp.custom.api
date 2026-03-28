# Stable Diffusion.cpp Server API

This document describes the REST API endpoints provided by the stable-diffusion.cpp server.

## Base URL

```
http://localhost:1234
```

## Endpoints

### 1. Text-to-Image Generation

**Endpoint:** `POST /v1/images/generations`

Generate images from text prompts (OpenAI-compatible).

#### Request Body

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| `prompt` | string | Yes | - | Text description of the desired image |
| `n` | integer | No | 1 | Number of images to generate (1-8) |
| `size` | string | No | "512x512" | Image size in format "WIDTHxHEIGHT" |
| `output_format` | string | No | "png" | Output format: "png" or "jpeg" |
| `output_compression` | integer | No | 100 | JPEG compression quality (0-100) |
| `response_format` | string | No | "base64" | Response format: "base64" (JSON) or "url" (direct binary) |
| `output_filename` | string | No | - | Custom filename for download (requires response_format="url") |
| `upscale` | boolean | No | false | Enable 2x upscaling with ESRGAN |
| `seed` | integer | No | -1 | Random seed for reproducibility |
| `steps` | integer | No | 20 | Number of sampling steps |
| `cfg_scale` | float | No | 7.0 | CFG scale for guidance |
| `negative_prompt` | string | No | "" | Negative prompt |

#### Example Request

```bash
curl -X POST http://localhost:1234/v1/images/generations \
  -H "Content-Type: application/json" \
  -d '{
    "prompt": "a beautiful landscape",
    "n": 1,
    "size": "512x512",
    "steps": 20,
    "cfg_scale": 7.0
  }'
```

#### Response (base64)

```json
{
  "created": 1234567890,
  "data": [
    {
      "b64_json": "iVBORw0KGgoAAAANSUhEUgAA..."
    }
  ],
  "output_format": "png"
}
```

#### Response (url)

Returns direct binary image with `Content-Disposition` header for download.

---

### 2. SD API - Text-to-Image

**Endpoint:** `POST /sdapi/v1/txt2img`

Generate images using AUTOMATIC1111/Forge compatible API.

#### Request Body

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| `prompt` | string | Yes | - | Text description of the desired image |
| `negative_prompt` | string | No | "" | Negative prompt |
| `width` | integer | No | 1024 | Image width |
| `height` | integer | No | 600 | Image height |
| `steps` | integer | No | 4 | Number of sampling steps |
| `cfg_scale` | float | No | 1.0 | CFG scale for guidance |
| `seed` | integer | No | -1 | Random seed (-1 for random) |
| `batch_size` | integer | No | 1 | Number of images per batch (1-8) |
| `clip_skip` | integer | No | -1 | CLIP skip value |
| `sampler_name` | string | No | "" | Sampler name (euler, euler_a, dpm++_2m, etc.) |
| `scheduler` | string | No | "" | Scheduler name |
| `response_format` | string | No | "base64" | Response format: "base64" or "url" |
| `output_format` | string | No | "jpeg" | Output format: "png" or "jpeg" |
| `output_compression` | integer | No | 90 | JPEG compression quality (0-100) |
| `output_filename` | string | No | - | Custom filename for download |
| `upscale` | boolean | No | false | Enable 2x upscaling |
| `lora` | array | No | - | LoRA configuration array |

#### LoRA Parameter Structure

```json
{
  "lora": [
    {
      "path": "lora_name",
      "multiplier": 1.0,
      "is_high_noise": false
    }
  ]
}
```

#### Example Request

```bash
# With all defaults (1024x600, steps=4, cfg=1, jpeg)
curl -X POST http://localhost:1234/sdapi/v1/txt2img \
  -H "Content-Type: application/json" \
  -d '{"prompt": "a cat"}'

# With custom parameters
curl -X POST http://localhost:1234/sdapi/v1/txt2img \
  -H "Content-Type: application/json" \
  -d '{
    "prompt": "a cat sitting on a table",
    "negative_prompt": "blurry, low quality",
    "width": 1024,
    "height": 600,
    "steps": 4,
    "cfg_scale": 1.0,
    "seed": 42,
    "sampler_name": "euler_a"
  }'
```

#### Response

```json
{
  "images": ["base64_encoded_image"],
  "parameters": {
    "prompt": "a cat sitting on a table",
    "negative_prompt": "blurry, low quality",
    ...
  },
  "info": ""
}
```

---

### 3. SD API - Image-to-Image

**Endpoint:** `POST /sdapi/v1/img2img`

Transform images using img2img.

#### Request Body

All parameters from `/sdapi/v1/txt2img` plus:

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| `init_images` | array | Yes | - | Base64 encoded input images |
| `denoising_strength` | float | No | -1 | Denoising strength (0-1) |
| `mask` | string | No | - | Base64 encoded mask image (for inpainting) |
| `inpainting_mask_invert` | boolean | No | false | Invert mask |
| `image_cfg_scale` | float | No | - | Image CFG scale |

#### Example Request

```bash
curl -X POST http://localhost:1234/sdapi/v1/img2img \
  -H "Content-Type: application/json" \
  -d '{
    "prompt": "a red cat",
    "init_images": ["base64_encoded_image"],
    "denoising_strength": 0.7
  }'
```

---

### 4. Image Edits

**Endpoint:** `POST /v1/images/edits`

Edit images (inpainting/outpainting) using multipart form data.

#### Request (multipart/form-data)

| Field | Type | Description |
|-------|------|-------------|
| `prompt` | string | Text description |
| `image[]` | file | Input image(s) |
| `mask` | file | Mask image (optional) |
| `strength` | float | Denoising strength (optional) |

#### Example Request

```bash
curl -X POST http://localhost:1234/v1/images/edits \
  -F "prompt=remove the background" \
  -F "image=@input.png" \
  -F "mask=@mask.png"
```

---

### 5. List Models

**Endpoint:** `GET /v1/models`

List available models.

#### Response

```json
{
  "data": [
    {
      "id": "sd-cpp-local",
      "object": "model",
      "owned_by": "local"
    }
  ]
}
```

---

### 6. SD API - Get LoRAs

**Endpoint:** `GET /sdapi/v1/loras`

List available LoRA models.

#### Response

```json
[
  {
    "name": "lora_name",
    "path": "/path/to/lora.safetensors"
  }
]
```

---

### 7. SD API - Get Samplers

**Endpoint:** `GET /sdapi/v1/samplers`

List available samplers.

#### Response

```json
[
  {
    "name": "default",
    "aliases": ["default"],
    "options": {}
  },
  {
    "name": "euler",
    "aliases": ["euler", "k_euler"],
    "options": {}
  }
]
```

---

### 8. SD API - Get Schedulers

**Endpoint:** `GET /sdapi/v1/schedulers`

List available schedulers.

#### Response

```json
[
  {
    "name": "default",
    "label": "default"
  }
]
```

---

### 9. SD API - Get Models

**Endpoint:** `GET /sdapi/v1/sd-models`

List loaded SD models.

#### Response

```json
[
  {
    "title": "model_name",
    "model_name": "model_name",
    "filename": "model.safetensors",
    "hash": "8888888888",
    "sha256": "8888888888888888888888888888888888888888888888888888888888888888",
    "config": null
  }
]
```

---

### 10. SD API - Get Options

**Endpoint:** `GET /sdapi/v1/options`

Get server options.

#### Response

```json
{
  "samples_format": "png",
  ...
}
```

---

### 11. Root Endpoint

**Endpoint:** `GET /`

Returns the web UI HTML.

---

## Server Startup Options

```bash
./bin/sd-server [options]

Options:
  -l, --listen-ip <ip>        Server listen IP (default: 127.0.0.1)
  --listen-port <port>        Server listen port (default: 1234)
  -m, --model <path>          Path to model (required)
  --vae <path>                Path to standalone VAE model
  --taesd <path>              Path to TAESD model
  --control-net <path>        Path to control net model
  --upscale-model <path>      Path to ESRGAN model for upscaling
  --lora-model-dir <path>     LoRA model directory
  -t, --threads <n>           Number of threads (-1 for auto)
  -v, --verbose               Print extra info
  --color                     Colorize logging
```

## Notes

1. **Upscaling**: Requires `--upscale-model` when starting the server and `upscale: true` in the request.
2. **Direct Download**: Use `response_format: "url"` with `output_filename` for direct binary download.
3. **LoRA Support**: LoRAs must be in the directory specified by `--lora-model-dir`.
4. **Seed**: Use `seed: -1` for random seed on each generation.
5. **Samplers**: Available: euler, euler_a, dpm++_2m, dpm++_2s, heun, lcm, etc.
6. **Schedulers**: Available: default, discrete, exponential, karras, etc.
