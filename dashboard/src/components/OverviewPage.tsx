import { useEffect, useState } from "react";
import { api, type DashboardSummary } from "@/lib/api";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Badge } from "@/components/ui/badge";
import { Progress } from "@/components/ui/progress";
import { Skeleton } from "@/components/ui/skeleton";
import { DIMENSION_META, getLevelLabel } from "@/lib/dimensions";
import {
  BarChart,
  Bar,
  XAxis,
  YAxis,
  CartesianGrid,
  Tooltip,
  ResponsiveContainer,
} from "recharts";
import {
  Trophy,
  Target,
  Clock,
  Flame,
  CheckCircle2,
  AlertTriangle,
} from "lucide-react";

interface Props {
  playerId: string;
  onDimensionClick: (dim: string) => void;
}

export function OverviewPage({ playerId, onDimensionClick }: Props) {
  const [summary, setSummary] = useState<DashboardSummary | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    setLoading(true);
    setError(null);
    api
      .getSummary(playerId)
      .then(setSummary)
      .catch((e) => setError(e.message))
      .finally(() => setLoading(false));
  }, [playerId]);

  if (loading) {
    return (
      <div className="space-y-6">
        <div className="grid grid-cols-1 gap-4 sm:grid-cols-2 lg:grid-cols-4">
          {[1, 2, 3, 4].map((i) => (
            <Skeleton key={i} className="h-28 rounded-lg" />
          ))}
        </div>
        <div className="grid grid-cols-1 gap-4 md:grid-cols-2 lg:grid-cols-3">
          {[1, 2, 3, 4, 5, 6].map((i) => (
            <Skeleton key={i} className="h-40 rounded-lg" />
          ))}
        </div>
      </div>
    );
  }

  if (error) {
    return (
      <Card>
        <CardContent className="py-8 text-center text-destructive">
          <AlertTriangle className="mx-auto mb-2 h-8 w-8" />
          <p>{error}</p>
        </CardContent>
      </Card>
    );
  }

  if (!summary) return null;

  const statCards = [
    {
      label: "Total Sessions",
      value: summary.total_sessions,
      icon: Target,
      color: "text-blue-600",
    },
    {
      label: "Tasks Completed",
      value: summary.total_tasks_completed,
      icon: CheckCircle2,
      color: "text-green-600",
    },
    {
      label: "Overall Accuracy",
      value: `${Math.round(summary.overall_accuracy * 100)}%`,
      icon: Trophy,
      color: "text-amber-600",
    },
    {
      label: "Streak Days",
      value: summary.streak_days,
      icon: Flame,
      color: "text-orange-600",
    },
  ];

  const chartData = summary.dimensions.map((d) => ({
    name: DIMENSION_META[d.dimension]?.emoji ?? "?",
    level: d.level,
    dimension: d.dimension,
  }));

  return (
    <div className="space-y-6">
      {/* Stats row */}
      <div className="grid grid-cols-1 gap-4 sm:grid-cols-2 lg:grid-cols-4">
        {statCards.map((s) => (
          <Card key={s.label}>
            <CardContent className="flex items-center gap-4 p-5">
              <div className={`rounded-lg bg-gray-50 p-3 ${s.color}`}>
                <s.icon className="h-5 w-5" />
              </div>
              <div>
                <p className="text-sm text-muted-foreground">{s.label}</p>
                <p className="text-2xl font-bold">{s.value}</p>
              </div>
            </CardContent>
          </Card>
        ))}
      </div>

      {/* Two-column layout */}
      <div className="grid grid-cols-1 gap-6 lg:grid-cols-3">
        {/* Dimension cards - 2 cols */}
        <div className="space-y-4 lg:col-span-2">
          <h2 className="text-lg font-semibold">Developmental Dimensions</h2>
          <div className="grid grid-cols-1 gap-4 sm:grid-cols-2">
            {summary.dimensions.map((d) => {
              const meta = DIMENSION_META[d.dimension];
              if (!meta) return null;
              return (
                <Card
                  key={d.dimension}
                  className="cursor-pointer transition hover:shadow-md"
                  onClick={() => onDimensionClick(d.dimension)}
                >
                  <CardHeader className="pb-2">
                    <div className="flex items-center justify-between">
                      <CardTitle className="text-base">
                        {meta.emoji} {meta.label}
                      </CardTitle>
                      <Badge variant={d.assessed ? "default" : "secondary"}>
                        {d.assessed ? "Assessed" : "Pending"}
                      </Badge>
                    </div>
                  </CardHeader>
                  <CardContent>
                    <div className="space-y-2">
                      <div className="flex items-center justify-between text-sm">
                        <span className="text-muted-foreground">Level {d.level}</span>
                        <span className="font-medium">
                          {getLevelLabel(d.dimension, d.level)}
                        </span>
                      </div>
                      <Progress value={d.level} max={4} indicatorClassName={meta.color} />
                    </div>
                  </CardContent>
                </Card>
              );
            })}
          </div>
        </div>

        {/* Right sidebar */}
        <div className="space-y-4">
          {/* Bar chart */}
          <Card>
            <CardHeader className="pb-2">
              <CardTitle className="text-base">Level Overview</CardTitle>
            </CardHeader>
            <CardContent>
              <div className="h-48">
                <ResponsiveContainer width="100%" height="100%">
                  <BarChart data={chartData}>
                    <CartesianGrid strokeDasharray="3 3" vertical={false} />
                    <XAxis dataKey="name" fontSize={16} />
                    <YAxis domain={[0, 4]} ticks={[0, 1, 2, 3, 4]} fontSize={12} />
                    <Tooltip
                      formatter={(value: number) => [`Level ${value}`, "Level"]}
                      labelFormatter={(label: string) => label}
                    />
                    <Bar dataKey="level" fill="hsl(240, 5.9%, 10%)" radius={[4, 4, 0, 0]} />
                  </BarChart>
                </ResponsiveContainer>
              </div>
            </CardContent>
          </Card>

          {/* Quick stats */}
          <Card>
            <CardHeader className="pb-2">
              <CardTitle className="text-base">Quick Stats</CardTitle>
            </CardHeader>
            <CardContent className="space-y-3 text-sm">
              <div className="flex justify-between">
                <span className="text-muted-foreground">Mastered tasks</span>
                <span className="font-medium text-green-600">{summary.mastered_tasks}</span>
              </div>
              <div className="flex justify-between">
                <span className="text-muted-foreground">Struggling tasks</span>
                <span className="font-medium text-orange-600">{summary.struggling_tasks}</span>
              </div>
            </CardContent>
          </Card>

          {/* Recent sessions */}
          <Card>
            <CardHeader className="pb-2">
              <CardTitle className="text-base flex items-center gap-2">
                <Clock className="h-4 w-4" /> Recent Sessions
              </CardTitle>
            </CardHeader>
            <CardContent>
              {summary.recent_sessions.length === 0 ? (
                <p className="text-sm text-muted-foreground">No sessions yet</p>
              ) : (
                <div className="space-y-2">
                  {summary.recent_sessions.slice(0, 5).map((s) => {
                    const acc =
                      s.total_count > 0
                        ? Math.round((s.correct_count / s.total_count) * 100)
                        : 0;
                    return (
                      <div
                        key={s.id}
                        className="flex items-center justify-between rounded border px-3 py-2 text-xs"
                      >
                        <div>
                          <span className="font-medium">
                            {DIMENSION_META[s.dimension ?? ""]?.emoji ?? "📋"}{" "}
                            {DIMENSION_META[s.dimension ?? ""]?.label ?? s.dimension}
                          </span>
                          <p className="text-muted-foreground">
                            {new Date(s.started_at).toLocaleDateString()}
                          </p>
                        </div>
                        <Badge variant={acc >= 80 ? "default" : "secondary"}>{acc}%</Badge>
                      </div>
                    );
                  })}
                </div>
              )}
            </CardContent>
          </Card>
        </div>
      </div>
    </div>
  );
}
