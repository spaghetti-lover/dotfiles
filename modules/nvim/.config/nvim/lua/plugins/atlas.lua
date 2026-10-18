local function current_repo()
  local repo = require("atlas.core.git").local_repository()
  if repo and (repo.provider == "github" or repo.provider == "gitlab") then
    return repo
  end
end

local function open_for_repo(command)
  local repo = current_repo()
  vim.cmd("Atlas " .. command .. (repo and (" " .. repo.provider) or ""))
end

local function create_issue()
  local repo = current_repo()
  if not repo then
    vim.cmd("Atlas create issue")
    return
  end

  local provider = require("atlas.providers").load(repo.provider, "issues")
  require("atlas.issues.actions").run("create_issue", {
    provider = provider,
    repo_slug = repo.repo_full_name,
    project_path = repo.project_path,
  })
end

local function gitlab_token()
  if vim.env.GITLAB_TOKEN and vim.env.GITLAB_TOKEN ~= "" then
    return vim.env.GITLAB_TOKEN
  end
  if vim.fn.executable("glab") == 0 then
    return nil
  end

  local result = vim.system(
    { "glab", "config", "get", "token", "--host", "gitlab-eng.dytechlab.com" },
    { text = true }
  ):wait(5000)
  if result.code == 0 then
    local token = vim.trim(result.stdout or "")
    if token ~= "" then
      return token
    end
  end
end

local function use_gitlab_ca_bundle()
  if vim.env.CURL_CA_BUNDLE and vim.env.CURL_CA_BUNDLE ~= "" then
    return
  end

  -- The Bash setup writes a bundle containing both system roots and the internal CA.
  local cache_homes = { vim.fn.expand("~/.cache") }
  if vim.env.XDG_CACHE_HOME and vim.env.XDG_CACHE_HOME ~= "" then
    table.insert(cache_homes, 1, vim.env.XDG_CACHE_HOME)
  end
  for _, cache_home in ipairs(cache_homes) do
    local bundle = cache_home .. "/dotfiles/gitlab-ca-bundle.pem"
    if vim.fn.filereadable(bundle) == 1 then
      vim.env.CURL_CA_BUNDLE = bundle
      return
    end
  end
end

return {
  {
    "emrearmagan/atlas.nvim",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    cmd = { "Atlas", "AtlasDiff" },
    keys = {
      { "<leader>gaa", "<cmd>Atlas<cr>", desc = "Atlas commands" },
      {
        "<leader>gap",
        function()
          open_for_repo("pulls")
        end,
        desc = "Pull requests or merge requests for current host",
      },
      {
        "<leader>gai",
        function()
          open_for_repo("issues")
        end,
        desc = "Issues for current host",
      },
      { "<leader>gar", "<cmd>Atlas review<cr>", desc = "Review pull request" },
      { "<leader>gac", "<cmd>Atlas create pr<cr>", desc = "Create pull request" },
      { "<leader>gaI", create_issue, desc = "Create issue for current host" },
      {
        "<leader>gas",
        function()
          open_for_repo("search")
        end,
        desc = "Search current host",
      },
      { "<leader>gan", "<cmd>Atlas notes<cr>", desc = "Local review notes" },
      { "<leader>gal", "<cmd>Atlas logs<cr>", desc = "Atlas logs" },
    },
    config = function(_, opts)
      use_gitlab_ca_bundle()
      opts.providers.gitlab.token = gitlab_token()
      require("atlas").setup(opts)

      local theme = require("config.atlas_theme")
      theme.apply()
      vim.api.nvim_create_autocmd("ColorScheme", {
        group = vim.api.nvim_create_augroup("AtlasCurrentTheme", { clear = true }),
        callback = theme.apply,
      })
    end,
    opts = {
      ui = { picker = "snacks" },
      providers = {
        github = {},
        gitlab = {
          base_url = vim.env.GITLAB_URL or "https://gitlab-eng.dytechlab.com",
        },
      },
      pulls = {
        diff = { layout = "side-by-side" },
        github = {
          views = {
            { name = "Assigned", key = "1", layout = "plain", search = "assignee:@me archived:false" },
            { name = "Authored", key = "2", layout = "plain", search = "author:@me archived:false" },
            { name = "Reviewing", key = "3", layout = "compact", search = "review-requested:@me archived:false" },
            { name = "Mentions", key = "4", layout = "compact", search = "mentions:@me archived:false" },
            {
              name = "All (current repo)",
              key = "5",
              layout = "compact",
              current_repo = true,
              search = "(is:open OR is:merged OR is:closed -is:merged)",
            },
          },
          bookmarks = {
            items = {
              ["Drafts"] = "is:pr is:draft author:@me",
              ["Recently merged"] = "is:pr is:merged author:@me sort:updated-desc",
              ["Involves me"] = "is:pr involves:@me sort:updated-desc",
            },
          },
        },
        gitlab = {
          views = {
            { name = "Assigned", key = "1", current_repo = true, scope = "assigned_to_me", order_by = "updated_at" },
            { name = "Created", key = "2", current_repo = true, scope = "created_by_me", order_by = "updated_at" },
            { name = "Reviewing", key = "3", current_repo = true, scope = "reviews_for_me", order_by = "updated_at" },
            {
              name = "All (current project)",
              key = "4",
              current_repo = true,
              scope = "all",
              order_by = "updated_at",
              extra_params = { state = "all" },
            },
          },
        },
      },
      issues = {
        github = {
          views = {
            { name = "Assigned", key = "1", layout = "plain", search = "assignee:@me is:open" },
            { name = "Created", key = "2", layout = "plain", search = "author:@me is:open" },
            { name = "Mentions", key = "3", layout = "compact", search = "mentions:@me is:open" },
          },
          bookmarks = {
            items = {
              ["Bugs"] = "is:issue is:open label:bug",
              ["Recently closed"] = "is:issue is:closed author:@me sort:updated-desc",
            },
          },
        },
        gitlab = {
          views = {
            { name = "Assigned", key = "1", current_repo = true, scope = "assigned_to_me", state = "opened" },
            { name = "Created", key = "2", current_repo = true, scope = "created_by_me", state = "opened" },
            { name = "All open (current project)", key = "3", current_repo = true, scope = "all", state = "opened" },
          },
        },
      },
    },
  },
}
