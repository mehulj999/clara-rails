import React, { useState } from "react";
import { useAuth } from "../auth/AuthContext";
import { useNavigate, Link } from "react-router-dom";

export default function Signup() {
  const nav = useNavigate();
  const { signUp } = useAuth();
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [err, setErr] = useState<string | null>(null);
  const [loading, setLoading] = useState(false);

  const submit = async (e: React.FormEvent) => {
    e.preventDefault();
    setErr(null); setLoading(true);
    try {
      await signUp(email, password);
      nav("/contracts/new");
    } catch (e: any) {
      setErr(e?.response?.data?.errors?.join?.(", ") || e?.message || "Signup failed");
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="p-6 max-w-md mx-auto">
      <h1 className="text-2xl font-semibold mb-4">Sign up</h1>
      <form onSubmit={submit} className="space-y-3">
        <input className="border p-2 w-full" placeholder="Email" value={email} onChange={e=>setEmail(e.target.value)} />
        <input className="border p-2 w-full" placeholder="Password" type="password" value={password} onChange={e=>setPassword(e.target.value)} />
        {err && <div className="text-red-600 text-sm">{err}</div>}
        <button disabled={loading} className="bg-black text-white px-4 py-2 rounded">{loading ? "..." : "Create account"}</button>
      </form>
      <p className="mt-3 text-sm">Already have an account? <Link className="underline" to="/login">Log in</Link></p>
    </div>
  );
}
