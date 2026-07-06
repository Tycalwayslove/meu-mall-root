"use strict";

const assert = require("assert/strict");
const http = require("http");
const {
  createServer,
  resolveRegisterTarget,
} = require("./server");

async function withServer(server, run) {
  await new Promise((resolve) => server.listen(0, "127.0.0.1", resolve));
  const { port } = server.address();
  try {
    return await run(`http://127.0.0.1:${port}`);
  } finally {
    await new Promise((resolve) => server.close(resolve));
  }
}

async function request(url) {
  return new Promise((resolve, reject) => {
    http
      .request(url, { method: "GET" }, (response) => {
        response.resume();
        response.on("end", () => resolve(response));
      })
      .on("error", reject)
      .end();
  });
}

async function main() {
  const manifest = {
    stableVersion: "v1.0.29",
    assets: {
      serviceBaseUrl: "https://hybird.aigcpop.com",
      basePath: "/h5-v/v1.0.29",
    },
    routes: {
      "/register": {
        path: "/register",
      },
    },
  };

  assert.deepEqual(
    resolveRegisterTarget(manifest, "?utm=qr").target,
    "https://hybird.aigcpop.com/h5-v/v1.0.29/register?utm=qr",
  );

  assert.deepEqual(
    resolveRegisterTarget({ data: JSON.stringify(manifest) }).target,
    "https://hybird.aigcpop.com/h5-v/v1.0.29/register",
  );

  assert.deepEqual(
    resolveRegisterTarget({ ...manifest, routes: ["/", "/register"] }).target,
    "https://hybird.aigcpop.com/h5-v/v1.0.29/register",
  );

  assert.equal(resolveRegisterTarget({ ...manifest, routes: ["/"] }).status, 404);
  assert.equal(resolveRegisterTarget({ ...manifest, assets: {} }).status, 502);

  const activeServer = http.createServer((_, response) => {
    response.writeHead(200, { "Content-Type": "application/json" });
    response.end(JSON.stringify({ data: manifest }));
  });

  await withServer(activeServer, async (activeBaseUrl) => {
    const resolverServer = createServer({ apiBaseUrl: activeBaseUrl });
    await withServer(resolverServer, async (resolverBaseUrl) => {
      const response = await request(`${resolverBaseUrl}/register?invite=123`);
      assert.equal(response.statusCode, 302);
      assert.equal(
        response.headers.location,
        "https://hybird.aigcpop.com/h5-v/v1.0.29/register?invite=123",
      );
    });
  });

  console.log("register resolver tests passed");
}

main().catch((error) => {
  console.error(error);
  process.exit(1);
});
