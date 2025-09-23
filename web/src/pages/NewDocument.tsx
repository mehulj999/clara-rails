// src/pages/NewDocument.tsx

import { useState } from "react";
import { uploadDocument } from "../lib/api-documents";  // <-- import here

export default function NewDocument() {
  const [file, setFile] = useState<File | null>(null);
  const [msg, setMsg] = useState<string | null>(null);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!file) {
      setMsg("Please select a file first.");
      return;
    }
    try {
      const res = await uploadDocument(file);
      setMsg(`Uploaded document with id ${res.id}`);
    } catch (err: any) {
      setMsg(`Upload failed: ${err.message}`);
    }
  };

  return (
    <div>
      <h1>Upload Document</h1>
      <form onSubmit={handleSubmit}>
        <input type="file" onChange={(e) => setFile(e.target.files?.[0] || null)} />
        <button type="submit">Upload</button>
      </form>
      {msg && <p>{msg}</p>}
    </div>
  );
}
