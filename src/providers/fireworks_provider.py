"""
Fireworks AI Provider - Tier 1 ($0.20-0.80/M tokens)

Optimized for fast, cost-effective inference with models like:
- llama-v3p1-8b-instruct ($0.20/M input, $0.20/M output)
- llama-v3p1-70b-instruct ($0.90/M input, $0.90/M output)
- mixtral-8x7b-instruct ($0.50/M input, $0.50/M output)
"""

import aiohttp
import asyncio
import os
from typing import List, Dict, Optional, AsyncIterator
from .base import LLMProvider, LLMResponse


class FireworksProvider(LLMProvider):
    """
    Fireworks AI provider implementation.

    Features:
    - 2-3x faster than OpenAI for same model sizes
    - Generous rate limits (up to 16k tokens/sec)
    - Streaming support
    - Health check with /models endpoint
    """

    # Pricing per 1M tokens (input, output)
    PRICING = {
        "accounts/fireworks/models/llama-v3p1-8b-instruct": (0.20, 0.20),
        "accounts/fireworks/models/llama-v3p1-70b-instruct": (0.90, 0.90),
        "accounts/fireworks/models/mixtral-8x7b-instruct": (0.50, 0.50),
        "accounts/fireworks/models/mixtral-8x22b-instruct": (1.20, 1.20),
    }

    def __init__(self, api_key: Optional[str] = None, base_url: str = "https://api.fireworks.ai/inference/v1"):
        """
        Initialize Fireworks provider.

        Args:
            api_key: Fireworks API key (or set FIREWORKS_API_KEY env var)
            base_url: API base URL (default: production endpoint)
        """
        self.api_key = api_key or os.getenv("FIREWORKS_API_KEY")
        if not self.api_key:
            raise ValueError("Fireworks API key required (set FIREWORKS_API_KEY env var)")

        self.base_url = base_url.rstrip("/")
        self._session = None

    async def _get_session(self) -> aiohttp.ClientSession:
        """Get or create aiohttp session."""
        if self._session is None or self._session.closed:
            self._session = aiohttp.ClientSession(
                headers={
                    "Authorization": f"Bearer {self.api_key}",
                    "Content-Type": "application/json"
                }
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
        Generate chat completion using Fireworks API.

        Args:
            model: Model name (e.g., "accounts/fireworks/models/llama-v3p1-8b-instruct")
            messages: List of message dicts with 'role' and 'content'
            temperature: Sampling temperature (0.0-2.0)
            max_tokens: Max tokens to generate
            stream: Whether to stream response (not used for non-streaming)
            **kwargs: Additional API parameters (top_p, top_k, etc.)

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
            **kwargs
        }

        if max_tokens:
            payload["max_tokens"] = max_tokens

        async with session.post(
            f"{self.base_url}/chat/completions",
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
        Stream completion chunks from Fireworks API.

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
            f"{self.base_url}/chat/completions",
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
        Check if Fireworks API is healthy.

        Returns:
            True if API is reachable and credentials are valid
        """
        try:
            session = await self._get_session()

            async with session.get(
                f"{self.base_url}/models",
                timeout=aiohttp.ClientTimeout(total=5)
            ) as resp:
                return resp.status == 200

        except Exception:
            return False

    def get_cost(self, input_tokens: int, output_tokens: int, model: str = None) -> float:
        """
        Calculate cost in USD for token usage.

        Args:
            input_tokens: Number of input tokens
            output_tokens: Number of output tokens
            model: Model name (defaults to llama-v3p1-8b-instruct)

        Returns:
            Cost in USD
        """
        if model is None:
            model = "accounts/fireworks/models/llama-v3p1-8b-instruct"

        # Get pricing or use default
        input_price, output_price = self.PRICING.get(
            model,
            (0.20, 0.20)  # Default to cheapest model pricing
        )

        # Prices are per 1M tokens
        cost = (input_tokens * input_price / 1_000_000) + \
               (output_tokens * output_price / 1_000_000)

        return cost

    async def close(self):
        """Close aiohttp session."""
        if self._session and not self._session.closed:
            await self._session.close()


# Example usage
if __name__ == "__main__":
    async def main():
        provider = FireworksProvider()

        # Health check
        is_healthy = await provider.health_check()
        print(f"Fireworks health: {is_healthy}")

        # Chat completion
        response = await provider.chat_completion(
            model="accounts/fireworks/models/llama-v3p1-8b-instruct",
            messages=[
                {"role": "system", "content": "You are a helpful assistant."},
                {"role": "user", "content": "What is the capital of France?"}
            ],
            temperature=0.7,
            max_tokens=100
        )

        print(f"Response: {response.content}")
        print(f"Usage: {response.usage}")

        # Calculate cost
        cost = provider.get_cost(
            response.usage["prompt_tokens"],
            response.usage["completion_tokens"],
            model=response.model
        )
        print(f"Cost: ${cost:.6f}")

        # Streaming
        print("\nStreaming:")
        async for chunk in provider.stream_completion(
            model="accounts/fireworks/models/llama-v3p1-8b-instruct",
            messages=[{"role": "user", "content": "Count from 1 to 5."}],
            max_tokens=50
        ):
            print(chunk, end="", flush=True)
        print()

        await provider.close()

    asyncio.run(main())
