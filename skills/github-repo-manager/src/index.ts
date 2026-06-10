import { Server } from "@modelcontextprotocol/sdk/server/index.js";
import { StdioServerTransport } from "@modelcontextprotocol/sdk/server/stdio.js";
import {
  CallToolRequestSchema,
  ListToolsRequestSchema,
} from "@modelcontextprotocol/sdk/types.js";
import { spawn } from "child_process";

function gh(args: string[]): Promise<string> {
  return new Promise((resolve, reject) => {
    const proc = spawn("gh", args, { shell: true });
    let stdout = "";
    let stderr = "";
    proc.stdout?.on("data", (data: Buffer) => (stdout += data.toString()));
    proc.stderr?.on("data", (data: Buffer) => (stderr += data.toString()));
    proc.on("close", (code: number | null) => {
      if (code === 0) resolve(stdout.trim());
      else reject(new Error(stderr || `Exit code: ${code}`));
    });
    proc.on("error", reject);
  });
}

const tools = [
  {
    name: "gh_list_repos",
    description: "List repositories for a user or organization",
    inputSchema: {
      type: "object",
      properties: {
        user: { type: "string", description: "Username or org name" },
        limit: { type: "number", description: "Number of repos to fetch (default 100)", default: 100 },
        visibility: { type: "string", enum: ["public", "private", "all"], description: "Filter by visibility" },
      },
      required: ["user"],
    },
  },
  {
    name: "gh_view_repo",
    description: "View details of a specific repository",
    inputSchema: {
      type: "object",
      properties: {
        owner: { type: "string", description: "Owner of the repository" },
        repo: { type: "string", description: "Repository name" },
      },
      required: ["owner", "repo"],
    },
  },
  {
    name: "gh_create_repo",
    description: "Create a new repository",
    inputSchema: {
      type: "object",
      properties: {
        name: { type: "string", description: "Repository name" },
        visibility: { type: "string", enum: ["public", "private"], description: "Public or private" },
        description: { type: "string", description: "Repository description" },
        clone: { type: "boolean", description: "Clone the repo locally after creation", default: false },
      },
      required: ["name", "visibility"],
    },
  },
  {
    name: "gh_delete_repo",
    description: "Delete a repository (⚠️ permanent)",
    inputSchema: {
      type: "object",
      properties: {
        owner: { type: "string", description: "Owner of the repository" },
        repo: { type: "string", description: "Repository name" },
      },
      required: ["owner", "repo"],
    },
  },
  {
    name: "gh_search_repos",
    description: "Search repositories by keyword or owner",
    inputSchema: {
      type: "object",
      properties: {
        query: { type: "string", description: "Search query" },
        owner: { type: "string", description: "Filter by owner" },
        limit: { type: "number", description: "Number of results (default 20)", default: 20 },
      },
    },
  },
  {
    name: "gh_edit_repo",
    description: "Edit repository settings (visibility, description, archive)",
    inputSchema: {
      type: "object",
      properties: {
        owner: { type: "string", description: "Owner of the repository" },
        repo: { type: "string", description: "Repository name" },
        visibility: { type: "string", enum: ["public", "private"], description: "Change visibility" },
        description: { type: "string", description: "Update description" },
        archive: { type: "boolean", description: "Archive/unarchive the repository" },
      },
      required: ["owner", "repo"],
    },
  },
  {
    name: "gh_fork_repo",
    description: "Fork a repository to your account",
    inputSchema: {
      type: "object",
      properties: {
        owner: { type: "string", description: "Owner of the repository" },
        repo: { type: "string", description: "Repository name" },
      },
      required: ["owner", "repo"],
    },
  },
  {
    name: "gh_rename_repo",
    description: "Rename a repository",
    inputSchema: {
      type: "object",
      properties: {
        newName: { type: "string", description: "New repository name" },
      },
      required: ["newName"],
    },
  },
];

interface Args {
  [key: string]: unknown;
}

const server = new Server(
  { name: "github-repo-manager", version: "1.0.0" },
  { capabilities: { tools: {} } }
);

server.setRequestHandler(ListToolsRequestSchema, async () => ({ tools }));

server.setRequestHandler(CallToolRequestSchema, async (request) => {
  const { name, arguments: args } = request.params as { name: string; arguments: Args };

  try {
    let result: string;

    switch (name) {
      case "gh_list_repos": {
        const user = args.user as string;
        const limit = (args.limit as number) || 100;
        const visibility = args.visibility as string | undefined;
        const cmd = ["repo", "list", user, "--limit", String(limit)];
        if (visibility && visibility !== "all") cmd.push("--visibility", visibility);
        cmd.push("--json", "name,visibility,description,createdAt,updatedAt,url");
        result = await gh(cmd);
        break;
      }
      case "gh_view_repo": {
        const owner = args.owner as string;
        const repo = args.repo as string;
        const cmd = ["repo", "view", `${owner}/${repo}`, "--json", "name,description,visibility,defaultBranch,url,createdAt,updatedAt,pushedAt,isFork,isArchived"];
        result = await gh(cmd);
        break;
      }
      case "gh_create_repo": {
        const nameVal = args.name as string;
        const visibility = args.visibility as string;
        const cmd = ["repo", "create", nameVal, `--${visibility}`];
        if (args.description) cmd.push("--description", args.description as string);
        if (args.clone) cmd.push("--clone");
        result = await gh(cmd);
        break;
      }
      case "gh_delete_repo": {
        const owner = args.owner as string;
        const repo = args.repo as string;
        result = await gh(["repo", "delete", `${owner}/${repo}`, "--confirm"]);
        break;
      }
      case "gh_search_repos": {
        const query = args.query as string | undefined;
        const owner = args.owner as string | undefined;
        const limit = (args.limit as number) || 20;
        const cmd = ["search", "repos"];
        if (query) cmd.push(query);
        if (owner) cmd.push("--owner", owner);
        cmd.push("--limit", String(limit));
        cmd.push("--json", "name,description,visibility,url,createdAt,owner");
        result = await gh(cmd);
        break;
      }
      case "gh_edit_repo": {
        const owner = args.owner as string;
        const repo = args.repo as string;
        const cmd = ["repo", "edit", `${owner}/${repo}`];
        if (args.visibility) cmd.push("--visibility", args.visibility as string);
        if (args.description !== undefined) cmd.push("--description", (args.description as string) || "");
        if (args.archive !== undefined) cmd.push(args.archive ? "--archive" : "--unarchive");
        result = await gh(cmd);
        break;
      }
      case "gh_fork_repo": {
        const owner = args.owner as string;
        const repo = args.repo as string;
        result = await gh(["repo", "fork", `${owner}/${repo}`]);
        break;
      }
      case "gh_rename_repo": {
        const newName = args.newName as string;
        result = await gh(["repo", "rename", newName]);
        break;
      }
      default:
        throw new Error(`Unknown tool: ${name}`);
    }

    return { content: [{ type: "text", text: result || "Success" }] };
  } catch (error: unknown) {
    const message = error instanceof Error ? error.message : String(error);
    return { content: [{ type: "text", text: `Error: ${message}` }], isError: true };
  }
});

const transport = new StdioServerTransport();
await server.connect(transport);