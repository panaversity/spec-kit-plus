from mcp.server.fastmcp import FastMCP
mcp = FastMCP("Spec-Kit")

@mcp.prompt()
def specify(goal: str):
    """Start the Spec-Driven Development process."""
    return f"Role: AI Architect. Goal: {goal}. Create a SPEC.md file."

@mcp.prompt()
def plan(spec_content: str):
    """Generate a plan from the spec."""
    return f"Read this spec: {spec_content}. Create a PLAN.md."

if __name__ == "__main__":
    mcp.run()
