// lib/api-documents.ts
import { api } from "./api";

// lib/api-documents.ts
export async function uploadDocument(file: File, contractId?: number) {
  const form = new FormData();
  form.append("file", file);
  if (contractId) form.append("contract_id", String(contractId));
  const res = await api.post("/api/v1/documents", form); // no headers override
  return res.data;
}