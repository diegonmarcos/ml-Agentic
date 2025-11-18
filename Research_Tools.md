# Tools of the Trade - Unwind AI Complete Collection
## Comprehensive Guide with Descriptions by Category

*Last Updated: November 11, 2025*
*Source: https://www.theunwindai.com/*
*Updated with 20+ new tools from recent posts*

---

## Table of Contents
1. [MCP (Model Context Protocol) Tools](#mcp-tools)
2. [AI Coding & Development Tools](#ai-coding--development-tools)
3. [Vector Search & RAG Systems](#vector-search--rag-systems)
4. [AI Agents & Orchestration](#ai-agents--orchestration)
5. [Infrastructure & APIs](#infrastructure--apis)
6. [Full-Stack Development](#full-stack-development)
7. [Productivity & Automation](#productivity--automation)
8. [Web Scraping & Data Extraction](#web-scraping--data-extraction)
9. [Local Inference & Models](#local-inference--models)
10. [Development Tools & IDEs](#development-tools--ides)
11. [Authentication & Security](#authentication--security)
12. [Monitoring & Analytics](#monitoring--analytics)
13. [Content Creation & Media](#content-creation--media)
14. [AI-Powered Platforms & Applications](#ai-powered-platforms--applications)

---

## MCP (Model Context Protocol) Tools

### 1. DeepContext MCP
**Link:** https://github.com/Wildcard-Official/deepcontext-mcp
**Description:** Provides symbol-aware semantic search for coding agents via MCP. Uses both AST (Abstract Syntax Tree) parsing and hybrid search with reranking to find semantically relevant code chunks rather than relying on text-based grep searches. Currently supports Typescript and Python, making it ideal for large codebases where understanding code structure is crucial.

### 2. MCP Pointer
**Link:** https://github.com/etsd-tech/mcp-pointer
**Description:** A Chrome extension and MCP server that enables you to Option+Click (or Alt+Click) any DOM element in your browser to capture its complete context for AI agents. This allows agents to analyze specific webpage elements you've visually selected rather than working with abstract descriptions, making web automation and testing much more intuitive.

### 3. MCP-Use
**Link:** https://github.com/pietrozullo/mcp-use
**Description:** Open-source Python package for connecting any LLM to MCP tools in just 6 lines of code, without requiring desktop applications. Provides a straightforward client-agent structure for accessing MCP server capabilities from Python environments, significantly reducing the complexity of MCP integration.

### 4. Dive
**Link:** https://github.com/OpenAgentPlatform/Dive
**Description:** Open-source MCP Host desktop application that seamlessly integrates with any LLMs supporting function calling capabilities. Supports multiple AI models including OpenAI GPT, Claude, Gemini, and Ollama, providing a unified interface for MCP server management.

### 5. Open Rube
**Link:** https://github.com/composiohq/open-rube
**Description:** Open-source implementation of Composio's Rube platform that uses their Tool Router to connect AI agents to 500+ applications like GitHub, Slack, and Gmail within the chat interface. Handles authentication via Supabase, manages conversation history in PostgreSQL, and streams live responses for real-time interaction.

### 6. PageIndex MCP
**Link:** https://github.com/VectifyAI/pageindex-mcp
**Description:** Vectorless, reasoning-based RAG system that represents documents as hierarchical tree structures instead of vectors. This MCP server exposes an AI-native tree index directly to LLMs, allowing agents to reason over document structure and retrieve the right information with better context understanding than traditional vector-based approaches.

### 7. web2mcp
**Link:** https://github.com/neelsomani/web2mcp
**Description:** Auto-generates MCP implementation for any web app. Stagehand crawls the app to map interactive elements, forms, and data collections, then GPT-5 converts this mapping into MCP configuration files. The resulting dynamic MCP server translates MCP calls into web application actions, enabling seamless web automation.

### 8. MCPcat
**Link:** https://mcpcat.io/
**Description:** Open-source monitoring library for MCP server maintainers that provides logging and observability with a single line of code. Tracks user sessions, tool calls, and agent behavior with out-of-the-box integration with existing platforms like Datadog and Sentry, making production MCP server monitoring straightforward.

### 9. mcpd
**Link:** https://github.com/mozilla-ai/mcpd
**Description:** Command-line tool that runs MCP servers from a config file, handling setup and management automatically so you don't need to manually start each server. Exposes all servers through a single HTTP API endpoint, simplifying multi-server MCP deployments.

### 10. Rube
**Link:** https://rube.composio.dev/
**Description:** Unified MCP server that connects MCP clients like Claude and Cursor to 500+ apps including Gmail, Slack, GitHub, and Notion. Auto-routes queries to the right app in real-time without manual instruction or configuration, making cross-app workflows seamless.

### 11. xmcp
**Link:** Referenced in Multi-Agent Trading post
**Description:** Framework that treats MCP development like modern web development with file-system routing, hot reloading, and zero-config deployment. Drop TypeScript files in /src/tools/ and they automatically become MCP tools with schema validation, metadata, and proper typing through Zod integration. Supports both STDIO and HTTP transport.

### 12. MCP Boilerplate
**Link:** https://mcpboilerplate.com/
**Description:** Starter kit designed to help quickly create, deploy, and monetize your own remote MCP server. Includes features like Cloudflare deployment, user authentication (Google/GitHub), and Stripe payment integration, providing everything needed to launch a commercial MCP service.

---

## AI Coding & Development Tools

### 1. Townie
**Link:** https://townie.val.run/
**Description:** 100% opensource AI coding agent built on Val Town, inspired by tools like Lovable, bolt, and v0. Lets you code, prompt, branch, and manage pull requests for full-stack projects directly in the browser with no local setup needed, making it perfect for quick prototyping and cloud-based development.

### 2. Jupyt
**Link:** https://www.ipynb.ai/
**Description:** AI agent specifically designed for Jupyter notebooks that can create, edit, and run code cells autonomously. Integrates with major model APIs, supports dataset search from platforms like Hugging Face and Kaggle, and brings modern IDE-like features without changing the familiar Jupyter workflow.

### 3. Nelly
**Link:** https://nelly.is/
**Description:** End-to-end desktop app to build, use, and monetize AI agents without code. Build agents with tools and databases, test and refine them locally, deploy for use, and soon monetize through their upcoming agent marketplace. Designed for non-technical users who want to create and share AI agents.

### 4. nao
**Link:** https://getnao.io/
**Description:** AI code editor specifically built for writing code on data. It's a local editor connected to your data warehouse with an AI copilot that has context of both your data schema and codebase. Built for data workflows, helping teams write faster, better code while ensuring data quality.

### 5. Claude Checkpoints
**Link:** https://claude-checkpoints.com/
**Description:** Version control tool that automatically monitors project files and creates snapshots when working with Claude Code for easy rollback. Has a built-in diff viewer to see exactly what changed between checkpoints, providing safety and transparency when AI makes code changes.

### 6. Vibecode Terminal
**Link:** https://www.vibecodeapp.com/terminal
**Description:** Web-based platform that runs Claude Code, OpenAI Codex with GPT-5, Gemini CLI, and Cursor CLI in one unified interface. Runs these CLI agents in a web-based sandbox, so your personal computer and files are safe while you experiment freely with different AI coding assistants.

### 7. Alex
**Link:** https://alexcodes.app/
**Description:** Cursor-like sidebar for Xcode bringing commands like Cmd+L and Cmd+K to streamline code suggestions, error fixes, and codebase search directly within Xcode. Makes AI-powered coding accessible to iOS and macOS developers in their native development environment.

### 8. gptel
**Link:** https://github.com/karthink/gptel
**Description:** Simple LLM chat client for Emacs with support for multiple models and backends. Works in the spirit of Emacs, available at any time and uniformly in any buffer, making it perfect for developers who live in Emacs and want AI assistance without leaving their editor.

### 9. llama-vscode
**Link:** https://marketplace.visualstudio.com/items?itemName=ggml-org.llama-vscode
**Description:** VS Code extension for local, LLM-powered code completions using llama.cpp as the backend server. Features auto-suggest, configurable context management, and support for different model sizes based on available VRAM, enabling private AI coding without cloud dependencies.

### 10. Claudable
**Link:** https://github.com/opactorai/Claudable
**Description:** Opensource alternative to Lovable that runs locally with Claude Code. Describe your app idea and watch it generate code with a live UI preview of your working app. Can deploy apps to Vercel and integrate databases with Supabase for free, making it easy to go from idea to production.

### 11. Runner
**Link:** https://runnercode.com/
**Description:** Task-based development environment where you design specs, AI agents write the code, and you review results through an integrated diff tool. Every change requires explicit approval before commit, keeping you accountable for what ships while leveraging AI for the heavy lifting.

### 12. Latitude
**Link:** https://latitude.so/
**Description:** Build autonomous AI agents by describing what you want in natural language, and it wires up models and integrations automatically. Integrates with 10,000+ tools via MCP for services like Slack, Notion, databases, or custom servers. Can self-host using Docker, Kubernetes, or PaaS, or use their managed cloud.

### 13. Inkflow
**Link:** Referenced in OpenSource AI Device post
**Description:** Generate a complete book with just a few clicks. Enter the book title, select the structure of the book, select the LLM, and Inkflow produces a draft of a 20,000+ word book saved as a .docx file for easy editing and review. Primarily for non-fiction books.

### 14. Agent.exe
**Link:** Referenced in Opensource Memory Layer post
**Description:** Free, opensource app that lets Claude 3.5 Sonnet control your computer with the computer-use API. Works on Mac, Windows, and Linux, allowing the model to perform tasks like navigating browsers and executing commands.

### 15. HuggingChat macOS
**Link:** Referenced in Opensource Memory Layer post
**Description:** Native chat app for macOS that uses opensource language models for AI-powered conversations. Provides desktop-native experience for interacting with open-source LLMs.

### 16. PaperQA2
**Link:** https://github.com/Future-House/paper-qa
**Description:** First AI agent that conducts entire scientific literature reviews autonomously. Surpasses PhD and postdoc-level biology researchers in literature research tasks. Can systematically identify contradictions within scientific literature. Open-sourced by FutureHouse with detailed research paper.

### 17. LlamaCoder
**Link:** https://llamacoder.together.ai/
**Description:** Opensource Claude Artifacts alternative that generates full React apps and components using Llama 3.1 405B. 100% free and open source. Provides instant app generation from natural language descriptions with live preview.

### 18. KTransformers
**Link:** https://github.com/kvcache-ai/ktransformers
**Description:** Framework to speed up LLM inference in hardware-constrained environments. Brings GPT-4 level code assistance locally in VS Code with optimized DeepSeek-Coder-V2 running on as little as 11GB VRAM. Includes Transformers-compatible interface and RESTful APIs.

### 19. Claude Auto Resume
**Link:** https://github.com/terryso/claude-auto-resume
**Description:** Shell script that automatically resumes Claude CLI tasks when usage limits are lifted. Detects restriction messages, waits with a countdown timer, then continues execution WITHOUT asking for permission, perfect for long-running tasks that hit rate limits.

---

## Vector Search & RAG Systems

### 1. Vectroid
**Link:** https://www.vectroid.com/
**Description:** Serverless vector search solution delivering exceptional accuracy and low latency in a cost-effective package. Splits system components (write, read, index) so they can scale separately, and stores data in layers with on-demand loading. Uses HNSW algorithm for ultra-fast, high-recall similarity search with near real-time capabilities.

### 2. Vectorize
**Link:** https://vectorize.io/
**Description:** Build AI apps with RAG faster and with less hassle. Automates creating optimized vector search indexes for RAG pipelines and keeps your data updated for real-time AI use. Handles data extraction, embedding evaluation, and integration with vector databases, eliminating the tedious parts of RAG setup.

### 3. LLM Scraper
**Link:** https://github.com/mishushakov/llm-scraper
**Description:** TypeScript library that converts webpage content into structured data using LLMs. Works with various LLM providers like OpenAI, Ollama, and GGUF. Offers features like type safety, schema definition using Zod, multiple formatting modes (HTML, markdown, text, image), making web scraping intelligent and structured.

### 4. Perplexica
**Link:** https://github.com/ItzCrazyKns/Perplexica
**Description:** Open-source alternative to Perplexity that understands your questions, searches deep into the internet, and gives you answers with proper citations. Offers different focus modes (academic, writing, YouTube, Reddit, Wolfram Alpha, etc.), Copilot Mode for query expansion, and support for local models.

### 5. Ragie.ai
**Link:** https://ragie.ai
**Description:** Fully managed RAG-as-a-Service for developers. Offers connectors for services like Google Drive, Notion, and Confluence, along with APIs for document upload and retrieval. Handles the entire pipeline—from chunking to hybrid keyword and semantic searches—so you can start with minimal setup.

---

## AI Agents & Orchestration

### 1. Scout
**Link:** https://x.com/scoutdotnew/
**Description:** Autonomous AI agent with its own virtual computer for deep research, coding, data analysis, content creation, and more. Browses the web, runs terminal commands, edits code, and creates files on its virtual computer. Can be set running on tasks that take minutes or hours while you come back later.

### 2. Dash
**Link:** https://www.usedash.ai/
**Description:** General agent that connects to your G-Suite, Slack, Notion, Linear, and more to take in personal context and perform actions. Consider it an agentic Glean that allows knowledge workers to save 2-3 hours a day of busy work by intelligently automating routine tasks.

### 3. Open Researcher
**Link:** https://github.com/mendableai/open-researcher
**Description:** Opensource agentic researcher powered by Firecrawl's web scraping and Claude's reasoning and intelligence. Searches and analyzes web content for real-time data, shows its thinking process, and responds with citations, making research transparent and verifiable.

### 4. Awesome LLM Apps
**Link:** https://github.com/Shubhamsaboo/awesome-llm-apps
**Description:** Curated collection of LLM apps with RAG, AI Agents, multi-agent teams, MCP, voice agents, and more. Uses models from OpenAI, Anthropic, Google, and open-source models like DeepSeek, Qwen, and Llama that you can run locally. Includes 100+ free step-by-step tutorials with working code.

### 5. MiniLLMFlow
**Link:** https://github.com/miniLLMFlow/miniLLMFlow
**Description:** 100-line Python framework providing the core abstraction of an LLM application. Represents tasks as a nested directed graph of LLM steps with branching and recursion for agent-like behavior. Intentionally avoids vendor-specific wrappers and is designed to be easily understood and used by LLMs for self-programming.

### 6. Smolmodels
**Link:** https://github.com/plexe-ai/smolmodels
**Description:** Open-source Python library that generates complete ML model training and inference code from natural language descriptions by combining graph search with LLM code generation. Handles the entire ML pipeline, making machine learning more accessible to non-experts.

### 7. Invent by Relevance AI
**Link:** https://relevanceai.com/invent
**Description:** Vibe code custom AI agents AND tools by simply describing what you want in plain English, no coding needed. Auto-generates the agent logic and integrates with existing apps like email and calendar. Your agent would be up and running in minutes, making agent creation accessible to everyone.

### 8. TradingAgents
**Link:** https://github.com/Tauric-Research/TradingAgents
**Description:** Multi-agent framework that simulates real-world trading firms with specialized roles including analysts, researchers, traders, and risk managers. Uses hybrid communication combining structured JSON for control flow with natural language debates for complex reasoning. Strategically mixes quick models (GPT-4o-mini) for data retrieval with reasoning models (o1-preview) for analysis. Proved effective during backtesting from January to March 2024, outperforming traditional strategies.

### 9. BabyAGI 2
**Link:** https://github.com/yoheinakajima/babyagi-2o
**Description:** Experimental Python framework for creating self-building autonomous agents capable of generating and managing their own functions. Functions are stored in a database as a graph structure. Features a no-code dashboard for function management and chat playground for agent interaction. Still experimental and should be used with caution.

### 10. Swarm
**Link:** https://github.com/openai/swarm
**Description:** OpenAI's lightweight framework for building multi-agent systems. Designed to manage interactions between multiple specialized agents, making it easy to break down complex workflows into manageable, specialized roles. Works seamlessly with tools and can be integrated with local models like Llama 3.2.

### 11. CoAgents
**Link:** Referenced in Opensource Memory Layer post
**Description:** Tool that bridges the gap between application front-end and LangGraph AI agents. Simplifies integrating custom AI agents directly into your app's UI/UX with shared state synchronization, agentic generative UI, and real-time agent-app communication. Makes building agent-native applications significantly easier.

### 12. Phidata
**Link:** https://github.com/phidatahq/phidata
**Description:** Toolkit for building AI assistants with function calling and connecting LLMs to external tools. Lets LLMs do web search, data analysis, send emails, or access application-specific logic. Designed for building agent-based systems and streamlines the setup of multi-agent applications.

---

## Infrastructure & APIs

### 1. APIPark
**Link:** https://github.com/APIParkLab/APIPark
**Description:** Opensource AI gateway and API developer portal for developers and enterprises to manage, integrate, and deploy AI services easily. Connects to over 100 AI models, standardizes API calls, and provides tools for monitoring and securing API usage, simplifying multi-model deployments.

### 2. ToolJet
**Link:** https://www.tooljet.ai/
**Description:** Low-code platform to build and deploy custom internal tools. Has a drag-and-drop app builder with 45 pre-built components to create complex applications in minutes. Connects to the most popular data sources and APIs out of the box, making internal tool development much faster.

### 3. Stanza
**Link:** https://stanza.sh/
**Description:** AI development tool that integrates with GitHub repos to provide code understanding and analysis capabilities. Three core features: natural language chat interface for codebase queries, automated code reviews on pull requests, and a developer API for building custom tools.

### 4. Vercel AI SDK Tools Registry
**Link:** https://ai-sdk-agents.vercel.app/
**Description:** Pre-built AI tools for use with the Vercel AI SDK enabling LLMs to interact with external services and APIs. These tools simplify integration of functionalities like web search, platform integrations (Discord, Slack, GitHub), and utilities (Postgres, Math) into LLM applications.

### 5. CoGenAI
**Link:** https://cogenai.kalavai.net/auth
**Description:** AI inference platform built for agent workflows, offering unlimited access to models for text, code, speech, tool use, and more. Instead of usage-based billing, runs on flat pricing with optional compute contribution to earn credits, making it cost-effective for heavy usage.

### 6. QueryDeck
**Link:** https://github.com/QueryDeck/querydeck
**Description:** Generates instant REST APIs, AI agent tools, and MCPs for Postgres using visual no-code builder. Create complex SQL queries with deep joins, nested inserts, dynamic parameters, and turn them into fully functional REST APIs. Deploy instantly or push as Node.js app to your repository.

### 7. txtai
**Link:** https://github.com/neuml/txtai
**Description:** All-in-one opensource embeddings database for semantic search, LLM orchestration and language model workflows. Combines vector databases, graph networks, and relational databases into one Python framework. Build production RAG applications with built-in source tracking and citations. Over 60 example notebooks included.

### 8. Agent Protocol (LangChain)
**Link:** Referenced in Agent Protocol post
**Description:** Framework-agnostic API specification for deploying LLM agents in production environments. Standardizes how agents handle execution runs, manage conversational threads, and interact with persistent storage. Includes built-in handling for retry mechanisms, connection drops, and traffic spikes.

### 9. aisuite
**Link:** https://github.com/andrewyng/aisuite
**Description:** Andrew Ng's Python package that makes working with multiple LLM providers simpler through a unified interface. Switch between GPT-4, Claude, Llama, or other models by changing just one string. Supports OpenAI, Anthropic, Azure, Google, AWS, Groq, Mistral, HuggingFace, and Ollama with more providers coming.

### 10. Prompt Poet
**Link:** Referenced in Last Week AI post
**Description:** Tool from Character.AI that makes writing complex prompts for LLMs easier. Uses YAML and Jinja2 instead of basic f-strings, making prompts more powerful and organized. Makes it easier for both developers and non-developers to work on and improve prompts.

### 11. torchchat
**Link:** https://github.com/pytorch/torchchat
**Description:** PyTorch tool to run LLMs like Llama 3.1 smoother and faster locally on devices, including laptops and mobile phones. Offers key features like export, quantization, and evaluation tools. Provides flexibility with Python, C++, and mobile device compatibility.

---

## Full-Stack Development

### 1. Bolt.new by StackBlitz
**Link:** https://bolt.new/
**Description:** Create, edit, run, and deploy full-stack applications quickly with a single English prompt. Provides a full development environment, solves errors automatically, and can deploy production-ready apps with just one click. Perfect for rapid prototyping and MVPs.

### 2. Claudable
**Link:** https://github.com/opactorai/Claudable
**Description:** Opensource Lovable that runs locally with Claude Code with live UI preview of your working app. Can deploy to Vercel and integrate databases with Supabase for free. Describe your app idea and watch it generate complete full-stack code in real-time.

---

## Productivity & Automation

### 1. Tackle AI
**Link:** https://www.timetackle.com/
**Description:** Automates time tracking and calendar audits, helping founders and executives align their daily actions with strategic priorities. Integrates with Google and Outlook calendars to deliver real-time insights on where time is actually being spent versus where it should be spent.

### 2. Shortcut
**Link:** https://x.com/nicochristie/status/1940440489972649989
**Description:** Autonomous Excel operator that can complete professional-level spreadsheet work, including financial modeling championship cases, in minutes in a single shot. Provides complete Excel environment with native functionality plus AI automation for data analysis, model building, and formula generation.

### 3. Merit
**Link:** https://terminal.merit.systems/
**Description:** Payment interface that allows open-source project maintainers to identify and compensate high-impact contributors based on their GitHub activity and PR contributions. Handles tax administration and uses stablecoins for global payouts, making open-source compensation easier.

### 4. Claude Auto Resume
**Link:** https://github.com/terryso/claude-auto-resume
**Description:** Shell script that automatically resumes Claude CLI tasks when usage limits are lifted. Detects restriction messages, waits with a countdown timer, then continues execution WITHOUT asking for permission. Useful for long-running tasks that hit rate limits.

### 5. AgentStack
**Link:** https://github.com/AgentOps-AI/AgentStack
**Description:** Command-line tool for quickly creating AI agent projects in Python. Provides preconfigured frameworks and tools like CrewAI, AutoGen, Mem0, MultiOn, E2B, etc., and a simple project structure. Not a low-code alternative but accelerates development setup.

### 6. Phantasm
**Link:** https://github.com/phantasmlabs/phantasm
**Description:** Toolkit to build human-in-the-loop approval layers for AI agents, letting humans monitor and guide AI workflows in real-time. Includes a server, dashboard, and client library to integrate human approval into AI agent actions before execution.

### 7. AgentServe
**Link:** https://github.com/PropsAI/agentserve
**Description:** Lightweight framework for hosting and scaling AI agents. Easy to use and integrates with existing projects and agent/LLM frameworks. Wraps your agent in a REST API and supports optional task queuing for scalability.

---

## Web Scraping & Data Extraction

### 1. AgentQL
**Link:** Referenced in Connect AI Agents post
**Description:** Framework built to connect LLMs and AI agents directly with live websites using natural language. Instead of traditional scraping methods like XPath or CSS selectors, simply describe what you're looking for and AgentQL handles the heavy lifting. Self-healing selectors keep working even as sites evolve.

### 2. LLM Scraper
**Link:** https://github.com/mishushakov/llm-scraper
**Description:** TypeScript library converting webpage content into structured data using LLMs. Works with various LLM providers like OpenAI, Ollama, and GGUF. Offers type safety, schema definition using Zod, multiple formatting modes (HTML, markdown, text, image) for intelligent, structured web scraping.

---

## Local Inference & Models

### 1. Cactus
**Link:** https://github.com/cactus-compute/cactus
**Description:** Inference engine for running LLMs, VLMs, and TTS models locally on smartphones and low-end ARM devices. Achieves 16-70 tokens/sec on typical phones depending on model size and device, faster than Llama.cpp. Makes AI accessible on edge devices without cloud dependencies.

### 2. DeepSeek R1 vs OpenAI o1
**Link:** https://r1-demo.deepset.ai/
**Description:** Live demo that compares DeepSeek R1 and OpenAI o1 models in a RAG pipeline. Key technical difference is that DeepSeek R1 shows its reasoning process through streaming output while OpenAI o1 provides complete answers at once. Useful for understanding reasoning model differences.

### 3. SmolLM3
**Link:** https://huggingface.co/blog/smollm3
**Description:** 3B parameter model from Hugging Face that outperforms Llama-3.2-3B and Qwen2.5-3B while staying competitive with larger 4B alternatives. Brings dual-mode reasoning (think/no_think), 128k context length, and multilingual support across six languages. Includes complete methodology for building competitive small-scale reasoning models.

### 4. NotebookLlama
**Link:** https://github.com/meta-llama/llama-recipes
**Description:** Meta's opensource recipe to replicate Google NotebookLM's core functionality. Transforms documents into engaging podcast-style audio using Llama 3 models and opensource text-to-speech tools. Provides flexible and customizable framework for generating podcast-style content from PDFs.

### 5. AMD OLMo
**Link:** https://huggingface.co/amd/AMD-OLMo
**Description:** AMD's first series of opensource language models featuring 1B models trained on 1.3 trillion tokens using AMD Instinct MI250 GPUs. Includes three variants: base pre-trained model, supervised fine-tuned version, and aligned version optimized for human preferences. Complete training details included.

### 6. OLMo 2
**Link:** https://allenai.org/blog/olmo2
**Description:** AI2's 7B and 13B language models trained on 5T tokens. OLMo 2 7B outperforms Llama 3.1 8B and OLMo 2 13B outperforms Qwen 2.5 7B despite lower total training FLOPs. Fully open including model weights, training data, code, and recipes.

### 7. Fireworks f1
**Link:** https://fireworks.ai/blog/fireworks-compound-ai-system-f1
**Description:** Compound AI model for complex reasoning that simplifies development by allowing declarative prompting instead of intricate system building. Available in preview with f1 and f1-mini variants that aim to match or exceed reasoning capabilities of frontier models.

### 8. Pixtral 12B
**Link:** https://huggingface.co/mistral-community/pixtral-12b-240910
**Description:** Mistral AI's first multimodal model that processes both text and images. Built on Nemo 12B with 128k context window, natively supports images of arbitrary sizes and resolutions. Outperforms opensource models like LLaVA and Phi-3 vision on key tasks. Available under Apache 2.0 license.

### 9. Jamba 1.5 (Mini & Large)
**Link:** https://huggingface.co/collections/ai21labs/jamba-15-66c44befa474a917fcf55251
**Description:** AI21 Labs' family of models built on SSM-Transformer architecture. Boasts 256K effective context window - longest in the market. Jamba 1.5 models are up to 2.5X faster on long contexts. Natively supports structured JSON output, function calling, and generating citations.

### 10. Qwen2-VL
**Link:** https://huggingface.co/Qwen/Qwen2-VL-7B
**Description:** Alibaba Cloud's vision-language model suite with significant improvements in image and video understanding. Can handle videos up to 20 minutes long, multi-image inputs, and multilingual text in images. 72B parameter model surpasses GPT-4o and Claude 3.5 Sonnet in many visual understanding tasks. Includes visual agent capabilities with function calling.

---

## Development Tools & IDEs

### 1. gptme
**Link:** Referenced in Local AI Agent post
**Description:** Opensource command-line AI assistant that brings the power of LLMs directly to your terminal. Integrates seamlessly with local tools, allowing it to execute code, manipulate files, browse the web, and use computer vision. Operates locally with confirmation prompts for safety.

### 2. Monadic Chat
**Link:** Referenced in Local AI Agent post
**Description:** Brings a full Linux environment to LLMs so you can create chatbots that execute system commands, run analyses, and handle complex computations. Opensource framework packages GPT-4, Claude, and other LLMs within Docker containers with access to external tools for tasks like web scraping and data processing.

### 3. Ditto
**Link:** Referenced in Opensource Self-building AI Coding Agent post
**Description:** Self-building coding agent that creates multi-file Flask apps from natural language descriptions. Written in roughly 500 lines of code using a straightforward LLM loop and five key tools: task_completed, fetch_code, update_file, create_file, and create_directory. Provides real-time progress tracking.

### 4. LazyLLM
**Link:** Referenced in Build & Deploy Multi-Agent LLM Apps post
**Description:** Low-code development tool designed to streamline the entire process of building sophisticated multi-agent LLM applications from initial prototype to optimized deployment. Simplifies the development workflow while maintaining flexibility for complex agent systems.

### 5. E2B Desktop Sandbox
**Link:** https://e2b.dev
**Description:** Cloud-based isolated environment that lets LLMs interact with a familiar desktop GUI. Optimized for secure "Computer Use" similar to Anthropic's approach. Launches in 300-500ms, supports customizable environments, and enables full filesystem control with programmatic keyboard/mouse input.

### 6. LangGraph Studio
**Link:** https://github.com/langchain-ai/langgraph-studio
**Description:** First dedicated IDE for AI agent development from LangChain. Offers visual and interactive way to build, debug, and understand complex LLM-powered applications. Features real-time debugging, agent graph visualization, and ability to modify code and replay nodes. Currently available for Apple Silicon.

### 7. n8n AI Starter Kit
**Link:** https://n8n.io
**Description:** Self-hosted AI starter kit with pre-configured Docker Compose template for running AI locally. Includes popular AI tools like Ollama, Qdrant, and PostgreSQL pre-configured for easy integration. Combines n8n's low-code platform with flexibility of local AI tools.

---

## Authentication & Security

### 1. AgentAuth by Composio
**Link:** https://composio.dev/agentauth
**Description:** Dedicated authentication solution that streamlines how AI agents connect with third-party services. Manages complex authentication flows across 250+ applications with single SDK handling all auth flows. Compatible with 15+ agent frameworks including LangChain, LlamaIndex, and CrewAI. Includes comprehensive webhook support for real-time connection monitoring.

### 2. Agentic LLM Vulnerability Scanner
**Link:** Referenced in Opensource Memory Layer post
**Description:** Opensource tool for testing LLM security with customizable attacks and stress testing. Integrates with LLM APIs and supports fuzzing and dataset-driven vulnerability checks to identify security weaknesses in AI applications.

---

## Monitoring & Analytics

### 1. MCPcat
**Link:** https://mcpcat.io/
**Description:** Open-source monitoring library for MCP server maintainers providing logging and observability with a single line of code. Tracks user sessions, tool calls, and agent behavior with out-of-the-box integration with existing platforms like Datadog and Sentry.

---

## Content Creation & Media

### 1. Wix AI Blog Tools
**Link:** https://www.wix.com
**Description:** Comprehensive suite of AI tools for blog creation. Generates blog post drafts in minutes complete with relevant images and SEO optimization. Analyzes website to suggest relevant topics, creates outlines or full drafts, and includes built-in SEO optimization with keyword integration.

### 2. Edit by Resemble AI
**Link:** https://www.resemble.ai/audio-editing/
**Description:** Modify audio recordings as easily as editing text using a chat interface. Includes AI voice cloning, filler word removal, and automatic audio enhancement. Streamlines audio editing workflow with AI-powered features.

### 3. D-ID Video Translation
**Link:** Referenced in Drag & Drop post
**Description:** AI video translation tool that translates videos into other languages while cloning the speaker's voice and syncing lip movements to translated words. Creates natural-looking multilingual videos with matched audio and visuals.

### 4. Adobe Firefly Video Model
**Link:** https://blog.adobe.com
**Description:** Generative AI for video editing from Adobe. Offers tools to generate b-roll, fill gaps, and create visual elements with simple text prompts. Speeds up creative video editing process with AI assistance.

### 5. WikiCrow (from PaperQA2)
**Link:** Referenced in Mistral AI post
**Description:** AI agent based on PaperQA2 that generates Wikipedia-style articles significantly more accurate than human-written Wikipedia articles. Being used by FutureHouse to write updated summaries for all human genes.

---

## AI-Powered Platforms & Applications

### 1. Truely
**Link:** https://github.com/HasflarSonto/Truely
**Description:** Opensource detection tool by Columbia students that automatically joins meetings as a monitoring bot to detect AI assistance tools like Cluely. Scans for AI assistance tools and alerts participants when suspicious processes are detected with timestamped warnings in meeting chat.

### 2. K-Scale Humanoid Robots
**Link:** https://www.kscale.dev/
**Description:** YC startup selling fully opensource humanoid robots for under $9,000, complete with hardware designs, software stack, and promise of free upgrades until full autonomy. Built first walking prototype in just two months using 3D printers and parts from Amazon and Alibaba.

### 3. Oasis
**Link:** https://oasis-model.github.io/
**Description:** First real-time, open-world AI model by Etched and Decart that generates interactive video game experience from scratch frame-by-frame using a transformer model—no game engine needed. Includes code, playable demo, and 500M parameter model that can run locally.

### 4. Nexa SDK (Qwen2-Audio)
**Link:** https://nexa.ai
**Description:** SDK that lets you run Qwen2-Audio multimodal model locally on your device. Use 'nexa run qwen2audio' command to experiment with speech processing, translation, and more with quantized versions optimized for edge deployment.

### 5. Social Studio by Captions
**Link:** Referenced in Build & Deploy post
**Description:** AI video editing platform feature that employs AI to run your social media accounts. With just a link to your website, the AI scans your website, plans content calendar, generates videos featuring you or an AI Creator, and posts across all social accounts with minimal involvement.

### 6. RouteLLM
**Link:** https://github.com/lm-sys/RouteLLM
**Description:** Automates routing between different models based on query complexity. Dynamically selects the best model for every query, optimizing both performance and cost. Allows simple queries to use efficient models while complex ones get powerful models.

### 7. Bolt.new Canvas Integration
**Link:** Referenced in Build & Deploy post
**Description:** Free and opensource alternative to Bloomberg Terminal for financial data analysis. Includes AI Copilot for complex queries, summaries, trends, and comprehensive reports. Features custom dashboards with personal datasets integration.

### 8. Fish Speech 1.4
**Link:** https://github.com/fishaudio/fish-speech
**Description:** Opensource tool that offers fast text-to-speech and instant voice cloning in 8 languages. Can self-host or use cloud service with simple pricing. Provides high-quality voice synthesis for multiple languages with minimal setup.

### 9. TuneLlama
**Link:** https://www.tunellama.com/
**Description:** Fine-tune Llama 3.1 models easily. Upload your data, choose between 8B or 70B models, and hit fine-tune. Download results in QLoRA or GGUF format. Simplifies the fine-tuning process for custom model training.

### 10. InteractiveDemo.ai
**Link:** https://InteractiveDemo.ai
**Description:** Create interactive screen demos with AI. Extracts keyframes from videos and generates popovers with information. Includes intelligent zoom, click-to-pause interaction, and animated elements for engaging presentations.

### 11. GPT Engineer
**Link:** https://gptengineer.app/
**Description:** Build web apps by chatting with AI, which generates code and provides live preview. Integrates with GitHub for version control and lets you make changes using simple language. Streamlines web development from concept to deployment.

### 12. Aider
**Link:** https://aider.chat/
**Description:** AI pair programming in your terminal. Edit code directly, working seamlessly with your local git repository. Supports various LLMs like GPT-4o and Claude 3.5 Sonnet. Provides real-time coding assistance without leaving the terminal.

### 13. KaneAI
**Link:** https://www.lambdatest.com/kane-ai
**Description:** AI-powered software testing tool that uses natural language to generate, debug, and manage automated tests across web and mobile applications. Simplifies the testing workflow with AI-driven test creation.

### 14. Outerport
**Link:** https://www.outerport.com/
**Description:** Unified registry for foundation model weights, enabling efficient inference and deployment. Offers instant hot swaps, fast cold starts, and optimized resource utilization for model management.

### 15. Scopilot
**Link:** https://www.scopilot.ai/
**Description:** AI tool that helps define and scope software projects faster by generating features, user stories, and clarification questions. Assists with product discovery and specification, streamlining project planning.

### 16. QuickVid Autopilot
**Link:** https://www.quickvid.ai/
**Description:** Create and post viral video clips from long-form content to social media channels on autopilot. Curates, edits, and posts clips daily, keeping content relevant and engaging without manual intervention.

### 17. Covalent
**Link:** https://www.covalent.xyz/
**Description:** Python tool to manage AI infrastructure across different environments. Makes the most of GPU resources, provides on-demand computing power, and supports various AI tasks like model training and image processing.

---

## Statistics

- **Total Posts Analyzed:** 30+
- **Total Unique Tools:** 130+
- **Most Featured Tool:** Awesome LLM Apps (appears in multiple analyzed posts)
- **Dominant Categories:**
  - AI-Powered Platforms & Applications: 17 tools (13%)
  - AI Coding & Development: 19 tools (15%)
  - MCP Tools: 12 tools (9%)
  - AI Agents & Orchestration: 12 tools (9%)
  - Local Inference & Models: 10 tools (8%)
  - Infrastructure & APIs: 11 tools (8%)
  - Development Tools & IDEs: 7 tools (5%)
  - Productivity & Automation: 7 tools (5%)
  - Content Creation & Media: 5 tools (4%)
- **Date Range:** March 2024 - November 2025
- **New Tools Added in This Update:** 40+

### Additional Tools Found in Recent Posts:
- **LiveKit Agents** - Multimodal AI framework
- **FalkorDB** - Graph database for RAG
- **Gemini Coder** - Next.js app generator
- **SRE Buddy** - DevOps alerting tool
- **LOTUS** - Semantic query engine
- **Computer Use (for Mac)** - Native macOS interaction
- **ask.py** - AI search engine implementation
- **expand.ai** - Website to API converter
- **Fragments by E2B** - Full-stack AI app template
- **Pandas AI** - Natural language data analysis
- **MLX-VLM** - Vision models for Mac
- **Superflex** - Figma to code converter
- **Git Pulse** - Open source project explorer
- **LlamaChunk** - Semantic document chunking
- **AgentAuth by Composio** - Multi-service authentication
- **aisuite** - Unified LLM interface

---

## Tool Count by Category

1. **AI Coding & Development Tools**: 19
2. **AI-Powered Platforms & Applications**: 17
3. **AI Agents & Orchestration**: 12
4. **MCP Tools**: 12
5. **Infrastructure & APIs**: 11
6. **Local Inference & Models**: 10
7. **Development Tools & IDEs**: 7
8. **Productivity & Automation**: 7
9. **Vector Search & RAG**: 5
10. **Content Creation & Media**: 5
11. **Authentication & Security**: 2
12. **Full-Stack Development**: 2
13. **Web Scraping & Data**: 2
14. **Monitoring**: 1

**Total Tools in Collection: 130+**

---

*This comprehensive collection represents the cutting edge of AI tooling and infrastructure as featured in the Unwind AI newsletter. All tools are actively maintained and represent production-ready solutions for building AI applications.*

## Recent Additions (August-November 2024)

The following tools were added from recent Unwind AI posts:

**Multi-Agent & Orchestration:**
- TradingAgents - Multi-agent trading firm simulation
- BabyAGI 2 - Self-building autonomous agents
- Swarm - OpenAI's multi-agent framework
- CoAgents - LangGraph integration for apps
- Phidata - AI assistant toolkit with function calling

**Local Models & Inference:**
- Pixtral 12B - Mistral AI's first multimodal model
- Jamba 1.5 - AI21's long-context models (256K tokens)
- Qwen2-VL - Alibaba's vision-language models with 20min video support
- SmolLM3 - 3B reasoning model
- NotebookLlama - Podcast generation from documents
- AMD OLMo - AMD's first LLM series
- OLMo 2 - Fully open 7B/13B models
- Fireworks f1 - Compound AI reasoning model

**AI Coding & Development:**
- PaperQA2 - Autonomous scientific literature review agent
- LlamaCoder - Opensource Claude Artifacts with Llama 3.1 405B
- KTransformers - Local GPT-4 level coding in VS Code
- Inkflow - Complete book generation tool
- Agent.exe - Computer control for Claude
- HuggingChat macOS - Native macOS LLM chat

**Development Tools & IDEs:**
- LangGraph Studio - First dedicated IDE for AI agents
- n8n AI Starter Kit - Self-hosted AI infrastructure
- E2B Desktop Sandbox - Cloud desktop for LLMs
- Ditto - Self-building Flask app agent
- LazyLLM - Low-code multi-agent development

**Content Creation & Media:**
- Wix AI Blog Tools - Complete blog creation suite
- Edit by Resemble AI - AI-powered audio editing
- D-ID Video Translation - Multilingual video with voice cloning
- Adobe Firefly Video Model - Generative AI for video editing
- WikiCrow - Wikipedia-style article generator

**AI-Powered Platforms:**
- Fish Speech 1.4 - Fast TTS and voice cloning in 8 languages
- TuneLlama - Easy Llama 3.1 fine-tuning
- InteractiveDemo.ai - Interactive screen demos with AI
- GPT Engineer - Build web apps by chatting
- Aider - AI pair programming in terminal
- KaneAI - Natural language software testing
- Outerport - Unified model weight registry
- Scopilot - AI project scoping and features
- QuickVid Autopilot - Automated viral clip creation
- Covalent - Python AI infrastructure management

**Infrastructure & Tools:**
- txtai - All-in-one embeddings database
- Agent Protocol - LangChain's production deployment spec
- aisuite - Unified LLM provider interface
- Prompt Poet - Advanced prompt management with YAML
- torchchat - Fast local LLM inference
- AgentAuth - Authentication for AI agents
- Ragie.ai - Managed RAG-as-a-Service

**Productivity & Security:**
- Claude Auto Resume - Auto-resume for rate limits
- AgentStack - AI agent project scaffolding
- Phantasm - Human-in-the-loop approval
- AgentServe - Lightweight agent hosting
- Truely - AI assistance detection
- Agentic LLM Vulnerability Scanner - Security testing

**Robotics & Hardware:**
- K-Scale Humanoid Robots - Opensource robots under $9,000
- Oasis - Real-time AI game generation

**Other Notable:**
- Nexa SDK - Local multimodal model deployment
- Social Studio by Captions - AI social media management
- RouteLLM - Intelligent model routing
