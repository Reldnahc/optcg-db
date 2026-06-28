import type { AuthProfileTitleUnlockMode } from "./schema.js";

export type ProfileTitleCatalogSeries = {
  key: string;
  label: string;
  description: string | null;
  active: boolean;
  sort_order: number;
};

export type ProfileTitleCatalogTitle = {
  key: string;
  label: string;
  unlock_mode: AuthProfileTitleUnlockMode;
  style: Record<string, unknown>;
  active: boolean;
  sort_order: number;
  series_key: string;
  series_item_key: string;
  series_item_label: string;
  tier_key: string;
};

export type ProfileTitleCatalogRequirement = {
  title_key: string;
  stat_key: string;
  operator: "gte";
  threshold: bigint;
};

export type ProfileTitleCatalog = {
  series: ProfileTitleCatalogSeries[];
  titles: ProfileTitleCatalogTitle[];
  requirements: ProfileTitleCatalogRequirement[];
};

type ColorKey = "red" | "green" | "blue" | "purple" | "black" | "yellow";

type ColorConfig = {
  key: ColorKey;
  label: string;
  color: string;
  glow: string;
};

type ColorBucketConfig = {
  key: string;
  label: string;
  colors: readonly ColorConfig[];
};

type ColorMasteryTier = {
  key: "novice" | "adept" | "enjoyer" | "expert" | "master";
  label: string;
  threshold: bigint;
};

export const colorMasterySeries: ProfileTitleCatalogSeries = {
  key: "color_mastery",
  label: "Color Mastery",
  description: "Titles earned by completing games with specific leader color identities.",
  active: true,
  sort_order: 100,
};

const colorConfigs: readonly ColorConfig[] = [
  { key: "red", label: "Red", color: "#ef4444", glow: "#f87171" },
  { key: "green", label: "Green", color: "#22c55e", glow: "#4ade80" },
  { key: "blue", label: "Blue", color: "#38bdf8", glow: "#7dd3fc" },
  { key: "purple", label: "Purple", color: "#a855f7", glow: "#c084fc" },
  { key: "black", label: "Black", color: "#d1d5db", glow: "#9ca3af" },
  { key: "yellow", label: "Yellow", color: "#facc15", glow: "#fde047" },
];

const colorMasteryTiers: readonly ColorMasteryTier[] = [
  { key: "novice", label: "Novice", threshold: 10n },
  { key: "adept", label: "Adept", threshold: 25n },
  { key: "enjoyer", label: "Enjoyer", threshold: 100n },
  { key: "expert", label: "Expert", threshold: 500n },
  { key: "master", label: "Master", threshold: 1000n },
];

function colorBuckets(): ColorBucketConfig[] {
  const buckets: ColorBucketConfig[] = colorConfigs.map((color) => ({
    key: `mono-${color.key}`,
    label: color.label,
    colors: [color],
  }));
  for (let leftIndex = 0; leftIndex < colorConfigs.length; leftIndex += 1) {
    for (let rightIndex = leftIndex + 1; rightIndex < colorConfigs.length; rightIndex += 1) {
      const left = colorConfigs[leftIndex];
      const right = colorConfigs[rightIndex];
      buckets.push({
        key: `${left.key}-${right.key}`,
        label: `${left.label}-${right.label}`,
        colors: [left, right],
      });
    }
  }
  return buckets;
}

function colorMasteryStyle(bucket: ColorBucketConfig, tierIndex: number): Record<string, unknown> {
  const [primary, secondary] = bucket.colors;
  if (tierIndex === 0) {
    return {
      text_color: "#e8e9ed",
      font_family: "display",
      font_weight: 700,
      animation: "none",
    };
  }
  const gradient = secondary === undefined
    ? { from: primary.color, to: primary.glow, angle: 90 }
    : { from: primary.color, to: secondary.color, angle: 90 };
  if (tierIndex === 1) {
    return {
      text_color: primary.color,
      font_family: "display",
      font_weight: 750,
      gradient,
      animation: "none",
    };
  }
  if (tierIndex === 2) {
    return {
      text_color: primary.color,
      font_family: "display",
      font_weight: 800,
      gradient,
      glow_color: primary.glow,
      animation: "none",
    };
  }
  return {
    text_color: primary.color,
    font_family: "display",
    font_weight: 900,
    gradient,
    glow_color: primary.glow,
    animation: "shine",
  };
}

export function buildProfileTitleCatalog(): ProfileTitleCatalog {
  const titles: ProfileTitleCatalogTitle[] = [];
  const requirements: ProfileTitleCatalogRequirement[] = [];
  const buckets = colorBuckets();
  for (const [bucketIndex, bucket] of buckets.entries()) {
    for (const [tierIndex, tier] of colorMasteryTiers.entries()) {
      const titleKey = `color_mastery_${bucket.key}_${tier.key}`;
      titles.push({
        key: titleKey,
        label: `${bucket.label} ${tier.label}`,
        unlock_mode: "automatic",
        style: colorMasteryStyle(bucket, tierIndex),
        active: true,
        sort_order: colorMasterySeries.sort_order + bucketIndex * 10 + tierIndex,
        series_key: colorMasterySeries.key,
        series_item_key: bucket.key,
        series_item_label: bucket.label,
        tier_key: tier.key,
      });
      requirements.push({
        title_key: titleKey,
        stat_key: `leader_color_matches_completed:${bucket.key}`,
        operator: "gte",
        threshold: tier.threshold,
      });
    }
  }
  return {
    series: [colorMasterySeries],
    titles,
    requirements,
  };
}
