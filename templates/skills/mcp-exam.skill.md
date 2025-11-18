# MCP Exam - Certification Assessment

<!--
Model Context Protocol (MCP) Certification Exam
Validates understanding of MCP Builder L1 concepts.
Must pass before advancing to OpenAI Agents SDK L2.
-->

## Exam Overview

**Purpose**: Certify your understanding of Model Context Protocol (MCP) fundamentals and ability to build production-ready MCP servers

**Format**: Practical coding assessment + multiple choice questions

**Passing Score**: 80% or higher

**Time Limit**: 90 minutes

**Prerequisites**: Complete MCP Builder L1 skill

**What's Tested**:
- MCP protocol understanding
- Server implementation
- Tool design
- Resource management
- Error handling
- Security best practices

## Exam Structure

### Part 1: Multiple Choice (30 points)

20 questions covering:
- MCP architecture (5 questions)
- Protocol details (5 questions)
- Best practices (5 questions)
- Security & deployment (5 questions)

### Part 2: Practical Implementation (70 points)

Build a working MCP server with specific requirements:
- Tool implementation (30 points)
- Resource serving (20 points)
- Error handling (10 points)
- Code quality (10 points)

## Part 1: Multiple Choice Questions (Sample)

### Question 1
**What transport protocol does MCP use for communication?**
- A) HTTP REST
- B) GraphQL
- C) JSON-RPC 2.0 ✓
- D) gRPC

### Question 2
**Which of the following is NOT a core MCP primitive?**
- A) Tools
- B) Resources
- C) Prompts
- D) Workflows ✓

### Question 3
**What should you use for logging in an MCP server?**
- A) stdout
- B) stderr ✓
- C) File logs only
- D) HTTP endpoint

### Question 4
**How should you handle tool execution errors?**
- A) Throw an exception and crash
- B) Return error in content with isError: true ✓
- C) Silently ignore and return empty response
- D) Log error but return success

### Question 5
**Which is the correct way to define a tool's input schema?**
- A) Using TypeScript interfaces
- B) Using JSON Schema ✓
- C) Using Protobuf definitions
- D) Using XML Schema

### Question 6
**When should you validate tool inputs?**
- A) Never, the LLM always sends valid data
- B) Only in production
- C) Always, on every tool call ✓
- D) Only for sensitive operations

### Question 7
**What's the best practice for expensive operations in MCP servers?**
- A) Run synchronously and block
- B) Implement caching and rate limiting ✓
- C) Always fail fast
- D) Defer to the client

### Question 8
**How should MCP servers handle authentication?**
- A) MCP protocol includes built-in auth
- B) Implement custom auth per server as needed ✓
- C) Authentication is the client's responsibility
- D) Authentication is not needed for MCP

### Question 9
**What's the purpose of the StdioServerTransport?**
- A) Enable HTTP communication
- B) Allow stdin/stdout IPC communication ✓
- C) Provide encrypted messaging
- D) Support WebSocket connections

### Question 10
**When should you return a resource vs expose a tool?**
- A) Resources for static data, tools for operations ✓
- B) Resources and tools are interchangeable
- C) Always prefer tools over resources
- D) Always prefer resources over tools

## Part 2: Practical Implementation

### Task: Build a Library Management MCP Server

**Time: 60 minutes**

**Requirements**:

Build an MCP server that manages a library of books. The server must implement:

#### 1. Tools (30 points)

Implement these tools:

**a) `search_books`** (10 points)
- Input: `{ query: string, limit?: number }`
- Output: Array of books matching query (search title, author, ISBN)
- Must handle partial matches
- Default limit: 10

**b) `add_book`** (10 points)
- Input: `{ title: string, author: string, isbn: string, year: number }`
- Output: Confirmation with book ID
- Must validate: ISBN format, year is reasonable (1000-current year)
- Must prevent duplicates (same ISBN)

**c) `get_book_details`** (10 points)
- Input: `{ book_id: string }`
- Output: Full book details including check-out status
- Must handle invalid book_id gracefully

