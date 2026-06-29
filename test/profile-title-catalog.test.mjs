import assert from "node:assert/strict";
import {
  buildLeaderNameTitleCatalog,
  buildProfileTitleCatalog,
  leaderNameKey,
  managedProfileTitleSeriesKeys,
} from "../dist/db/profile-title-catalog.js";

const catalog = buildProfileTitleCatalog();
const titles = catalog.titles;
const requirements = catalog.requirements;

assert.equal(catalog.series.length, 3);
assert.deepEqual(catalog.series[0], {
  key: "sim_access",
  label: "Sim Access",
  description: "Titles granted with simulator access permissions.",
  active: true,
  sort_order: 50,
});
assert.deepEqual(catalog.series[1], {
  key: "color_mastery",
  label: "Color Mastery",
  description: "Titles earned by completing games with specific leader color identities.",
  active: true,
  sort_order: 100,
});
assert.deepEqual(catalog.series[2], {
  key: "bot_wins",
  label: "Bot Wins",
  description: "Titles earned by winning games against the bot.",
  active: true,
  sort_order: 200,
});
assert.deepEqual(managedProfileTitleSeriesKeys, [
  "sim_access",
  "color_mastery",
  "bot_wins",
  "leader_name_mastery",
]);

assert.equal(titles.length, 112);
assert.equal(requirements.length, 110);

const keyPattern = /^[a-z0-9][a-z0-9_-]{1,63}$/u;
for (const title of titles) {
  assert.match(title.key, keyPattern);
  assert.ok(["sim_access", "color_mastery", "bot_wins"].includes(title.series_key));
  assert.ok(["manual", "automatic"].includes(title.unlock_mode));
  assert.equal(title.active, true);
  assert.equal(typeof title.series_item_label, "string");
}

const simAccessTitles = titles.filter((title) => title.series_key === "sim_access");
assert.deepEqual(
  simAccessTitles.map((title) => [title.key, title.label, title.unlock_mode, title.series_item_key, title.tier_key]),
  [
    ["tester", "Tester", "manual", "dev", "access"],
    ["developer", "Developer", "manual", "local", "access"],
  ],
);

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

assert.equal(leaderNameKey("Monkey.D.Luffy"), "monkey-d-luffy");
assert.equal(leaderNameKey("Roronoa Zoro"), "roronoa-zoro");
assert.equal(leaderNameKey("   Trafalgar   Law   "), "trafalgar-law");

const leaderCatalog = buildLeaderNameTitleCatalog([
  "Monkey.D.Luffy",
  "Monkey D Luffy",
  "Roronoa Zoro",
]);
assert.deepEqual(leaderCatalog.series, [
  {
    key: "leader_name_mastery",
    label: "Leader Name Mastery",
    description: "Titles earned by completing games with leaders that share a canonical name.",
    active: true,
    sort_order: 300,
  },
]);
assert.equal(leaderCatalog.titles.length, 10);
assert.equal(leaderCatalog.requirements.length, 10);
assert.deepEqual(
  leaderCatalog.titles
    .filter((title) => title.series_item_key === "monkey-d-luffy")
    .map((title) => [title.key, title.label, title.tier_key]),
  [
    ["leader_name_mastery_monkey-d-luffy_novice", "Monkey.D.Luffy Novice", "novice"],
    ["leader_name_mastery_monkey-d-luffy_adept", "Monkey.D.Luffy Adept", "adept"],
    ["leader_name_mastery_monkey-d-luffy_enjoyer", "Monkey.D.Luffy Enjoyer", "enjoyer"],
    ["leader_name_mastery_monkey-d-luffy_expert", "Monkey.D.Luffy Expert", "expert"],
    ["leader_name_mastery_monkey-d-luffy_master", "Monkey.D.Luffy Master", "master"],
  ],
);
assert.deepEqual(
  leaderCatalog.requirements
    .filter((requirement) => requirement.title_key.startsWith("leader_name_mastery_monkey-d-luffy_"))
    .map((requirement) => [requirement.stat_key, requirement.threshold.toString()]),
  [
    ["leader_name_matches_completed:monkey-d-luffy", "10"],
    ["leader_name_matches_completed:monkey-d-luffy", "25"],
    ["leader_name_matches_completed:monkey-d-luffy", "100"],
    ["leader_name_matches_completed:monkey-d-luffy", "500"],
    ["leader_name_matches_completed:monkey-d-luffy", "1000"],
  ],
);
assert.deepEqual(
  leaderCatalog.titles.find((title) => title.key === "leader_name_mastery_monkey-d-luffy_novice")?.style,
  {
    text_color: "#e8e9ed",
    font_family: "display",
    font_weight: 700,
    animation: "none",
  },
);
assert.deepEqual(
  leaderCatalog.titles.find((title) => title.key === "leader_name_mastery_monkey-d-luffy_master")?.style,
  {
    text_color: "#22d3ee",
    font_family: "display",
    font_weight: 900,
    gradient: { from: "#22d3ee", via: "#a78bfa", to: "#67e8f9", angle: 90 },
    glow_color: "#67e8f9",
    animation: "shine",
  },
);
