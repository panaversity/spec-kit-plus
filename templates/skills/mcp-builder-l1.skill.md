# MCP Builder L1 Skill

<!--
Model Context Protocol (MCP) Builder Level 1
This skill enables AI agents to build, test, and deploy MCP servers.
-->

## Skill Overview

**Purpose**: Build production-ready MCP (Model Context Protocol) servers that extend AI agent capabilities

**Level**: L1 (Foundation)

**Prerequisites**:
- Understanding of TypeScript/Python
- Basic knowledge of AI agent architectures
- Familiarity with JSON-RPC protocols

**Learning Outcomes**:
- Understand MCP architecture and protocol
- Build custom MCP servers for specific domains
- Implement tools, resources, and prompts
- Test and debug MCP integrations
- Deploy MCP servers for AI agents

## MCP Fundamentals

### What is MCP?

**Model Context Protocol (MCP)** is an open protocol that standardizes how AI applications interact with external data sources and tools. Think of it as a universal adapter that lets AI agents:

- Access external data (databases, APIs, filesystems)
- Use tools (calculators, code executors, web scrapers)
- Leverage domain-specific knowledge (prompts, templates)

### Architecture

```
┌─────────────────┐
│   AI Client     │ (Claude, GPT, etc.)
│   (Host)        │
└────────┬────────┘
         │ MCP Protocol
         │ (JSON-RPC 2.0)
┌────────▼────────┐
│   MCP Server    │
│  (Your Code)    │
└────────┬────────┘
         │
    ┌────┴────┐
    │  Tools  │ Resources │ Prompts
    └─────────┘
```

### Core Concepts

1. **Server**: Provides capabilities (tools, resources, prompts) to clients
2. **Tools**: Functions the AI can call (e.g., `search_database`, `calculate`)
3. **Resources**: Data the AI can read (e.g., files, API responses)
4. **Prompts**: Pre-defined prompt templates for common tasks

## Building Your First MCP Server

### Step 1: Choose Your Stack

**TypeScript/Node.js**:
```bash
npm install @modelcontextprotocol/sdk
```

**Python**:
```bash
pip install mcp
```

### Step 2: Define Your Server

**Example: Simple Calculator MCP Server (TypeScript)**

```typescript
import { Server } from "@modelcontextprotocol/sdk/server/index.js";
import { StdioServerTransport } from "@modelcontextprotocol/sdk/server/stdio.js";
import {
  CallToolRequestSchema,
  ListToolsRequestSchema,
} from "@modelcontextprotocol/sdk/types.js";

// Create server instance
const server = new Server(
  {
    name: "calculator-server",
    version: "1.0.0",
  },
  {
    capabilities: {
      tools: {},
    },
  }
);

// Define available tools
server.setRequestHandler(ListToolsRequestSchema, async () => {
  return {
    tools: [
      {
        name: "add",
        description: "Add two numbers together",
        inputSchema: {
          type: "object",
          properties: {
            a: { type: "number", description: "First number" },
            b: { type: "number", description: "Second number" },
          },
          required: ["a", "b"],
        },
      },
      {
        name: "multiply",
        description: "Multiply two numbers",
        inputSchema: {
          type: "object",
          properties: {
            a: { type: "number", description: "First number" },
            b: { type: "number", description: "Second number" },
          },
          required: ["a", "b"],
        },
      },
    ],
  };
});

// Handle tool calls
server.setRequestHandler(CallToolRequestSchema, async (request) => {
  const { name, arguments: args } = request.params;

  if (name === "add") {
    const { a, b } = args as { a: number; b: number };
    return {
      content: [
        {
          type: "text",
          text: `${a} + ${b} = ${a + b}`,
        },
      ],
    };
  }

  if (name === "multiply") {
    const { a, b } = args as { a: number; b: number };
    return {
      content: [
        {
          type: "text",
          text: `${a} × ${b} = ${a * b}`,
        },
      ],
    };
  }

  throw new Error(`Unknown tool: ${name}`);
});

// Start server
async function main() {
  const transport = new StdioServerTransport();
  await server.connect(transport);
  console.error("Calculator MCP Server running on stdio");
}

main().catch(console.error);
```

### Step 3: Configure MCP Client

**Claude Desktop Configuration** (`~/Library/Application Support/Claude/claude_desktop_config.json`):

```json
{
  "mcpServers": {
    "calculator": {
      "command": "node",
      "args": ["/path/to/calculator-server/build/index.js"]
    }
  }
}
```

### Step 4: Test Your Server

1. **Unit Tests**: Test tool functions independently
2. **Integration Tests**: Test with MCP inspector
3. **End-to-End Tests**: Test with actual AI client

## Advanced MCP Patterns

### 1. Resource Serving

Provide dynamic data to AI:

