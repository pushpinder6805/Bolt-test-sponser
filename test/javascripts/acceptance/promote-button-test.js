import { acceptance, query } from "discourse/tests/helpers/qunit-helpers";
import { test } from "qunit";

acceptance("Promote Button", function (needs) {
  needs.user();

  test("shows promote button on posts", async function (assert) {
    // Visit a topic with posts
    await visit("/t/1"); // change '1' to a known topic ID in dev DB

    // Check if the promote button exists
    const button = query(".promote-post-btn");

    assert.ok(button, "Promote button is rendered on the post menu");
  });
});
