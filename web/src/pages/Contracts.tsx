import { useEffect, useState } from "react";
import { api } from "../lib/api";

export default function Contracts() {
  const [items, setItems] = useState<any[]>([]);
  useEffect(() => {
    api.get("/api/v1/contracts").then(res => setItems(res.data.data));
  }, []);
  return (
    <div>
      <h1>Contracts</h1>
      <ul>{items.map(c => <li key={c.id}>{c.type} — {c.provider}</li>)}</ul>
    </div>
  );
}
