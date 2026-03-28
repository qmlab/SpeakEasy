import { useEffect, useState, useRef, useCallback } from "react";
import {
  api,
  type AdaptiveTask,
  type CMSStats,
  type TasksPage,
  type ImportResult,
} from "@/lib/api";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Badge } from "@/components/ui/badge";
import { Skeleton } from "@/components/ui/skeleton";
import { DIMENSION_META } from "@/lib/dimensions";
import {
  Search,
  Plus,
  Trash2,
  Download,
  Upload,
  ChevronLeft,
  ChevronRight,
  X,
  Save,
  FileJson,
  FileSpreadsheet,
  AlertTriangle,
  CheckCircle2,
  Database,
} from "lucide-react";

const PAGE_SIZE = 15;

// ── Task Editor Modal ───────────────────────────────────────────────────

interface TaskEditorProps {
  task: AdaptiveTask | null; // null = new task
  dimensions: string[];
  taskTypes: string[];
  onSave: (task: Omit<AdaptiveTask, "id" | "created_at">) => void;
  onCancel: () => void;
}

function TaskEditor({ task, dimensions, taskTypes, onSave, onCancel }: TaskEditorProps) {
  const [dimension, setDimension] = useState(task?.dimension ?? dimensions[0] ?? "");
  const [level, setLevel] = useState(task?.level ?? 0);
  const [taskType, setTaskType] = useState(task?.task_type ?? taskTypes[0] ?? "");
  const [modalities, setModalities] = useState(
    task?.modalities?.join(", ") ?? "touch"
  );
  const [contentStr, setContentStr] = useState(
    JSON.stringify(task?.content ?? {}, null, 2)
  );
  const [metadataStr, setMetadataStr] = useState(
    task?.metadata_info ? JSON.stringify(task.metadata_info, null, 2) : ""
  );
  const [isAssessment, setIsAssessment] = useState(task?.is_assessment ?? false);
  const [error, setError] = useState("");

  function handleSave() {
    try {
      const content = JSON.parse(contentStr);
      const metadata_info = metadataStr.trim() ? JSON.parse(metadataStr) : null;
      const modalitiesList = modalities.split(",").map((m) => m.trim()).filter(Boolean);
      onSave({
        dimension,
        level,
        task_type: taskType,
        modalities: modalitiesList,
        content,
        metadata_info,
        is_assessment: isAssessment,
      });
    } catch (e) {
      setError(`Invalid JSON: ${(e as Error).message}`);
    }
  }

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/50">
      <div className="mx-4 w-full max-w-2xl rounded-lg bg-white shadow-xl">
        <div className="flex items-center justify-between border-b px-6 py-4">
          <h3 className="text-lg font-semibold">
            {task ? "Edit Task" : "New Task"}
          </h3>
          <button onClick={onCancel} className="rounded p-1 hover:bg-gray-100">
            <X className="h-5 w-5" />
          </button>
        </div>
        <div className="max-h-96 space-y-4 overflow-y-auto px-6 py-4 lg:max-h-[32rem]">
          <div className="grid grid-cols-2 gap-4">
            <div>
              <label className="mb-1 block text-sm font-medium">Dimension</label>
              <select
                value={dimension}
                onChange={(e) => setDimension(e.target.value)}
                className="w-full rounded border px-3 py-2 text-sm"
              >
                {dimensions.map((d) => (
                  <option key={d} value={d}>
                    {DIMENSION_META[d]?.emoji ?? ""} {DIMENSION_META[d]?.label ?? d}
                  </option>
                ))}
              </select>
            </div>
            <div>
              <label className="mb-1 block text-sm font-medium">Level</label>
              <input
                type="number"
                min={0}
                max={4}
                value={level}
                onChange={(e) => setLevel(Number(e.target.value))}
                className="w-full rounded border px-3 py-2 text-sm"
              />
            </div>
          </div>
          <div className="grid grid-cols-2 gap-4">
            <div>
              <label className="mb-1 block text-sm font-medium">Task Type</label>
              <select
                value={taskType}
                onChange={(e) => setTaskType(e.target.value)}
                className="w-full rounded border px-3 py-2 text-sm"
              >
                {taskTypes.map((t) => (
                  <option key={t} value={t}>{t}</option>
                ))}
              </select>
            </div>
            <div>
              <label className="mb-1 block text-sm font-medium">
                Modalities <span className="text-muted-foreground">(comma-sep)</span>
              </label>
              <input
                value={modalities}
                onChange={(e) => setModalities(e.target.value)}
                className="w-full rounded border px-3 py-2 text-sm"
                placeholder="touch, voice, text"
              />
            </div>
          </div>
          <div className="flex items-center gap-2">
            <input
              type="checkbox"
              id="is_assessment"
              checked={isAssessment}
              onChange={(e) => setIsAssessment(e.target.checked)}
              className="rounded"
            />
            <label htmlFor="is_assessment" className="text-sm">Assessment task</label>
          </div>
          <div>
            <label className="mb-1 block text-sm font-medium">Content (JSON)</label>
            <textarea
              value={contentStr}
              onChange={(e) => { setContentStr(e.target.value); setError(""); }}
              rows={8}
              className="w-full rounded border px-3 py-2 font-mono text-xs"
              spellCheck={false}
            />
          </div>
          <div>
            <label className="mb-1 block text-sm font-medium">
              Metadata (JSON, optional)
            </label>
            <textarea
              value={metadataStr}
              onChange={(e) => { setMetadataStr(e.target.value); setError(""); }}
              rows={3}
              className="w-full rounded border px-3 py-2 font-mono text-xs"
              spellCheck={false}
            />
          </div>
          {error && (
            <p className="flex items-center gap-1 text-sm text-red-600">
              <AlertTriangle className="h-4 w-4" /> {error}
            </p>
          )}
        </div>
        <div className="flex justify-end gap-3 border-t px-6 py-4">
          <button
            onClick={onCancel}
            className="rounded border px-4 py-2 text-sm hover:bg-gray-50"
          >
            Cancel
          </button>
          <button
            onClick={handleSave}
            className="flex items-center gap-2 rounded bg-primary px-4 py-2 text-sm text-white hover:bg-primary/90"
          >
            <Save className="h-4 w-4" />
            {task ? "Update" : "Create"}
          </button>
        </div>
      </div>
    </div>
  );
}

