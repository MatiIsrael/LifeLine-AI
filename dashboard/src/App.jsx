import { useState } from "react";
import Login from "./pages/Login";
import Dashboard from "./pages/Dashboard";

export default function App() {
  const [authed, setAuthed] = useState(!!sessionStorage.getItem("ll_dashboard_key"));

  const logout = () => {
    sessionStorage.removeItem("ll_dashboard_key");
    setAuthed(false);
  };

  if (!authed) {
    return <Login onLogin={() => setAuthed(true)} />;
  }

  return <Dashboard onLogout={logout} />;
}
