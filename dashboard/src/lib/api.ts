const API_URL = import.meta.env.VITE_API_URL || "http://localhost:8000";

async function request<T>(path: string, options?: RequestInit): Promise<T> {
  const res = await fetch(`${API_URL}${path}`, {
    headers: { "Content-Type": "application/json" },
    ...options,
  });
  if (!res.ok) {
    const err = await res.json().catch(() => ({ detail: res.statusText }));
    throw new Error(err.detail || res.statusText);
  }
  return res.json();
}

// ---- Types ----

export interface Player {
  id: string;
  name: string;
  age?: number;
  created_at?: string;
}

export interface DimensionProfile {
  id: string;
  player_id: string;
  dimension: string;
  level: number;
  sub_scores: Record<string, unknown> | null;
  assessed: boolean;
  last_assessed_at: string | null;
  created_at: string;
  updated_at: string;
}

export interface SessionInfo {
  id: string;
  player_id: string;
  session_type: string;
  dimension: string | null;
  started_at: string;
  ended_at: string | null;
  tasks_completed: number;
  correct_count: number;
  total_count: number;
  avg_response_time_ms: number | null;
  status: string;
  current_level: number;
}

export interface DashboardSummary {
  player_id: string;
  player_name: string;
  dimensions: DimensionProfile[];
  recent_sessions: SessionInfo[];
  total_sessions: number;
  total_tasks_completed: number;
  overall_accuracy: number;
  streak_days: number;
  mastered_tasks: number;
  struggling_tasks: number;
}

export interface DimensionProgress {
  dimension: string;
  current_level: number;
  history: Array<Record<string, unknown>>;
  mastered_count: number;
  total_count: number;
  accuracy_trend: number[];
}

export interface AIStatus {
  llm_enabled: boolean;
  model: string | null;
  fallback_mode: string;
  supported_features: string[];
}

export interface SocialStory {
  player_id: string;
  title: string;
  story: string;
  target_skill: string;
  practice_tips: string[];
  social_level: number | null;
  source: string;
}

export interface GuidanceRecommendation {
  dimension: string;
  dimension_label: string | null;
  current_level: number | null;
  priority: string;
  suggestions: string[];
  rationale: string | null;
}

export interface BehaviorGuidance {
  player_id: string;
  summary: string;
  recommendations: GuidanceRecommendation[];
  home_activities: string[];
  source: string;
}

export interface DimensionAnalysis {
  dimension: string;
  dimension_label: string;
  level: number;
  current_ability: string;
  next_skill: string | null;
  status: string;
}

export interface ProgressSummary {
  player_id: string;
  narrative: string;
  strengths: string[];
  areas_for_growth: string[];
  next_steps: string[];
  dimensions: DimensionAnalysis[];
  stats: { total_sessions: number; total_attempts: number; overall_accuracy: number };
  source: string;
}

export interface AssessmentResults {
  assessment_id: string;
  player_id: string;
  status: string;
  character: string;
  total_activities: number;
  completed_activities: number;
  dimension_results: Record<string, { level: number; correct: number; total: number }>;
}

// ---- API Functions ----

export const api = {
  // Players
  getPlayers: () => request<Player[]>("/players/"),
  createPlayer: (name: string, age: number) =>
    request<Player>("/players/", {
      method: "POST",
      body: JSON.stringify({ name, age }),
    }),

  // Dashboard
  getSummary: (playerId: string) =>
    request<DashboardSummary>(`/dashboard/${playerId}/summary`),
  getDimensionProgress: (playerId: string, dimension: string) =>
    request<DimensionProgress>(`/dashboard/${playerId}/dimensions/${dimension}`),
  getSessions: (playerId: string, limit = 20) =>
    request<SessionInfo[]>(`/dashboard/${playerId}/sessions?limit=${limit}`),

  // AI
  getAIStatus: () => request<AIStatus>("/ai/status"),
  getSocialStory: (playerId: string, scenario?: string) =>
    request<SocialStory>("/ai/social-story", {
      method: "POST",
      body: JSON.stringify({ player_id: playerId, scenario }),
    }),
  getBehaviorGuidance: (playerId: string, dimension?: string) =>
    request<BehaviorGuidance>("/ai/behavior-guidance", {
      method: "POST",
      body: JSON.stringify({ player_id: playerId, dimension }),
    }),
  getProgressSummary: (playerId: string) =>
    request<ProgressSummary>("/ai/progress-summary", {
      method: "POST",
      body: JSON.stringify({ player_id: playerId }),
    }),

  // Assessment
  getAssessmentResults: (assessmentId: string) =>
    request<AssessmentResults>(`/assessment/${assessmentId}/results`),

  // Tasks
  seedTasks: () => request<Record<string, number>>("/tasks/seed", { method: "POST" }),
};
