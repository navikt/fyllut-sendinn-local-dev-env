---
name: pr-list
description: Find one pull request or a copyable list of pull requests related to a completed task. Use when preparing pull requests for teammates to review, including requests to find open PRs by task, feature, migration, upgrade, or bug fix.
license: MIT
metadata:
  version: "1.0.0"
---

# List task-related pull requests

Find the pull requests connected to a user's stated task and return a concise
Slack-ready list. The default output is for review requests, so include only
open pull requests unless the user asks for another state.

## Resolve the search

1. Treat the task words supplied by the user as search terms. Use its key
   nouns, identifiers, component names, issue numbers, and version numbers.
   Do not add unrelated guesses.
2. Default the author to the authenticated GitHub user. Resolve their login
   with:

   ```sh
   gh api user --jq .login
   ```

   Use a named author when the user supplies one.
3. Search all repositories unless the user supplies a repository or
   organization. Search title and body first:

   ```sh
   gh search prs \
     --author <login> \
     --state open \
     --match title,body \
     --limit 100 \
     '<task terms>' \
     --json repository,number,title,url,createdAt,updatedAt,isDraft
   ```

4. If the user asks for a particular PR, resolve it from its number, URL, or
   repository and number. Fetch it with `gh pr view`, using `--repo` outside a
   checkout.
5. When the first search returns no results, retry with the most distinctive
   task term. Report no matches if that also returns none. Do not invent a
   connection between a PR and the task.
6. Verify each candidate's state, author, title, URL, and draft status with
   `gh pr view <number> --repo <owner/repository>`. Remove results that no
   longer match the requested state or author.

## Return Slack-ready output

Return only a short introduction and one copyable Markdown bullet per pull
request. Use Slack link syntax so the repository, PR number, and title are one
clickable label:

```text
Open PRs for <task>:

- <https://github.com/owner/repository/pull/123|owner/repository #123: PR title>
- <https://github.com/owner/repository/pull/456|owner/repository #456: PR title> (draft)
```

For one result, use `Open PR for <task>:`. Preserve GitHub's exact PR title.
Mark a draft only when GitHub reports it as a draft. Do not include creation
dates, update dates, author names, explanations, or a table unless the user
asks for them.
