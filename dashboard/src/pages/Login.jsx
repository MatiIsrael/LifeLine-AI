import { useState } from "react";
import { setDashboardKey } from "../api";

export default function Login({ onLogin }) {
  const [key, setKey] = useState(import.meta.env.VITE_DASHBOARD_KEY || "lifeline-dashboard-dev");
  const [role, setRole] = useState("coordinator");

  const submit = (e) => {
    e.preventDefault();
    setDashboardKey(key.trim());
    sessionStorage.setItem("ll_operator_role", role);
    onLogin();
  };

  return (
    <div className="login-wrap">
      <form className="login-card" onSubmit={submit}>
        <h1>Lifeline Command Center</h1>
        <p>Secure access for hospitals, EMS, police, and emergency coordinators.</p>
        <label htmlFor="role">Operator role</label>
        <select
          id="role"
          value={role}
          onChange={(e) => setRole(e.target.value)}
          style={{
            width: "100%",
            padding: "12px 14px",
            borderRadius: 10,
            border: "1px solid var(--border)",
            background: "var(--bg-1)",
            color: "var(--text)",
            marginBottom: 16,
          }}
        >
          <option value="coordinator">Emergency coordinator</option>
          <option value="hospital">Hospital dispatch</option>
          <option value="ambulance">Ambulance operator</option>
          <option value="police">Police command</option>
        </select>
        <label htmlFor="key">Dashboard API key</label>
        <input
          id="key"
          type="password"
          value={key}
          onChange={(e) => setKey(e.target.value)}
          placeholder="lifeline-dashboard-dev"
          autoComplete="off"
        />
        <button type="submit">Enter command center</button>
        <div className="role-tags">
          <span className="role-tag">Live map</span>
          <span className="role-tag">SOS feed</span>
          <span className="role-tag">WebSocket</span>
          <span className="role-tag">Responder dispatch</span>
        </div>
      </form>
    </div>
  );
}
