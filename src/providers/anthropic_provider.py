"""
Anthropic Provider - Tier 3 ($3-15/M tokens)

Premium models for complex reasoning:
- claude-3-5-sonnet-20241022 ($3/M input, $15/M output)
- claude-3-5-haiku-20241022 ($1/M input, $5/M output)
- claude-3-opus-20240229 ($15/M input, $75/M output)
"""

import aiohttp
import asyncio
import os
from typing import List, Dict, Optional, AsyncIterator
from .base import LLMProvider, LLMResponse


class AnthropicProvider(LLMProvider):
    """
    Anthropic Claude provider implementation.

    Features:
    - State-of-the-art reasoning and coding capabilities
    - 200k context window
    - System prompts and tool use
    - Streaming support with server-sent events
    """

    # Pricing per 1M tokens (input, output)
    PRICING = {
        "claude-3-5-sonnet-20241022": (3.00, 15.00),
        "claude-3-5-haiku-20241022": (1.00, 5.00),
        "claude-3-opus-20240229": (15.00, 75.00),
        "claude-3-sonnet-20240229": (3.00, 15.00),
        "claude-3-haiku-20240307": (0.25, 1.25),
    }

    def __init__(self, api_key: Optional[str] = None, base_url: str = "https://api.anthropic.com/v1"):
        """
        Initialize Anthropic provider.

        Args:
            api_key: Anthropic API key (or set ANTHROPIC_API_KEY env var)
            base_url: API base URL (default: production endpoint)
        """
        self.api_key = api_key or os.getenv("ANTHROPIC_API_KEY")
        if not self.api_key:
            raise ValueError("Anthropic API key required (set ANTHROPIC_API_KEY env var)")

        self.base_url = base_url.rstrip("/")
        self._session = None

    async def _get_session(self) -> aiohttp.ClientSession:
        """Get or create aiohttp session."""
        if self._session is None or self._session.closed:
            self._session = aiohttp.ClientSession(
                headers={
                    "x-api-key": self.api_key,
                    "anthropic-version": "2023-06-01",
                    "Content-Type": "application/json"
                }
            )
        return self._session

    def _convert_messages(self, messages: List[Dict[str, str]]) -> tuple[Optional[str], List[Dict[str, str]]]:
        """
        Convert OpenAI-style messages to Anthropic format.

        Anthropic separates system messages from conversation messages.

        Args:
            messages: List of message dicts with 'role' and 'content'

        Returns:
            Tuple of (system_prompt, user_messages)
        """
        system_prompt = None
        user_messages = []

        for msg in messages:
            if msg["role"] == "system":
                # Extract system prompt (Anthropic uses separate field)
                system_prompt = msg["content"]
            else:
                # Keep user/assistant messages
                user_messages.append({
                    "role": msg["role"],
                    "content": msg["content"]
                })

        return system_prompt, user_messages

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
        Generate chat completion using Anthropic API.

        Args:
            model: Model name (e.g., "claude-3-5-sonnet-20241022")
            messages: List of message dicts with 'role' and 'content'
            temperature: Sampling temperature (0.0-1.0)
            max_tokens: Max tokens to generate (required by Anthropic)
            stream: Whether to stream response (not used for non-streaming)
            **kwargs: Additional API parameters (top_p, top_k, etc.)

        Returns:
            LLMResponse with content, usage, model, finish_reason

        Raises:
            aiohttp.ClientError: On network/API errors
        """
        session = await self._get_session()

        # Convert messages to Anthropic format
        system_prompt, user_messages = self._convert_messages(messages)

        # Anthropic requires max_tokens
        if max_tokens is None:
            max_tokens = 4096

        payload = {
            "model": model,
            "messages": user_messages,
            "max_tokens": max_tokens,
            "temperature": temperature,
            **kwargs
        }

        if system_prompt:
            payload["system"] = system_prompt

        async with session.post(
            f"{self.base_url}/messages",
            json=payload
        ) as resp:
            resp.raise_for_status()
            data = await resp.json()

        # Extract content (Anthropic returns array of content blocks)
        content_blocks = data.get("content", [])
        content = "".join(
            block.get("text", "") for block in content_blocks if block.get("type") == "text"
        )

        usage = data.get("usage", {})

        return LLMResponse(
            content=content,
            usage={
                "prompt_tokens": usage.get("input_tokens", 0),
                "completion_tokens": usage.get("output_tokens", 0)
            },
            model=data.get("model", model),
            finish_reason=data.get("stop_reason", "end_turn")
        )

    async def stream_completion(
        self,
        model: str,
        messages: List[Dict[str, str]],
        **kwargs
    ) -> AsyncIterator[str]:
        """
        Stream completion chunks from Anthropic API.

        Args:
            model: Model name
            messages: List of message dicts
            **kwargs: Additional API parameters

        Yields:
            Content chunks as they arrive
        """
        session = await self._get_session()

        # Convert messages
        system_prompt, user_messages = self._convert_messages(messages)

        # Ensure max_tokens
        max_tokens = kwargs.pop("max_tokens", 4096)

        payload = {
            "model": model,
            "messages": user_messages,
            "max_tokens": max_tokens,
            "stream": True,
            **kwargs
        }

        if system_prompt:
            payload["system"] = system_prompt

        async with session.post(
            f"{self.base_url}/messages",
            json=payload
        ) as resp:
            resp.raise_for_status()

            async for line in resp.content:
                line = line.decode("utf-8").strip()

                if not line or not line.startswith("data: "):
                    continue

                # Skip pings and non-data events
                if line == "data: [DONE]":
                    continue

                import json
                try:
                    data = json.loads(line[6:])

                    # Anthropic streaming events
                    if data.get("type") == "content_block_delta":
                        delta = data.get("delta", {})
                        if delta.get("type") == "text_delta":
                            yield delta.get("text", "")

                except (json.JSONDecodeError, KeyError):
                    continue

    async def health_check(self) -> bool:
        """
        Check if Anthropic API is healthy.

        Uses a minimal completion request as health check.

        Returns:
            True if API is reachable and credentials are valid
        """
        try:
            session = await self._get_session()

            # Minimal request to test connectivity
            async with session.post(
                f"{self.base_url}/messages",
                json={
                    "model": "claude-3-5-haiku-20241022",  # Cheapest model
                    "messages": [{"role": "user", "content": "hi"}],
                    "max_tokens": 1
                },
                timeout=aiohttp.ClientTimeout(total=10)
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
            model: Model name (defaults to claude-3-5-sonnet)

        Returns:
            Cost in USD
        """
        if model is None:
            model = "claude-3-5-sonnet-20241022"

        # Get pricing or use default
        input_price, output_price = self.PRICING.get(
            model,
            (3.00, 15.00)  # Default to Sonnet pricing
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
        provider = AnthropicProvider()

        # Health check
        is_healthy = await provider.health_check()
        print(f"Anthropic health: {is_healthy}")

        # Chat completion
        response = await provider.chat_completion(
            model="claude-3-5-sonnet-20241022",
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
            model="claude-3-5-haiku-20241022",
            messages=[{"role": "user", "content": "Count from 1 to 5."}],
            max_tokens=50
        ):
            print(chunk, end="", flush=True)
        print()

        await provider.close()

    asyncio.run(main())
