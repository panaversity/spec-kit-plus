# OpenAI Agents SDK L2 Skill

<!--
OpenAI Agents SDK Level 2
This skill enables building production-grade AI agents using OpenAI's Agents SDK.
Combined with MCP, this creates powerful, scalable agent systems.
-->

## Skill Overview

**Purpose**: Build production-grade AI agents using OpenAI Agents SDK that can reason, use tools, and collaborate

**Level**: L2 (Advanced)

**Prerequisites**:
- MCP Builder L1 (completed)
- Understanding of OpenAI API
- Async programming (Python/TypeScript)
- Agent architecture concepts

**Learning Outcomes**:
- Build OpenAI agents with custom tools
- Implement multi-agent systems
- Integrate MCP servers with agents
- Handle agent handoffs and collaboration
- Deploy scalable agent architectures

## OpenAI Agents SDK Fundamentals

### What is an Agent?

An **agent** is an AI system that can:
1. **Reason** about tasks using LLMs
2. **Use tools** to take actions
3. **Maintain context** across interactions
4. **Collaborate** with other agents
5. **Learn** from feedback

### Architecture

```
┌─────────────────────────────────┐
│      Orchestration Layer        │
│    (Swarm/Agent Framework)      │
└────────────┬────────────────────┘
             │
    ┌────────┴──────────┐
    │                   │
┌───▼────┐        ┌────▼───┐
│ Agent 1│        │Agent 2 │
│        │◄──────►│        │
│ + Tools│ Handoff│+ Tools │
└────┬───┘        └────┬───┘
     │                 │
     │                 │
┌────▼─────────────────▼────┐
│     MCP Servers            │
│  (Tools & Resources)       │
└────────────────────────────┘
```

## Getting Started with OpenAI Agents SDK

### Installation

```bash
pip install openai-agents-sdk
# or
npm install openai-agents-sdk
```

### Basic Agent Setup (Python)

```python
from openai_agents import Agent, AgentConfig
from openai import OpenAI

client = OpenAI(api_key="your-api-key")

# Define agent configuration
config = AgentConfig(
    name="customer_support_agent",
    instructions="""You are a helpful customer support agent.
    You can help users with orders, returns, and general inquiries.
    Be friendly, professional, and concise.""",
    model="gpt-4o",
    temperature=0.7,
)

# Create agent
agent = Agent(client=client, config=config)

# Run agent
response = agent.run(
    thread_id="user_123",
    message="I want to return my order #12345"
)

print(response.message)
```

## Adding Tools to Agents

### Define Custom Tools

```python
from openai_agents import Tool

def get_order_status(order_id: str) -> dict:
    """Retrieve the status of an order."""
    # Your business logic here
    return {
        "order_id": order_id,
        "status": "shipped",
        "tracking": "1Z999AA10123456784",
        "estimated_delivery": "2025-01-20"
    }

def process_return(order_id: str, reason: str) -> dict:
    """Process a return request."""
    # Your business logic here
    return {
        "return_id": "RET-" + order_id,
        "status": "approved",
        "refund_amount": 49.99,
        "return_label": "https://example.com/label/xyz"
    }

# Define tools
tools = [
    Tool(
        name="get_order_status",
        description="Get the current status of an order",
        function=get_order_status,
        parameters={
            "type": "object",
            "properties": {
                "order_id": {
                    "type": "string",
                    "description": "The order ID to check"
                }
            },
            "required": ["order_id"]
        }
    ),
    Tool(
        name="process_return",
        description="Process a return request for an order",
        function=process_return,
        parameters={
            "type": "object",
            "properties": {
                "order_id": {
                    "type": "string",
                    "description": "The order ID to return"
                },
                "reason": {
                    "type": "string",
                    "description": "Reason for return"
                }
            },
            "required": ["order_id", "reason"]
        }
    ),
]

# Create agent with tools
agent = Agent(
    client=client,
    config=config,
    tools=tools
)
```

### Tool Execution Flow

```python
# User input
message = "What's the status of order #12345?"

# Agent reasoning
# 1. Understands user wants order status
# 2. Identifies get_order_status tool
# 3. Extracts order_id parameter
# 4. Calls tool
# 5. Receives result
# 6. Formulates response

response = agent.run(thread_id="user_123", message=message)
# → "Your order #12345 has shipped! The tracking number is..."
```

## Multi-Agent Systems with Handoffs

### Agent Handoff Pattern

