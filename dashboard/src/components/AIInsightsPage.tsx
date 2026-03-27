import { useEffect, useState } from "react";
import {
  api,
  type BehaviorGuidance,
  type ProgressSummary,
  type SocialStory,
} from "@/lib/api";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Badge } from "@/components/ui/badge";
import { Skeleton } from "@/components/ui/skeleton";
import { DIMENSION_META } from "@/lib/dimensions";
import {
  BookOpen,
  Brain,
  TrendingUp,
  Lightbulb,
  ArrowUpRight,
  ArrowDownRight,
  Minus,
  RefreshCw,
} from "lucide-react";

interface Props {
  playerId: string;
}

type Tab = "progress" | "guidance" | "story";

export function AIInsightsPage({ playerId }: Props) {
  const [tab, setTab] = useState<Tab>("progress");
  const [progressData, setProgressData] = useState<ProgressSummary | null>(null);
  const [guidanceData, setGuidanceData] = useState<BehaviorGuidance | null>(null);
  const [storyData, setStoryData] = useState<SocialStory | null>(null);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  function load(t: Tab) {
    setLoading(true);
    setError(null);
    const promise =
      t === "progress"
        ? api.getProgressSummary(playerId).then(setProgressData)
        : t === "guidance"
        ? api.getBehaviorGuidance(playerId).then(setGuidanceData)
        : api.getSocialStory(playerId).then(setStoryData);
    promise.catch((e) => setError(e.message)).finally(() => setLoading(false));
  }

  useEffect(() => {
    setProgressData(null);
    setGuidanceData(null);
    setStoryData(null);
  }, [playerId]);

  useEffect(() => {
    load(tab);
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [playerId, tab]);

  const tabs: { key: Tab; label: string; icon: React.ElementType }[] = [
    { key: "progress", label: "Progress Report", icon: TrendingUp },
    { key: "guidance", label: "Behavior Guidance", icon: Brain },
    { key: "story", label: "Social Story", icon: BookOpen },
  ];

  return (
    <div className="space-y-6">
      {/* Tab nav */}
      <div className="flex gap-2 border-b pb-1">
        {tabs.map((t) => (
          <button
            key={t.key}
            onClick={() => setTab(t.key)}
            className={`flex items-center gap-2 rounded-t-lg px-4 py-2 text-sm font-medium transition ${
              tab === t.key
                ? "border-b-2 border-primary text-primary"
                : "text-muted-foreground hover:text-foreground"
            }`}
          >
            <t.icon className="h-4 w-4" />
            {t.label}
          </button>
        ))}
        <button
          onClick={() => load(tab)}
          className="ml-auto flex items-center gap-1 rounded px-3 py-1 text-xs text-muted-foreground hover:bg-gray-50"
          title="Refresh"
        >
          <RefreshCw className="h-3 w-3" /> Refresh
        </button>
      </div>

      {loading && (
        <div className="space-y-4">
          <Skeleton className="h-32 rounded-lg" />
          <Skeleton className="h-48 rounded-lg" />
        </div>
      )}

      {error && (
        <Card>
          <CardContent className="py-6 text-center text-destructive">
            {error}
          </CardContent>
        </Card>
      )}

      {!loading && !error && tab === "progress" && progressData && (
        <ProgressReport data={progressData} />
      )}
      {!loading && !error && tab === "guidance" && guidanceData && (
        <GuidanceReport data={guidanceData} />
      )}
      {!loading && !error && tab === "story" && storyData && (
        <StoryView data={storyData} />
      )}
    </div>
  );
}

function ProgressReport({ data }: { data: ProgressSummary }) {
  return (
    <div className="space-y-6">
      {/* Narrative */}
      <Card>
        <CardHeader className="pb-2">
          <div className="flex items-center justify-between">
            <CardTitle className="text-base">Summary</CardTitle>
            <Badge variant="secondary">{data.source}</Badge>
          </div>
        </CardHeader>
        <CardContent>
          <p className="text-sm leading-relaxed whitespace-pre-line">{data.narrative}</p>
        </CardContent>
      </Card>

      {/* Stats */}
      <div className="grid grid-cols-3 gap-4">
        <Card>
          <CardContent className="p-4 text-center">
            <p className="text-2xl font-bold">{data.stats.total_sessions}</p>
            <p className="text-xs text-muted-foreground">Sessions</p>
          </CardContent>
        </Card>
        <Card>
          <CardContent className="p-4 text-center">
            <p className="text-2xl font-bold">{data.stats.total_attempts}</p>
            <p className="text-xs text-muted-foreground">Attempts</p>
          </CardContent>
        </Card>
        <Card>
          <CardContent className="p-4 text-center">
            <p className="text-2xl font-bold">
              {Math.round(data.stats.overall_accuracy)}%
            </p>
            <p className="text-xs text-muted-foreground">Accuracy</p>
          </CardContent>
        </Card>
      </div>

      {/* Strengths & Growth */}
      <div className="grid grid-cols-1 gap-4 md:grid-cols-2">
        <Card>
          <CardHeader className="pb-2">
            <CardTitle className="flex items-center gap-2 text-base text-green-700">
              <ArrowUpRight className="h-4 w-4" /> Strengths
            </CardTitle>
          </CardHeader>
          <CardContent>
            <ul className="space-y-1">
              {data.strengths.map((s, i) => (
                <li key={i} className="flex items-start gap-2 text-sm">
                  <span className="mt-1 text-green-500">+</span> {s}
                </li>
              ))}
            </ul>
          </CardContent>
        </Card>
        <Card>
          <CardHeader className="pb-2">
            <CardTitle className="flex items-center gap-2 text-base text-orange-700">
              <ArrowDownRight className="h-4 w-4" /> Areas for Growth
            </CardTitle>
          </CardHeader>
          <CardContent>
            <ul className="space-y-1">
              {data.areas_for_growth.map((s, i) => (
                <li key={i} className="flex items-start gap-2 text-sm">
                  <span className="mt-1 text-orange-500">~</span> {s}
                </li>
              ))}
            </ul>
          </CardContent>
        </Card>
      </div>

      {/* Next steps */}
      <Card>
        <CardHeader className="pb-2">
          <CardTitle className="flex items-center gap-2 text-base">
            <Lightbulb className="h-4 w-4 text-amber-500" /> Recommended Next Steps
          </CardTitle>
        </CardHeader>
        <CardContent>
          <ol className="list-decimal list-inside space-y-1 text-sm">
            {data.next_steps.map((s, i) => (
              <li key={i}>{s}</li>
            ))}
          </ol>
        </CardContent>
      </Card>

      {/* Per-dimension analysis */}
      <Card>
        <CardHeader className="pb-2">
          <CardTitle className="text-base">Dimension Analysis</CardTitle>
        </CardHeader>
        <CardContent>
          <div className="space-y-3">
            {data.dimensions.map((d) => {
              const meta = DIMENSION_META[d.dimension];
              const StatusIcon =
                d.status === "progressing"
                  ? ArrowUpRight
                  : d.status === "struggling"
                  ? ArrowDownRight
                  : Minus;
              const statusColor =
                d.status === "progressing"
                  ? "text-green-600"
                  : d.status === "struggling"
                  ? "text-orange-600"
                  : "text-gray-500";
              return (
                <div
                  key={d.dimension}
                  className="flex items-center gap-4 rounded-lg border p-3"
                >
                  <span className="text-xl">{meta?.emoji ?? "📋"}</span>
                  <div className="flex-1">
                    <p className="text-sm font-medium">{d.dimension_label}</p>
                    <p className="text-xs text-muted-foreground">
                      Level {d.level}: {d.current_ability}
                    </p>
                    {d.next_skill && (
                      <p className="text-xs text-blue-600">Next: {d.next_skill}</p>
                    )}
                  </div>
                  <StatusIcon className={`h-5 w-5 ${statusColor}`} />
                </div>
              );
            })}
          </div>
        </CardContent>
      </Card>
    </div>
  );
}

function GuidanceReport({ data }: { data: BehaviorGuidance }) {
  return (
    <div className="space-y-6">
      <Card>
        <CardHeader className="pb-2">
          <div className="flex items-center justify-between">
            <CardTitle className="text-base">Overview</CardTitle>
            <Badge variant="secondary">{data.source}</Badge>
          </div>
        </CardHeader>
        <CardContent>
          <p className="text-sm leading-relaxed">{data.summary}</p>
        </CardContent>
      </Card>

      {/* Recommendations */}
      {data.recommendations.map((r, i) => {
        const meta = DIMENSION_META[r.dimension];
        const priorityColor =
          r.priority === "high"
            ? "bg-red-100 text-red-700"
            : r.priority === "medium"
            ? "bg-amber-100 text-amber-700"
            : "bg-green-100 text-green-700";
        return (
          <Card key={i}>
            <CardHeader className="pb-2">
              <div className="flex items-center justify-between">
                <CardTitle className="text-base">
                  {meta?.emoji} {r.dimension_label ?? r.dimension}
                  {r.current_level !== null && (
                    <span className="ml-2 text-sm font-normal text-muted-foreground">
                      Level {r.current_level}
                    </span>
                  )}
                </CardTitle>
                <Badge className={priorityColor}>{r.priority} priority</Badge>
              </div>
            </CardHeader>
            <CardContent className="space-y-2">
              {r.rationale && (
                <p className="text-sm italic text-muted-foreground">{r.rationale}</p>
              )}
              <ul className="space-y-1">
                {r.suggestions.map((s, j) => (
                  <li key={j} className="flex items-start gap-2 text-sm">
                    <span className="mt-0.5 text-primary">•</span> {s}
                  </li>
                ))}
              </ul>
            </CardContent>
          </Card>
        );
      })}

      {/* Home activities */}
      <Card>
        <CardHeader className="pb-2">
          <CardTitle className="text-base">Home Activities</CardTitle>
        </CardHeader>
        <CardContent>
          <ul className="space-y-2">
            {data.home_activities.map((a, i) => (
              <li key={i} className="flex items-start gap-2 text-sm">
                <span className="mt-0.5 font-bold text-primary">{i + 1}.</span> {a}
              </li>
            ))}
          </ul>
        </CardContent>
      </Card>
    </div>
  );
}

function StoryView({ data }: { data: SocialStory }) {
  return (
    <div className="space-y-6">
      <Card>
        <CardHeader>
          <div className="flex items-center justify-between">
            <CardTitle>{data.title}</CardTitle>
            <Badge variant="secondary">{data.source}</Badge>
          </div>
          <p className="text-sm text-muted-foreground">
            Target skill: {data.target_skill}
            {data.social_level !== null && ` | Social Level ${data.social_level}`}
          </p>
        </CardHeader>
        <CardContent>
          <div className="prose prose-sm max-w-none">
            <p className="whitespace-pre-line leading-relaxed">{data.story}</p>
          </div>
        </CardContent>
      </Card>

      <Card>
        <CardHeader className="pb-2">
          <CardTitle className="text-base">Practice Tips</CardTitle>
        </CardHeader>
        <CardContent>
          <ol className="list-decimal list-inside space-y-2 text-sm">
            {data.practice_tips.map((tip, i) => (
              <li key={i}>{tip}</li>
            ))}
          </ol>
        </CardContent>
      </Card>
    </div>
  );
}
