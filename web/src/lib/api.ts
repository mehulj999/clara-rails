//lib/api.ts

import axios from "axios";

export const api = axios.create({
  baseURL: import.meta.env.VITE_API_URL || "http://localhost:3000",
  headers: {
    Accept: "application/json",
    // "Content-Type": "application/json",
  },
});

// attach JWT from localStorage on every request
api.interceptors.request.use((config) => {
  const token = localStorage.getItem("jwt");
  if (token) config.headers.Authorization = `Bearer ${token}`;
  return config;
});