// ── Import Modal ────────────────────────────────────────────────────────

interface ImportModalProps {
  onClose: () => void;
  onImported: (result: ImportResult) => void;
}

function ImportModal({ onClose, onImported }: ImportModalProps) {
  const [file, setFile] = useState<File | null>(null);
  const [overwrite, setOverwrite] = useState(false);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState("");
  const fileRef = useRef<HTMLInputElement>(null);

  async function handleImport() {
    if (!file) return;
    setLoading(true);
    setError("");
    try {
      const isCSV = file.name.endsWith(".csv");
      const result = isCSV
        ? await api.importTasksCSV(file, overwrite)
        : await api.importTasksJSON(file, overwrite);
      onImported(result);
    } catch (e) {
      setError((e as Error).message);
    } finally {
      setLoading(false);
    }
  }

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/50">
      <div className="mx-4 w-full max-w-md rounded-lg bg-white shadow-xl">
        <div className="flex items-center justify-between border-b px-6 py-4">
          <h3 className="text-lg font-semibold">Import Tasks</h3>
          <button onClick={onClose} className="rounded p-1 hover:bg-gray-100">
            <X className="h-5 w-5" />
          </button>
        </div>
        <div className="space-y-4 px-6 py-4">
          <p className="text-sm text-muted-foreground">
            Upload a <strong>.json</strong> or <strong>.csv</strong> file containing
            task definitions. JSON should be an array of task objects. CSV should have
            headers: dimension, level, task_type, modalities, content, metadata_info,
            is_assessment.
          </p>
          <div
            onClick={() => fileRef.current?.click()}
            className="flex cursor-pointer flex-col items-center gap-2 rounded-lg border-2 border-dashed p-8 hover:border-primary hover:bg-gray-50"
          >
            <Upload className="h-8 w-8 text-muted-foreground" />
            {file ? (
              <p className="text-sm font-medium">{file.name}</p>
            ) : (
              <p className="text-sm text-muted-foreground">
                Click to select a file (.json or .csv)
              </p>
            )}
            <input
              ref={fileRef}
              type="file"
              accept=".json,.csv"
              className="hidden"
              onChange={(e) => setFile(e.target.files?.[0] ?? null)}
            />
          </div>
          <div className="flex items-center gap-2">
            <input
              type="checkbox"
              id="overwrite"
              checked={overwrite}
              onChange={(e) => setOverwrite(e.target.checked)}
            />
            <label htmlFor="overwrite" className="text-sm">
              Overwrite existing tasks (match by ID)
            </label>
          </div>
          {error && (
            <p className="flex items-center gap-1 text-sm text-red-600">
              <AlertTriangle className="h-4 w-4" /> {error}
            </p>
          )}
        </div>
        <div className="flex justify-end gap-3 border-t px-6 py-4">
          <button
            onClick={onClose}
            className="rounded border px-4 py-2 text-sm hover:bg-gray-50"
          >
            Cancel
          </button>
          <button
            onClick={handleImport}
            disabled={!file || loading}
            className="flex items-center gap-2 rounded bg-primary px-4 py-2 text-sm text-white hover:bg-primary/90 disabled:opacity-50"
          >
            <Upload className="h-4 w-4" />
            {loading ? "Importing..." : "Import"}
          </button>
        </div>
      </div>
    </div>
  );
}

