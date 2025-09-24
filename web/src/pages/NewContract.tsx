
import React, { useState } from "react";
import { api } from "../lib/api";
import { useNavigate } from "react-router-dom";
import { useAuth } from "../auth/AuthContext";
import PersonPicker from "../components/PersonPicker";
import { uploadDocument } from "../lib/api-documents";

const TYPES = ["mobile", "gym", "insurance"] as const;

export default function NewContract() {
  const nav = useNavigate();
  const { signOut } = useAuth();

  const [personId, setPersonId] = useState<number | undefined>();
  const [contractType, setContractType] = useState<string>("mobile");
  const [provider, setProvider] = useState<string>("Telekom");
  const [currency, setCurrency] = useState<string>("EUR");
  const [country, setCountry] = useState<"DE"|"IN">("DE");

  const [file, setFile] = useState<File | null>(null);
  const [err, setErr] = useState<string | null>(null);
  const [ok, setOk] = useState<string | null>(null);
  const [loading, setLoading] = useState(false);

  const submit = async (e: React.FormEvent) => {
    e.preventDefault();
    setErr(null); setOk(null); setLoading(true);
    try {
      if (!personId) throw new Error("Please select a person");
      const payload = {
        contract: {
          contract_type: contractType,
          provider,
          currency,
          country_code: country,
          person_id: personId
        }
      };
      const res = await api.post("/api/v1/contracts", payload);
      const contractId = res.data?.id;

      // 2) Optionally upload the PDF and link it to this contract
      let uploadedDocId: number | undefined;
      if (file) {
        const doc = await uploadDocument(file, contractId);
        uploadedDocId = doc.id;
      }

      setOk(
        file
          ? `Created contract #${contractId} and uploaded document #${uploadedDocId}`
          : `Created contract #${contractId}`
      );
    } catch (e: any) {
      if (e?.response?.status === 401) {
        setErr("Session expired, please log in again.");
        signOut();
        nav("/login");
      } else {
        setErr(e?.response?.data?.errors?.join?.(", ") || e?.message || "Failed to create contract");
      }
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="p-6 max-w-lg mx-auto">
      <div className="flex items-center justify-between">
        <h1 className="text-2xl font-semibold mb-4">New Contract</h1>
        <button onClick={() => { signOut(); nav("/login"); }} className="text-sm underline">Sign out</button>
      </div>

      <form onSubmit={submit} className="space-y-3">
        <label className="block text-sm">Person</label>
        <PersonPicker value={personId} onChange={setPersonId} />

        <label className="block text-sm">Contract type</label>
        <select className="border p-2 w-full" value={contractType} onChange={e=>setContractType(e.target.value)}>
          {TYPES.map(t => <option key={t} value={t}>{t}</option>)}
        </select>

        <label className="block text-sm">Provider</label>
        <input className="border p-2 w-full" value={provider} onChange={e=>setProvider(e.target.value)} />

        <select value={country} onChange={e=>setCountry(e.target.value as "DE"|"IN")} className="border p-2 w-full">
          <option value="DE">Germany (DE)</option>
          <option value="IN">India (IN)</option>
        </select>

        <label className="block text-sm">Currency</label>
        <input className="border p-2 w-full" value={currency} onChange={e=>setCurrency(e.target.value)} />

        {/* New optional PDF picker */}
        <label className="block text-sm">Attach contract PDF (optional)</label>
        <input
          type="file"
          accept="application/pdf"
          onChange={(e) => setFile(e.target.files?.[0] || null)}
          className="border p-2 w-full"
        />

        {err && <div className="text-red-600 text-sm">{err}</div>}
        {ok && <div className="text-green-700 text-sm">{ok}</div>}
        <button disabled={loading} className="bg-black text-white px-4 py-2 rounded">
          {loading ? "..." : "Create"}
        </button>
      </form>
    </div>
  );
}