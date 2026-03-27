import { useEffect, useState } from "react";
import { api, type SessionInfo } from "@/lib/api";
import { Card, CardContent } from "@/components/ui/card";
import { Badge } from "@/components/ui/badge";
import { Skeleton } from "@/components/ui/skeleton";
import { DIMENSION_META } from "@/lib/dimensions";
import { Clock, CheckCircle2, XCircle } from "lucide-react";

interface Props {
  playerId: string;
}

export function SessionsPage({ playerId }: Props) {
  const [sessions, setSessions] = useState<SessionInfo[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    setLoading(true);
    api
      .getSessions(playerId, 50)
      .then(setSessions)
      .catch(console.error)
      .finally(() => setLoading(false));
  }, [playerId]);

  if (loading) {
    return (
      <div className="space-y-3">
        {[1, 2, 3, 4, 5].map((i) => (
          <Skeleton key={i} className="h-20 rounded-lg" />
        ))}
      </div>
    );
  }

  if (sessions.length === 0) {
    return (
      <Card>
        <CardContent className="py-12 text-center text-muted-foreground">
          <Clock className="mx-auto mb-3 h-10 w-10" />
          <p className="text-lg font-medium">No sessions yet</p>
          <p className="text-sm">Sessions will appear here once the child starts learning.</p>
        </CardContent>
      </Card>
    );
  }

  return (
    <div className="space-y-4">
      <h2 className="text-lg font-semibold">Session History ({sessions.length})</h2>
      <div className="space-y-3">
        {sessions.map((s) => {
          const meta = DIMENSION_META[s.dimension ?? ""];
          const acc =
            s.total_count > 0
              ? Math.round((s.correct_count / s.total_count) * 100)
              : 0;
          const duration = s.ended_at
            ? Math.round(
                (new Date(s.ended_at).getTime() -
                  new Date(s.started_at).getTime()) /
                  60000
              )
            : null;
          return (
            <Card key={s.id}>
              <CardContent className="flex items-center gap-4 p-4">
                <div className="text-2xl">{meta?.emoji ?? "📋"}</div>
                <div className="flex-1">
                  <div className="flex items-center gap-2">
                    <p className="font-medium text-sm">
                      {meta?.label ?? s.dimension ?? "General"}
                    </p>
                    <Badge
                      variant={s.status === "completed" ? "default" : "secondary"}
                      className="text-xs"
                    >
                      {s.status}
                    </Badge>
                  </div>
                  <p className="text-xs text-muted-foreground">
                    {new Date(s.started_at).toLocaleString()}
                    {duration !== null && ` · ${duration} min`}
                  </p>
                </div>
                <div className="flex items-center gap-4 text-sm">
                  <div className="text-center">
                    <p className="font-medium">{s.tasks_completed}</p>
                    <p className="text-xs text-muted-foreground">Tasks</p>
                  </div>
                  <div className="text-center">
                    <div className="flex items-center gap-1">
                      <CheckCircle2 className="h-3 w-3 text-green-500" />
                      <span className="font-medium">{s.correct_count}</span>
                    </div>
                    <div className="flex items-center gap-1">
                      <XCircle className="h-3 w-3 text-red-400" />
                      <span className="font-medium">
                        {s.total_count - s.correct_count}
                      </span>
                    </div>
                  </div>
                  <div className="text-center min-w-12">
                    <p
                      className={`text-lg font-bold ${
                        acc >= 80
                          ? "text-green-600"
                          : acc >= 50
                          ? "text-amber-600"
                          : "text-red-500"
                      }`}
                    >
                      {acc}%
                    </p>
                    <p className="text-xs text-muted-foreground">Accuracy</p>
                  </div>
                </div>
              </CardContent>
            </Card>
          );
        })}
      </div>
    </div>
  );
}