// ── Main CMS Page ───────────────────────────────────────────────────────

export function CMSPage() {
  const [stats, setStats] = useState<CMSStats | null>(null);
  const [tasksPage, setTasksPage] = useState<TasksPage | null>(null);
  const [loading, setLoading] = useState(true);
  const [page, setPage] = useState(1);

  // Filters
  const [dimension, setDimension] = useState("");
  const [levelFilter, setLevelFilter] = useState<string>("");
  const [taskTypeFilter, setTaskTypeFilter] = useState("");
  const [searchQuery, setSearchQuery] = useState("");
  const [searchInput, setSearchInput] = useState("");

  // Selection
  const [selected, setSelected] = useState<Set<string>>(new Set());

  // Modals
  const [editingTask, setEditingTask] = useState<AdaptiveTask | null | undefined>(
    undefined
  ); // undefined = closed, null = new
  const [showImport, setShowImport] = useState(false);
  const [notification, setNotification] = useState<{
    type: "success" | "error";
    message: string;
  } | null>(null);

  const loadStats = useCallback(() => {
    api.getCMSStats().then(setStats).catch(console.error);
  }, []);

  const loadTasks = useCallback(() => {
    setLoading(true);
    api
      .getCMSTasks({
        page,
        page_size: PAGE_SIZE,
        dimension: dimension || undefined,
        level: levelFilter !== "" ? Number(levelFilter) : undefined,
        task_type: taskTypeFilter || undefined,
        search: searchQuery || undefined,
      })
      .then((data) => {
        setTasksPage(data);
        setSelected(new Set());
      })
      .catch(console.error)
      .finally(() => setLoading(false));
  }, [page, dimension, levelFilter, taskTypeFilter, searchQuery]);

  useEffect(() => {
    loadStats();
  }, [loadStats]);

  useEffect(() => {
    loadTasks();
  }, [loadTasks]);

  function showNotification(type: "success" | "error", message: string) {
    setNotification({ type, message });
    setTimeout(() => setNotification(null), 4000);
  }

  function handleSearch(e: React.FormEvent) {
    e.preventDefault();
    setPage(1);
    setSearchQuery(searchInput);
  }

  function toggleSelect(id: string) {
    setSelected((prev) => {
      const next = new Set(prev);
      if (next.has(id)) next.delete(id);
      else next.add(id);
      return next;
    });
  }

  function toggleSelectAll() {
    if (!tasksPage) return;
    if (selected.size === tasksPage.tasks.length) {
      setSelected(new Set());
    } else {
      setSelected(new Set(tasksPage.tasks.map((t) => t.id)));
    }
  }

  async function handleSaveTask(data: Omit<AdaptiveTask, "id" | "created_at">) {
    try {
      if (editingTask === null) {
        await api.createTask(data);
        showNotification("success", "Task created");
      } else if (editingTask) {
        await api.updateTask(editingTask.id, data);
        showNotification("success", "Task updated");
      }
      setEditingTask(undefined);
      loadTasks();
      loadStats();
    } catch (e) {
      showNotification("error", (e as Error).message);
    }
  }

  async function handleDelete(taskId: string) {
    if (!confirm("Delete this task?")) return;
    try {
      await api.deleteTask(taskId);
      showNotification("success", "Task deleted");
      loadTasks();
      loadStats();
    } catch (e) {
      showNotification("error", (e as Error).message);
    }
  }

  async function handleBatchDelete() {
    if (selected.size === 0) return;
    if (!confirm(`Delete ${selected.size} selected tasks?`)) return;
    try {
      const result = await api.batchDeleteTasks(Array.from(selected));
      showNotification("success", `Deleted ${result.deleted} tasks`);
      setSelected(new Set());
      loadTasks();
      loadStats();
    } catch (e) {
      showNotification("error", (e as Error).message);
    }
  }

  function handleImported(result: ImportResult) {
    setShowImport(false);
    const msg = `Imported: ${result.created} created, ${result.updated} updated${
      result.errors.length > 0 ? `, ${result.errors.length} errors` : ""
    }`;
    showNotification(result.errors.length > 0 ? "error" : "success", msg);
    loadTasks();
    loadStats();
  }

  function getTaskPreview(content: Record<string, unknown>): string {
    const instruction =
      (content.instruction_text as string) ??
      (content.instruction_audio as string) ??
      "";
    if (instruction) return instruction;
    const keys = Object.keys(content).slice(0, 3);
    return keys.join(", ") || "(empty)";
  }

  return (
    <div className="space-y-6">
      {/* Notification toast */}
      {notification && (
        <div
          className={`fixed right-4 top-20 z-50 flex items-center gap-2 rounded-lg px-4 py-3 text-sm font-medium shadow-lg ${
            notification.type === "success"
              ? "bg-green-50 text-green-800"
              : "bg-red-50 text-red-800"
          }`}
        >
          {notification.type === "success" ? (
            <CheckCircle2 className="h-4 w-4" />
          ) : (
            <AlertTriangle className="h-4 w-4" />
          )}
          {notification.message}
        </div>
      )}

      {/* Stats cards */}
      {stats && (
        <div className="grid grid-cols-2 gap-4 sm:grid-cols-3 lg:grid-cols-6">
          <Card>
            <CardContent className="p-4 text-center">
              <p className="text-2xl font-bold">{stats.total}</p>
              <p className="text-xs text-muted-foreground">Total Tasks</p>
            </CardContent>
          </Card>
          {Object.entries(stats.by_dimension).map(([dim, data]) => (
            <Card key={dim}>
              <CardContent className="p-4 text-center">
                <p className="text-xl font-bold">{data.total}</p>
                <p className="text-xs text-muted-foreground">
                  {DIMENSION_META[dim]?.emoji ?? ""}{" "}
                  {DIMENSION_META[dim]?.label ?? dim}
                </p>
              </CardContent>
            </Card>
          ))}
        </div>
      )}

      {/* Toolbar */}
      <Card>
        <CardContent className="p-4">
          <div className="flex flex-wrap items-center gap-3">
            {/* Search */}
            <form onSubmit={handleSearch} className="flex gap-2">
              <div className="relative">
                <Search className="absolute left-3 top-2.5 h-4 w-4 text-muted-foreground" />
                <input
                  value={searchInput}
                  onChange={(e) => setSearchInput(e.target.value)}
                  placeholder="Search tasks..."
                  className="rounded border py-2 pl-9 pr-3 text-sm"
                />
              </div>
              <button
                type="submit"
                className="rounded border px-3 py-2 text-sm hover:bg-gray-50"
              >
                Search
              </button>
            </form>

            {/* Filters */}
            <select
              value={dimension}
              onChange={(e) => { setDimension(e.target.value); setPage(1); }}
              className="rounded border px-3 py-2 text-sm"
            >
              <option value="">All Dimensions</option>
              {stats?.dimensions.map((d) => (
                <option key={d} value={d}>
                  {DIMENSION_META[d]?.label ?? d}
                </option>
              ))}
            </select>

            <select
              value={levelFilter}
              onChange={(e) => { setLevelFilter(e.target.value); setPage(1); }}
              className="rounded border px-3 py-2 text-sm"
            >
              <option value="">All Levels</option>
              {[0, 1, 2, 3, 4].map((l) => (
                <option key={l} value={l}>Level {l}</option>
              ))}
            </select>

            <select
              value={taskTypeFilter}
              onChange={(e) => { setTaskTypeFilter(e.target.value); setPage(1); }}
              className="rounded border px-3 py-2 text-sm"
            >
              <option value="">All Types</option>
              {stats?.task_types.map((t) => (
                <option key={t} value={t}>{t}</option>
              ))}
            </select>

            <div className="flex-1" />

            {/* Actions */}
            {selected.size > 0 && (
              <button
                onClick={handleBatchDelete}
                className="flex items-center gap-1 rounded bg-red-600 px-3 py-2 text-sm text-white hover:bg-red-700"
              >
                <Trash2 className="h-4 w-4" />
                Delete ({selected.size})
              </button>
            )}

            <button
              onClick={() => setEditingTask(null)}
              className="flex items-center gap-1 rounded bg-primary px-3 py-2 text-sm text-white hover:bg-primary/90"
            >
              <Plus className="h-4 w-4" /> New Task
            </button>

            <button
              onClick={() => setShowImport(true)}
              className="flex items-center gap-1 rounded border px-3 py-2 text-sm hover:bg-gray-50"
            >
              <Upload className="h-4 w-4" /> Import
            </button>

            {/* Export dropdown */}
            <div className="relative group">
              <button className="flex items-center gap-1 rounded border px-3 py-2 text-sm hover:bg-gray-50">
                <Download className="h-4 w-4" /> Export
              </button>
              <div className="absolute right-0 top-full z-10 mt-1 hidden w-44 rounded border bg-white shadow-lg group-hover:block">
                <a
                  href={api.exportTasksJSON(dimension || undefined)}
                  className="flex items-center gap-2 px-4 py-2 text-sm hover:bg-gray-50"
                  download
                >
                  <FileJson className="h-4 w-4" /> Export JSON
                </a>
                <a
                  href={api.exportTasksCSV(dimension || undefined)}
                  className="flex items-center gap-2 px-4 py-2 text-sm hover:bg-gray-50"
                  download
                >
                  <FileSpreadsheet className="h-4 w-4" /> Export CSV
                </a>
              </div>
            </div>
          </div>
        </CardContent>
      </Card>

      {/* Task list */}
      <Card>
        <CardHeader className="pb-2">
          <div className="flex items-center justify-between">
            <CardTitle className="flex items-center gap-2 text-base">
              <Database className="h-4 w-4" />
              Tasks {tasksPage && `(${tasksPage.total})`}
            </CardTitle>
            {tasksPage && tasksPage.total_pages > 1 && (
              <div className="flex items-center gap-2 text-sm">
                <button
                  onClick={() => setPage((p) => Math.max(1, p - 1))}
                  disabled={page <= 1}
                  className="rounded border p-1 hover:bg-gray-50 disabled:opacity-30"
                >
                  <ChevronLeft className="h-4 w-4" />
                </button>
                <span className="text-muted-foreground">
                  Page {page} of {tasksPage.total_pages}
                </span>
                <button
                  onClick={() =>
                    setPage((p) => Math.min(tasksPage.total_pages, p + 1))
                  }
                  disabled={page >= tasksPage.total_pages}
                  className="rounded border p-1 hover:bg-gray-50 disabled:opacity-30"
                >
                  <ChevronRight className="h-4 w-4" />
                </button>
              </div>
            )}
          </div>
        </CardHeader>
        <CardContent>
          {loading ? (
            <div className="space-y-2">
              {Array.from({ length: 5 }).map((_, i) => (
                <Skeleton key={i} className="h-12 rounded" />
              ))}
            </div>
          ) : !tasksPage || tasksPage.tasks.length === 0 ? (
            <p className="py-8 text-center text-muted-foreground">
              No tasks found. Try adjusting filters or create a new task.
            </p>
          ) : (
            <div className="overflow-x-auto">
              <table className="w-full text-sm">
                <thead>
                  <tr className="border-b text-left text-xs text-muted-foreground">
                    <th className="px-2 py-2">
                      <input
                        type="checkbox"
                        checked={
                          tasksPage.tasks.length > 0 &&
                          selected.size === tasksPage.tasks.length
                        }
                        onChange={toggleSelectAll}
                      />
                    </th>
                    <th className="px-2 py-2">Dimension</th>
                    <th className="px-2 py-2">Lvl</th>
                    <th className="px-2 py-2">Type</th>
                    <th className="px-2 py-2">Preview</th>
                    <th className="px-2 py-2">Flags</th>
                    <th className="px-2 py-2 text-right">Actions</th>
                  </tr>
                </thead>
                <tbody>
                  {tasksPage.tasks.map((task) => (
                    <tr
                      key={task.id}
                      className="border-b last:border-0 hover:bg-gray-50"
                    >
                      <td className="px-2 py-2">
                        <input
                          type="checkbox"
                          checked={selected.has(task.id)}
                          onChange={() => toggleSelect(task.id)}
                        />
                      </td>
                      <td className="px-2 py-2">
                        <span className="whitespace-nowrap">
                          {DIMENSION_META[task.dimension]?.emoji ?? ""}{" "}
                          {DIMENSION_META[task.dimension]?.label ?? task.dimension}
                        </span>
                      </td>
                      <td className="px-2 py-2">{task.level}</td>
                      <td className="px-2 py-2">
                        <Badge variant="secondary" className="text-xs">
                          {task.task_type}
                        </Badge>
                      </td>
                      <td className="max-w-xs truncate px-2 py-2 text-muted-foreground">
                        {getTaskPreview(task.content)}
                      </td>
                      <td className="px-2 py-2">
                        {task.is_assessment && (
                          <Badge variant="default" className="text-xs">
                            Assessment
                          </Badge>
                        )}
                      </td>
                      <td className="px-2 py-2 text-right">
                        <div className="flex justify-end gap-1">
                          <button
                            onClick={() => setEditingTask(task)}
                            className="rounded p-1 text-muted-foreground hover:bg-gray-100 hover:text-foreground"
                            title="Edit"
                          >
                            <Save className="h-4 w-4" />
                          </button>
                          <button
                            onClick={() => handleDelete(task.id)}
                            className="rounded p-1 text-muted-foreground hover:bg-red-50 hover:text-red-600"
                            title="Delete"
                          >
                            <Trash2 className="h-4 w-4" />
                          </button>
                        </div>
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          )}
        </CardContent>
      </Card>

      {/* Modals */}
      {editingTask !== undefined && stats && (
        <TaskEditor
          task={editingTask}
          dimensions={stats.dimensions}
          taskTypes={stats.task_types}
          onSave={handleSaveTask}
          onCancel={() => setEditingTask(undefined)}
        />
      )}
      {showImport && (
        <ImportModal onClose={() => setShowImport(false)} onImported={handleImported} />
      )}
    </div>
  );
}
