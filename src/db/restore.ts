import { mkdtemp, rm } from "node:fs/promises";
import { tmpdir } from "node:os";
import path from "node:path";
import { spawn } from "node:child_process";

function requireEnv(name: string): string {
  const value = process.env[name];
  if (!value) throw new Error(`Missing required environment variable: ${name}`);
  return value;
}

function run(command: string, args: string[], env: NodeJS.ProcessEnv = process.env): Promise<void> {
  return new Promise((resolve, reject) => {
    const child = spawn(command, args, {
      stdio: "inherit",
      env,
    });

    child.on("error", reject);
    child.on("exit", (code) => {
      if (code === 0) {
        resolve();
        return;
      }
      reject(new Error(`${command} exited with code ${code ?? "unknown"}`));
    });
  });
}

async function main(): Promise<void> {
  const dumpUrl = requireEnv("DUMP_URL");
  const host = requireEnv("DB_HOST");
  const port = process.env.DB_PORT ?? "5432";
  const database = process.env.DB_NAME ?? "optcg";
  const user = requireEnv("DB_USER");
  const password = requireEnv("DB_PASSWORD");

  const clean = process.env.RESTORE_CLEAN !== "false";
  const jobs = process.env.RESTORE_JOBS ?? "1";

  const tempDir = await mkdtemp(path.join(tmpdir(), "optcg-restore-"));
  const dumpPath = path.join(tempDir, "database.dump");

  try {
    console.log(`Downloading dump from ${dumpUrl} ...`);
    await run("curl", ["-fL", dumpUrl, "-o", dumpPath]);

    const pgEnv = {
      ...process.env,
      PGPASSWORD: password,
    };

    const args = [
      "--verbose",
      "--no-owner",
      "--no-privileges",
      "--host",
      host,
      "--port",
      port,
      "--username",
      user,
      "--dbname",
      database,
      "--jobs",
      jobs,
    ];

    if (clean) {
      args.push("--clean", "--if-exists");
    }

    args.push(dumpPath);

    console.log(`Restoring dump into ${database}@${host}:${port} ...`);
    await run("pg_restore", args, pgEnv);
    console.log("Restore completed successfully.");
  } finally {
    await rm(tempDir, { recursive: true, force: true });
  }
}

main().catch((error) => {
  console.error("Restore failed");
  console.error(error);
  process.exitCode = 1;
});
