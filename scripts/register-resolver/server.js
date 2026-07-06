"use strict";

const http = require("http");
const https = require("https");

const DEFAULT_ACTIVE_PATH = "/platform/h5Release/active";
const DEFAULT_REGISTER_ROUTE = "/register";
const DEFAULT_PORT = 4110;
const MAX_RESPONSE_BYTES = 1024 * 1024;

function trimTrailingSlash(value) {
  return String(value || "").replace(/\/+$/, "");
}

function normalizePath(value, fallback = "/") {
  const raw = String(value || fallback || "/").trim();
  if (!raw || raw === "/") {
    return "/";
  }
  return `/${raw.replace(/^\/+/, "").replace(/\/+$/, "")}`;
}

function appendPaths(left, right) {
  const base = trimTrailingSlash(left);
  const path = normalizePath(right);
  if (!base) {
    return path;
  }
  return `${base}${path}`;
}

function unwrapManifest(payload) {
  let manifest = payload && typeof payload === "object" && payload.data != null ? payload.data : payload;
  if (typeof manifest === "string") {
    try {
      manifest = JSON.parse(manifest);
    } catch (_) {
      return null;
    }
  }
  return manifest && typeof manifest === "object" ? manifest : null;
}

function getRoutePath(manifest, routeKey) {
  const routes = manifest && manifest.routes;
  if (Array.isArray(routes)) {
    return routes.includes(routeKey) ? routeKey : null;
  }
  if (routes && typeof routes === "object") {
    const route = routes[routeKey];
    if (!route) {
      return null;
    }
    if (typeof route === "string") {
      return route;
    }
    if (route && typeof route === "object" && typeof route.path === "string") {
      return route.path;
    }
  }
  return null;
}

function resolveRegisterTarget(payload, requestSearch = "", routeKey = DEFAULT_REGISTER_ROUTE) {
  const manifest = unwrapManifest(payload);
  if (!manifest) {
    return { ok: false, status: 502, message: "Active manifest payload is invalid" };
  }

  const routePath = getRoutePath(manifest, routeKey);
  if (!routePath) {
    return {
      ok: false,
      status: 404,
      message: `Public entry route ${routeKey} is not available in active manifest`,
    };
  }

  const assets = manifest.assets && typeof manifest.assets === "object" ? manifest.assets : manifest;
  const serviceBaseUrl = assets.serviceBaseUrl;
  const basePath = assets.basePath;
  if (!serviceBaseUrl || typeof serviceBaseUrl !== "string") {
    return { ok: false, status: 502, message: "Active manifest assets.serviceBaseUrl is missing" };
  }
  if (!basePath || typeof basePath !== "string") {
    return { ok: false, status: 502, message: "Active manifest assets.basePath is missing" };
  }

  const targetWithoutQuery = appendPaths(appendPaths(serviceBaseUrl, basePath), routePath);
  const target = `${targetWithoutQuery}${requestSearch || ""}`;
  return { ok: true, target };
}

function requestJson(url, token) {
  return new Promise((resolve, reject) => {
    const transport = url.startsWith("https:") ? https : http;
    const request = transport.request(
      url,
      {
        method: "GET",
        timeout: 15000,
        headers: {
          Accept: "application/json",
          ...(token ? { Authorization: token } : {}),
        },
      },
      (response) => {
        let size = 0;
        const chunks = [];
        response.on("data", (chunk) => {
          size += chunk.length;
          if (size > MAX_RESPONSE_BYTES) {
            request.destroy(new Error("Active manifest response is too large"));
            return;
          }
          chunks.push(chunk);
        });
        response.on("end", () => {
          const text = Buffer.concat(chunks).toString("utf8");
          if (response.statusCode < 200 || response.statusCode >= 300) {
            resolve({
              ok: false,
              statusCode: response.statusCode,
              body: text,
            });
            return;
          }
          try {
            resolve({
              ok: true,
              statusCode: response.statusCode,
              body: JSON.parse(text),
            });
          } catch (error) {
            reject(new Error(`Active manifest response is not JSON: ${error.message}`));
          }
        });
      },
    );
    request.on("timeout", () => request.destroy(new Error("Active manifest request timed out")));
    request.on("error", reject);
    request.end();
  });
}

function sendJson(response, statusCode, body) {
  const payload = JSON.stringify(body);
  response.writeHead(statusCode, {
    "Content-Type": "application/json; charset=utf-8",
    "Cache-Control": "no-store",
  });
  response.end(payload);
}

function createServer(config) {
  const registerRoute = normalizePath(config.registerRoute || DEFAULT_REGISTER_ROUTE);
  const activePath = normalizePath(config.activePath || DEFAULT_ACTIVE_PATH);
  const apiBaseUrl = trimTrailingSlash(config.apiBaseUrl);
  const activeUrl = apiBaseUrl ? appendPaths(apiBaseUrl, activePath) : "";

  return http.createServer(async (request, response) => {
    const requestUrl = new URL(request.url, "http://127.0.0.1");

    if (request.method === "GET" && requestUrl.pathname === "/health") {
      sendJson(response, 200, { ok: true });
      return;
    }

    if (request.method !== "GET" || requestUrl.pathname !== registerRoute) {
      sendJson(response, 404, { ok: false, message: "Not Found" });
      return;
    }

    if (!activeUrl) {
      sendJson(response, 500, {
        ok: false,
        message: "JAVA_H5_RELEASE_API_BASE_URL is required",
      });
      return;
    }

    try {
      const activeResponse = await requestJson(activeUrl, config.token);
      if (!activeResponse.ok) {
        console.error(
          `[register-resolver] active manifest request failed: status=${activeResponse.statusCode}`,
        );
        sendJson(response, 502, {
          ok: false,
          message: "Active manifest request failed",
          statusCode: activeResponse.statusCode,
        });
        return;
      }

      const resolved = resolveRegisterTarget(activeResponse.body, requestUrl.search, registerRoute);
      if (!resolved.ok) {
        console.error(`[register-resolver] ${resolved.message}`);
        sendJson(response, resolved.status, { ok: false, message: resolved.message });
        return;
      }

      response.writeHead(302, {
        Location: resolved.target,
        "Cache-Control": "no-store",
      });
      response.end();
    } catch (error) {
      console.error(`[register-resolver] ${error.message}`);
      sendJson(response, 502, {
        ok: false,
        message: "Active manifest resolver failed",
      });
    }
  });
}

function start() {
  const port = Number(process.env.REGISTER_RESOLVER_PORT || process.env.PORT || DEFAULT_PORT);
  const server = createServer({
    apiBaseUrl: process.env.JAVA_H5_RELEASE_API_BASE_URL,
    token: process.env.JAVA_H5_RELEASE_TOKEN,
    activePath: process.env.JAVA_H5_RELEASE_ACTIVE_PATH || DEFAULT_ACTIVE_PATH,
    registerRoute: process.env.REGISTER_ROUTE || DEFAULT_REGISTER_ROUTE,
  });

  server.listen(port, "0.0.0.0", () => {
    console.log(`[register-resolver] listening on ${port}`);
  });
}

if (require.main === module) {
  start();
}

module.exports = {
  appendPaths,
  createServer,
  normalizePath,
  resolveRegisterTarget,
  unwrapManifest,
};
