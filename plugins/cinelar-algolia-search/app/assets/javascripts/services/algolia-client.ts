import { ajax } from "@/lib/Ajax";

interface AlgoliaConfig {
  app_id: string;
  search_api_key: string;
  index_prefix: string;
  environment: string;
}

let cachedConfig: AlgoliaConfig | null = null;

export async function getAlgoliaConfig(): Promise<AlgoliaConfig> {
  if (cachedConfig) return cachedConfig;
  const { data } = await ajax.get("/algolia/config.json");
  cachedConfig = data;
  return data;
}

export async function searchAlgolia(query: string, hitsPerPage = 30) {
  const { data } = await ajax.get("/search.json", {
    params: { query, hitsPerPage },
  });
  return data.data || [];
}
