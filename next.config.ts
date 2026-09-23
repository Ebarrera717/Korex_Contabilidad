import type { NextConfig } from "next";

const nextConfig: NextConfig = {
  output: "standalone",
  serverExternalPackages: ["mssql", "pg", "node-windows"],
};

export default nextConfig;
