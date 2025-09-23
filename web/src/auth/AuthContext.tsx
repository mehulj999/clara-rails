import React, { createContext, useContext, useEffect, useState } from "react";
import { api } from "../lib/api";

type AuthContextType = {
  token: string | null;
  isAuthed: boolean;
  signIn: (email: string, password: string) => Promise<void>;
  signUp: (email: string, password: string) => Promise<void>;
  signOut: () => void;
};

const AuthContext = createContext<AuthContextType | null>(null);

export const AuthProvider: React.FC<React.PropsWithChildren> = ({ children }) => {
  const [token, setToken] = useState<string | null>(() => localStorage.getItem("jwt"));

  useEffect(() => {
    if (token) localStorage.setItem("jwt", token);
    else localStorage.removeItem("jwt");
  }, [token]);

  const signIn = async (email: string, password: string) => {
    const res = await api.post("/users/sign_in", { user: { email, password } });
    const auth = res.headers["authorization"] as string | undefined; // "Bearer <token>"
    if (!auth?.startsWith("Bearer ")) throw new Error("JWT not returned in Authorization header");
    setToken(auth.split(" ")[1]);
  };

  const signUp = async (email: string, password: string) => {
    await api.post("/users", { user: { email, password } });
    // auto sign-in after signup
    await signIn(email, password);
  };

  const signOut = () => {
    setToken(null);
    // optional: call /users/sign_out if you want revocation behavior
    // api.delete("/users/sign_out").catch(()=>{});
  };

  return (
    <AuthContext.Provider value={{ token, isAuthed: !!token, signIn, signUp, signOut }}>
      {children}
    </AuthContext.Provider>
  );
};

export const useAuth = () => {
  const ctx = useContext(AuthContext);
  if (!ctx) throw new Error("useAuth must be used within AuthProvider");
  return ctx;
};
