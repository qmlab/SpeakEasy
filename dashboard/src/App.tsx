import { useState } from "react";
import { PlayerSelector } from "@/components/PlayerSelector";
import { OverviewPage } from "@/components/OverviewPage";
import { DimensionDetailPage } from "@/components/DimensionDetailPage";
import { SessionsPage } from "@/components/SessionsPage";
import { AIInsightsPage } from "@/components/AIInsightsPage";
import {
  LayoutDashboard,
  Clock,
  Brain,
  Star,
} from "lucide-react";

type Page = "overview" | "sessions" | "insights" | "dimension";

function App() {
  const [playerId, setPlayerId] = useState<string | null>(null);
  const [page, setPage] = useState<Page>("overview");
  const [selectedDimension, setSelectedDimension] = useState<string>("");

  function handleDimensionClick(dim: string) {
    setSelectedDimension(dim);
    setPage("dimension");
  }

  const navItems: { key: Page; label: string; icon: React.ElementType }[] = [
    { key: "overview", label: "Overview", icon: LayoutDashboard },
    { key: "sessions", label: "Sessions", icon: Clock },
    { key: "insights", label: "AI Insights", icon: Brain },
  ];

  return (
    <div className="min-h-screen bg-gray-50">
      {/* Top nav */}
      <header className="sticky top-0 z-40 border-b bg-white shadow-sm">
        <div className="mx-auto flex max-w-7xl items-center justify-between px-4 py-3">
          <div className="flex items-center gap-3">
            <Star className="h-6 w-6 text-amber-500" />
            <h1 className="text-lg font-bold tracking-tight">Rising Star Kid</h1>
            <span className="hidden text-sm text-muted-foreground sm:inline">
              Parent & Therapist Dashboard
            </span>
          </div>
          <PlayerSelector selectedId={playerId} onSelect={setPlayerId} />
        </div>
      </header>

      {/* Page nav */}
      {playerId && (
        <nav className="border-b bg-white">
          <div className="mx-auto flex max-w-7xl gap-1 px-4">
            {navItems.map((item) => (
              <button
                key={item.key}
                onClick={() => setPage(item.key)}
                className={`flex items-center gap-2 border-b-2 px-4 py-2.5 text-sm font-medium transition ${
                  page === item.key || (page === "dimension" && item.key === "overview")
                    ? "border-primary text-primary"
                    : "border-transparent text-muted-foreground hover:text-foreground"
                }`}
              >
                <item.icon className="h-4 w-4" />
                {item.label}
              </button>
            ))}
          </div>
        </nav>
      )}

      {/* Content */}
      <main className="mx-auto max-w-7xl px-4 py-6">
        {!playerId ? (
          <div className="flex flex-col items-center justify-center py-24 text-center">
            <Star className="mb-4 h-16 w-16 text-amber-400" />
            <h2 className="text-2xl font-bold">Welcome to Rising Star Kid</h2>
            <p className="mt-2 text-muted-foreground">
              Select or add a child from the top-right to view their learning dashboard.
            </p>
          </div>
        ) : page === "overview" ? (
          <OverviewPage
            playerId={playerId}
            onDimensionClick={handleDimensionClick}
          />
        ) : page === "dimension" ? (
          <DimensionDetailPage
            playerId={playerId}
            dimension={selectedDimension}
            onBack={() => setPage("overview")}
          />
        ) : page === "sessions" ? (
          <SessionsPage playerId={playerId} />
        ) : page === "insights" ? (
          <AIInsightsPage playerId={playerId} />
        ) : null}
      </main>
    </div>
  );
}

export default App;