```python
from openai_agents import Agent, handoff

# Agent 1: Triage (determines user intent)
triage_agent = Agent(
    client=client,
    config=AgentConfig(
        name="triage",
        instructions="""Determine if user needs:
        - Order support → hand off to order_agent
        - Returns → hand off to returns_agent
        - General inquiry → answer directly
        """,
        model="gpt-4o-mini",  # Faster, cheaper for triage
    )
)

# Agent 2: Order Support (specialized)
order_agent = Agent(
    client=client,
    config=AgentConfig(
        name="order_support",
        instructions="""You help with order-related questions.
        You can check status, track packages, and modify orders.""",
        model="gpt-4o",
    ),
    tools=[get_order_status_tool, modify_order_tool]
)

# Agent 3: Returns (specialized)
returns_agent = Agent(
    client=client,
    config=AgentConfig(
        name="returns",
        instructions="""You process returns and refunds.
        Be empathetic and process returns quickly.""",
        model="gpt-4o",
    ),
    tools=[process_return_tool, check_return_policy_tool]
)

# Define handoff functions
@handoff(to=order_agent)
def transfer_to_order_support(context: str):
    """Transfer to order support agent."""
    return {"context": context}

@handoff(to=returns_agent)
def transfer_to_returns(context: str):
    """Transfer to returns agent."""
    return {"context": context}

# Add handoff tools to triage agent
triage_agent.tools = [
    transfer_to_order_support,
    transfer_to_returns
]

# Run multi-agent flow
result = triage_agent.run(
    thread_id="user_123",
    message="I need to return my order"
)
# Triage → identifies return intent → hands off to returns_agent
# Returns agent → processes return using its tools
```

## Integrating MCP Servers with Agents

### Connect MCP Tools to Agent

```python
from openai_agents import Agent, MCPTool
from mcp import Client as MCPClient

# Connect to your MCP server
mcp_client = MCPClient(
    server_params={
        "command": "node",
        "args": ["path/to/your/mcp-server.js"]
    }
)

# Discover tools from MCP server
mcp_tools = mcp_client.list_tools()

# Convert MCP tools to Agent tools
agent_tools = [
    MCPTool.from_mcp(tool, mcp_client)
    for tool in mcp_tools
]

# Create agent with MCP tools
agent = Agent(
    client=client,
    config=config,
    tools=agent_tools
)

# Now agent can use all MCP server capabilities!
```

### Example: Legal Research Agent + MCP

```python
# MCP Server provides:
# - search_cases(query) → finds relevant legal cases
# - get_case_details(case_id) → retrieves case info
# - analyze_precedent(case_id, current_case) → compares cases

legal_agent = Agent(
    client=client,
    config=AgentConfig(
        name="legal_research",
        instructions="""You are a legal research assistant.
        Use the search_cases tool to find relevant precedents.
        Analyze cases thoroughly and cite sources.""",
        model="gpt-4o",
    ),
    tools=mcp_tools  # All legal research tools from MCP
)

# User query
response = legal_agent.run(
    thread_id="lawyer_456",
    message="Find precedents for data breach liability in California"
)

# Agent will:
# 1. Call search_cases("data breach liability California")
# 2. Get top cases
# 3. Call get_case_details for each
# 4. Call analyze_precedent to compare
# 5. Synthesize findings into response
```

## Advanced Agent Patterns

### 1. Agent with Memory (RAG)

```python
from openai_agents import Agent, VectorStore

# Create vector store for long-term memory
vector_store = VectorStore(
    client=client,
    name="customer_history"
)

# Add documents to memory
vector_store.add_documents([
    {"customer_id": "123", "content": "Previous order: laptop, happy with service"},
    {"customer_id": "123", "content": "Complained about shipping delay once"},
])

# Agent with memory
agent = Agent(
    client=client,
    config=config,
    tools=tools,
    vector_store=vector_store,  # Agent can search memory
)

# Agent will automatically search memory for relevant context
response = agent.run(
    thread_id="user_123",
    message="I want to order another laptop"
)
# → Agent knows about previous laptop purchase and satisfaction
```

### 2. Supervisor Agent Pattern

```python
from openai_agents import SupervisorAgent

# Create specialized agents
research_agent = Agent(...)
writing_agent = Agent(...)
review_agent = Agent(...)

# Create supervisor
supervisor = SupervisorAgent(
    client=client,
    config=AgentConfig(
        name="supervisor",
        instructions="""Coordinate a team of agents to complete tasks.
        - Research agent: gathers information
        - Writing agent: drafts content
        - Review agent: checks quality

        Assign tasks to appropriate agents and synthesize results.""",
    ),
    agents=[research_agent, writing_agent, review_agent]
)

# Complex task
result = supervisor.run(
    message="Write a comprehensive report on AI trends in healthcare"
)

# Supervisor will:
# 1. Assign research_agent to gather data
# 2. Assign writing_agent to draft report
# 3. Assign review_agent to check quality
# 4. Iterate if needed
# 5. Return final report
```

### 3. Human-in-the-Loop

```python
from openai_agents import Agent, requires_approval

@requires_approval
def execute_payment(amount: float, account: str):
    """Execute a payment (requires human approval)."""
    # This tool will pause and ask for human approval
    return process_payment(amount, account)

agent = Agent(
    client=client,
    config=config,
    tools=[execute_payment]
)

# When agent wants to execute payment:
response = agent.run(
    thread_id="user_123",
    message="Pay invoice #789"
)

if response.requires_approval:
    # Show approval UI to human
    approval = get_human_approval(response.pending_action)

    if approval:
        # Continue with approved action
        final_response = agent.continue_with_approval(response.id)
    else:
        # Reject and ask agent for alternative
        final_response = agent.reject_action(response.id, reason="User declined")
```

