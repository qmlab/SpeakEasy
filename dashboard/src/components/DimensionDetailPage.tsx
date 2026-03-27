import { useEffect, useState } from "react";
import { api, type DimensionProgress } from "@/lib/api";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Badge } from "@/components/ui/badge";
import { Progress } from "@/components/ui/progress";
import { Skeleton } from "@/components/ui/skeleton";
import { DIMENSION_META, getLevelLabel } from "@/lib/dimensions";
import {
  LineChart,
  Line,
  XAxis,
  YAxis,
  CartesianGrid,
  Tooltip,
  ResponsiveContainer,
} from "recharts";
import { ArrowLeft, CheckCircle2, BookOpen } from "lucide-react";

interface Props {
  playerId: string;
  dimension: string;
  onBack: () => void;
}

export function DimensionDetailPage({ playerId, dimension, onBack }: Props) {
  const [progress, setProgress] = useState<DimensionProgress | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    setLoading(true);
    setError(null);
    api
      .getDimensionProgress(playerId, dimension)
      .then(setProgress)
      .catch((e) => setError(e.message))
      .finally(() => setLoading(false));
  }, [playerId, dimension]);

  const meta = DIMENSION_META[dimension];

  if (loading) {
    return (
      <div className="space-y-4">
        <Skeleton className="h-10 w-48" />
        <Skeleton className="h-64 rounded-lg" />
        <Skeleton className="h-48 rounded-lg" />
      </div>
    );
  }

  if (error || !progress) {
    return (
      <Card>
        <CardContent className="py-8 text-center text-destructive">
          <p>{error || "No data available"}</p>
          <button onClick={onBack} className="mt-4 text-sm underline">
            Go back
          </button>
        </CardContent>
      </Card>
    );
  }

  const trendData = progress.accuracy_trend.map((acc, i) => ({
    session: i + 1,
    accuracy: Math.round(acc * 100),
  }));

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex items-center gap-4">
        <button
          onClick={onBack}
          className="rounded-lg border p-2 hover:bg-gray-50 transition"
        >
          <ArrowLeft className="h-5 w-5" />
        </button>
        <div>
          <h2 className="text-xl font-bold">
            {meta?.emoji} {meta?.label ?? dimension}
          </h2>
          <p className="text-sm text-muted-foreground">
            Current Level: {progress.current_level} -{" "}
            {getLevelLabel(dimension, progress.current_level)}
          </p>
        </div>
      </div>

      {/* Level progression */}
      <Card>
        <CardHeader className="pb-2">
          <CardTitle className="text-base">Level Progression</CardTitle>
        </CardHeader>
        <CardContent>
          <div className="space-y-3">
            {meta?.levels.map((levelName, i) => (
              <div key={i} className="flex items-center gap-4">
                <div className="w-8 text-center text-sm font-medium text-muted-foreground">
                  L{i}
                </div>
                <div className="flex-1">
                  <div className="flex items-center justify-between mb-1">
                    <span className="text-sm font-medium">{levelName}</span>
                    {i < progress.current_level && (
                      <Badge variant="default" className="bg-green-600">
                        <CheckCircle2 className="mr-1 h-3 w-3" /> Mastered
                      </Badge>
                    )}
                    {i === progress.current_level && (
                      <Badge variant="secondary">
                        <BookOpen className="mr-1 h-3 w-3" /> Current
                      </Badge>
                    )}
                  </div>
                  <Progress
                    value={i <= progress.current_level ? 100 : 0}
                    indicatorClassName={
                      i < progress.current_level
                        ? "bg-green-500"
                        : i === progress.current_level
                        ? meta?.color ?? "bg-blue-500"
                        : "bg-gray-200"
                    }
                  />
                </div>
              </div>
            ))}
          </div>
        </CardContent>
      </Card>

      {/* Stats row */}
      <div className="grid grid-cols-1 gap-4 sm:grid-cols-3">
        <Card>
          <CardContent className="p-5 text-center">
            <p className="text-3xl font-bold text-green-600">
              {progress.mastered_count}
            </p>
            <p className="text-sm text-muted-foreground">Tasks Mastered</p>
          </CardContent>
        </Card>
        <Card>
          <CardContent className="p-5 text-center">
            <p className="text-3xl font-bold">{progress.total_count}</p>
            <p className="text-sm text-muted-foreground">Total Attempts</p>
          </CardContent>
        </Card>
        <Card>
          <CardContent className="p-5 text-center">
            <p className="text-3xl font-bold text-blue-600">
              {trendData.length > 0
                ? `${trendData[trendData.length - 1].accuracy}%`
                : "N/A"}
            </p>
            <p className="text-sm text-muted-foreground">Latest Accuracy</p>
          </CardContent>
        </Card>
      </div>

      {/* Accuracy trend chart */}
      {trendData.length > 0 && (
        <Card>
          <CardHeader className="pb-2">
            <CardTitle className="text-base">Accuracy Trend</CardTitle>
          </CardHeader>
          <CardContent>
            <div className="h-56">
              <ResponsiveContainer width="100%" height="100%">
                <LineChart data={trendData}>
                  <CartesianGrid strokeDasharray="3 3" />
                  <XAxis
                    dataKey="session"
                    label={{ value: "Session", position: "insideBottom", offset: -5 }}
                    fontSize={12}
                  />
                  <YAxis
                    domain={[0, 100]}
                    label={{
                      value: "Accuracy %",
                      angle: -90,
                      position: "insideLeft",
                    }}
                    fontSize={12}
                  />
                  <Tooltip formatter={(v: number) => [`${v}%`, "Accuracy"]} />
                  <Line
                    type="monotone"
                    dataKey="accuracy"
                    stroke="hsl(240, 5.9%, 10%)"
                    strokeWidth={2}
                    dot={{ r: 4 }}
                    activeDot={{ r: 6 }}
                  />
                </LineChart>
              </ResponsiveContainer>
            </div>
          </CardContent>
        </Card>
      )}

      {/* Session history */}
      {progress.history.length > 0 && (
        <Card>
          <CardHeader className="pb-2">
            <CardTitle className="text-base">Session History</CardTitle>
          </CardHeader>
          <CardContent>
            <div className="overflow-x-auto">
              <table className="w-full text-sm">
                <thead>
                  <tr className="border-b text-left text-muted-foreground">
                    <th className="pb-2 font-medium">Date</th>
                    <th className="pb-2 font-medium">Tasks</th>
                    <th className="pb-2 font-medium">Accuracy</th>
                    <th className="pb-2 font-medium">Level</th>
                  </tr>
                </thead>
                <tbody>
                    {progress.history.map((h, i) => {
                      const acc = Math.round(((h.accuracy as number) || 0) * 100);
                      return (
                        <tr key={i} className="border-b last:border-0">
                          <td className="py-2">
                            {h.date
                              ? new Date(h.date as string).toLocaleDateString()
                              : "N/A"}
                          </td>
                          <td className="py-2">{h.tasks_completed as number}</td>
                          <td className="py-2">
                            <Badge variant={acc >= 80 ? "default" : "secondary"}>
                              {acc}%
                            </Badge>
                          </td>
                          <td className="py-2">Level {h.level as number}</td>
                        </tr>
                      );
                    })}
                </tbody>
              </table>
            </div>
          </CardContent>
        </Card>
      )}
    </div>
  );
}
