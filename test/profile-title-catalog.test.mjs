import assert from "node:assert/strict";
import { buildProfileTitleCatalog } from "../dist/db/profile-title-catalog.js";

const catalog = buildProfileTitleCatalog();
const titles = catalog.titles;
const requirements = catalog.requirements;

assert.equal(catalog.series.length, 1);
assert.deepEqual(catalog.series[0], {
  key: "color_mastery",
  label: "Color Mastery",
  description: "Titles earned by completing games with specific leader color identities.",
  active: true,
  sort_order: 100,
});

assert.equal(titles.length, 105);
assert.equal(requirements.length, 105);

const keyPattern = /^[a-z0-9][a-z0-9_-]{1,63}$/u;
for (const title of titles) {
  assert.match(title.key, keyPattern);
  assert.equal(title.series_key, "color_mastery");
  assert.equal(title.unlock_mode, "automatic");
  assert.equal(title.active, true);
  assert.equal(typeof title.series_item_label, "string");
}

const buckets = new Set(titles.map((title) => title.series_item_key));
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
  const bucketTitles = titles.filter((title) => title.series_item_key === bucket);
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
