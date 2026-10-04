"""
Jan Provider - Privacy Mode (Tier 0, $0 cost)

100% local inference with privacy-first design:
- Runs entirely on-device (CPU or GPU)
- No telemetry or analytics
- OpenAI-compatible API
- Supports GGUF models from HuggingFace

Models supported:
- llama-3.1-8b-instruct
- mistral-7b-instruct
- phi-3-mini-4k-instruct
- Any GGUF model from HuggingFace
"""

import aiohttp
import asyncio
import os
from typing import List, Dict, Optional, AsyncIterator
from .base import LLMProvider, LLMResponse


class JanProvider(LLMProvider):
    """
    Jan.ai provider implementation for privacy-first local inference.

    Features:
    - 100% local execution (no API calls)
    - Zero cost (runs on your hardware)
    - Privacy-compatible (GDPR/HIPAA friendly)
    - OpenAI-compatible API
    - GPU acceleration support
    """

    def __init__(self, base_url: str = "http://localhost:1337"):
        """
        Initialize Jan provider.

        Args:
            base_url: Jan API base URL (default: http://localhost:1337)

        Note:
            Jan must be running locally. Start with: `jan serve`
        """
        self.base_url = base_url.rstrip("/")
        self._session = None

    async def _get_session(self) -> aiohttp.ClientSession:
        """Get or create aiohttp session."""
        if self._session is None or self._session.closed:
            self._session = aiohttp.ClientSession(
                headers={"Content-Type": "application/json"}
            )
        return self._session

    async def chat_completion(
        self,
        model: str,
        messages: List[Dict[str, str]],
        temperature: float = 0.7,
        max_tokens: Optional[int] = None,
        stream: bool = False,
        **kwargs
    ) -> LLMResponse:
        """
        Generate chat completion using Jan API.

        Args:
            model: Model name (e.g., "llama-3.1-8b-instruct")
            messages: List of message dicts with 'role' and 'content'
            temperature: Sampling temperature (0.0-2.0)
            max_tokens: Max tokens to generate
            stream: Whether to stream response (not used for non-streaming)
            **kwargs: Additional API parameters

        Returns:
            LLMResponse with content, usage, model, finish_reason

        Raises:
            aiohttp.ClientError: On network/API errors
        """
        session = await self._get_session()

        payload = {
            "model": model,
            "messages": messages,
            "temperature": temperature,
            "stream": False,
            **kwargs
        }

        if max_tokens:
            payload["max_tokens"] = max_tokens

        async with session.post(
            f"{self.base_url}/v1/chat/completions",
            json=payload
        ) as resp:
            resp.raise_for_status()
            data = await resp.json()

        choice = data["choices"][0]
        usage = data.get("usage", {})

        return LLMResponse(
            content=choice["message"]["content"],
            usage={
                "prompt_tokens": usage.get("prompt_tokens", 0),
                "completion_tokens": usage.get("completion_tokens", 0)
            },
            model=data.get("model", model),
            finish_reason=choice.get("finish_reason", "stop")
        )

    async def stream_completion(
        self,
        model: str,
        messages: List[Dict[str, str]],
        **kwargs
    ) -> AsyncIterator[str]:
        """
        Stream completion chunks from Jan API.

        Args:
            model: Model name
            messages: List of message dicts
            **kwargs: Additional API parameters

        Yields:
            Content chunks as they arrive
        """
        session = await self._get_session()

        payload = {
            "model": model,
            "messages": messages,
            "stream": True,
            **kwargs
        }

        async with session.post(
            f"{self.base_url}/v1/chat/completions",
            json=payload
        ) as resp:
            resp.raise_for_status()

            async for line in resp.content:
                line = line.decode("utf-8").strip()

                if not line or line == "data: [DONE]":
                    continue

                if line.startswith("data: "):
                    import json
                    try:
                        data = json.loads(line[6:])
                        delta = data["choices"][0].get("delta", {})

                        if "content" in delta:
                            yield delta["content"]
                    except (json.JSONDecodeError, KeyError):
                        continue

    async def health_check(self) -> bool:
        """
        Check if Jan is running and healthy.

        Returns:
            True if Jan API is reachable
        """
        try:
            session = await self._get_session()

            # Jan has /v1/models endpoint
            async with session.get(
                f"{self.base_url}/v1/models",
                timeout=aiohttp.ClientTimeout(total=5)
            ) as resp:
                return resp.status == 200

        except Exception:
            return False

    def get_cost(self, input_tokens: int, output_tokens: int, model: str = None) -> float:
        """
        Calculate cost in USD for token usage.

        Jan is always free (local inference).

        Args:
            input_tokens: Number of input tokens
            output_tokens: Number of output tokens
            model: Model name (ignored, always $0)

        Returns:
            Cost in USD (always 0.0)
        """
        return 0.0

    async def list_models(self) -> List[Dict[str, str]]:
        """
        List available models in Jan.

        Returns:
            List of model dicts with 'id', 'name', 'size' keys
        """
        session = await self._get_session()

        async with session.get(f"{self.base_url}/v1/models") as resp:
            resp.raise_for_status()
            data = await resp.json()

        return [
            {
                "id": model["id"],
                "name": model.get("name", model["id"]),
                "size": model.get("size", "unknown")
            }
            for model in data.get("data", [])
        ]

    async def download_model(self, model_id: str) -> bool:
        """
        Download a model to Jan.

        Args:
            model_id: HuggingFace model ID (e.g., "TheBloke/Llama-2-7B-Chat-GGUF")

        Returns:
            True if download started successfully
        """
        session = await self._get_session()

        async with session.post(
            f"{self.base_url}/v1/models/download",
            json={"model": model_id}
        ) as resp:
            return resp.status == 200

    async def close(self):
        """Close aiohttp session."""
        if self._session and not self._session.closed:
            await self._session.close()


# Example usage
if __name__ == "__main__":
    async def main():
        provider = JanProvider()

        # Health check
        is_healthy = await provider.health_check()
        print(f"Jan health: {is_healthy}")

        if not is_healthy:
            print("Jan is not running. Start it with: jan serve")
            return

        # List models
        models = await provider.list_models()
        print(f"\nAvailable models: {len(models)}")
        for model in models[:3]:
            print(f"  - {model['id']} ({model['size']})")

        # Chat completion
        if models:
            model_id = models[0]["id"]
            response = await provider.chat_completion(
                model=model_id,
                messages=[
                    {"role": "system", "content": "You are a helpful assistant."},
                    {"role": "user", "content": "What is the capital of France?"}
                ],
                temperature=0.7,
                max_tokens=100
            )

            print(f"\nResponse: {response.content}")
            print(f"Usage: {response.usage}")
            print(f"Cost: ${provider.get_cost(response.usage['prompt_tokens'], response.usage['completion_tokens']):.6f}")

            # Streaming
            print("\nStreaming:")
            async for chunk in provider.stream_completion(
                model=model_id,
                messages=[{"role": "user", "content": "Count from 1 to 5."}],
                max_tokens=50
            ):
                print(chunk, end="", flush=True)
            print()

        await provider.close()

    asyncio.run(main())
