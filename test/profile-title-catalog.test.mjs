import assert from "node:assert/strict";
import { buildProfileTitleCatalog } from "../dist/db/profile-title-catalog.js";

const catalog = buildProfileTitleCatalog();
const titles = catalog.titles;
const requirements = catalog.requirements;

assert.equal(catalog.series.length, 2);
assert.deepEqual(catalog.series[0], {
  key: "color_mastery",
  label: "Color Mastery",
  description: "Titles earned by completing games with specific leader color identities.",
  active: true,
  sort_order: 100,
});
assert.deepEqual(catalog.series[1], {
  key: "bot_wins",
  label: "Bot Wins",
  description: "Titles earned by winning games against the bot.",
  active: true,
  sort_order: 200,
});

assert.equal(titles.length, 110);
assert.equal(requirements.length, 110);

const keyPattern = /^[a-z0-9][a-z0-9_-]{1,63}$/u;
for (const title of titles) {
  assert.match(title.key, keyPattern);
  assert.ok(["color_mastery", "bot_wins"].includes(title.series_key));
  assert.equal(title.unlock_mode, "automatic");
  assert.equal(title.active, true);
  assert.equal(typeof title.series_item_label, "string");
}

const colorTitles = titles.filter((title) => title.series_key === "color_mastery");
const buckets = new Set(colorTitles.map((title) => title.series_item_key));
assert.equal(buckets.size, 21);
assert.deepEqual([...buckets], [
  "mono-red",
  "mono-green",
  "mono-blue",
  "mono-purple",
  "mono-black",
  "mono-yellow",
  "red-green",
  "red-blue",
  "red-purple",
  "red-black",
  "red-yellow",
  "green-blue",
  "green-purple",
  "green-black",
  "green-yellow",
  "blue-purple",
  "blue-black",
  "blue-yellow",
  "purple-black",
  "purple-yellow",
  "black-yellow",
]);

for (const bucket of buckets) {
  const bucketTitles = colorTitles.filter((title) => title.series_item_key === bucket);
  assert.deepEqual(bucketTitles.map((title) => title.tier_key), [
    "novice",
    "adept",
    "enjoyer",
    "expert",
    "master",
  ]);
  assert.deepEqual(
    requirements
      .filter((requirement) => requirement.title_key.startsWith(`color_mastery_${bucket}_`))
      .map((requirement) => requirement.threshold.toString()),
    ["10", "25", "100", "500", "1000"],
  );
}

assert.equal(
  titles.find((title) => title.key === "color_mastery_mono-red_master")?.label,
  "Red Master",
);
assert.equal(
  titles.find((title) => title.key === "color_mastery_red-blue_enjoyer")?.label,
  "Red-Blue Enjoyer",
);
assert.equal(
  requirements.find((requirement) => requirement.title_key === "color_mastery_red-blue_master")?.stat_key,
  "leader_color_matches_completed:red-blue",
);

const botTitles = titles.filter((title) => title.series_key === "bot_wins");
assert.deepEqual(
  botTitles.map((title) => [title.key, title.label, title.series_item_key, title.tier_key]),
  [
    ["first_bot_win", "Bot Basher", "bot", "basher"],
    ["bot_wins_breaker", "Bot Breaker", "bot", "breaker"],
    ["bot_wins_hunter", "Bot Hunter", "bot", "hunter"],
    ["bot_wins_slayer", "Bot Slayer", "bot", "slayer"],
    ["bot_wins_machine_reaper", "Machine Reaper", "bot", "machine_reaper"],
  ],
);
assert.deepEqual(
  botTitles.map((title) => title.style),
  [
    {
      text_color: "#e8e9ed",
      font_family: "display",
      font_weight: 700,
      animation: "none",
    },
    {
      text_color: "#60a5fa",
      font_family: "display",
      font_weight: 750,
      animation: "none",
    },
    {
      text_color: "#60a5fa",
      font_family: "display",
      font_weight: 800,
      glow_color: "#93c5fd",
      animation: "none",
    },
    {
      text_color: "#60a5fa",
      font_family: "display",
      font_weight: 900,
      gradient: { from: "#60a5fa", to: "#c084fc", angle: 90 },
      glow_color: "#93c5fd",
      animation: "shine",
    },
    {
      text_color: "#f8fafc",
      font_family: "display",
      font_weight: 900,
      gradient: { from: "#f8fafc", via: "#60a5fa", to: "#c084fc", angle: 90 },
      glow_color: "#c084fc",
      animation: "shine",
    },
  ],
);
assert.deepEqual(
  requirements
    .filter((requirement) => requirement.title_key === "first_bot_win" || requirement.title_key.startsWith("bot_wins_"))
    .map((requirement) => [requirement.title_key, requirement.stat_key, requirement.threshold.toString()]),
  [
    ["first_bot_win", "bot_matches_won", "1"],
    ["bot_wins_breaker", "bot_matches_won", "100"],
    ["bot_wins_hunter", "bot_matches_won", "500"],
    ["bot_wins_slayer", "bot_matches_won", "1000"],
    ["bot_wins_machine_reaper", "bot_matches_won", "5000"],
  ],
);
