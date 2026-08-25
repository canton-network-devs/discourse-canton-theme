import { apiInitializer } from "discourse/lib/api";

function normalizePath(path) {
  try {
    const url = new URL(path, window.location.origin);
    return url.pathname.replace(/\/+$/, "") || "/";
  } catch {
    return (path || "/").replace(/\/+$/, "") || "/";
  }
}

function parseThemePaths(pathsSetting) {
  const raw = Array.isArray(pathsSetting)
    ? pathsSetting
    : String(pathsSetting || "")
        .split("\n")
        .map((s) => s.trim())
        .filter(Boolean);

  return raw.map(normalizePath);
}

export default apiInitializer("0.8.7", (api) => {
  const landingPaths = parseThemePaths(
    settings?.canton_landing_paths ?? "/\n/categories"
  );

  let createTopicHome = null;

  function isLandingPath(url) {
    const path = normalizePath(url || window.location.pathname);
    return landingPaths.includes(path);
  }

  function setLandingFlag(on) {
    document.documentElement.toggleAttribute("data-canton-landing", !!on);
  }

  function moveCreateTopicButtonIntoHero() {
    const hero = document.querySelector("[data-canton-hero]");
    const actions = document.querySelector("[data-canton-hero-actions]");

    if (!hero || !actions) {
      return;
    }

    const btn = document.querySelector("#create-topic");
    if (!btn) {
      return;
    }

    if (!createTopicHome) {
      const placeholder = document.createElement("span");
      placeholder.setAttribute("data-canton-create-topic-home", "");
      btn.parentElement?.insertBefore(placeholder, btn);
      createTopicHome = placeholder;
    }

    if (btn.closest("[data-canton-hero-actions]")) {
      return;
    }

    actions.appendChild(btn);
  }

  function restoreCreateTopicButton() {
    const btn = document.querySelector("#create-topic");
    if (!btn || !createTopicHome?.parentElement) {
      return;
    }

    if (btn.previousElementSibling === createTopicHome) {
      return;
    }

    createTopicHome.parentElement.insertBefore(btn, createTopicHome);
  }

  api.onPageChange((url) => {
    const enabled = !!settings?.canton_enable_landing_hero;
    const onLanding = enabled && isLandingPath(url);

    setLandingFlag(onLanding);

    if (onLanding) {
      // Let Ember render the page content first, then move blocks.
      requestAnimationFrame(() => {
        moveCreateTopicButtonIntoHero();
      });
    } else {
      restoreCreateTopicButton();
    }
  });
});

