```
graph TB
    subgraph "The Orchestrator Layer (PaaS)"
        n8n[("n8n Workflow Engine<br/>(Self-Hosted on 1GB VPS)")]
        style n8n fill:#ff6d5a,stroke:#333,stroke-width:2px,color:white
    end

    subgraph "The Brain Layer (MaaS - Inference API)"
        Groq[("Groq API<br/>(Llama 3 70B)")]
        style Groq fill:#00d084,stroke:#333,stroke-width:2px,color:white
        Together[("Together AI<br/>(Mixtral/Qwen)")]
        style Together fill:#00d084,stroke:#333,stroke-width:2px,color:white
    end

    subgraph "The Logic Layer (FaaS - Serverless GPU)"
        Modal[("Modal.com<br/>(Python Agents)")]
        style Modal fill:#ff9f43,stroke:#333,stroke-width:2px,color:white
        Beam[("Beam.cloud<br/>(Custom Scripts)")]
        style Beam fill:#ff9f43,stroke:#333,stroke-width:2px,color:white
    end

    subgraph "The Memory Layer (Database)"
        Supabase[("Supabase<br/>(PostgreSQL + Vector)")]
        style Supabase fill:#3ecf8e,stroke:#333,stroke-width:2px,color:white
    end

    %% Connections
    n8n -- "1. Send Prompt (HTTP)" --> Groq
    Groq -- "2. Return Text" --> n8n

    n8n -- "3. Trigger Job (Webhook)" --> Modal
    Modal -- "4. Execute Complex Logic" --> Modal
    Modal -- "5. Return Result" --> n8n

    n8n -- "6. Store/Retrieve Data" --> Supabase

    %% Styling for connections
    linkStyle 0,1 stroke:#00d084,stroke-width:2px
    linkStyle 2,3,4 stroke:#ff9f43,stroke-width:2px
    linkStyle 5 stroke:#3ecf8e,stroke-width:2px
```





Category,"Your ""Mental Model""",Technical Term,Top Providers
IaaS,"""Raw VPS""",Infrastructure-as-a-Service,"Vast.ai (Rentals), Oracle (Free), DigitalOcean"
PaaS,"""Managed App Host""",Platform-as-a-Service,"Hugging Face Spaces, Koyeb, Railway, Render"
FaaS,"""Agent Logic Host""",Serverless GPU,"Modal, Beam.cloud, RunPod Serverless"
MaaS,"""The Brain / API""",Inference-as-a-Service,"Hugging Face (Serverless API), Groq, Together AI, OpenRouter"
AaaS,"""Agent Sandbox""",Agent Infrastructure,"E2B (Code Execution), Relevance AI"
