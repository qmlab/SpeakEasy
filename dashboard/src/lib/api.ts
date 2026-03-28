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

// ---- CMS Types ----

export interface AdaptiveTask {
  id: string;
  dimension: string;
  level: number;
  task_type: string;
  modalities: string[];
  content: Record<string, unknown>;
  metadata_info: Record<string, unknown> | null;
  is_assessment: boolean;
  created_at: string;
}

export interface TasksPage {
  tasks: AdaptiveTask[];
  total: number;
  page: number;
  page_size: number;
  total_pages: number;
}

export interface CMSStats {
  total: number;
  assessment_total: number;
  practice_total: number;
  by_dimension: Record<string, { total: number; levels: Record<string, number> }>;
  dimensions: string[];
  task_types: string[];
}

export interface ImportResult {
  created: number;
  updated: number;
  errors: string[];
  total_processed: number;
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

  // CMS
  getCMSStats: () => request<CMSStats>("/cms/stats"),
  getCMSTasks: (params: {
    page?: number;
    page_size?: number;
    dimension?: string;
    level?: number;
    task_type?: string;
    is_assessment?: boolean;
    search?: string;
  }) => {
    const qs = new URLSearchParams();
    if (params.page) qs.set("page", String(params.page));
    if (params.page_size) qs.set("page_size", String(params.page_size));
    if (params.dimension) qs.set("dimension", params.dimension);
    if (params.level !== undefined && params.level !== null)
      qs.set("level", String(params.level));
    if (params.task_type) qs.set("task_type", params.task_type);
    if (params.is_assessment !== undefined && params.is_assessment !== null)
      qs.set("is_assessment", String(params.is_assessment));
    if (params.search) qs.set("search", params.search);
    return request<TasksPage>(`/cms/tasks?${qs.toString()}`);
  },
  createTask: (task: Omit<AdaptiveTask, "id" | "created_at">) =>
    request<AdaptiveTask>("/tasks/", {
      method: "POST",
      body: JSON.stringify(task),
    }),
  updateTask: (taskId: string, task: Omit<AdaptiveTask, "id" | "created_at">) =>
    request<AdaptiveTask>(`/cms/tasks/${taskId}`, {
      method: "PUT",
      body: JSON.stringify(task),
    }),
  deleteTask: (taskId: string) =>
    request<{ message: string }>(`/tasks/${taskId}`, { method: "DELETE" }),
  batchDeleteTasks: (taskIds: string[]) =>
    request<{ deleted: number; requested: number }>("/cms/tasks/batch-delete", {
      method: "POST",
      body: JSON.stringify(taskIds),
    }),
  importTasksJSON: async (file: File, overwrite = false): Promise<ImportResult> => {
    const formData = new FormData();
    formData.append("file", file);
    const res = await fetch(
      `${API_URL}/cms/import/json?overwrite=${overwrite}`,
      { method: "POST", body: formData }
    );
    if (!res.ok) {
      const err = await res.json().catch(() => ({ detail: res.statusText }));
      throw new Error(err.detail || res.statusText);
    }
    return res.json();
  },
  importTasksCSV: async (file: File, overwrite = false): Promise<ImportResult> => {
    const formData = new FormData();
    formData.append("file", file);
    const res = await fetch(
      `${API_URL}/cms/import/csv?overwrite=${overwrite}`,
      { method: "POST", body: formData }
    );
    if (!res.ok) {
      const err = await res.json().catch(() => ({ detail: res.statusText }));
      throw new Error(err.detail || res.statusText);
    }
    return res.json();
  },
  exportTasksJSON: (dimension?: string) => {
    const qs = dimension ? `?dimension=${dimension}` : "";
    return `${API_URL}/cms/export/json${qs}`;
  },
  exportTasksCSV: (dimension?: string) => {
    const qs = dimension ? `?dimension=${dimension}` : "";
    return `${API_URL}/cms/export/csv${qs}`;
  },
};