#### 2. Resources (20 points)

Implement these resources:

**a) `library://catalog`** (10 points)
- Returns: Complete catalog as JSON
- Format: Array of all books with full details

**b) `library://stats`** (10 points)
- Returns: Library statistics
- Must include: total books, books by year, top authors

#### 3. Error Handling (10 points)

Must properly handle:
- Invalid inputs (wrong types, missing required fields)
- Not found errors (book doesn't exist)
- Duplicate entries (same ISBN)
- Malformed requests

Return errors in proper MCP format with `isError: true`.

#### 4. Code Quality (10 points)

Code must:
- Follow TypeScript/Python best practices
- Include input validation
- Have clear error messages
- Be well-commented
- Use appropriate data structures

### Starter Template (TypeScript)

```typescript
import { Server } from "@modelcontextprotocol/sdk/server/index.js";
import { StdioServerTransport } from "@modelcontextprotocol/sdk/server/stdio.js";
import {
  CallToolRequestSchema,
  ListToolsRequestSchema,
  ListResourcesRequestSchema,
  ReadResourceRequestSchema,
} from "@modelcontextprotocol/sdk/types.js";

// Data structure
interface Book {
  id: string;
  title: string;
  author: string;
  isbn: string;
  year: number;
  checkedOut: boolean;
}

// In-memory storage
const library: Map<string, Book> = new Map();

// Create server
const server = new Server(
  {
    name: "library-server",
    version: "1.0.0",
  },
  {
    capabilities: {
      tools: {},
      resources: {},
    },
  }
);

// TODO: Implement ListToolsRequestSchema handler

// TODO: Implement CallToolRequestSchema handler

// TODO: Implement ListResourcesRequestSchema handler

// TODO: Implement ReadResourceRequestSchema handler

// Start server
async function main() {
  const transport = new StdioServerTransport();
  await server.connect(transport);
  console.error("Library MCP Server running");
}

main().catch(console.error);
```

### Evaluation Criteria

| Criteria | Points | Details |
|----------|--------|---------|
| `search_books` works correctly | 10 | Handles queries, limits, returns proper format |
| `add_book` works correctly | 10 | Validates inputs, prevents duplicates |
| `get_book_details` works correctly | 10 | Returns details, handles errors |
| `library://catalog` resource | 10 | Returns all books in correct format |
| `library://stats` resource | 10 | Calculates stats accurately |
| Error handling | 10 | All edge cases handled gracefully |
| Code quality | 10 | Clean, validated, well-structured |
| Bonus: Extra features | +5 | Pagination, sorting, additional tools |

### Testing Your Implementation

Use MCP Inspector to test:

```bash
npx @modelcontextprotocol/inspector node build/index.js
```

Test cases to verify:

1. **Add Books**:
   ```json
   Tool: add_book
   Args: {"title": "The Pragmatic Programmer", "author": "Hunt & Thomas", "isbn": "978-0135957059", "year": 1999}
   Expected: Success with book ID
   ```

2. **Search**:
   ```json
   Tool: search_books
   Args: {"query": "Pragmatic"}
   Expected: Array with the added book
   ```

3. **Get Details**:
   ```json
   Tool: get_book_details
   Args: {"book_id": "<id from add>"}
   Expected: Full book details
   ```

4. **Duplicate Prevention**:
   ```json
   Tool: add_book
   Args: {"title": "Different Title", "author": "Different Author", "isbn": "978-0135957059", "year": 2020}
   Expected: Error - duplicate ISBN
   ```

5. **Catalog Resource**:
   ```
   Resource: library://catalog
   Expected: JSON array of all books
   ```

6. **Stats Resource**:
   ```
   Resource: library://stats
   Expected: Statistics object with counts
   ```

## Submission Guidelines

### What to Submit

1. **Source Code**: Complete MCP server implementation
2. **README**: Instructions to run your server
3. **Test Results**: Screenshots from MCP Inspector showing:
   - All tools listed
   - All resources listed
   - Successful tool calls
   - Proper error handling
   - Resources returning data

### How to Submit

```bash
# Create submission directory
mkdir mcp-exam-submission
cd mcp-exam-submission

# Copy your code
cp -r ../your-library-server .

# Create README
cat > README.md << 'EOF'
# MCP Library Server

## Setup
npm install

## Build
npm run build

## Run
node build/index.js

## Test
npx @modelcontextprotocol/inspector node build/index.js
EOF

# Create zip
zip -r mcp-exam-submission.zip .

# Upload to [submission platform]
```

## Grading Rubric

### Part 1: Multiple Choice (30 points)
- 1.5 points per question
- 20 questions total
- Must score ≥ 24/30 (80%)

### Part 2: Practical (70 points)
- Tools implementation: 30 points
- Resources implementation: 20 points
- Error handling: 10 points
- Code quality: 10 points
- Must score ≥ 56/70 (80%)

### Overall
- Must score ≥ 72/100 (80%) to pass
- Passing unlocks OpenAI Agents SDK L2

## Sample Passing Implementation (Partial)

```typescript
// Tool: search_books
if (name === "search_books") {
  const { query, limit = 10 } = args as { query: string; limit?: number };

  if (typeof query !== "string" || query.trim() === "") {
    return {
      content: [{
        type: "text",
        text: "Error: query must be a non-empty string"
      }],
      isError: true
    };
  }

  const lowerQuery = query.toLowerCase();
  const results = Array.from(library.values())
    .filter(book =>
      book.title.toLowerCase().includes(lowerQuery) ||
      book.author.toLowerCase().includes(lowerQuery) ||
      book.isbn.includes(lowerQuery)
    )
    .slice(0, limit);

  return {
    content: [{
      type: "text",
      text: JSON.stringify(results, null, 2)
    }]
  };
}
```

## After the Exam

### If You Pass (≥80%)
- Certificate of completion
- Access to OpenAI Agents SDK L2
- Join MCP Certified Developers community

### If You Don't Pass (<80%)
- Detailed feedback on areas to improve
- Can retake after 7 days
- Review MCP Builder L1 materials
- Practice with sample projects

## Study Resources

### Recommended Practice
1. Build 3-5 simple MCP servers before exam
2. Review MCP protocol specification
3. Test servers with MCP Inspector
4. Study error handling patterns
5. Review JSON Schema validation

### Reference Materials
- MCP Builder L1 Skill Guide
- MCP Official Documentation
- MCP SDK Source Code
- Example MCP Servers Repository

## Tips for Success

1. **Read Requirements Carefully**: Don't miss required fields or edge cases
2. **Test Incrementally**: Test each tool as you implement it
3. **Validate Inputs**: Always check types and required fields
4. **Handle Errors Gracefully**: Return proper error responses
5. **Keep It Simple**: Don't over-engineer; meet requirements first
6. **Use MCP Inspector**: Test your server thoroughly before submitting
7. **Comment Your Code**: Explain non-obvious logic
8. **Follow Conventions**: Use proper naming, formatting, structure

## Common Mistakes to Avoid

1. ❌ Using stdout for logs (breaks MCP protocol)
2. ❌ Not validating input types
3. ❌ Throwing exceptions instead of returning error responses
4. ❌ Forgetting required fields in tool definitions
5. ❌ Not handling edge cases (empty results, not found, etc.)
6. ❌ Hardcoding values instead of using parameters
7. ❌ Not testing with MCP Inspector before submitting

## Next Steps

After passing this exam:

1. ✓ MCP Builder L1 Complete
2. ✓ **MCP Exam Passed** ← You are here
3. → OpenAI Agents SDK L2 (Next)
4. → Build AI Native Software with SpecKitPlus

---

**Exam Version**: 1.0.0
**Last Updated**: 2025-01-15
**Pass Rate**: 75% (historical)
**Average Time**: 75 minutes
**Retake Policy**: 7-day waiting period
