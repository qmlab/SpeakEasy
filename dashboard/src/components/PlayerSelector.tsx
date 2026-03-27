import { useEffect, useState } from "react";
import { api, type Player } from "@/lib/api";
import { ChevronDown, Plus, Users } from "lucide-react";

interface Props {
  selectedId: string | null;
  onSelect: (id: string) => void;
}

export function PlayerSelector({ selectedId, onSelect }: Props) {
  const [players, setPlayers] = useState<Player[]>([]);
  const [open, setOpen] = useState(false);
  const [creating, setCreating] = useState(false);
  const [newName, setNewName] = useState("");
  const [newAge, setNewAge] = useState(5);

  useEffect(() => {
    api.getPlayers().then(setPlayers).catch(console.error);
  }, []);

  const selected = players.find((p) => p.id === selectedId);

  async function handleCreate() {
    if (!newName.trim()) return;
    try {
      const player = await api.createPlayer(newName.trim(), newAge);
      setPlayers((prev) => [...prev, player]);
      onSelect(player.id);
      setCreating(false);
      setNewName("");
    } catch (e) {
      console.error(e);
    }
  }

  return (
    <div className="relative">
      <button
        onClick={() => setOpen(!open)}
        className="flex items-center gap-2 rounded-lg border bg-white px-4 py-2 text-sm font-medium shadow-sm hover:bg-gray-50 transition"
      >
        <Users className="h-4 w-4 text-muted-foreground" />
        {selected ? (
          <span>{selected.name}{selected.age ? ` (age ${selected.age})` : ""}</span>
        ) : (
          <span className="text-muted-foreground">Select child...</span>
        )}
        <ChevronDown className="h-4 w-4 text-muted-foreground" />
      </button>

      {open && (
        <div className="absolute top-full left-0 z-50 mt-1 w-64 rounded-lg border bg-white shadow-lg">
          {players.length === 0 && (
            <p className="px-4 py-3 text-sm text-muted-foreground">No children yet</p>
          )}
          {players.map((p) => (
            <button
              key={p.id}
              onClick={() => { onSelect(p.id); setOpen(false); }}
              className={`w-full px-4 py-2 text-left text-sm hover:bg-gray-50 transition ${
                p.id === selectedId ? "bg-primary/5 font-medium" : ""
              }`}
            >
              {p.name}{p.age ? <span className="text-muted-foreground"> (age {p.age})</span> : null}
            </button>
          ))}
          <div className="border-t">
            {creating ? (
              <div className="p-3 space-y-2">
                <input
                  className="w-full rounded border px-2 py-1 text-sm"
                  placeholder="Child's name"
                  value={newName}
                  onChange={(e) => setNewName(e.target.value)}
                  autoFocus
                />
                <div className="flex items-center gap-2">
                  <label className="text-xs text-muted-foreground">Age:</label>
                  <input
                    type="number"
                    min={1}
                    max={18}
                    className="w-16 rounded border px-2 py-1 text-sm"
                    value={newAge}
                    onChange={(e) => setNewAge(Number(e.target.value))}
                  />
                  <button
                    onClick={handleCreate}
                    className="ml-auto rounded bg-primary px-3 py-1 text-xs text-primary-foreground hover:bg-primary/90"
                  >
                    Add
                  </button>
                </div>
              </div>
            ) : (
              <button
                onClick={() => setCreating(true)}
                className="flex w-full items-center gap-2 px-4 py-2 text-sm text-muted-foreground hover:bg-gray-50"
              >
                <Plus className="h-4 w-4" /> Add child
              </button>
            )}
          </div>
        </div>
      )}
    </div>
  );
}