## Production Best Practices

### 1. Error Handling

```python
from openai_agents import Agent, AgentError

try:
    response = agent.run(thread_id="user_123", message=message)
except AgentError as e:
    if e.type == "tool_error":
        # Tool execution failed
        handle_tool_error(e)
    elif e.type == "rate_limit":
        # Rate limited
        retry_with_backoff(e)
    elif e.type == "timeout":
        # Agent took too long
        handle_timeout(e)
    else:
        # Other error
        log_error(e)
        return fallback_response()
```

### 2. Monitoring & Logging

```python
from openai_agents import Agent, AgentLogger

logger = AgentLogger(
    log_level="INFO",
    log_to="file",  # or "cloud", "datadog", etc.
)

agent = Agent(
    client=client,
    config=config,
    logger=logger
)

# Logs will include:
# - Tool calls and results
# - Reasoning traces
# - Token usage
# - Latency metrics
# - Errors and retries
```

### 3. Cost Optimization

```python
config = AgentConfig(
    name="cost_optimized_agent",
    model="gpt-4o-mini",  # Use cheaper model when possible
    temperature=0.3,  # Lower temp = more deterministic = fewer retries
    max_tokens=500,  # Limit response length
    parallel_tool_calls=True,  # Call multiple tools at once
)

# Use caching for expensive operations
@cache(ttl=3600)  # Cache for 1 hour
def expensive_tool_call(params):
    # Expensive operation
    pass
```

### 4. Testing Agents

```python
import pytest
from openai_agents import MockClient

def test_customer_support_agent():
    # Use mock client for testing
    mock_client = MockClient(
        responses={
            "get_order_status": {"status": "shipped"},
        }
    )

    agent = Agent(client=mock_client, config=config, tools=tools)

    response = agent.run(
        thread_id="test_123",
        message="What's my order status?"
    )

    assert "shipped" in response.message.lower()
    assert mock_client.tool_called("get_order_status")
```

## Real-World Agent Examples

### Example 1: Customer Support Agent

**Capabilities**:
- Answer FAQs
- Check order status
- Process returns
- Escalate to human when needed

**Tools**:
- MCP server with CRM integration
- Knowledge base search
- Ticketing system integration

### Example 2: Research Assistant Agent

**Capabilities**:
- Search academic papers
- Summarize findings
- Generate citations
- Draft literature reviews

**Tools**:
- MCP server for PubMed, arXiv APIs
- PDF extraction tools
- Citation formatting

### Example 3: Code Review Agent

**Capabilities**:
- Review pull requests
- Suggest improvements
- Check style compliance
- Run security scans

**Tools**:
- MCP server for GitHub API
- Static analysis tools
- Security scanners

## Practice Exercises

### Exercise 1: Travel Booking Agent

Build a multi-agent system:
- **Triage Agent**: Determines if user wants flights, hotels, or both
- **Flights Agent**: Searches and books flights
- **Hotels Agent**: Searches and books hotels
- **Supervisor Agent**: Coordinates the booking process

### Exercise 2: Content Creation Pipeline

Build a pipeline with:
- **Research Agent**: Gathers information on topic
- **Outline Agent**: Creates content outline
- **Writing Agent**: Drafts content sections
- **Editor Agent**: Reviews and improves content

### Exercise 3: Data Analysis Agent

Build an agent that:
- Connects to database via MCP
- Understands natural language queries
- Generates SQL
- Visualizes results
- Provides insights

## Integration with SpecKitPlus Workflow

When building AI Native Software with SpecKitPlus:

1. **Domain Knowledge** (`/sp.agent.domain_knowledge`):
   - Defines what agents need to do
   - Identifies tools needed

2. **Business Success Evals** (`/sp.agent.business_success_evals`):
   - Defines agent quality metrics
   - Sets performance targets

3. **Implement Agents**:
   - Build agents using this SDK
   - Connect MCP servers for tools
   - Test against evals

4. **Deploy & Monitor**:
   - Production deployment
   - Monitor agent performance against evals
   - Iterate based on feedback

## Next Steps

After mastering OpenAI Agents SDK L2:

1. **Advanced Multi-Agent Patterns**: Hierarchical agents, agent swarms
2. **Production Deployment**: Scaling, monitoring, cost optimization
3. **Custom Agent Frameworks**: Build your own agent orchestration
4. **Agent Security**: Auth, sandboxing, safety constraints

## Resources

- OpenAI Agents SDK Docs: https://platform.openai.com/docs/agents
- Swarm Framework: https://github.com/openai/swarm
- Agent Examples: https://github.com/openai/agents-examples
- Community: OpenAI Developer Forum

---

**Skill Version**: 1.0.0
**Last Updated**: 2025-01-15
**Prerequisites**: MCP Builder L1, MCP Exam
**Part of**: SpecKitPlus AI Native Software Development