```typescript
server.setRequestHandler(ListResourcesRequestSchema, async () => {
  return {
    resources: [
      {
        uri: "file:///data/customers.json",
        name: "Customer Database",
        description: "List of all customers",
        mimeType: "application/json",
      },
    ],
  };
});

server.setRequestHandler(ReadResourceRequestSchema, async (request) => {
  const { uri } = request.params;

  if (uri === "file:///data/customers.json") {
    const customers = await loadCustomers(); // Your data loading logic
    return {
      contents: [
        {
          uri,
          mimeType: "application/json",
          text: JSON.stringify(customers, null, 2),
        },
      ],
    };
  }

  throw new Error(`Unknown resource: ${uri}`);
});
```

### 2. Prompt Templates

Provide reusable prompts:

```typescript
server.setRequestHandler(ListPromptsRequestSchema, async () => {
  return {
    prompts: [
      {
        name: "analyze_customer",
        description: "Analyze customer behavior and suggest actions",
        arguments: [
          {
            name: "customer_id",
            description: "The customer's ID",
            required: true,
          },
        ],
      },
    ],
  };
});

server.setRequestHandler(GetPromptRequestSchema, async (request) => {
  const { name, arguments: args } = request.params;

  if (name === "analyze_customer") {
    const customerId = args?.customer_id as string;
    const customerData = await fetchCustomer(customerId);

    return {
      messages: [
        {
          role: "user",
          content: {
            type: "text",
            text: `Analyze this customer's behavior and suggest next actions:\n\n${JSON.stringify(customerData, null, 2)}`,
          },
        },
      ],
    };
  }

  throw new Error(`Unknown prompt: ${name}`);
});
```

### 3. Error Handling

```typescript
server.setRequestHandler(CallToolRequestSchema, async (request) => {
  try {
    // Tool logic
    return { content: [...] };
  } catch (error) {
    return {
      content: [
        {
          type: "text",
          text: `Error: ${error.message}`,
        },
      ],
      isError: true,
    };
  }
});
```

## Real-World MCP Server Examples

### Example 1: Database Query Server

**Use Case**: Let AI query a PostgreSQL database

**Tools**:
- `execute_query`: Run SQL queries
- `list_tables`: Show available tables
- `describe_table`: Get table schema

**Resources**:
- `schema://database`: Full database schema

### Example 2: Web Scraper Server

**Use Case**: Let AI scrape and analyze web pages

**Tools**:
- `fetch_page`: Get page content
- `extract_data`: Extract structured data with selectors
- `search_site`: Search within a website

### Example 3: File System Server

**Use Case**: Let AI read/write files securely

**Tools**:
- `read_file`: Read file contents
- `write_file`: Create/update files
- `list_directory`: Browse directories

**Resources**:
- `file:///path/to/file`: Individual file access

## Testing & Debugging

### Use MCP Inspector

```bash
npx @modelcontextprotocol/inspector node path/to/your/server.js
```

Opens a web UI to:
- Test tools interactively
- Inspect resources
- Try prompts
- Debug issues

### Logging

```typescript
// Use stderr for logs (stdout is for protocol communication)
console.error("Processing request:", request);
```

### Common Issues

1. **Server doesn't start**: Check stdio transport configuration
2. **Tools not appearing**: Verify ListToolsRequestSchema handler
3. **Calls failing**: Check inputSchema matches actual arguments
4. **Performance**: Implement caching for expensive operations

## Deployment

### Local Development

1. Build your server: `npm run build` or `tsc`
2. Update MCP client config with path
3. Restart AI client

### Production

1. **Package**: Bundle server with dependencies
2. **Deploy**: Host on server or edge function
3. **Security**: Implement authentication, rate limiting
4. **Monitoring**: Log usage, errors, performance

### Security Best Practices

- Validate all inputs
- Sanitize queries (prevent SQL injection)
- Rate limit expensive operations
- Use read-only access where possible
- Implement authentication for sensitive data

## Practice Exercises

### Exercise 1: Weather MCP Server

Build an MCP server that:
- Has a `get_weather` tool that takes city name
- Returns current weather (can use mock data or real API)
- Provides a `weather_forecast` prompt template

### Exercise 2: Todo List MCP Server

Build an MCP server that:
- Stores todos in memory or file
- Tools: `add_todo`, `list_todos`, `complete_todo`, `delete_todo`
- Resource: `todos://all` returns all todos as JSON

### Exercise 3: Code Analyzer MCP Server

Build an MCP server that:
- Analyzes code files for issues
- Tools: `analyze_file`, `suggest_improvements`
- Resources: Access to project files

## Next Steps

After mastering MCP Builder L1:

1. **MCP Exam**: Test your knowledge with certification exam
2. **Advanced MCP Patterns**: Learn about streaming, subscriptions, complex protocols
3. **Integration**: Combine MCP servers with OpenAI Agents SDK
4. **Production**: Deploy MCP servers at scale

## Resources

- MCP Official Docs: https://modelcontextprotocol.io
- MCP SDK GitHub: https://github.com/modelcontextprotocol/sdk
- Example Servers: https://github.com/modelcontextprotocol/servers
- Community: MCP Discord/Forum

---

**Skill Version**: 1.0.0
**Last Updated**: 2025-01-15
**Next Skill**: MCP Exam → OpenAI Agents SDK L2
