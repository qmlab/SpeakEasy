export const DIMENSION_META: Record<
  string,
  { label: string; emoji: string; color: string; levels: string[] }
> = {
  object_cognition: {
    label: "Object Cognition",
    emoji: "🧩",
    color: "bg-blue-500",
    levels: ["Match", "Identify", "Classify", "Function", "Abstract"],
  },
  language_expression: {
    label: "Language Expression",
    emoji: "🗣️",
    color: "bg-green-500",
    levels: ["Imitate", "Name Object", "Describe", "Build Sentence", "Conversation"],
  },
  language_comprehension: {
    label: "Language Comprehension",
    emoji: "👂",
    color: "bg-purple-500",
    levels: ["Point To", "Follow Instruction", "Story Comprehension", "Infer Meaning", "Complex"],
  },
  literacy: {
    label: "Literacy",
    emoji: "📖",
    color: "bg-orange-500",
    levels: ["Recognize Image", "Match Word-Image", "Read Word", "Read Sentence", "Read Passage"],
  },
  social_behavior: {
    label: "Social Behavior",
    emoji: "🤝",
    color: "bg-pink-500",
    levels: ["Attend", "Imitate Action", "Turn Take", "Joint Attention", "Initiate"],
  },
  cognitive_logic: {
    label: "Cognitive Logic",
    emoji: "🧠",
    color: "bg-indigo-500",
    levels: ["Pair", "Sort", "Cause & Effect", "Sequence", "Reason"],
  },
};

export const DIMENSION_KEYS = Object.keys(DIMENSION_META);

export function getDimensionLabel(dim: string): string {
  return DIMENSION_META[dim]?.label ?? dim;
}

export function getDimensionEmoji(dim: string): string {
  return DIMENSION_META[dim]?.emoji ?? "📋";
}

export function getLevelLabel(dim: string, level: number): string {
  const meta = DIMENSION_META[dim];
  if (!meta) return `Level ${level}`;
  return meta.levels[level] ?? `Level ${level}`;
}
