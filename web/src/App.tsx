import React from "react";
import { Routes, Route, Navigate } from "react-router-dom";
import Login from "./pages/Login";
import Signup from "./pages/Signup";
import NewContract from "./pages/NewContract";
import { ProtectedRoute } from "./components/ProtectedRoute";

export default function App() {
  return (
    <Routes>
      <Route path="/" element={<Navigate to="/contracts/new" replace />} />
      <Route path="/login" element={<Login />} />
      <Route path="/signup" element={<Signup />} />
      <Route
        path="/contracts/new"
        element={
          <ProtectedRoute>
            <NewContract />
          </ProtectedRoute>
        }
      />
      <Route path="*" element={<div className="p-6">Not found</div>} />
    </Routes>
  );
}
