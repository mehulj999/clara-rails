import React, { useEffect, useState } from "react";
import { api } from "../lib/api";

type Person = { id: number; name: string; relation: string };

export default function PersonPicker(props: { value?: number; onChange: (id: number) => void; }) {
  const [people, setPeople] = useState<Person[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    api.get("/api/v1/people")
      .then(res => setPeople(res.data?.data || res.data)) // adapt if your people#index shape differs
      .finally(() => setLoading(false));
  }, []);

  if (loading) return <p>Loading people…</p>;
  if (!people.length) return <p className="text-sm">No people yet. Create one first in API/console.</p>;

  return (
    <select className="border p-2 w-full" value={props.value ?? ""} onChange={e => props.onChange(Number(e.target.value))}>
      <option value="" disabled>Select a person</option>
      {people.map(p => (
        <option key={p.id} value={p.id}>{p.name} — {p.relation}</option>
      ))}
    </select>
  );
}
